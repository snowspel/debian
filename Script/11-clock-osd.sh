#!/usr/bin/env bash
# 11-clock-osd.sh : OSD: clock
# Super+Backspace big clock popup.
#   bash Script/11-clock-osd.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/11-clock-osd.sh check    read-only check
MOD="11-clock-osd"; TITLE="OSD: clock"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/quickshell/snow/osd/ClockOsd.qml|644|0"
)
emit() {
case "$1" in
"u/.config/quickshell/snow/osd/ClockOsd.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  ClockOsd.qml  —  GHADI KA CARD  (Super+BackSpace se dikhao / chhupao)
// ----------------------------------------------------------------------------
//  DIKHTA KYA HAI : Neeche-daayein kone me chhota card: 12-ghante ka samay (3:20 PM) + tareekh aur din (24 · SATURDAY).
//  KAISE CHALTA HAI : Click-through hai (mouse use nahi karta). Dubara key = chhup jata hai.
//  KEY : ~/.config/hypr/snow-osd-keys.lua me "SUPER + BackSpace" -> qs.sh ipc call clock toggle
//  BADLO (SETTINGS) : edge (kone se doori), font sizes.
// ============================================================================
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.core

PanelWindow {
    id: win

    readonly property int edge: 16              // screen ke kone se doori (SETTINGS)
    property bool shown: false                  // card dikh raha hai?

    visible: card.opacity > 0
    color: "transparent"
    anchors { bottom: true; right: true }
    margins { bottom: edge; right: edge }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: card.width
    implicitHeight: card.height
    mask: Region {}                             // click-through

    WlrLayershell.namespace: "snow-clock"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // har minute badalta hai
    SystemClock { id: clock; precision: SystemClock.Minutes }

    // 15:20 -> "3:20" aur "PM"
    readonly property int hh: clock.date.getHours()
    readonly property string timeText: (hh % 12 === 0 ? 12 : hh % 12) + ":" + ("0" + clock.date.getMinutes()).slice(-2)
    readonly property string ampmText: hh >= 12 ? "PM" : "AM"

    IpcHandler {
        target: "clock"
        function toggle(): void { win.shown = !win.shown }
        function show(): void { win.shown = true }
        function hide(): void { win.shown = false }
    }

    Rectangle {
        antialiasing: true
        id: card
        width: timeRow.width + 40
        height: col.height + 26
        radius: Theme.rCard - 2
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.78)
        border.width: 1
        border.color: Theme.hairline
        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Column {
            id: col
            anchors.centerIn: parent
            spacing: 0

            Item {                                          // "3:20" + chhota "PM"
                id: timeRow
                anchors.horizontalCenter: parent.horizontalCenter
                width: timeTxt.width + 6 + ampmTxt.width
                height: timeTxt.height
                Text { id: timeTxt; text: win.timeText; font.family: Theme.uiFont; font.pixelSize: 30; font.weight: Font.Bold; color: Theme.text }
                Text {
                    id: ampmTxt
                    anchors.left: timeTxt.right
                    anchors.leftMargin: 6
                    anchors.baseline: timeTxt.baseline
                    text: win.ampmText
                    font.family: Theme.uiFont; font.pixelSize: 11; font.weight: Font.Medium; color: Theme.muted
                }
            }

            Row {                                           // tareekh · din
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Text { anchors.verticalCenter: parent.verticalCenter; text: Qt.formatDateTime(clock.date, "dd"); font.family: Theme.uiFont; font.pixelSize: 13; font.weight: Font.Bold; color: Theme.accent }
                Rectangle { antialiasing: true; anchors.verticalCenter: parent.verticalCenter; width: 3; height: 3; radius: 1.5; color: Theme.muted }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "dddd").toUpperCase()
                    font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Medium; font.letterSpacing: 1.6; color: Theme.muted
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
extra_check() {
for n in osd/ClockOsd; do qml_ok "$QS/$n.qml"; done
}
component_main "$@"
