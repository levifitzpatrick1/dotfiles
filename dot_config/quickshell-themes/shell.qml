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
            color: Qt.rgba(root.colorBackground.r, root.colorBackground.g, root.colorBackground.b, root.styleBgOpacity)

            // Dismiss window on click outside the content box
            MouseArea {
                anchors.fill: parent
                onClicked: Qt.quit()
            }

            // Main UI container (fixed width to prevent ultrawide stretching)
            Item {
                width: 1360
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
                            text: "Search wallpapers..."
                            font.family: root.styleFont
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
                    anchors.top: searchBox.bottom
                    anchors.topMargin: 32
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 48
                    width: parent.width
                    cellWidth: 340
                    cellHeight: 226
                    clip: true

                    model: filteredThemesModel
                    currentIndex: 0

                    Text {
                        text: "No wallpapers match"
                        font.family: root.styleFont
                        font.pixelSize: 15
                        color: root.colorSubtext
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 48
                        visible: filteredThemesModel.count === 0
                    }

                    delegate: Item {
                        id: cell
                        width: gridView.cellWidth
                        height: gridView.cellHeight

                        required property int index
                        required property string label
                        required property string kind
                        required property string source
                        required property string icon

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
                            width: 320
                            height: 202
                            anchors.centerIn: parent
                            radius: root.styleRadius
                            color: cell.hasArt
                                ? root.colorBackground
                                : Qt.rgba(root.colorActive.r, root.colorActive.g, root.colorActive.b, 0.07)
                            border.width: cell.hasArt ? 0 : 1
                            border.color: root.colorBorder

                            scale: cell.isCurrent ? root.styleHoverScale : 1.0
                            Behavior on scale { NumberAnimation { duration: root.styleAnimMs; easing.type: Easing.OutQuad } }

                            // Wallpaper Preview
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
                                height: 72
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
                                anchors.margins: 12
                                visible: cell.hasArt
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                horizontalAlignment: Text.AlignHCenter
                                font.family: root.styleFont
                                font.pixelSize: 12
                                font.bold: true
                                color: "#ffffff"
                            }

                            // Kind badge (animated / workshop subscribe)
                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 10
                                width: badgeText.width + 16
                                height: 20
                                radius: root.styleRadius > 0 ? height / 2 : 0
                                color: Qt.rgba(0, 0, 0, 0.6)
                                visible: cell.kind === "Animated"

                                Text {
                                    id: badgeText
                                    text: "ANIMATED"
                                    font.family: root.styleFont
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: root.colorActive
                                    anchors.centerIn: parent
                                }
                            }

                            // Fallback tile for workshop items not yet installed
                            Column {
                                anchors.centerIn: parent
                                width: parent.width - 48
                                spacing: 8
                                visible: !cell.hasArt

                                Text {
                                    text: "󰓓"
                                    font.pixelSize: 32
                                    color: Qt.rgba(root.colorActive.r, root.colorActive.g, root.colorActive.b, 0.6)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: cell.label
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    font.family: root.styleFont
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.colorText
                                }
                                Text {
                                    text: cell.kind === "Subscribe" ? "Subscribe on Workshop" : cell.kind
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    font.family: root.styleFont
                                    font.pixelSize: 10
                                    color: root.colorSubtext
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: gridView.currentIndex = cell.index
                                onClicked: root.applySelected()
                            }
                        }
                    }
                }
            }
        }
    }
}
