#!/usr/bin/env bash
# 10-workspace-osd.sh : OSD: workspace number
# Small popup when you change workspace (Super+1..0), also when you press the key for the workspace you are already on. workspace.sh does the switch + badge.
#   bash Script/10-workspace-osd.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/10-workspace-osd.sh check    read-only check
MOD="10-workspace-osd"; TITLE="OSD: workspace number"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/quickshell/snow/osd/WorkspaceOsd.qml|644|0"
  "u|.config/snow/bin/osd/workspace.sh|755|0"
)
emit() {
case "$1" in
"u/.config/quickshell/snow/osd/WorkspaceOsd.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  WorkspaceOsd.qml  —  WORKSPACE KA GOL NUMBER  (apne aap dikhta hai)
// ----------------------------------------------------------------------------
//  DIKHTA KYA HAI : Screen ke upar-left kone me chhota gol kala badge, jisme workspace ka number.
//                   1.5 second baad gayab. Dark hi rehta hai taki number har theme me padhne layak ho.
//  KAB DIKHTA HAI : (1) workspace badalte hi   (2) Super+1..0 dabane par — chahe tum usi workspace par ho
//                   (2) ke liye hyprland key workspace.sh chalati hai (switch + "qs.sh ipc call workspace flash").
//  BADLO (SETTINGS) : size, showMs (kitni der dikhe), corner doori (margins).
//  NOTE : shell.qml isse code se load karta hai, taki Hyprland module na mile to baaki shell na toote.
// ============================================================================
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.core

PanelWindow {
    id: win

    // ---------------- SETTINGS (yahan badlo) ----------------
    readonly property int size: 40          // gol badge ka diameter
    readonly property int ring: 3           // bahar ka halka ring
    readonly property int showMs: 1500      // kitni der dikhe (milliseconds)
    readonly property int edge: 16          // screen ke kone se doori

    property bool active: false             // abhi dikh raha hai?
    property bool ready: false              // false = abhi start hua, pehli baar pop-up mat dikhao

    readonly property var fw: Hyprland.focusedWorkspace
    readonly property int wsId: fw ? fw.id : 0

    visible: badge.opacity > 0
    color: "transparent"
    anchors { top: true; left: true }
    margins { top: edge - ring; left: edge - ring }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: size + 2 * ring
    implicitHeight: size + 2 * ring
    mask: Region {}                         // click-through

    WlrLayershell.namespace: "snow-workspace"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // workspace badla -> badge dikhao
    onWsIdChanged: {
        if (wsId <= 0) return               // abhi koi nahi / special workspace
        if (!ready) { ready = true; return }
        active = true
        hideTimer.restart()
    }
    Component.onCompleted: ready = wsId > 0

    Timer { id: hideTimer; interval: win.showMs; onTriggered: win.active = false }

    // Super+number ka IPC: 60ms ruko taki Hyprland switch ho chuka ho (naya number dikhe, purana nahi)
    Timer { id: showTimer; interval: 60; onTriggered: { if (win.wsId > 0) { win.active = true; hideTimer.restart() } } }
    // NOTE: the function is called "flash", NOT "show": "qs ipc call workspace show" is read by the qs command line as the sub command "ipc show"
    //       (it only printed the target's help and never called the function).
    IpcHandler {
        target: "workspace"
        function flash(): void {
            if (win.wsId > 0) { win.active = true; hideTimer.restart() }   // at once (also when the workspace did not change)
            showTimer.restart()                                              // and once more after 60 ms, when the switch has happened
        }
    }

    Item {
        id: badge
        anchors.fill: parent
        opacity: win.active ? 1 : 0
        scale: win.active ? 1 : 0.85
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

        Rectangle { antialiasing: true; anchors.fill: parent; radius: width / 2; color: Qt.rgba(0, 0, 0, 0.30) }      // bahar ka halka ring

        Rectangle {                                                                               // asli gol badge
            antialiasing: true
            x: win.ring
            y: win.ring
            width: win.size
            height: win.size
            radius: width / 2
            border.width: 1
            border.color: Qt.alpha(Theme.accent, 0.55)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0.17, 0.17, 0.21, 0.96) }
                GradientStop { position: 1.0; color: Qt.rgba(0.06, 0.06, 0.08, 0.96) }
            }
            Text {
                anchors.centerIn: parent
                text: win.wsId
                font.family: Theme.uiFont
                font.pixelSize: win.wsId >= 10 ? 15 : 18
                font.weight: Font.ExtraBold
                color: "#ffffff"           // jaan-bujh ke fixed safed: badge hamesha dark hai
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/osd/workspace.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# workspace.sh N : go to workspace N (Super+1..0) AND show the round number badge - also when you are already on workspace N.
#   One key = one command, so the badge cannot be missed. The badge itself is WorkspaceOsd.qml (IPC: workspace flash).
#   Log of the last calls: ~/.cache/snow-workspace.log   (if the badge ever does not appear, send this file)
N="${1:-}"; case "$N" in ''|*[!0-9]*) echo "usage: workspace.sh NUMBER"; exit 2 ;; esac
LOG="$HOME/.cache/snow-workspace.log"; mkdir -p "$HOME/.cache"
out=$(hyprctl dispatch "hl.dsp.focus({ workspace = $N })" 2>&1)
case "$out" in *ok*) ;; *) out="lua-form said [$out]; plain: $(hyprctl dispatch workspace "$N" 2>&1)" ;; esac
ipc=$(bash "$HOME/.config/snow/bin/core/qs.sh" ipc call workspace flash 2>&1); rc=$?
printf '%s ws=%s dispatch=%s ipc_rc=%s ipc=%s\n' "$(date '+%F %T')" "$N" "$out" "$rc" "$ipc" >> "$LOG"
tail -n 50 "$LOG" > "$LOG.tmp" 2>/dev/null && mv -f "$LOG.tmp" "$LOG"
exit 0
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
extra_check() {
for n in osd/WorkspaceOsd; do qml_ok "$QS/$n.qml"; done
for s in osd/workspace.sh; do [ -f "$BIN/$s" ] || continue; bash -n "$BIN/$s" && pass "$s: syntax ok" || fail "$s: syntax error" "bash ~/Snow/Script/${MOD}.sh"; done
}
component_main "$@"
