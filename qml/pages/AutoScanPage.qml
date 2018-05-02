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

import QtQuick 2.1
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import harbour.barcode.AutoBarcodeScanner 1.0

import "../js/Settings.js" as Settings
import "../js/History.js" as History
import "../js/Utils.js" as Utils

Page {
    id: scanPage

    property Item viewFinder

    property bool flagAutoScan: true
    property bool flagScanByCover: false

    property int scanTimeout: 60

    function createScanner() {
        if (viewFinder) {
            return
        }

        console.log("creating viewfinder ...")
        viewFinder = viewFinderComponent.createObject(parentViewFinder)

        if (viewFinder.source.availability === Camera.Available) {
            viewFinder.source.start()
            autoStart()
        } else {
            stateAbort();
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
        if (viewFinder) {
            if (flagScanByCover || (flagAutoScan && Settings.getBoolean(Settings.keys.SCAN_ON_START))) {
                console.log("auto-starting scan ...")
                startScan();
            }

            flagAutoScan = false
            flagScanByCover = false
        }
    }

    function applyResult(result) {
        console.log("result from scan page: " + result)
        if (result.length > 0) {
            Clipboard.text = result
            clickableResult.setValue(result)
            History.addHistoryValue(result)
        }
    }

    function startScan() {
        viewFinder.showMarker = false
        setMarkerColor()
        stateScanning()
        scanner.startScanning(scanTimeout * 1000)
    }

    function abortScan() {
        stateAbort()
        scanner.stopScanning()
    }

    function setMarkerColor() {
        var markerColor = Settings.get(Settings.keys.MARKER_COLOR)
        console.log("marker color: ", markerColor)

        var red =  parseInt(markerColor.substr(1, 2), 16)
        var green =  parseInt(markerColor.substr(3, 2), 16)
        var blue =  parseInt(markerColor.substr(5, 2), 16)

        console.log("red: ", red, " green: ", green, " blue: ", blue)
        scanner.setMarkerColor(red, green, blue)
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

    state: "INACTIVE"

    onStatusChanged: {
        if (scanPage.status === PageStatus.Active) {
            console.log("Page is ACTIVE")
            createScanner()
        } else if (scanPage.status === PageStatus.Inactive) {
            console.log("Page is INACTIVE")
            // stop scanning if page is not active
            destroyScanner()
        }
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active && scanPage.status === PageStatus.Active) {
                console.log("application state changed to ACTIVE and AutoScanPage is active")
                createScanner()
            }
            else if (!Qt.application.active) {
                console.log("application state changed to INACTIVE")
                // if the application is deactivated we have to stop the camera and destroy the scanner object
                // because of power consumption issues and impact to the camera application
                destroyScanner()
            }
        }
    }

    function cameraStarted() {
        console.log("camera is started")

        if (!Qt.application.active) {
            // use case: start app => lock device immediately => signal Qt.application.onActiveChanged is not emitted
            console.log("WARN: device immediately locked")
            destroyScanner()
            return
        }

        stateReady()
        autoStart();
    }

    AutoBarcodeScanner {
        id: scanner

        viewFinderItem: parentViewFinder

        onDecodingFinished: {
            console.log("decoding finished, code: ", code)
            statusText.text = ""
            if (scanPage.state !== "ABORT") {
                if (code.length > 0) {
                    applyResult(code)
                    viewFinder.decodingFinished()
                } else {
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
            fillMode: VideoOutput.PreserveAspectCrop
            property bool showMarker: false
            property bool playBeep: false
            property alias digitalZoom: camera.digitalZoom
            readonly property bool tapFocusActive: focusTimer.running
            readonly property bool flashOn: camera.flash.mode !== Camera.FlashOff
            // Not sure why not just camera.orientation but this makes the camera
            // behave similar to what it does for Jolla Camera
            readonly property int cameraOrientation: 360 - camera.orientation

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
                var resultViewDuration = Settings.get(Settings.keys.RESULT_VIEW_DURATION)
                if (resultViewDuration > 0) {
                    showMarker = true
                    resultViewTimer.interval = resultViewDuration * 1000
                    resultViewTimer.restart()
                }
                if (Settings.getBoolean(Settings.keys.SOUND)) {
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
                    }
                }
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

                    readonly property rect mappedRect: frameToViewfinderRect(area);
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
            MenuItem {
                //: About page title, label and menu item
                //% "About CodeReader"
                text: qsTrId("about-title")
                onClicked: {
                    pageStack.push("AboutPage.qml");
                }
            }
            MenuItem {
                //: Setting page title and menu item
                //% "Settings"
                text: qsTrId("settings-title")
                onClicked: {
                    pageStack.push("SettingsPage.qml");
                }
            }
        }

        Column {
            id: flickableColumn
            y: Theme.paddingLarge
            width: parent.width
            spacing: Theme.paddingLarge

            anchors {
                topMargin: Theme.paddingLarge
            }

            Item {
                id: parentViewFinder

                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.round(scanPage.width * 0.56) & (-2)
                height: Math.round(scanPage.height * 0.56) & (-2)

                onWidthChanged: updateViewFinderPosition()
                onHeightChanged: updateViewFinderPosition()
                onXChanged: updateViewFinderPosition()
                onYChanged: updateViewFinderPosition()

                function updateViewFinderPosition() {
                    scanner.setViewFinderRect(Qt.rect(x, y + flickableColumn.y, width, height))
                }
            }

            Item {
                width: parent.width
                height: Math.max(flashButton.height, zoomSlider.height)

                Item {
                    height: parent.height
                    width: parentViewFinder.x
                    visible: TorchSupported
                    IconButton {
                        id: flashButton
                        anchors.centerIn: parent
                        icon.source: viewFinder && viewFinder.flashOn ?
                                "image://theme/icon-camera-flash-on" :
                                "image://theme/icon-camera-flash-off"
                        onClicked: if (viewFinder) viewFinder.toggleFlash()
                    }
                }

                Slider {
                    id: zoomSlider
                    x: parentViewFinder.x
                    width: parentViewFinder.width
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
                        value = Settings.get(Settings.keys.DIGITAL_ZOOM)
                        saveZoomDelay.stop()
                    }
                    Timer {
                        id: saveZoomDelay
                        interval: 500
                        onTriggered: Settings.set(Settings.keys.DIGITAL_ZOOM, zoomSlider.value)
                    }
                }
            }

            Label {
                id: statusText
                text: ""
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Theme.paddingLarge * 2
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.Center
                color: Theme.highlightColor
            }

            BackgroundItem {
                id: clickableResult

                property bool isLink: false

                property string text: ""

                function setValue(text) {
                    if (Utils.isLink(text)) {
                        setLink(text)
                    }
                    else {
                        setText(text)
                    }
                }

                function clear() {
                    clickableResult.enabled = false
                    clickableResult.isLink = false
                    clickableResult.text = ""
                    resultText.text = ""
                    resultText.width = rowResult.width - clipboardImg.width - 2 * Theme.paddingLarge
                }

                function setLink(link) {
                    clickableResult.enabled = true
                    clickableResult.isLink = true
                    clickableResult.text = link
                    resultText.text = link
                    resultText.width = rowResult.width - clipboardImg.width - 2 * Theme.paddingLarge
                }

                function setText(text) {
                    clickableResult.enabled = true
                    clickableResult.isLink = false
                    clickableResult.text = text
                    resultText.text = text
                    resultText.width = rowResult.width - clipboardImg.width - 2 * Theme.paddingLarge
                }

                contentHeight: rowResult.height
                height: contentHeight
                width: scanPageFlickable.width
                anchors {
                    left: parent.left
                }
                enabled: false

                Row {
                    id: rowResult
                    width: parent.width - 2 * Theme.paddingLarge
                    height: Math.max(clipboardImg.contentHeight, resultText.contentHeight)
                    spacing: Theme.paddingLarge
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.paddingLarge
                    }

                    Image {
                        id: clipboardImg
                        source: "image://theme/icon-m-clipboard"
                        visible: resultText.text.length > 0
                        anchors {
                            leftMargin: Theme.paddingLarge
                        }
                    }

                    Label {
                        id: resultText
                        anchors {
                            leftMargin: Theme.paddingLarge
                            top: clipboardImg.top
                        }
                        color: clickableResult.highlighted
                               ? Theme.highlightColor
                               : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                        font.underline: clickableResult.isLink
                        truncationMode: TruncationMode.Fade
                        width: parent.width - clipboardImg.width - 2 * Theme.paddingLarge
                    }
                }

                onClicked: {
                    if (clickableResult.isLink) {
                        openInDefaultApp(clickableResult.text)
                    } else {
                        pageStack.push("TextPage.qml", {text: clickableResult.text})
                    }
                }
            }
        }
    }

    Button {
        id: actionButton
        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        onClicked: {
            if (scanPage.state === "READY") {
                startScan()
            } else if (scanPage.state === "SCANNING") {
                abortScan()
            }
        }
        enabled: (scanPage.state === "READY") || (scanPage.state === "SCANNING")
    }
}
