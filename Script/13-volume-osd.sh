#!/usr/bin/env bash
# 13-volume-osd.sh : OSD: volume / brightness / mic
# Popup for the volume, brightness and microphone keys. Default sound volume 40% once on a fresh install (defaults.sh).
#   bash Script/13-volume-osd.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/13-volume-osd.sh check    read-only check
MOD="13-volume-osd"; TITLE="OSD: volume / brightness / mic"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/hypr/snow-osd-keys.lua|644|0"
  "u|.config/quickshell/snow/osd/OsdPopup.qml|644|0"
  "u|.config/snow/bin/core/defaults.sh|755|0"
)
emit() {
case "$1" in
"u/.config/hypr/snow-osd-keys.lua")
cat <<'SNOW_FILE_END_4b7d'
-- ============================================================================
--  snow-osd-keys.lua  —  GHADI KI KEY, VOLUME KEYS, WORKSPACE BADGE KI KEYS
-- ----------------------------------------------------------------------------
--  Super + BackSpace      ghadi ka card dikhao/chhupao
--  Volume keys (XF86Audio...) volume +5% / -5% / mute. Pop-up apne aap aata hai (OsdPopup.qml).
--  Super + 1..0           workspace badalna + badge: hyprland.lua me workspace.sh se (yahan koi bind nahi).
--  NOTE: install.sh dekhta hai ki volume keys hyprland.lua me pehle se bound to nahi hain; agar hain to
--        neeche wali volume lines hata deta hai (duplicate se bachne ke liye).
-- ============================================================================
local home = os.getenv("HOME")
local qs = home .. "/.config/snow/bin/core/qs.sh"

hl.bind("SUPER + BackSpace", hl.dsp.exec_cmd(qs .. " ipc call clock toggle"))


-- Workspace number badge: Super+1..0 is bound in hyprland.lua to workspace.sh (it switches AND shows the badge).
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/osd/OsdPopup.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  OsdPopup.qml  —  VOLUME POP-UP  (apne aap dikhta hai)
// ----------------------------------------------------------------------------
//  DIKHTA KYA HAI : Neeche-beech me gol patti: icon + bhari hui line + percent. 1.5 second baad gayab.
//  KAB DIKHTA HAI : Jab bhi system volume ya mute badle — keyboard keys, Quick settings slider, ya koi bhi app.
//  KAISE PATA CHALTA HAI : "pactl subscribe" har badlav ki khabar deta hai, "wpctl get-volume" asli value padhta hai.
//  AGAR POP-UP NA AAYE : terminal me:  wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+    phir   tail -30 ~/.cache/snow/qs.log
//  BADLO (SETTINGS) : showMs (kitni der dikhe), bottomGap (neeche se doori).
// ============================================================================
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.core

