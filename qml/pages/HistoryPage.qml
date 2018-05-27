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
import Sailfish.Silica 1.0
import harbour.barcode 1.0

import "../js/Utils.js" as Utils

Page {
    id: historyPage

    readonly property bool empty: historyList.model.count === 0

    onStatusChanged: {
        if (status === PageStatus.Inactive) {
            historyList.model.commitChanges()
        }
    }

    SilicaListView {
        id: historyList

        anchors.fill: parent
        width: parent.width
        spacing: 0

        header: PageHeader {
            //: History page title
            //% "History"
            title: qsTrId("history-title")
            height: Theme.itemSizeLarge
        }

        model: historyModel

        delegate: ListItem {
            id: delegate
            readonly property int modelIndex: index

            onClicked: {
                var historyItem = historyList.model.get(index)
                pageStack.push("TextPage.qml", {
                    hasImage: historyItem.hasImage,
                    recordId: historyItem.id,
                    text: historyItem.value,
                    format: Utils.barcodeFormat(historyItem.format)
                })
            }

            ListView.onRemove: RemoveAnimation { target: delegate }

            Column {
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - (2 * Theme.horizontalPageMargin)
                    color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                    text: Utils.getValueText(model.value)
                }
                Item {
                    width: parent.width
                    height: Math.max(timestampLabel.height, formatLabel.height)
                    Label {
                        id: timestampLabel
                        anchors {
                            left: parent.left
                            margins: Theme.horizontalPageMargin
                        }
                        color: delegate.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: historyList.model.formatTimestamp(model.timestamp)
                    }
                    Label {
                        id: formatLabel
                        anchors {
                            right: parent.right
                            margins: Theme.horizontalPageMargin
                            verticalCenter: parent.verticalCenter
                        }
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: Utils.barcodeFormat(model.format)
                    }
                }
            }

            menu: Component {
                ContextMenu {
                    id: contextMenu

                    MenuItem {
                        //: Context menu item
                        //% "Delete"
                        text: qsTrId("history-menu-delete")
                        onClicked: {
                            var item = delegate
                            var model = historyList.model
                            var remorse = remorseComponent.createObject(null)
                            remorse.z = item.z + 1
                            //: Remorse popup text
                            //% "Deleting"
                            remorse.execute(item, qsTrId("history-menu-delete_remorse"),
                                function() { model.remove(item.modelIndex) })
                        }
                    }
                    MenuItem {
                        //: Context menu item
                        //% "Copy to clipboard"
                        text: qsTrId("history-menu-copy")
                        onClicked: Clipboard.text = historyList.model.getValue(delegate.modelIndex)
                    }
                }
            }

        }

        PullDownMenu {
            visible: !historyPage.empty
            MenuItem {
                //: Pulley menu item
                //% "Delete all"
                text: qsTrId("history-menu-delete_all")
                onClicked: {
                    //: Remorse popup text
                    //% "Deleting all"
                    remorsePopup.execute(qsTrId("history-menu-delete_all_remorse"),
                        function() { historyList.model.removeAll() })
                }
            }
        }

        Component {
            id: remorseComponent
            RemorseItem { }
        }

        RemorsePopup {
            id: remorsePopup
        }

        VerticalScrollDecorator { }

        ViewPlaceholder {
            id: placeHolder
            enabled: historyPage.empty
            //: Placeholder text
            //% "History is empty"
            text: qsTrId("history-empty")
        }
    }
}
