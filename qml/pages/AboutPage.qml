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
import "../components"

Page {
    id: aboutPage

    SilicaFlickable {
        id: aboutPageFlickable
        anchors.fill: parent
        contentHeight: aboutColumn.height

        Column {
            PageHeader {
                //: About page title, label and menu item
                //% "About CodeReader"
                title: qsTrId("about-title")
            }

            id: aboutColumn
            anchors { left: parent.left; right: parent.right }
            height: childrenRect.height

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                //: About page title, label and menu item
                //% "About CodeReader"
                label: qsTrId("about-title")
                //: About page text
                //% "This app demonstrates a bar code reader for Sailfish OS. I hope it is useful for other projects. CodeReader is open source and licensed under the MIT License."
                text: qsTrId("about-description")
                separator: true
            }

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                //: About page label
                //% "Version"
                label: qsTrId("about-version-label")
                text: AppVersion
                separator: true
            }

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                //: About page label
                //% "Author"
                label: qsTrId("about-author-label")
                text: "Steffen Förster"
                separator: true
            }

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                //: About page label
                //% "Contributors"
                label: qsTrId("about-contributors-label")
                text: "Diego Russo, Åke Engelbrektson, Dominik Chrástecký, Miklós Márton, Hauke Schade, Slava Monich"
                separator: true
            }

            BackgroundItem {
                id: clickableUrl
                contentHeight: labelUrl.height
                height: contentHeight
                width: aboutPageFlickable.width
                anchors {
                    left: parent.left
                }

                LabelText {
                    id: labelUrl
                    anchors {
                        left: parent.left
                        margins: Theme.paddingLarge
                    }
                    //: About page label
                    //% "Source code"
                    label: qsTrId("about-source_code-label")
                    text: "https://github.com/monich/sailfish-barcode"
                    color: clickableUrl.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                onClicked: Qt.openUrlExternally(labelUrl.text);
            }

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                //: About page label
                //% "References"
                label: qsTrId("about-references-label")
                //: About page text
                //% "This project uses code and ideas of other projects, see README.md on Github."
                text: qsTrId("about-references-text")
                separator: true
            }

            LabelText {
                anchors {
                    left: parent.left
                    margins: Theme.paddingLarge
                }
                //: About page label
                //% "Supported 1D/2D bar codes"
                label: qsTrId("about-supported_codes-label")
                //: About page text
                //% "Image source: %1"
                text: qsTrId("about-supported_codes-text").arg("http://wikipedia.de")
                separator: false
            }

            ListModel {
                id: imageModel
                ListElement {
                    name: "QR code"
                    imgSrc: "img/qr-code_240.png"
                }
                ListElement {
                    name: "Aztec"
                    imgSrc: "img/aztec_240.png"
                }
                ListElement {
                    name: "Data Matrix"
                    imgSrc: "img/datamatrix_240.png"
                }
                ListElement {
                    name: "Code 39"
                    imgSrc: "img/code-39_240.png"
                }
                ListElement {
                    name: "Code 93"
                    imgSrc: "img/code-93_240.png"
                }
                ListElement {
                    name: "Code 128"
                    imgSrc: "img/code-128_240.png"
                }
                ListElement {
                    name: "EAN 13"
                    imgSrc: "img/ean-13_240.png"
                }
                ListElement {
                    name: "Interleaved 2/5"
                    imgSrc: "img/interleaved_240.png"
                }
                ListElement {
                    name: "UPC-A"
                    imgSrc: "img/upc_240.png"
                }
                ListElement {
                    name: "Codebar"
                    imgSrc: "img/codebar_240.png"
                }
                ListElement {
                    name: "MaxiCode"
                    imgSrc: "img/maxicode_240.png"
                }
                ListElement {
                    name: "PDF417"
                    imgSrc: "img/pdf417_240.png"
                }
            }

            SilicaGridView {
                id: grid

                function adjustGridDimensions() {
                    var columns = [5, 4, 3]
                    var adjusted = false
                    for (var i = 0; i < columns.length; i++) {
                        if (!adjusted && Screen.width / columns[i] >= 270) {
                            grid.cellWidth = Screen.width / columns[i]
                            grid.height = grid.cellHeight * Math.ceil(imageModel.count / columns[i])
                            adjusted = true
                        }
                    }
                }

                width: parent.width
                height: 180 * Math.ceil(imageModel.count / 2)
                cellWidth: Screen.width / 2
                cellHeight: 180
                quickScroll: false
                interactive: false
                model: imageModel

                Component.onCompleted: adjustGridDimensions()

                delegate: Item {
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Image {
                        source: imgSrc;
                        anchors {
                            centerIn: parent
                        }

                        Text {
                            text: name;
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: "black"
                            anchors {
                                bottomMargin: 2
                                bottom: parent.bottom
                                horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    VerticalScrollDecorator { flickable: aboutPageFlickable }
}
