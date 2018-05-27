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
import Sailfish.Silica 1.0

Page {
    id: settingsPage

    property var colors: [
        "#FF0080", "#FF0000", "#FF8000", "#FFFF00",
        "#00FF00", "#8000FF", "#00FFFF", "#0000FF"
    ]

    property int currentColor: getColorFromSettings()

    function getColorFromSettings() {
        var savedColor = AppSettings.markerColor
        for	(var i = 0; i < colors.length; i++) {
            if (savedColor === colors[i]) {
                return i
            }
        }
        return 0
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width

            //: Setting page title and menu item
            //% "Settings"
            PageHeader { title: qsTrId("settings-title") }

            //: Section header
            //% "Scan"
            SectionHeader { text: qsTrId("settings-scan-section") }

            IconTextSwitch {
                checked: AppSettings.sound
                //: Switch button text
                //% "Detection sound"
                text: qsTrId("settings-sound-label")
                icon.source: "image://theme/icon-m-speaker"
                onCheckedChanged: AppSettings.sound = checked
            }

            IconTextSwitch {
                checked: AppSettings.scanOnStart
                //: Switch button text
                //% "Scan on start"
                text: qsTrId("settings-autoscan-label")
                icon.source: "image://theme/icon-m-play"
                onCheckedChanged: AppSettings.scanOnStart = checked
            }

            IconTextSwitch {
                id: saveImagesSwitch
                checked: AppSettings.saveImages
                //: Switch button text
                //% "Save barcode images"
                text: qsTrId("settings-save_images-label")
                icon.source: "image://theme/icon-m-camera"
                automaticCheck: false
                onClicked: {
                    if (checked) {
                        //: Switch button description (explanation)
                        //% "This will delete all previously saved barcode images."
                        description = qsTrId("settings-save_images-description")
                        picturesConfirmButtons.visible = true
                    } else {
                        AppSettings.saveImages = true
                    }
                }
                onCheckedChanged: {
                    description = ""
                    picturesConfirmButtons.visible = false
                }
            }

            Row {
                id: picturesConfirmButtons

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
                spacing: Theme.paddingMedium
                visible: false

                Button {
                    width: Math.round((parent.width - parent.spacing) / 2)
                    //: Button label (confirm deletion of image files)
                    //% "Confirm delete"
                    text: qsTrId("settings-save_images-confirm_delete")
                    onClicked: AppSettings.saveImages = false
                }

                Button {
                    width: Math.round((parent.width - parent.spacing) / 2)
                    //: Button label
                    //% "Cancel"
                    text: qsTrId("settings-history-cancel")
                    onClicked: {
                        saveImagesSwitch.description = ""
                        picturesConfirmButtons.visible = false
                    }
                }
            }

            //: Section header
            //% "History"
            SectionHeader { text: qsTrId("settings-history-section") }

            Slider {
                id: historySizeSlider

                readonly property int currentCount: historyModel.count

                width: parent.width
                minimumValue: 0
                maximumValue: 100
                value: AppSettings.historySize
                stepSize: 10
                //: Slider label
                //% "Max history size (saved values: %1)"
                label: qsTrId("settings-history-slider_label").arg(currentCount)
                valueText: value === 0 ?
                    //: Generic slider value
                    //% "deactivated"
                    qsTrId("settings-value-deactivated") :
                    //: History slider value
                    //% "%1 item(s)"
                    qsTrId("settings-history-slider_value",value).arg(value)
                onSliderValueChanged: {
                    if (value < currentCount) {
                        historyConfirmButtons.visible = true
                    } else {
                        historyConfirmButtons.visible = false
                        AppSettings.historySize = value
                    }
                }
            }

            Row {
                id: historyConfirmButtons

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
                spacing: Theme.paddingMedium
                visible: false

                Button {
                    width: Math.round((parent.width - parent.spacing) / 2)
                    //: Button label
                    //% "Confirm resize"
                    text: qsTrId("settings-history-confirm_resize")
                    onClicked: {
                        AppSettings.historySize = historySizeSlider.value
                        historyConfirmButtons.visible = false
                    }
                }

                Button {
                    width: Math.round((parent.width - parent.spacing) / 2)
                    //: Button label
                    //% "Cancel"
                    text: qsTrId("settings-history-cancel")
                    onClicked: {
                        historySizeSlider.value = AppSettings.historySize
                        historyConfirmButtons.visible = false
                    }
                }
            }

            //: Section header
            //% "Marker"
            SectionHeader { text: qsTrId("settings-marker-section") }

            Grid {
                id: colorSelector

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
                columns: 4

                Repeater {
                    model: colors

                    Item {
                        width: parent.width/colorSelector.columns
                        height: parent.width/colorSelector.columns

                        Rectangle {
                            property real adjustment: (index == currentColor) ? 0 :
                                colorSelectorBackground.down ? (2 * Theme.paddingMedium) :
                                (2 * Theme.paddingLarge)

                            width: parent.width - adjustment
                            height: parent.height - adjustment
                            radius: Theme.paddingLarge
                            color: colors[index]
                            anchors.centerIn: parent

                            Behavior on adjustment { SmoothedAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: colorSelectorBackground

                            readonly property bool down: pressed && containsMouse
                            anchors.fill: parent
                            onClicked: {
                                currentColor = index
                                AppSettings.markerColor = colors[index]
                            }
                        }
                    }
                }
            }

            Slider {
                width: parent.width
                minimumValue: 0
                maximumValue: 15
                value: AppSettings.resultViewDuration
                stepSize: 1
                //: Slider label
                //% "Mark detected code"
                label: qsTrId("settings-marker-slider_label")
                valueText: value === 0 ?
                    //: Generic slider value
                    //% "deactivated"
                    qsTrId("settings-value-deactivated") :
                    //: Marker slider value
                    //% "%1 second(s)"
                    qsTrId("settings-marker-slider_value",value).arg(value)
                onSliderValueChanged: AppSettings.resultViewDuration = value
            }
        }
    }
}