PanelWindow {
    id: win

    // ---------------- SETTINGS (yahan badlo) ----------------
    readonly property int showMs: 1500       // kitni der dikhe
    readonly property int bottomGap: 90      // screen ke neeche se doori

    property string kind: "vol"              // "vol" ya "bright"
    property real level: 0                   // 0..1
    property bool muted: false
    property bool active: false              // pop-up dikh raha hai?
    property bool ready: false               // false = pehli reading (start par pop-up nahi)
    property bool forceShow: false           // true = value na badle tab bhi dikhao

    visible: card.opacity > 0
    color: "transparent"
    anchors { bottom: true }
    margins { bottom: bottomGap }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 300
    implicitHeight: 60
    mask: Region {}                          // click-through

    WlrLayershell.namespace: "snow-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function pop(): void { win.active = true; hideTimer.restart() }

    // ---- 1) volume padho; badla ho to dikhao ----
    Process {
        id: volGet
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var m = text.match(/([0-9]+\.[0-9]+)/)
                if (!m) return
                var v = parseFloat(m[1])
                var mu = text.indexOf("MUTED") !== -1
                var changed = (v !== win.level || mu !== win.muted || win.kind !== "vol")
                var first = !win.ready
                win.ready = true
                if (win.kind !== "vol" && !changed) return
                win.kind = "vol"
                win.level = v
                win.muted = mu
                if ((changed && !first) || win.forceShow) win.pop()
                win.forceShow = false
            }
        }
    }

    // ---- 2) badlav ki khabar sunna ----
    // pactl seedha chalta hai (sh / pipe nahi), taaki Quickshell band ho to pactl bhi band ho jaye (leak nahi).
    // LC_ALL=C = shabd English me rahein. Agar pactl mar jaye to 2s, 4s ... 60s ruk ke dobara koshish.
    Process {
        id: watcher
        running: true
        property int backoff: 2000
        command: ["env", "LC_ALL=C", "pactl", "subscribe"]
        stdout: SplitParser {
            onRead: data => {
                watcher.backoff = 2000
                if (data.indexOf("'change' on sink #") >= 0) debounce.restart()
            }
        }
        onRunningChanged: if (!running) { restartTimer.interval = backoff; backoff = Math.min(backoff * 2, 60000); restartTimer.start() }
    }
    Timer { id: restartTimer; onTriggered: watcher.running = true }
    Timer { id: debounce; interval: 30; onTriggered: if (!volGet.running) volGet.running = true }   // bahut tez badlav ek baar me
    Timer { id: hideTimer; interval: win.showMs; onTriggered: win.active = false }

    Component.onCompleted: volGet.running = true

    IpcHandler {
        target: "osd"
        function trigger(): void { win.forceShow = true; if (!volGet.running) volGet.running = true }
        function brightness(v: real): void { win.kind = "bright"; win.level = v; win.muted = false; win.pop() }
    }

    Rectangle {
        antialiasing: true
        id: card
        anchors.fill: parent
        radius: height / 2
        color: Qt.alpha(Theme.bg, 0.94)
        border.width: 1
        border.color: Theme.hairline
        opacity: win.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 22
            width: parent.width - 44
            spacing: 14

            Text {                                              // icon: level ke hisaab se badalta hai
                width: 24
                anchors.verticalCenter: parent.verticalCenter
                text: win.kind === "bright" ? Icons.brightness
                    : (win.muted || win.level === 0 ? Icons.volumeOff
                    : (win.level < 0.34 ? Icons.volumeMute : (win.level < 0.67 ? Icons.volumeDown : Icons.volumeUp)))
                font.family: Theme.iconFont
                font.pixelSize: 24
                color: win.muted ? Theme.muted : Theme.text
            }

            Item {                                              // bhari hui line
                width: parent.width - 24 - 44 - 28
                height: 5
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { antialiasing: true; anchors.fill: parent; radius: 2.5; color: Theme.surfaceHi }
                Rectangle {
                    antialiasing: true
                    width: parent.width * Math.min(1, win.level)
                    height: parent.height
                    radius: 2.5
                    color: win.muted ? Theme.muted : Theme.accent
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
            }

            Text {                                              // percent
                width: 44
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: Math.round(win.level * 100) + "%"
                font.family: Theme.uiFont
                font.pixelSize: Theme.fsBody
                font.weight: Font.Medium
                color: win.muted ? Theme.muted : Theme.text
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/core/defaults.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# defaults.sh : one-time default sound volume = 40% (fresh install). Started at Hyprland start and by the install script.
#   It waits up to 30 s for the sound system, sets 40% ONCE and remembers that (marker file). After that it does nothing,
#   so your own volume is never touched again. (Default brightness 60% is in ~/.config/snow/state/quick.json.)
M="$HOME/.config/snow/state/.default-volume-done"
[ -e "$M" ] && exit 0
command -v wpctl >/dev/null 2>&1 || exit 0
for _ in $(seq 1 30); do
  if wpctl get-volume @DEFAULT_AUDIO_SINK@ >/dev/null 2>&1; then
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 40% && { mkdir -p "$(dirname "$M")"; : > "$M"; }
    exit 0
  fi
  sleep 1
done
exit 0
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
post() {
( nohup bash "$BIN/core/defaults.sh" >/dev/null 2>&1 & )
pass "default volume 40% is set once (now or at the next login)"
}
extra_check() {
for n in osd/OsdPopup; do qml_ok "$QS/$n.qml"; done
for s in core/defaults.sh; do [ -f "$BIN/$s" ] || continue; bash -n "$BIN/$s" && pass "$s: syntax ok" || fail "$s: syntax error" "bash ~/Snow/Script/${MOD}.sh"; done
}
component_main "$@"
