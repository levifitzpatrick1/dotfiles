import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Qt.labs.folderlistmodel 2.15

PanelWindow {
    id: launcherWindow
    color: "transparent"
    visible: false
    focusable: isOpen
    exclusiveZone: -1
    aboveWindows: true

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool isOpen: false
    property bool isSearchingFiles: false
    property var allApps: systemActions
    property var filteredApps: []
    property int selectedIndex: 0

    onAllAppsChanged: filterApps()

    property var themeColors: getThemeColors("")

    property var systemActions: [
        {
            "name": "Lock Screen",
            "exec": "hyprlock",
            "icon_char": "",
            "comment": "Lock the active computer session",
            "is_action": true
        },
        {
            "name": "Toggle Control Center",
            "exec": "qs ipc call controlcenter toggle",
            "icon_char": "",
            "comment": "Open or close the settings control panel",
            "is_action": true
        },
        {
            "name": "Open Calendar",
            "exec": "qs ipc call calendar toggle",
            "icon_char": "",
            "comment": "Open or close the calendar widget",
            "is_action": true
        },
        {
            "name": "Check System Health",
            "exec": "ghostty -e btop",
            "icon_char": "",
            "comment": "Monitor CPU, memory, processes, and thermals",
            "is_action": true
        },
        {
            "name": "System Package Sync & Update",
            "exec": "ghostty -e yay -Syu",
            "icon_char": "",
            "comment": "Synchronize Arch and AUR packages",
            "is_action": true
        },
        {
            "name": "Quick Note / Todo List",
            "exec": "ghostty -e nano /home/levi/.config/quickshell/scratchpad.md",
            "icon_char": "",
            "comment": "Edit the desktop scratchpad",
            "is_action": true
        },
        {
            "name": "Open Ghostty Terminal",
            "exec": "ghostty",
            "icon_char": "",
            "comment": "Launch a terminal",
            "is_action": true
        },
        {
            "name": "File Manager (Dolphin)",
            "exec": "dolphin",
            "icon_char": "",
            "comment": "Browse files graphically",
            "is_action": true
        }
    ]

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            launcherWindow.toggle();
        }
    }

    FileView {
        id: jsonThemeFile
        path: "/home/levi/.config/hypr/current_theme/theme_colors.json"
        watchChanges: true
        onLoaded: themeColors = getThemeColors(text())
        onTextChanged: themeColors = getThemeColors(text())
    }

    FileView {
        id: appsCacheFile
        path: "/home/levi/.cache/quickshell-apps.json"
        watchChanges: true
        onLoaded: {
            console.log("[Launcher] Apps cache loaded successfully! Length: " + (text ? text().length : 0));
            var apps = getAppsFromCache(text());
            if (apps && apps.length > 0) {
                allApps = apps;
                console.log("[Launcher] Successfully loaded " + apps.length + " apps into allApps.");
            } else {
                console.log("[Launcher] getAppsFromCache returned empty or null.");
            }
        }
        onLoadFailed: function(err) {
            console.log("[Launcher] Apps cache load failed: " + err);
        }
        onTextChanged: {
            console.log("[Launcher] Apps cache text changed! Length: " + (text ? text().length : 0));
            var apps = getAppsFromCache(text());
            if (apps && apps.length > 0) {
                allApps = apps;
                console.log("[Launcher] Successfully updated " + apps.length + " apps into allApps via onTextChanged.");
            }
        }
    }

    FolderListModel {
        id: folderModel
        showDirs: true
        showFiles: true
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        folder: "file:///home/levi"
        nameFilters: ["*"]
        onCountChanged: {
            if (isSearchingFiles) populateFiles();
        }
    }

    Component {
        id: processComponent
        Process {
            onRunningChanged: {
                if (!running) {
                    destroy();
                }
            }
        }
    }

    Process {
        id: cacheBuilder
        command: ["python3", "/home/levi/.config/quickshell/launcher_apps.py"]
        running: false
    }

    function getThemeColors(text) {
        try {
            if (text && text.length > 0) return JSON.parse(text);
        } catch (e) {}
        return {
            "primary": "#d0bcff",
            "onPrimary": "#07001f",
            "primaryContainer": "rgba(208, 188, 255, 0.18)",
            "background": "rgba(7, 0, 31, 0.72)",
            "surface": "rgba(24, 18, 43, 0.68)",
            "text": "#e6e1e5",
            "subtext": "#cac4d0",
            "border": "rgba(208, 188, 255, 0.28)",
            "fontFamily": "Comfortaa"
        };
    }

    function getAppsFromCache(text) {
        try {
            if (text && text.length > 0) {
                var apps = JSON.parse(text);
                if (apps && apps.length > 0) return apps;
            }
        } catch (e) {
            console.log("[Launcher] Failed to parse app cache:", e);
        }
        return systemActions;
    }

    function parseColor(str, fallback) {
        if (!str) return fallback;
        if (str.indexOf("#") === 0) return str;
        if (str.indexOf("rgba") === 0) {
            var m = str.match(/rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)/);
            if (m) return Qt.rgba(parseInt(m[1]) / 255, parseInt(m[2]) / 255, parseInt(m[3]) / 255, parseFloat(m[4]));
        }
        return fallback;
    }

    function getThemeColor(name, fallback) {
        return themeColors && themeColors[name] !== undefined ? themeColors[name] : fallback;
    }


    function resolvePath(query) {
        if (query.indexOf("~/") === 0) return "/home/levi/" + query.substring(2);
        if (query.indexOf("/") === 0) return query;
        if (query.indexOf("./") === 0) return "/home/levi/" + query.substring(2);
        return "";
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function evaluateMath(query) {
        var expr = query.trim();
        if (!expr.match(/^[0-9+\-*\/(). %]+$/)) return null;
        if (!expr.match(/[+\-*\/%]/)) return null;

        try {
            var result = Function("return (" + expr + ")")();
            if (typeof result === "number" && isFinite(result)) return String(result);
        } catch (e) {}
        return null;
    }

    function populateFiles() {
        if (!isSearchingFiles) return;

        var currentFolder = folderModel.folder.toString();
        if (currentFolder.indexOf("file://") === 0) currentFolder = currentFolder.substring(7);
        if (currentFolder.length > 1 && currentFolder.endsWith("/")) currentFolder = currentFolder.slice(0, -1);

        var items = [{
            "name": "Open folder in Zed",
            "exec": "zed " + shellQuote(currentFolder),
            "icon_char": "",
            "comment": currentFolder,
            "is_action": true,
            "is_zed_open": true,
            "path": currentFolder
        }];

        for (var i = 0; i < folderModel.count; i++) {
            var name = folderModel.get(i, "fileName");
            var isDir = folderModel.get(i, "fileIsDir");
            var path = folderModel.get(i, "filePath");
            if (path.indexOf("file://") === 0) path = path.substring(7);

            items.push({
                "name": name + (isDir ? "/" : ""),
                "exec": isDir ? "" : "xdg-open " + shellQuote(path),
                "icon_char": isDir ? "" : "",
                "comment": path,
                "is_directory": isDir,
                "is_file": !isDir,
                "path": path
            });
        }

        filteredApps = items;
        selectedIndex = 0;
    }

    function filterApps() {
        if (typeof searchInput === "undefined" || !searchInput) return; // Guard early calls
        var queryRaw = searchInput.text ? searchInput.text.trim() : "";
        var query = queryRaw.toLowerCase();

        if (queryRaw.indexOf("/") === 0 || queryRaw.indexOf("~/") === 0 || queryRaw.indexOf("./") === 0) {
            isSearchingFiles = true;
            var resolved = resolvePath(queryRaw);
            var lastSlash = resolved.lastIndexOf("/");
            var parentPath = resolved.substring(0, lastSlash + 1);
            var pattern = resolved.substring(lastSlash + 1);
            if (parentPath === "") parentPath = "/home/levi/";
            if (typeof folderModel !== "undefined" && folderModel) {
                folderModel.folder = "file://" + parentPath;
                folderModel.nameFilters = [pattern + "*"];
                populateFiles();
            }
            return;
        }

        isSearchingFiles = false;

        if (query === "") {
            filteredApps = allApps;
            selectedIndex = 0;
            return;
        }

        var items = [];
        var mathResult = evaluateMath(queryRaw);
        if (mathResult !== null) {
            items.push({
                "name": mathResult,
                "exec": "",
                "icon_char": "",
                "comment": "= " + queryRaw + " (Enter copies result)",
                "is_calculator": true
            });
        }

        for (var i = 0; i < systemActions.length; i++) {
            var action = systemActions[i];
            if (action.name.toLowerCase().indexOf(query) !== -1 || action.comment.toLowerCase().indexOf(query) !== -1) {
                items.push(action);
            }
        }

        if (allApps && allApps.length > 0) {
            for (var j = 0; j < allApps.length; j++) {
                var app = allApps[j];
                var haystack = (app.name + " " + app.exec + " " + (app.comment || "")).toLowerCase();
                if (haystack.indexOf(query) !== -1) items.push(app);
            }
        }

        items.push({
            "name": "Search Google for \"" + queryRaw + "\"",
            "exec": "xdg-open " + shellQuote("https://www.google.com/search?q=" + encodeURIComponent(queryRaw)),
            "icon_char": "",
            "comment": "Open this search in your browser",
            "is_action": true
        });

        items.push({
            "name": "Ask AI about \"" + queryRaw + "\"",
            "exec": "ghostty -e python3 /home/levi/.config/quickshell/llm_ask.py " + shellQuote(queryRaw),
            "icon_char": "󰚩",
            "comment": "Open the terminal AI helper",
            "is_action": true
        });

        filteredApps = items;
        selectedIndex = 0;
        if (typeof appsListView !== "undefined" && appsListView) {
            appsListView.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    function launchSelected() {
        if (filteredApps.length === 0 || selectedIndex < 0 || selectedIndex >= filteredApps.length) return;

        var app = filteredApps[selectedIndex];
        if (app.is_calculator) {
            var proc = processComponent.createObject(launcherWindow, {
                "command": ["sh", "-c", "printf %s " + shellQuote(app.name) + " | wl-copy"]
            });
            proc.running = true;
            close();
        } else if (app.is_directory) {
            searchInput.text = app.path + "/";
            searchInput.cursorPosition = searchInput.text.length;
            filterApps();
        } else {
            var proc = processComponent.createObject(launcherWindow, {
                "command": ["setsid", "-f", "sh", "-c", app.exec + " >/dev/null 2>&1"]
            });
            proc.running = true;
            close();
        }
    }

    function launchAltSelected() {
        if (filteredApps.length === 0 || selectedIndex < 0 || selectedIndex >= filteredApps.length) return;
        var app = filteredApps[selectedIndex];
        if (!app.path) return;
        var proc = processComponent.createObject(launcherWindow, {
            "command": ["setsid", "-f", "sh", "-c", "zed " + shellQuote(app.path) + " >/dev/null 2>&1"]
        });
        proc.running = true;
        close();
    }

    function toggle() {
        if (isOpen) close();
        else open();
    }

    function open() {
        closeTimer.stop();
        visible = true;
        isOpen = true;
        searchInput.text = "";
        filterApps();
        searchInput.forceActiveFocus();
        cacheBuilder.running = true;
    }

    function close() {
        isOpen = false;
        closeTimer.start();
    }

    Timer {
        id: closeTimer
        interval: 180
        repeat: false
        onTriggered: launcherWindow.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: "#660a0a0a"
        opacity: launcherWindow.isOpen ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: launcherWindow.close()
        }

        Rectangle {
            id: mainCard
            width: Math.min(640, parent.width - 32)
            height: Math.min(480, parent.height - 96)
            anchors.centerIn: parent
            radius: 28
            color: parseColor(getThemeColor("background", "rgba(17, 19, 15, 0.85)"), Qt.rgba(17/255, 19/255, 15/255, 0.85))
            border.color: parseColor(getThemeColor("border", "rgba(255, 255, 255, 0.08)"), Qt.rgba(1, 1, 1, 0.08))
            border.width: 1
            opacity: launcherWindow.isOpen ? 1 : 0
            scale: launcherWindow.isOpen ? 1 : 0.96

            Behavior on opacity {
                NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: 28
                    color: parseColor(getThemeColor("surface", "rgba(24, 18, 43, 0.68)"), Qt.rgba(24/255, 18/255, 43/255, 0.68))
                    border.color: searchInput.activeFocus ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff") : "transparent"
                    border.width: searchInput.activeFocus ? 2 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 12

                        Text {
                            text: ""
                            font.family: "Hack Nerd Font"
                            font.pixelSize: 18
                            color: parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                            font.family: getThemeColor("fontFamily", "Comfortaa")
                            font.pixelSize: 16
                            selectByMouse: true
                            selectionColor: parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                            selectedTextColor: parseColor(getThemeColor("onPrimary", "#07001f"), "#07001f")
                            onTextChanged: filterApps()

                            Text {
                                text: "Search applications..."
                                color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                                font.family: parent.font.family
                                font.pixelSize: parent.font.pixelSize
                                opacity: 0.65
                                visible: searchInput.text === ""
                            }

                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Down) {
                                    if (filteredApps.length > 0) selectedIndex = (selectedIndex + 1) % filteredApps.length;
                                    appsListView.positionViewAtIndex(selectedIndex, ListView.Contain);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    if (filteredApps.length > 0) selectedIndex = (selectedIndex - 1 + filteredApps.length) % filteredApps.length;
                                    appsListView.positionViewAtIndex(selectedIndex, ListView.Contain);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (event.modifiers & Qt.AltModifier) launchAltSelected();
                                    else launchSelected();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) {
                                    launcherWindow.close();
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: appsListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: filteredApps

                    delegate: Rectangle {
                        id: itemDelegate
                        width: appsListView.width
                        height: 60
                        radius: 14

                        property bool isSelected: index === selectedIndex
                        property bool isHovered: false

                        color: isSelected ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff") : (isHovered ? "#0dffffff" : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: 8
                                color: itemDelegate.isSelected ? "#26000000" : "#0dffffff"
                                clip: true

                                Image {
                                    id: appIcon
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    source: modelData.icon ? "file://" + modelData.icon : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    visible: status === Image.Ready && !modelData.is_calculator && !modelData.is_action && !modelData.is_directory && !modelData.is_file
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon_char || ""
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: 20
                                    color: itemDelegate.isSelected ? parseColor(getThemeColor("onPrimary", "#07001f"), "#07001f") : parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                                    visible: !appIcon.visible
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.family: getThemeColor("fontFamily", "Comfortaa")
                                    font.bold: true
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    color: itemDelegate.isSelected ? parseColor(getThemeColor("onPrimary", "#07001f"), "#07001f") : parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.comment || modelData.exec || ""
                                    font.family: getThemeColor("fontFamily", "Comfortaa")
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    color: itemDelegate.isSelected ? "rgba(7, 0, 31, 0.6)" : parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                                }
                            }

                            Text {
                                text: ""
                                font.family: "Hack Nerd Font"
                                font.pixelSize: 14
                                color: parseColor(getThemeColor("onPrimary", "#07001f"), "#07001f")
                                visible: itemDelegate.isSelected
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: itemDelegate.isHovered = true
                            onExited: itemDelegate.isHovered = false
                            onClicked: {
                                selectedIndex = index;
                                launchSelected();
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "No applications found."
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.pixelSize: 16
                        color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                        visible: filteredApps.length === 0
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: parseColor(getThemeColor("border", "rgba(208, 188, 255, 0.28)"), Qt.rgba(208/255, 188/255, 255/255, 0.28))
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24

                    Text {
                        text: "↑↓ Navigate"
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.pixelSize: 11
                        color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                    }

                    Text {
                        text: "  •  ↵ Launch  •  Alt+↵ Zed  •  Esc Dismiss"
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.pixelSize: 11
                        color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: filteredApps.length + " Items"
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.pixelSize: 11
                        font.bold: true
                        color: parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        filterApps();
    }
}
