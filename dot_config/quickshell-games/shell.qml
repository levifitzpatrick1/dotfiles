import Quickshell
import Quickshell.Io
import Quickshell.Widgets
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

    // ── Menu Style (user-tweakable via ~/.config/quickshell-menus/style.json) ──
    property real styleRadius: 16
    property real styleBgOpacity: 0.75
    property string styleFont: "Comfortaa"
    property int styleAnimMs: 150
    property bool styleScrim: true
    property real styleHoverScale: 1.04

    FileView {
        id: styleFile
        path: Quickshell.env("HOME") + "/.config/quickshell-menus/style.json"
        watchChanges: true
        onLoaded: parse(text())
        onFileChanged: parse(text())

        function parse(raw) {
            if (!raw || raw.trim() === "") return
            try {
                var obj = JSON.parse(raw)
                if (obj.cornerRadius !== undefined)      root.styleRadius = obj.cornerRadius
                if (obj.backgroundOpacity !== undefined) root.styleBgOpacity = obj.backgroundOpacity
                if (obj.fontFamily)                      root.styleFont = obj.fontFamily
                if (obj.animationMs !== undefined)       root.styleAnimMs = obj.animationMs
                if (obj.titleScrim !== undefined)        root.styleScrim = obj.titleScrim
                if (obj.hoverScale !== undefined)        root.styleHoverScale = obj.hoverScale
            } catch(e) {}
        }
    }

    // ── Data Models ───────────────────────────────────────────────────────────
    ListModel { id: allGamesModel }
    ListModel { id: filteredGamesModel }
    ListModel { id: utilitiesModel }

    // ── Data Fetching Process ──────────────────────────────────────────────────
    Process {
        id: fetchProcess
        command: [Quickshell.env("HOME") + "/.config/quickshell-games/games", "--list"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split("\t")
                if (parts.length >= 5) {
                    var entry = {
                        label: parts[0],
                        source: parts[1],
                        icon: parts[2],
                        commandStr: parts[4]
                    }
                    if (parts[3] === "utility")
                        utilitiesModel.append(entry)
                    else
                        allGamesModel.append(entry)
                }
            }
        }
        onExited: function() {
            filterGames()
        }
    }

    // ── Launch Process ─────────────────────────────────────────────────────────
    Process {
        id: launchProcess
        command: []
        onExited: {
            Qt.quit()
        }
    }

    function launch(commandStr) {
        // Run in background so launcher can quit immediately
        launchProcess.command = ["sh", "-c", commandStr + " &"]
        launchProcess.running = true
    }

    function launchSelected() {
        if (gridView.currentIndex >= 0 && gridView.currentIndex < filteredGamesModel.count)
            launch(filteredGamesModel.get(gridView.currentIndex).commandStr)
    }

    // ── Filtering Logic ────────────────────────────────────────────────────────
    function filterGames() {
        var query = searchInput.text.toLowerCase().trim()
        filteredGamesModel.clear()
        for (var i = 0; i < allGamesModel.count; i++) {
            var item = allGamesModel.get(i)
            if (query === "" || item.label.toLowerCase().indexOf(query) >= 0 || item.source.toLowerCase().indexOf(query) >= 0) {
                filteredGamesModel.append(item)
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
            color: Qt.rgba(root.colorBackground.r, root.colorBackground.g, root.colorBackground.b, root.styleBgOpacity)

            // Dismiss window on click outside the content box
            MouseArea {
                anchors.fill: parent
                onClicked: Qt.quit()
            }

            // Main UI container (fixed width to prevent ultrawide stretching)
            Item {
                width: 1560
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                // Prevent mouse clicks inside from closing the launcher
                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: false
                }

                // Search Box
                Rectangle {
                    id: searchBox
                    width: 420
                    height: 48
                    anchors.top: parent.top
                    anchors.topMargin: 72
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(root.colorBackground.r, root.colorBackground.g, root.colorBackground.b, 0.5)
                    border.width: 1
                    border.color: searchInput.activeFocus ? root.colorActive : root.colorBorder
                    radius: Math.min(root.styleRadius, height / 2)

                    Behavior on border.color { ColorAnimation { duration: root.styleAnimMs } }

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter

                        font.family: root.styleFont
                        font.pixelSize: 15
                        color: root.colorText
                        focus: true

                        selectByMouse: true

                        // Placeholder Text
                        Text {
                            text: "Search games..."
                            font.family: root.styleFont
                            font.pixelSize: 15
                            color: root.colorSubtext
                            visible: parent.text === ""
                            anchors.centerIn: parent
                        }

                        onTextChanged: root.filterGames()

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
                                root.launchSelected()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                Qt.quit()
                                event.accepted = true
                            }
                        }
                    }
                }

                // Grid View for Game Cards
                GridView {
                    id: gridView
                    anchors.top: searchBox.bottom
                    anchors.topMargin: 32
                    anchors.bottom: utilityRow.top
                    anchors.bottomMargin: 24
                    width: parent.width
                    cellWidth: 260
                    cellHeight: 380
                    clip: true

                    model: filteredGamesModel
                    currentIndex: 0

                    Text {
                        text: "No games match"
                        font.family: root.styleFont
                        font.pixelSize: 15
                        color: root.colorSubtext
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 48
                        visible: filteredGamesModel.count === 0
                    }

                    delegate: Item {
                        id: cell
                        width: gridView.cellWidth
                        height: gridView.cellHeight

                        required property int index
                        required property string label
                        required property string source
                        required property string icon
                        required property string commandStr

                        property bool isCurrent: GridView.isCurrentItem
                        property bool hasArt: icon.charAt(0) === "/"

                        // Selection ring
                        Rectangle {
                            width: card.width + 12
                            height: card.height + 12
                            anchors.centerIn: parent
                            radius: root.styleRadius > 0 ? root.styleRadius + 6 : 0
                            color: "transparent"
                            border.width: 2
                            border.color: root.colorActive
                            opacity: cell.isCurrent ? 1 : 0
                            scale: card.scale
                            Behavior on opacity { NumberAnimation { duration: root.styleAnimMs } }
                        }

                        ClippingRectangle {
                            id: card
                            width: 228
                            height: 342
                            anchors.centerIn: parent
                            radius: root.styleRadius
                            color: cell.hasArt
                                ? root.colorBackground
                                : Qt.rgba(root.colorActive.r, root.colorActive.g, root.colorActive.b, 0.07)
                            border.width: cell.hasArt ? 0 : 1
                            border.color: root.colorBorder

                            scale: cell.isCurrent ? root.styleHoverScale : 1.0
                            Behavior on scale { NumberAnimation { duration: root.styleAnimMs; easing.type: Easing.OutQuad } }

                            // Box Art
                            Image {
                                anchors.fill: parent
                                source: cell.hasArt ? "file://" + cell.icon : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: cell.hasArt
                            }

                            // Bottom scrim so the title stays readable over art
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 96
                                visible: cell.hasArt && root.styleScrim
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
                                }
                            }

                            // Title over art
                            Text {
                                text: cell.label
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 14
                                visible: cell.hasArt
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                                font.family: root.styleFont
                                font.pixelSize: 13
                                font.bold: true
                                color: "#ffffff"
                            }

                            // Fallback tile when there is no box art
                            Column {
                                anchors.centerIn: parent
                                width: parent.width - 40
                                spacing: 12
                                visible: !cell.hasArt

                                Text {
                                    text: "󰊗"
                                    font.pixelSize: 42
                                    color: Qt.rgba(root.colorActive.r, root.colorActive.g, root.colorActive.b, 0.6)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: cell.label
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    font.family: root.styleFont
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: root.colorText
                                }
                                Text {
                                    text: cell.source
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    font.family: root.styleFont
                                    font.pixelSize: 11
                                    color: root.colorSubtext
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: gridView.currentIndex = cell.index
                                onClicked: root.launchSelected()
                            }
                        }
                    }
                }

                // Utility actions as a compact pill row
                Row {
                    id: utilityRow
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 48
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Repeater {
                        model: utilitiesModel

                        delegate: Rectangle {
                            id: pill

                            required property string label
                            required property string commandStr

                            width: pillText.width + 40
                            height: 36
                            radius: root.styleRadius > 0 ? height / 2 : 0
                            color: pillMouse.containsMouse
                                ? Qt.rgba(root.colorActive.r, root.colorActive.g, root.colorActive.b, 0.15)
                                : Qt.rgba(root.colorBackground.r, root.colorBackground.g, root.colorBackground.b, 0.5)
                            border.width: 1
                            border.color: pillMouse.containsMouse ? root.colorActive : root.colorBorder

                            Behavior on color { ColorAnimation { duration: root.styleAnimMs } }
                            Behavior on border.color { ColorAnimation { duration: root.styleAnimMs } }

                            Text {
                                id: pillText
                                text: pill.label
                                anchors.centerIn: parent
                                font.family: root.styleFont
                                font.pixelSize: 12
                                color: pillMouse.containsMouse ? root.colorActive : root.colorSubtext
                            }

                            MouseArea {
                                id: pillMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.launch(pill.commandStr)
                            }
                        }
                    }
                }
            }
        }
    }
}
