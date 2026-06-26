import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

ShellRoot {
    id: root

    // ── Theme State (loaded dynamically from Brain Shell cache) ────────────────
    property color colorBackground: "#121216"
    property color colorActive:     "#89b4fa"
    property color colorText:       "#ebebf0"
    property color colorSubtext:    "#a0a0aa"
    property color colorBorder:     "#32323c"

    FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.cache/brain-shell/colors.json"
        watchChanges: true
        onLoaded: parse(text())
        onFileChanged: parse(text())

        function parse(raw) {
            if (!raw || raw.trim() === "") return
            try {
                var obj = JSON.parse(raw)
                if (obj.background) root.colorBackground = obj.background
                if (obj.active)     root.colorActive     = obj.active
                if (obj.text)       root.colorText       = obj.text
                if (obj.subtext)    root.colorSubtext    = obj.subtext
                if (obj.border)     root.colorBorder     = obj.border
            } catch(e) {}
        }
    }

    // ── Data Models ───────────────────────────────────────────────────────────
    ListModel { id: allThemesModel }
    ListModel { id: filteredThemesModel }

    // ── Data Fetching Process ──────────────────────────────────────────────────
    Process {
        id: fetchProcess
        command: [Quickshell.env("HOME") + "/.config/themes/select_theme", "--list"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split("\t")
                if (parts.length >= 4) {
                    allThemesModel.append({
                        label: parts[0],
                        kind: parts[1],
                        source: parts[2],
                        icon: parts[3]
                    })
                }
            }
        }
        onExited: function() {
            filterThemes()
        }
    }

    // ── Apply Process ─────────────────────────────────────────────────────────
    Process {
        id: applyProcess
        command: []
        onExited: {
            Qt.quit()
        }
    }

    function applySelected() {
        if (gridView.currentIndex >= 0 && gridView.currentIndex < filteredThemesModel.count) {
            var item = filteredThemesModel.get(gridView.currentIndex)
            if (item.kind === "Subscribe") {
                applyProcess.command = ["steam", item.source]
            } else {
                applyProcess.command = [Quickshell.env("HOME") + "/.config/themes/set_wallpaper", item.source]
            }
            applyProcess.running = true
        }
    }

    // ── Filtering Logic ────────────────────────────────────────────────────────
    function filterThemes() {
        var query = searchInput.text.toLowerCase().trim()
        filteredThemesModel.clear()
        for (var i = 0; i < allThemesModel.count; i++) {
            var item = allThemesModel.get(i)
            if (query === "" || item.label.toLowerCase().indexOf(query) >= 0 || item.kind.toLowerCase().indexOf(query) >= 0) {
                filteredThemesModel.append(item)
            }
        }
        // Reset selection index
        gridView.currentIndex = 0
    }

    // ── Fullscreen Window ──────────────────────────────────────────────────────
    PanelWindow {
        id: win
        
        // Fullscreen setup
        anchors {
            top:    true
            left:   true
            right:  true
            bottom: true
        }
        exclusionMode: ExclusionMode.Ignore
        
        // Input grab settings
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell" // Triggers blur from Hyprland layer rule!

        color: "transparent"

        // Fullscreen background with blur compatibility
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(root.colorBackground.r, root.colorBackground.g, root.colorBackground.b, 0.75)

            // Dismiss window on click outside the content box
            MouseArea {
                anchors.fill: parent
                onClicked: Qt.quit()
            }

            // Main UI container (fixed width to prevent ultrawide stretching)
            Item {
                width: 1320
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                // Prevent mouse clicks inside from closing the launcher
                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: false
                }

                Column {
                    anchors.fill: parent
                    anchors.topMargin: 80
                    anchors.bottomMargin: 80
                    spacing: 24

                    // Title
                    Text {
                        text: "SELECT THEME"
                        font.family: "Comfortaa"
                        font.pixelSize: 32
                        font.bold: true
                        color: root.colorActive
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Search Box Container
                    Rectangle {
                        width: 420
                        height: 50
                        color: Qt.rgba(root.colorBackground.r, root.colorBackground.g, root.colorBackground.b, 0.5)
                        border.width: 1
                        border.color: searchInput.activeFocus ? root.colorActive : root.colorBorder
                        border.radius: 16
                        anchors.horizontalCenter: parent.horizontalCenter

                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.leftMargin: 24
                            anchors.rightMargin: 24
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignHCenter
                            
                            font.family: "Comfortaa"
                            font.pixelSize: 15
                            color: root.colorText
                            focus: true

                            selectByMouse: true

                            // Placeholder Text
                            Text {
                                text: "Search themes..."
                                font.family: "Comfortaa"
                                font.pixelSize: 15
                                color: root.colorSubtext
                                visible: parent.text === ""
                                anchors.centerIn: parent
                            }

                            onTextChanged: root.filterThemes()

                            // Full Keyboard Navigation
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Down) {
                                    gridView.moveCurrentIndexDown()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    gridView.moveCurrentIndexUp()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Left) {
                                    gridView.moveCurrentIndexLeft()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Right) {
                                    gridView.moveCurrentIndexRight()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.applySelected()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    Qt.quit()
                                    event.accepted = true
                                }
                            }
                        }
                    }

                    // Grid View for Wallpaper Cards
                    GridView {
                        id: gridView
                        width: parent.width
                        height: parent.height - 180
                        cellWidth: 330
                        cellHeight: 240
                        clip: true

                        model: filteredThemesModel
                        currentIndex: 0

                        delegate: Item {
                            width: 330
                            height: 240

                            property bool isCurrent: GridView.isCurrentItem

                            Rectangle {
                                width: 314
                                height: 224
                                anchors.centerIn: parent
                                radius: 20
                                color: isCurrent ? Qt.rgba(root.colorActive.r, root.colorActive.g, root.colorActive.b, 0.1) : "transparent"
                                border.width: 1
                                border.color: isCurrent ? root.colorActive : "transparent"

                                scale: isCurrent ? 1.03 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    // Wallpaper Preview (16:9 aspect ratio)
                                    Rectangle {
                                        width: 298
                                        height: 168 // 16:9 ratio
                                        radius: 12
                                        clip: true
                                        color: Qt.rgba(root.colorBackground.r, root.colorBackground.g, root.colorBackground.b, 0.3)

                                        Image {
                                            anchors.fill: parent
                                            source: icon !== "" && icon !== "steam" ? "file://" + icon : ""
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            visible: icon !== "" && icon !== "steam"
                                        }

                                        // Fallback Steam Icon
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 8
                                            visible: icon === "" || icon === "steam"

                                            Text {
                                                text: "󰓓"
                                                font.pixelSize: 48
                                                color: root.colorActive
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }
                                        }

                                        // Animated Wallpaper badge
                                        Rectangle {
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 8
                                            width: 70
                                            height: 20
                                            radius: 6
                                            color: Qt.rgba(0, 0, 0, 0.6)
                                            visible: kind === "Animated"

                                            Text {
                                                text: "ANIMATED"
                                                font.family: "Comfortaa"
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: root.colorActive
                                                anchors.centerIn: parent
                                            }
                                        }
                                    }

                                    // Theme Title
                                    Text {
                                        text: label
                                        width: parent.width
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                        font.family: "Comfortaa"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: isCurrent ? root.colorActive : root.colorText
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: gridView.currentIndex = index
                                    onClicked: root.applySelected()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
