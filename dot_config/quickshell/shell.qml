import Quickshell
import QtQuick

ShellRoot {
    // Scope allows Quickshell's live reloading engine to safely rebuild when saved
    Scope {
        StatusBar {
            id: statusBar
            controlCenter: controlCenter
            calendarWindow: calendarWindow
        }

        ControlCenter {
            id: controlCenter
        }

        CalendarWindow {
            id: calendarWindow
        }

        Launcher {}

        OsdWindow {}

        LockOsdWindow {}
    }
}
