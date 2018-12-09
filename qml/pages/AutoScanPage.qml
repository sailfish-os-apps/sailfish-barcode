/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018 Slava Monich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import QtQuick 2.0
import QtMultimedia 5.4
import Sailfish.Silica 1.0
import org.nemomobile.notifications 1.0
import harbour.barcode 1.0

import "../js/Utils.js" as Utils
import "../components"

Page {
    id: scanPage

    property Item viewFinder
    property Item hint
    property bool flagAutoScan
    property int scanTimeout: 60
    readonly property string imageProvider: HarbourTheme.darkOnLight ? HarbourImageProviderDarkOnLight : HarbourImageProviderDefault
    readonly property string iconSourcePrefix: "image://" + imageProvider + "/"

    function createScanner() {
        if (viewFinder) {
            return
        }

        console.log("creating viewfinder ...")
        viewFinder = viewFinderComponent.createObject(parentViewFinder, {
            viewfinderResolution: parentViewFinder.viewfinderResolution
        })

        if (viewFinder.source.availability === Camera.Available) {
            viewFinder.source.start()
            autoStart()
        } else {
            stateAbort()
        }
    }

    function destroyScanner() {
        if (!viewFinder) {
            return
        }

        console.log("destroying viewfinder ...")
        scanner.stopScanning()
        viewFinder.source.stop()
        viewFinder.destroy()
        viewFinder = null

        stateInactive()
    }

    function autoStart() {
        if (viewFinder && viewFinder.cameraActive) {
            if (flagAutoScan) {
                console.log("auto-starting scan ...")
                startScan()
            }
            flagAutoScan = false
        }
    }

    function applyResult(result) {
        var text = result.text
        console.log(result.format, text)
        if (text.length > 0) {
            Clipboard.text = text
            var recId = historyModel.insert(text, result.format)
            clickableResult.setValue(recId, text, result.format)
        }
    }

    function requestScan() {
        if (scanPage.status === PageStatus.Active && Qt.application.active && viewFinder.cameraActive) {
            startScan()
        } else {
            flagAutoScan = true
        }
    }

    function startScan() {
        viewFinder.showMarker = false
        stateScanning()
        scanner.startScanning(scanTimeout * 1000)
    }

    function abortScan() {
        stateAbort()
        scanner.stopScanning()
    }

    function stateInactive() {
        state = "INACTIVE"
        statusText.text = ""
        if (viewFinder) viewFinder.turnFlashOff()
    }

    function stateReady() {
        state = "READY"
        //: Scan button label
        //% "Scan"
        actionButton.text = qsTrId("scan-action-scan")
    }

    function stateScanning() {
        state = "SCANNING"
        //: Scan status label
        //% "Scan in progress ..."
        statusText.text = qsTrId("scan-status-busy")
        clickableResult.clear()
        //: Scan button label
        //% "Abort"
        actionButton.text = qsTrId("scan-action-abort")
    }

    function stateAbort() {
        state = "ABORT"
    }

    Component {
        id: hintComponent
        Hint { }
    }

    function showHint(text) {
        if (!hint) {
            hint = hintComponent.createObject(scanPage)
        }
        hint.text = text
        hint.opacity = 1.0
    }

    function hideHint() {
        if (hint) {
            hint.opacity = 0.0
        }
    }

    state: "INACTIVE"

    onStatusChanged: {
        if (scanPage.status === PageStatus.Active) {
            console.log("Page is ACTIVE")
            if (Qt.application.active) {
                createScanner()
            }
        } else if (scanPage.status === PageStatus.Inactive) {
            console.log("Page is INACTIVE")
            // stop scanning if page is not active
            destroyScanner()
        }
    }

    // Pause blanking while scanning
    DisplayBlanking {
        pauseRequested: state === "SCANNING"
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active) {
                console.log("Application is ACTIVE")
                if (scanPage.status === PageStatus.Active) {
                    createScanner()
                }
            } else if (!Qt.application.active) {
                console.log("Application is INACTIVE")
                destroyScanner()
            }
        }
    }

    function cameraStarted() {
        console.log("camera is started")
        stateReady()
        autoStart()
    }

    Notification {
        id: clipboardNotification
        //: Pop-up notification
        //% "Copied to clipboard"
        previewBody: qsTrId("notification-copied_to_clipboard")
        expireTimeout: 2000
        Component.onCompleted: {
            if ("icon" in clipboardNotification) {
                clipboardNotification.icon = "icon-s-clipboard"
            }
        }
    }

    AutoBarcodeScanner {
        id: scanner

        viewFinderItem: parentViewFinder
        markerColor: AppSettings.markerColor

        onDecodingFinished: {
            statusText.text = ""
            if (scanPage.state !== "ABORT") {
                if (result.ok) {
                    applyResult(result)
                    viewFinder.decodingFinished()
                } else if (scanPage.state !== "INACTIVE") {
                    //: Scan status label
                    //% "No code detected! Try again."
                    statusText.text = qsTrId("scan-status-nothing_found")
                }
            }
            stateReady()
        }
    }

    Component {
        id: viewFinderComponent

        VideoOutput {
            id: viewFinderItem
            layer.enabled: true

            anchors.fill: parent
            fillMode: VideoOutput.Stretch
            property bool showMarker: false
            property bool playBeep: false
            property alias digitalZoom: camera.digitalZoom
            property size viewfinderResolution
            property bool completed
            readonly property bool cameraActive: camera.cameraState === Camera.ActiveState
            readonly property bool tapFocusActive: focusTimer.running
            readonly property bool flashOn: camera.flash.mode !== Camera.FlashOff
            // Not sure why not just camera.orientation but this makes the camera
            // behave similar to what it does for Jolla Camera
            readonly property int cameraOrientation: 360 - camera.orientation

            onViewfinderResolutionChanged: {
                if (viewfinderResolution && camera.viewfinder.resolution !== viewfinderResolution) {
                    if (camera.cameraState === Camera.UnloadedState) {
                        camera.viewfinder.resolution = viewfinderResolution
                    } else {
                        reloadTimer.restart()
                    }
                }
            }

            Component.onCompleted: {
                if (viewfinderResolution) {
                    camera.viewfinder.resolution = viewfinderResolution
                }
                completed = true
            }

            function turnFlashOn() {
                camera.flash.mode = Camera.FlashTorch
            }

            function turnFlashOff() {
                camera.flash.mode = Camera.FlashOff
            }

            function toggleFlash() {
                if (flashOn) {
                    turnFlashOff()
                } else {
                    turnFlashOn()
                }
            }

            function decodingFinished() {
                var resultViewDuration = AppSettings.resultViewDuration
                if (resultViewDuration > 0) {
                    showMarker = true
                    resultViewTimer.interval = resultViewDuration * 1000
                    resultViewTimer.restart()
                }
                if (AppSettings.sound) {
                    // Camera locks the output playback resouce, we need
                    // to stop it before we can play the beep. Luckily,
                    // the viewfinder is typically covered with the marker
                    // image so the user won't even notice the pause.
                    playBeep = true
                    // The beep starts playing when the camera stops and
                    // audio becomes available. When playback is stopped,
                    // (playback state becomes Audio.StoppedState) the
                    // camera is restarted.
                    camera.stop()
                }
            }

            function viewfinderToFramePoint(vx, vy) {
                var x = (vx - viewFinderItem.contentRect.x)/viewFinderItem.contentRect.width
                var y = (vy - viewFinderItem.contentRect.y)/viewFinderItem.contentRect.height
                switch (cameraOrientation) {
                case 90:  return Qt.point(y, 1 - x)
                case 180: return Qt.point(1 - x, 1 - y)
                case 270: return Qt.point(1 - y, x)
                default:  return Qt.point(x, y)
                }
            }

            function frameToViewfinderRect(rect) {
                var vx, vy, vw, vh
                switch (cameraOrientation) {
                case 90:
                case 270:
                    vw = rect.height
                    vh = rect.width
                    break
                default:
                    vw = rect.width
                    vh = rect.height
                    break
                }
                switch (cameraOrientation) {
                case 90:
                    vx = 1 - rect.y - vw
                    vy = rect.x
                    break
                case 180:
                    vx = 1 - rect.x - vw
                    vy = 1 - rect.y - vh
                    break
                case 270:
                    vx = rect.y
                    vy = 1 - rect.x - vh
                    break
                default:
                    vx = rect.x
                    vy = rect.y
                    break
                }
                return Qt.rect(viewFinderItem.contentRect.width * vx +  viewFinderItem.contentRect.x,
                               viewFinderItem.contentRect.height * vy + viewFinderItem.contentRect.y,
                               viewFinderItem.contentRect.width * vw, viewFinderItem.contentRect.height * vh)
            }

            source: Camera {
                id: camera

                flash.mode: Camera.FlashOff
                captureMode: Camera.CaptureVideo
                imageProcessing.whiteBalanceMode: flashOn ?
                    CameraImageProcessing.WhiteBalanceFlash :
                    CameraImageProcessing.WhiteBalanceTungsten
                cameraState: completed && !reloadTimer.running ?
                    Camera.ActiveState : Camera.UnloadedState
                exposure {
                    exposureCompensation: 1.0
                    exposureMode: Camera.ExposureAuto
                }
                focus {
                    focusMode: tapFocusActive ? Camera.FocusAuto : Camera.FocusContinuous
                    focusPointMode: tapFocusActive ? Camera.FocusPointCustom : Camera.FocusPointAuto
                }
                onCameraStatusChanged: {
                    if (cameraStatus === Camera.ActiveStatus) {
                        digitalZoom = zoomSlider.value
                    }
                }
                onCameraStateChanged: {
                    if (cameraState === Camera.ActiveState) {
                        if (viewFinderItem.playBeep) {
                            viewFinderItem.playBeep = false
                        } else {
                            cameraStarted()
                        }
                    } else if (cameraState === Camera.UnloadedState) {
                        if (viewFinderItem.viewfinderResolution &&
                            viewFinderItem.viewfinderResolution !== viewfinder.resolution) {
                            viewfinder.resolution = viewFinderItem.viewfinderResolution
                        }
                    }
                }
            }

            Timer {
                id: reloadTimer
                interval: 100
            }

            // Display focus areas
            Repeater {
                model: camera.focus.focusZones
                delegate: Rectangle {
                    visible: !scanner.grabbing &&
                             status !== Camera.FocusAreaUnused &&
                             camera.focus.focusPointMode === Camera.FocusPointCustom &&
                             camera.cameraStatus === Camera.ActiveStatus
                    border {
                        width: Math.round(Theme.pixelRatio * 2)
                        color: status === Camera.FocusAreaFocused ? Theme.highlightColor : "white"
                    }
                    color: "transparent"

                    readonly property rect mappedRect: frameToViewfinderRect(area)
                    readonly property real diameter: Math.round(Math.min(mappedRect.width, mappedRect.height))

                    x: Math.round(mappedRect.x + (mappedRect.width - diameter)/2)
                    y: Math.round(mappedRect.y + (mappedRect.height - diameter)/2)
                    width: diameter
                    height: diameter
                    radius: diameter / 2
                }
            }

            MouseArea {
                anchors.fill: parent
                onPressed: {
                    focusTimer.restart()
                    camera.unlock()
                    camera.focus.customFocusPoint = viewfinderToFramePoint(mouse.x, mouse.y)
                    camera.searchAndLock()
                }
            }

            Timer {
                id: resultViewTimer

                onTriggered: viewFinderItem.showMarker = false
            }

            Timer {
                id: focusTimer

                interval: 5000
                onTriggered: camera.unlock()
            }

            Image {
                id: markerImage
                readonly property bool markerShown: showMarker

                anchors.fill: parent
                z: 2
                source: markerShown ? "image://scanner/marked" : ""
                visible: status === Image.Ready
                cache: false
            }

            Audio {
                source: "sound/beep.wav"
                volume: 1.0
                readonly property bool canPlay: availability == Audio.Available && playBeep

                onCanPlayChanged: if (canPlay) play()

                onPlaybackStateChanged: {
                    if (playbackState === Audio.StoppedState) {
                        camera.start()
                    }
                }
            }
        }
    }

    SilicaFlickable {
        id: scanPageFlickable
        anchors.fill: parent
        contentHeight: flickableColumn.height

        PullDownMenu {
            id: menu
            enabled: scanPage.state == "INACTIVE" || scanPage.state === "READY"
            visible: enabled
            onActiveChanged: if (active) statusText.text = ""

            MenuItem {
                //: About page title, label and menu item
                //% "About CodeReader"
                text: qsTrId("about-title")
                onClicked: pageStack.push("AboutPage.qml")
            }
            MenuItem {
                //: Setting page title and menu item
                //% "Settings"
                text: qsTrId("settings-title")
                onClicked: pageStack.push("SettingsPage.qml")
            }
        }

        Column {
            id: flickableColumn
            x: Theme.horizontalPageMargin
            y: Theme.paddingLarge
            width: parent.width - 2 * x
            spacing: Theme.paddingLarge

            Item {
                id: parentViewFinder

                readonly property bool canSwitchResolutions: typeof ViewfinderResolution_4_3 !== "undefined" &&
                    typeof ViewfinderResolution_16_9 !== "undefined"
                readonly property int defaultWidth: Math.round(window.width * 0.56) & (-2)
                readonly property int narrowWidth: canSwitchResolutions ? height/16*9 : defaultWidth
                readonly property int wideWidth: canSwitchResolutions ? height/4*3 : defaultWidth
                readonly property size viewfinderResolution: canSwitchResolutions ?
                    (wideMode ? ViewfinderResolution_4_3 : ViewfinderResolution_16_9) : Qt.size(0,0)
                readonly property bool wideMode: canSwitchResolutions && AppSettings.wideMode
                anchors.horizontalCenter: parent.horizontalCenter
                width: wideMode ? wideWidth : narrowWidth
                height: Math.round(window.height * 0.56) & (-16)

                onWidthChanged: updateViewFinderPosition()
                onHeightChanged: updateViewFinderPosition()
                onXChanged: updateViewFinderPosition()
                onYChanged: updateViewFinderPosition()

                onViewfinderResolutionChanged: {
                    if (viewFinder && viewfinderResolution && canSwitchResolutions) {
                        viewFinder.viewfinderResolution = viewfinderResolution
                    }
                }

                function updateViewFinderPosition() {
                    scanner.setViewFinderRect(Qt.rect(x + parent.x, y + parent.y, width, height))
                }
            }

            Item {
                width: parent.width
                height: Math.max(flashButton.height, zoomSlider.height)

                Item {
                    height: parent.height
                    anchors {
                        left: parent.left
                        right: zoomSlider.left
                    }
                    visible: TorchSupported
                    HintIconButton {
                        id: flashButton
                        anchors.centerIn: parent
                        icon.source: viewFinder && viewFinder.flashOn ?
                                "image://theme/icon-camera-flash-on" :
                                "image://theme/icon-camera-flash-off"
                        onClicked: if (viewFinder) viewFinder.toggleFlash()
                        //: Hint label
                        //% "Toggle flashlight"
                        hint: qsTrId("hint-toggle-flash")
                        onShowHint: scanPage.showHint(hint)
                        onHideHint: scanPage.hideHint()
                    }
                }

                Slider {
                    id: zoomSlider
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parentViewFinder.narrowWidth
                    leftMargin: 0
                    rightMargin: 0
                    minimumValue: 1.0
                    maximumValue: 70.0
                    value: 1
                    stepSize: 5
                    onValueChanged: {
                        if (viewFinder) {
                            viewFinder.digitalZoom = value
                        }
                        saveZoomDelay.restart()
                    }
                    Component.onCompleted: {
                        value = AppSettings.digitalZoom
                        saveZoomDelay.stop()
                    }
                    Timer {
                        id: saveZoomDelay
                        interval: 500
                        onTriggered: AppSettings.digitalZoom = zoomSlider.value
                    }
                }

                Item {
                    height: parent.height
                    visible: parentViewFinder.canSwitchResolutions
                    anchors {
                        left: zoomSlider.right
                        right: parent.right
                    }
                    HintIconButton {
                        id: aspectButton
                        readonly property string icon_16_9: iconSourcePrefix + Qt.resolvedUrl("img/resolution_16_9.svg")
                        readonly property string icon_4_3: iconSourcePrefix +  Qt.resolvedUrl("img/resolution_4_3.svg")
                        anchors.centerIn: parent
                        icon {
                            source: AppSettings.wideMode ? icon_4_3 : icon_16_9
                            sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                        }
                        onClicked: AppSettings.wideMode = !AppSettings.wideMode
                        //: Hint label
                        //% "Switch the aspect ratio between 9:16 and 3:4"
                        hint: qsTrId("hint-aspect-ratio")
                        onShowHint: scanPage.showHint(hint)
                        onHideHint: scanPage.hideHint()
                    }
                }
            }

            Label {
                id: statusText
                text: ""
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.Center
                color: Theme.highlightColor
            }

            Item {
                id: clickableResult

                property string recordId
                property string text
                property string format

                property var vcard: null
                readonly property bool haveContact: vcard && vcard.count > 0
                readonly property string normalizedText: Utils.convertLineBreaks(text)
                readonly property bool isVCard: Utils.isVcard(normalizedText)
                readonly property bool isLink: Utils.isLink(normalizedText)

                function setValue(recId, text, format) {
                    clickableResult.recordId = recId
                    clickableResult.text = text
                    clickableResult.format = Utils.barcodeFormat(format)
                    opacity = 1.0
                }

                function clear() {
                    opacity = 0.0
                    clickableResult.recordId = ""
                    clickableResult.text = ""
                    clickableResult.format = ""
                }

                signal itemHidden()

                onIsVCardChanged: {
                    if (isVCard) {
                        if (!vcard) {
                            var component = Qt.createComponent("VCard.qml");
                            if (component.status === Component.Ready) {
                                vcard = component.createObject(scanPage, { content: normalizedText })
                            }
                        }
                    } else {
                        if (vcard) {
                            vcard.destroy()
                            vcard = null
                        }
                    }
                }

                height: Math.max(resultItem.height, Theme.itemSizeSmall)
                width: parent.width

                // Hide the results button when it touches the scan button
                readonly property real bottomY: y + flickableColumn.y - scanPageFlickable.contentY + scanPageFlickable.y + height
                onBottomYChanged: {
                    if (visible && bottomY >= actionButton.y) {
                        opacity = 0.0
                        itemHidden()
                    }
                }
                visible: opacity > 0.0

                Behavior on opacity { FadeAnimation { } }

                // Clear results when the first history item gets deleted
                Connections {
                    target: historyModel
                    onRowsRemoved: if (first == 0) clickableResult.clear()
                }

                Item {
                    height: parent.height
                    width: resultItem.x
                    visible: clickableResult.text.length > 0
                    anchors.verticalCenter: parent.verticalCenter

                    HintIconButton {
                        anchors.centerIn: parent
                        icon.source: "image://theme/icon-m-clipboard"
                        visible: !linkButton.visible && !vcardButton.visible
                        onClicked: {
                            Clipboard.text = clickableResult.text
                            clipboardNotification.publish()
                        }
                        //: Hint label
                        //% "Copy to clipboard"
                        hint: qsTrId("hint-copy-clipboard")
                        onShowHint: scanPage.showHint(hint)
                        onHideHint: scanPage.hideHint()
                    }

                    HintIconButton {
                        id: linkButton
                        anchors.centerIn: parent
                        icon {
                            source: iconSourcePrefix + Qt.resolvedUrl("img/open_link.svg")
                            sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                        }
                        visible: !clickableResult.haveContact && clickableResult.isLink
                        enabled: visible && !holdOffTimer.running
                        //: Hint label
                        //% "Open link in browser"
                        hint: qsTrId("hint-open_link")
                        onShowHint: scanPage.showHint(hint)
                        onHideHint: scanPage.hideHint()
                        onClicked: {
                            console.log("opening", clickableResult.text)
                            Qt.openUrlExternally(clickableResult.text)
                            holdOffTimer.restart()
                        }
                        Timer {
                            id: holdOffTimer
                            interval: 2000
                        }
                    }

                    HintIconButton {
                        id: vcardButton
                        anchors.centerIn: parent
                        icon {
                            source: iconSourcePrefix + Qt.resolvedUrl("img/open_vcard.svg")
                            sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                        }
                        visible: clickableResult.haveContact && !clickableResult.isLink
                        //: Hint label
                        //% "Open contact card"
                        hint: qsTrId("hint-open_contact_card")
                        onShowHint: scanPage.showHint(hint)
                        onHideHint: scanPage.hideHint()
                        onClicked: {
                            var page = Qt.createQmlObject("import QtQuick 2.0;import Sailfish.Silica 1.0;import Sailfish.Contacts 1.0; \
Page { id: page; signal saveContact(); property alias contact: card.contact; property alias saveText: saveMenu.text; \
ContactCard { id: card; PullDownMenu { MenuItem { id: saveMenu; onClicked: page.saveContact(); }}}}",
                                scanPage, "ContactPage")
                            pageStack.push(page, {
                                contact: clickableResult.vcard.contact(),
                                //: Pulley menu item (saves contact)
                                //% "Save"
                                saveText: qsTrId("contact-menu-save")
                            }).saveContact.connect(function() {
                                pageStack.pop()
                                clickableResult.vcard.importContact()
                            })
                        }
                    }
                }

                BackgroundItem {
                    id: resultItem
                    x: zoomSlider.x
                    height: Math.max(resultColumn.height, implicitHeight)
                    width: parent.width - x
                    enabled: parent.enabled
                    anchors.verticalCenter: parent.verticalCenter

                    function deleteItem() {
                        var remorse = remorseComponent.createObject(null)
                        //: Remorse popup text
                        //% "Deleting"
                        remorse.execute(resultItem, qsTrId("history-menu-delete_remorse"),
                            function() {
                                historyModel.remove(0)
                                if (scanPage.status === PageStatus.Active) {
                                    historyModel.commitChanges()
                                }
                                remorse.destroy()
                            })
                        actionButton.clicked.connect(remorse.destroy)
                        clickableResult.itemHidden.connect(remorse.destroy)
                    }

                    Column {
                        id: resultColumn
                        x: Theme.paddingSmall
                        width: parent.width - x
                        anchors.verticalCenter: parent.verticalCenter
                        Label {
                            text: Utils.getValueText(clickableResult.text)
                            color: resultItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            font.underline: clickableResult.isLink
                        }
                        Label {
                            width: parent.width
                            color: resultItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                            text: clickableResult.format
                            truncationMode: TruncationMode.Fade
                        }
                    }

                    onClicked: {
                        pageStack.push("TextPage.qml", {
                            hasImage: AppSettings.saveImages,
                            recordId: clickableResult.recordId,
                            text: clickableResult.text,
                            format: clickableResult.format,
                            canDelete: true
                        }).deleteEntry.connect(function() {
                            pageStack.pop()
                            resultItem.deleteItem()
                        })
                    }
                }
            }
        }
    }

    Button {
        id: actionButton
        // Attach to the window so that the position of the button is
        // not affected by the on-screen keyboard (which changes the
        // page height)
        y: window.height - height - Theme.paddingLarge
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
            if (scanPage.state === "READY") {
                startScan()
            } else if (scanPage.state === "SCANNING") {
                abortScan()
            }
        }
        enabled: (scanPage.state === "READY") || (scanPage.state === "SCANNING")
    }

    Component {
        id: remorseComponent
        RemorseItem { }
    }
}
