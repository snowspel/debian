#!/usr/bin/env bash
# 06-core.sh : Panels core: shell, colours file, icons
# shell.qml, Theme.qml, Sys.qml, Display.qml, Dimmer.qml, qs.sh (starts the panels), gen-icons.sh. Generates Icons.qml from the icon font.
#   bash Script/06-core.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/06-core.sh check    read-only check
MOD="06-core"; TITLE="Panels core: shell, colours file, icons"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/quickshell/snow/core/Display.qml|644|0"
  "u|.config/quickshell/snow/core/Sys.qml|644|0"
  "u|.config/quickshell/snow/core/Theme.qml|644|0"
  "u|.config/quickshell/snow/osd/Dimmer.qml|644|0"
  "u|.config/quickshell/snow/shell.qml|644|0"
  "u|.config/snow/bin/core/gen-icons.sh|755|0"
  "u|.config/snow/bin/core/qs.sh|755|0"
)
emit() {
case "$1" in
"u/.config/quickshell/snow/core/Display.qml")
cat <<'SNOW_FILE_END_4b7d'
pragma Singleton
// ⚠ RULE: 'pragma Singleton' hamesha FILE KI PEHLI LINE rahe. Quickshell pehli '{' wali line (comment me bhi) par header khatam maan leta hai,
//   isliye is line se upar kabhi koi '{' wali comment mat likho — warna ye singleton ban hi nahi paata (Sys.xxx = undefined).
// ============================================================================
//  Display.qml  —  SOFTWARE BRIGHTNESS (screen ko kala parda dalke dim karna)
// ----------------------------------------------------------------------------
//  KYA HAI   : Real monitor brightness nahi, ek kala transparent parda (Dimmer.qml) hai.
//              Level 20..100 ke beech; 100 = bilkul normal.
//  YAAD       : Level ~/.config/snow/state/quick.json me save hota hai, restart ke baad bhi rehta hai.
//  BADLO     : minLevel (sabse kam kitna dim ho sakta hai).
// ============================================================================

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int minLevel: 20          // BADLO: isse kam dim nahi hoga (screen kala na ho jaye)
    property int brightness: 100
    readonly property string home: Quickshell.env("HOME")

    function setBrightness(n: real): void {
        brightness = Math.max(minLevel, Math.min(100, Math.round(n)))
        saveTimer.restart()
    }

    // slider hilate waqt har pixel par save nahi karte; 0.3 sec ruk ke ek baar
    Timer {
        id: saveTimer
        interval: 300
        onTriggered: Quickshell.execDetached(["bash", root.home + "/.config/snow/bin/quicksettings/quick.sh", "set-brightness", String(root.brightness)])
    }

    FileView {
        path: root.home + "/.config/snow/state/quick.json"
        printErrors: false
        onLoaded: root.brightness = Math.max(root.minLevel, Math.min(100, qa.brightness))
        adapter: JsonAdapter {
            id: qa
            property int brightness: 100
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/core/Sys.qml")
cat <<'SNOW_FILE_END_4b7d'
pragma Singleton
// ⚠ RULE: 'pragma Singleton' hamesha FILE KI PEHLI LINE rahe. Quickshell pehli '{' wali line (comment me bhi) par header khatam maan leta hai,
//   isliye is line se upar kabhi koi '{' wali comment mat likho — warna ye singleton ban hi nahi paata (Sys.xxx = undefined).
// ============================================================================
//  Sys.qml  —  SYSTEM KI HALAT (Wi-Fi, Bluetooth, Internet, Volume, WARP) + unke kaam
// ----------------------------------------------------------------------------
//  KYA HAI   : Ye "singleton" hai. Quick settings ke saare panels yahin se
//              "Sys.wifi.enabled", "Sys.vol" jaise naam se haalat padhte hain.
//  KAAM KAISE: Asli kaam shell scripts karte hain:
//                ~/.config/snow/bin/quicksettings/quick.sh   (Wi-Fi, Bluetooth, volume ...)
//                ~/.config/snow/bin/quicksettings/warp.sh    (Cloudflare WARP)
//              Ye file un scripts ko chalati hai aur unka JSON jawab padhti hai.
//  CHALNA    : Jab Quick settings khula ho tab har 2 second me status refresh hota hai.
//  BADLO     : polling interval (neeche "Timer { interval: 2000 ...") — chhota = zyada fresh, par zyada CPU.
// ============================================================================

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string sh: Quickshell.env("HOME") + "/.config/snow/bin/quicksettings/quick.sh"
    readonly property string warpSh: Quickshell.env("HOME") + "/.config/snow/bin/quicksettings/warp.sh"
    property bool polling: false          // QuickSettings khulte hi true ho jata hai

    // ---------------- haalat (script se aata hai) ----------------
    property var st: ({})
    readonly property var wifi: st.wifi || ({ present: false, enabled: false, ssid: "" })
    readonly property var bt: st.bt || ({ present: false, enabled: false })
    readonly property var net: st.net || ({ state: "disconnected", type: "none", name: "", ip: "", connectivity: "", eth: false })
    readonly property var audio: st.audio || ({ present: false, vol: 0, muted: false, micVol: 0, micMuted: false, micPresent: false, sink: "", source: "", sinks: [], sources: [] })

    // download manager (aria2): the bar shows a download icon while something is downloading / waiting
    readonly property string dmRpc: Quickshell.env("HOME") + "/.config/snow/bin/downloads/dm-rpc.sh"
    property var dl: ({ active: 0, waiting: 0, speed: 0, frac: -1 })
    function fmtSpeed(b: real): string {
        if (!(b > 0)) return "0 KB/s"
        if (b < 1024 * 1024) return Math.round(b / 1024) + " KB/s"
        return (b / 1048576).toFixed(1) + " MB/s"
    }

    property var stW: ({})
    readonly property var warp: stW.state ? stW : ({ installed: false, state: "none", mode: "" })

    // volume ki "screen wali" value: slider hilate waqt turant badalti hai, script ka jawab baad me aata hai
    property int vol: 0
    property bool muted: false
    property int micVol: 0                // mic ki volume / mute (Sound card)
    property bool micMuted: false

    // ---------------- Wi-Fi / Bluetooth ki lists ----------------
    property var wifiList: []
    property var btList: []
    property bool wifiBusy: false         // scan chal raha hai
    property bool btScanning: false
    property string btBusyMac: ""
    property string btMsg: ""             // Bluetooth kaam fail hua to laal text (panel me dikhta hai)
    property bool connecting: false       // connect ka kaam chal raha hai
    property string pendingSsid: ""
    property string needPassFor: ""       // is network ka password maangna hai
    property string connectMsg: ""        // laal error text ("Wrong password" ...)
    signal wifiConnected()

    onStChanged: {
        if (!holdVol.running) {           // slider hilate waqt script ki purani value se mat likho
            vol = audio.vol
            muted = audio.muted
        }
        if (!holdMic.running) {
            micVol = audio.micVol || 0
            micMuted = audio.micMuted === true
        }
    }

    // ---------------- KAAM (functions) ----------------
    function refresh(): void {
        if (!statusProc.running) statusProc.running = true
        if (!warpProc.running) warpProc.running = true
        if (!dlProc.running) dlProc.running = true
    }

    // quick.sh ko ek kaam dena (jawab ki zaroorat nahi), phir thodi der me status refresh
    function act(args: var): void {
        Quickshell.execDetached(["bash", sh].concat(args))
        soon.restart()
    }

    function warpAct(args: var): void {
        Quickshell.execDetached(["bash", warpSh].concat(args))
        warpSoon.restart()
    }

    function setVol(n: real): void {
        vol = Math.max(0, Math.min(100, Math.round(n)))
        holdVol.restart()
        applyVol.restart()
    }

    function toggleMute(): void {
        muted = !muted
        holdVol.restart()
        Quickshell.execDetached(["bash", sh, "vol-mute"])
    }

    function setMicVol(n: real): void {
        micVol = Math.max(0, Math.min(100, Math.round(n)))
        holdMic.restart()
        applyMic.restart()
    }

    function toggleMicMute(): void {
        micMuted = !micMuted
        holdMic.restart()
        Quickshell.execDetached(["bash", sh, "mic-mute"])
    }

    function loadWifi(): void { if (!wifiListProc.running) wifiListProc.running = true }

    function scanWifi(): void {
        wifiBusy = true
        Quickshell.execDetached(["bash", sh, "wifi-scan"])
        wifiTimer.restart()
    }

    // Password command-line me nahi jata (ps me dikhta). Environment variable SNOW_WIFI_PW se jata hai;
    // quick.sh use ek private temp file se nmcli ko deti hai aur turant mita deti hai.
    function connectWifi(ssid: string, pass: string): void {
        if (connecting) return
        connecting = true
        pendingSsid = ssid
        connectMsg = ""
        connectProc.command = ["bash", sh, "wifi-connect", ssid]
        connectProc.environment = pass === "" ? ({}) : ({ "SNOW_WIFI_PW": pass })
        connectProc.running = true
    }

    function connectHidden(ssid: string, pass: string): void {
        if (connecting) return
        connecting = true
        pendingSsid = ssid
        connectMsg = ""
        connectProc.command = ["bash", sh, "wifi-connect-hidden", ssid]
        connectProc.environment = pass === "" ? ({}) : ({ "SNOW_WIFI_PW": pass })
        connectProc.running = true
    }

    function forgetWifi(ssid: string): void {
        act(["wifi-forget", ssid])
        listSoon.restart()
    }

    function disconnectWifi(): void {
        act(["wifi-disconnect"])
        listSoon.restart()
    }

    function loadBt(): void { if (!btListProc.running) btListProc.running = true }

    function scanBt(): void {
        btScanning = true
        Quickshell.execDetached(["bash", sh, "bt-scan"])
        btStop.restart()
        loadBt()
    }

    // kind: bt-pair | bt-connect | bt-disconnect | bt-remove.  quick.sh {"ok":..,"msg":..} deta hai; fail ho to btMsg me aata hai
    function btAction(kind: string, mac: string): void {
        if (btBusyMac !== "") return          // ek waqt me ek hi kaam
        btBusyMac = mac
        btMsg = ""
        btGuard.restart()
        btActProc.command = ["bash", sh, kind, mac]
        btActProc.running = true
    }

    // ---------------- scripts chalane wale "Process" ----------------
    // Har Process: script chalao -> uska JSON jawab padho -> upar ki property me rakho.
    Process {
        id: statusProc
        command: ["bash", root.sh, "status"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.st = JSON.parse(text) } catch (e) { } }
        }
    }
    Process {
        id: warpProc
        command: ["bash", root.warpSh, "status"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.stW = JSON.parse(text) } catch (e) { } }
        }
    }
    Process {
        id: dlProc
        command: ["bash", root.dmRpc, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var r = null
                try { r = JSON.parse(text) } catch (e) { r = null }
                if (r === null || !r.ok) { root.dl = { active: 0, waiting: 0, speed: 0, frac: -1 }; return }
                var d = 0, t = 0
                for (var i = 0; i < r.items.length; i++) {
                    var it = r.items[i]
                    if ((it.status === "active" || it.status === "paused") && it.total > 0) { d += it.done; t += it.total }
                }
                root.dl = { active: r.active, waiting: r.waiting, speed: r.speed, frac: t > 0 ? d / t : -1 }
            }
        }
    }
    Process {
        id: wifiListProc
        command: ["bash", root.sh, "wifi-list"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.wifiList = JSON.parse(text) } catch (e) { } }
        }
    }
    Process {
        id: btActProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var r = JSON.parse(text)
                    if (r.ok === false) { root.btMsg = r.msg || "Bluetooth: something went wrong"; btMsgClear.restart() }
                } catch (e) { }
                btGuard.stop()
                root.btBusyMac = ""
                root.refresh()
                root.loadBt()
            }
        }
    }
    Process {
        id: btListProc
        command: ["bash", root.sh, "bt-list"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.btList = JSON.parse(text) } catch (e) { } }
        }
    }
    Process {
        id: connectProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.connecting = false
                let r = {}
                try { r = JSON.parse(text) } catch (e) { r = { ok: false, msg: "No answer from nmcli" } }
                if (r.ok) {
                    root.needPassFor = ""
                    root.connectMsg = ""
                    root.wifiConnected()
                    root.refresh()
                    root.loadWifi()
                } else if (r.need === "password") {
                    root.needPassFor = root.pendingSsid
                    root.connectMsg = r.wrong ? "Wrong password" : ""
                } else {
                    root.connectMsg = r.msg || "Could not connect"
                }
            }
        }
    }

    // ---------------- timers ----------------
    Timer { interval: 2000; repeat: true; running: root.polling; triggeredOnStart: true; onTriggered: root.refresh() }   // BADLO: status refresh speed
    Timer { id: soon; interval: 800; onTriggered: root.refresh() }
    Timer { id: warpSoon; interval: 1200; onTriggered: root.refresh() }
    Timer { id: holdVol; interval: 1500 }                                                       // slider ke baad itni der script ki value ignore
    Timer { id: applyVol; interval: 90; onTriggered: Quickshell.execDetached(["bash", root.sh, "vol-set", String(root.vol)]) }
    Timer { id: holdMic; interval: 1500 }                                                       // mic slider ke baad bhi wahi
    Timer { id: applyMic; interval: 90; onTriggered: Quickshell.execDetached(["bash", root.sh, "mic-set", String(root.micVol)]) }
    Timer { id: wifiTimer; interval: 2500; onTriggered: { root.wifiBusy = false; root.loadWifi() } }
    Timer { id: listSoon; interval: 1800; onTriggered: root.loadWifi() }
    Timer { id: btPoll; interval: 2500; repeat: true; running: root.btScanning; onTriggered: root.loadBt() }
    Timer { id: btStop; interval: 9500; onTriggered: { root.btScanning = false; root.loadBt() } }
    Timer { id: btGuard; interval: 35000; onTriggered: { root.btBusyMac = ""; root.loadBt() } }      // safety: kaam atak jaye to "Working…" hat jaye
    Timer { id: btMsgClear; interval: 12000; onTriggered: root.btMsg = "" }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/core/Theme.qml")
cat <<'SNOW_FILE_END_4b7d'
pragma Singleton
// ⚠ RULE: 'pragma Singleton' hamesha FILE KI PEHLI LINE rahe. Quickshell pehli '{' wali line (comment me bhi) par header khatam maan leta hai,
//   isliye is line se upar kabhi koi '{' wali comment mat likho — warna ye singleton ban hi nahi paata (Sys.xxx = undefined).
// ============================================================================
//  Theme.qml  —  SAARE RANG, SIZE AUR SPEED YAHAN SE AATE HAIN
// ----------------------------------------------------------------------------
//  KYA HAI   : Ye ek "singleton" hai. Matlab poore Quickshell me ek hi copy,
//              aur har QML file isse "Theme.accent", "Theme.text" jaise naam se padh sakti hai.
//  RANG KAHAN SE : ~/.config/snow/state/theme.json  (is file ko theme.sh banata hai).
//              Rang badalna ho to QML nahi, ye command chalao:
//                  bash ~/.config/snow/bin/theme/theme.sh base   '#000000'   (background)
//                  bash ~/.config/snow/bin/theme/theme.sh accent '#d4af37'   (highlight)
//                  bash ~/.config/snow/bin/theme/theme.sh mode   dark|light|toggle
//  SIZE / SPEED : neeche "DESIGN SETTINGS" me. Sab panels same numbers use karte hain,
//              isliye yahan ek number badlo to poora desktop ek saath badal jata hai.
// ============================================================================

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ---------------------------------------------------------------- RANG
    // ":" ke baad wala rang sirf tab chalta hai jab theme.json abhi nahi bani.
    property color bg:        ja.bg        !== "" ? ja.bg        : "#14161b"   // sabse peeche ka rang
    property color surface:   ja.surface   !== "" ? ja.surface   : "#1b1e25"   // card / dabbe ka rang
    property color surfaceHi: ja.surfaceHi !== "" ? ja.surfaceHi : "#272b35"   // thoda ubhara hua rang
    property color text:      ja.text      !== "" ? ja.text      : "#e6e8ee"   // mukhya likhawat
    property color muted:     ja.muted     !== "" ? ja.muted     : "#8b91a1"   // halki likhawat / band icons
    property color accent:    ja.accent    !== "" ? ja.accent    : "#d4af37"   // highlight rang
    property color warn:      ja.warn      !== "" ? ja.warn      : "#e0a84a"   // chetavni
    property color danger:    ja.danger    !== "" ? ja.danger    : "#e0625f"   // galti / shutdown
    property color success:   ja.success   !== "" ? ja.success   : "#5fba7d"   // sab theek / connected
    property color tint:      ja.tint      !== "" ? ja.tint      : "#ffffff"   // dark me safed, light me kala (halke overlay ke liye)

    // accent ke upar likhi cheez ka rang: halka accent ho to kala text, gehra ho to safed
    readonly property color accentText: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.55 ? "#14161b" : "#ffffff"

    // ---------------------------------------------------------------- TAYAR (derived) RANG
    // Ye upar ke rangon se apne aap bante hain. Inhe direct mat badlo.
    readonly property color cardBg:     Qt.alpha(surface, 0.96)   // floating card ka background
    readonly property color railBg:     Qt.alpha(surface, 0.90)   // right wali vertical bar ka background
    readonly property color hairline:   Qt.alpha(tint, 0.09)      // patli border line
    readonly property color hover:      Qt.alpha(tint, 0.07)      // mouse upar aane par
    readonly property color pressed:    Qt.alpha(tint, 0.12)      // dabate waqt
    readonly property color field:      Qt.alpha(tint, 0.06)      // text box ka background
    readonly property color accentSoft: Qt.alpha(accent, 0.16)    // "ON" wali cheez ka halka background

    // ---------------------------------------------------------------- DESIGN SETTINGS (yahan badlo)
    readonly property string uiFont:   "Inter"                    // likhawat ka font
    readonly property string iconFont: "Material Symbols Rounded" // icon wala font (Icons.qml iske code points use karti hai)

    readonly property int rCard: 20     // bade card ke kone kitne gol
    readonly property int rRail: 24     // right wali bar ke kone
    readonly property int rTile: 14     // button / row ke kone
    readonly property int rChip: 10     // chhote chips ke kone
    readonly property int gap:   12     // cheezon ke beech ki jagah
    readonly property int pad:   16     // card ke andar ki jagah (padding)

    readonly property int fsTitle: 15   // card ka title
    readonly property int fsBody:  13   // normal likhawat
    readonly property int fsSmall: 12   // chhoti likhawat
    readonly property int fsTiny:  11   // sabse chhoti likhawat (subtitle, tooltip)

    readonly property int animMs:  160  // khulne / band hone ki speed (milliseconds). Bada number = dheema.
    readonly property int hoverMs: 110  // hover ke rang badalne ki speed

    // ---------------------------------------------------------------- theme.json PADHNE WALA HISSA
    FileView {
        path: Quickshell.env("HOME") + "/.config/snow/state/theme.json"
        watchChanges: true          // file badle to turant naya rang le lo
        printErrors: false
        onFileChanged: reload()

        adapter: JsonAdapter {
            id: ja
            property string bg: ""
            property string surface: ""
            property string surfaceHi: ""
            property string text: ""
            property string muted: ""
            property string accent: ""
            property string warn: ""
            property string danger: ""
            property string success: ""
            property string tint: ""
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/osd/Dimmer.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  Dimmer.qml  —  kala transparent parda (brightness kam karne ke liye)
// ----------------------------------------------------------------------------
//  Poori screen par hamesha rehta hai, par click-through hai (mask: Region {}),
//  isliye mouse/keyboard par koi asar nahi. Level Display.brightness se aata hai.
//  BADLO : "* 0.9" = sabse zyada kitna kala ho sakta hai (0.9 = 90%).
// ============================================================================
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

Scope {
    PanelWindow {
        visible: Display.brightness < 100
        color: Qt.rgba(0, 0, 0, (100 - Display.brightness) / 100 * 0.9)
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}                                   // click-through
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "snow-dimmer"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/shell.qml")
cat <<'SNOW_FILE_END_4b7d'
//@ pragma UseQApplication
// ============================================================================
//  shell.qml  —  QUICKSHELL KA "MAIN SWITCH"  (sabse pehle yahi file padhi jati hai)
// ----------------------------------------------------------------------------
//  Chalane ka tareeka : qs -p ~/.config/quickshell/snow        (qs.sh ye khud karta hai)
//  KYA KARTI HAI      : Saare panels ko ek jagah jodti hai.
//    Launcher       Super+Space        search; Tab (khali search par) = saari apps grid
//    PowerMenu      Super+Escape       ek gol icon
//    QuickSettings  Super+Tab          right wali vertical bar
//    ClockOsd       Super+BackSpace    ghadi ka card (neeche-daayein)
//    OsdPopup       (apne aap)         volume badalne par pop-up
//    WorkspaceOsd   (apne aap)         workspace badalne par gol number
//    PolkitDialog   (apne aap)         "password daalo" wali window
//    Notifs         (apne aap)         notification pop-up (upar-daayein)
//  Ek waqt par sirf EK panel khula rehta hai (Launcher / Power / Quick): neeche onOpenChanged dekho.
//  NAYA PANEL JODNA HO: (1) panel ki .qml file apne folder me rakho (jaise launcher/, osd/ ; import qs.<folder>)  (2) neeche ek block jodo.
//  NOTE : "Timer" wale panels (Workspace/Polkit/Notifs) code se load hote hain, taaki agar
//         koi Quickshell module na mile to poora shell na toote — sirf wo ek panel band rahe.
// ============================================================================
import Quickshell
import QtQuick
import qs.launcher
import qs.osd
import qs.powermenu
import qs.quicksettings

ShellRoot {
    id: snowRoot

    Dimmer {}                                   // brightness ka kala parda (hamesha chalta hai)

    Launcher {
        id: launcher
        onOpenChanged: if (open) { power.open = false; quick.open = false }
    }

    PowerMenu {
        id: power
        onOpenChanged: if (open) { launcher.open = false; quick.open = false }
    }

    QuickSettings {
        id: quick
        onOpenChanged: if (open) { launcher.open = false; power.open = false }
    }

    ClockOsd {}
    OsdPopup {}

    // 0.3 second baad ye 3 panel code se load hote hain
    Timer {
        interval: 300
        running: true
        repeat: false
        onTriggered: {
            // naam, agar load na ho to kya karna hai
            var list = ["osd/WorkspaceOsd.qml", "polkit/PolkitDialog.qml", "notifications/Notifs.qml"]
            for (var i = 0; i < list.length; i++) {
                var c = Qt.createComponent(list[i], Component.PreferSynchronous)
                if (c.status === Component.Ready) {
                    c.createObject(snowRoot)
                } else {
                    console.warn("snow: " + list[i] + " failed to load: " + c.errorString())
                    // Polkit na chale to purana hyprpolkitagent chalu kar do (password window hamesha rahe)
                    if (list[i] === "polkit/PolkitDialog.qml") Quickshell.execDetached(["/usr/libexec/hyprpolkitagent"])
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/core/gen-icons.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  gen-icons.sh  —  Icons.qml BANANE WALI SCRIPT  (Icons.qml ko haath se mat badlo!)
# ----------------------------------------------------------------------------
#  KYA KARTA HAI : Icon font ki "codepoints" list (naam -> number) padhta hai aur
#                  Icons.qml banata hai, jisme har icon ka ek naam hota hai (Icons.wifi, Icons.power ...).
#  USE           : bash gen-icons.sh  DEST.qml  [DEST2.qml ...]
#  NAYA ICON JODNA HO:
#     1) neeche list me ek line jodo:     icon  mera_naam  FALLBACK_HEX  material_symbol_ka_naam
#        (material_symbol_ka_naam = https://fonts.google.com/icons se naam, jaise "home")
#     2) bash ~/.config/snow/bin/core/gen-icons.sh ~/.config/quickshell/snow/core/Icons.qml
#     3) QML me Icons.mera_naam likho.
#  EXIT CODE     : 0 = sab icon font ki list se mile | 10 = kuch icon "yaad se" (fallback) liye gaye | 1 = file nahi likhi
# ============================================================================
set -u

[ "$#" -ge 1 ] || { echo "usage: gen-icons.sh DEST.qml [...]"; exit 2; }

# ---- font ki codepoints file dhundho ----
CP=""
for d in /usr/local/share/fonts/material-symbols "$HOME/.local/share/fonts/snow"; do
  [ -f "$d/MaterialSymbolsRounded.codepoints" ] && { CP="$d/MaterialSymbolsRounded.codepoints"; break; }
done

FALL=0
LINES=()

# icon KEY FALLBACK_HEX NAAM1 [NAAM2 ...]
#   KEY          = QML me use hone wala naam
#   FALLBACK_HEX = agar codepoints file na mile to ye number
#   NAAM1..      = font me icon ke naam (pehla jo mile)
icon() {
  local key="$1" def="$2" n hex=""; shift 2
  if [ -n "$CP" ]; then
    for n in "$@"; do
      hex=$(awk -v n="$n" '$1==n {print $2; exit}' "$CP")
      [ -n "$hex" ] && break
    done
  fi
  if ! [[ "$hex" =~ ^[0-9a-fA-F]{4,6}$ ]]; then
    hex="$def"; FALL=$((FALL + 1))
    echo "WARN icon '$key' not found in the codepoints file, used the built-in number 0x$def [U]"
  fi
  LINES+=("    readonly property string $key: String.fromCodePoint(0x$hex)")
}

# ---------------------------- ICON LIST (yahan jodo / badlo) ----------------------------
# power menu
icon power         e8ac power_settings_new
icon restart       f053 restart_alt
icon logout        e9ba logout
icon sleep         f159 bedtime
icon lock          e897 lock
icon screenoff     ef5b tv_off desktop_access_disabled monitor
icon clean         f0ff cleaning_services delete_sweep
icon monitor       e30c desktop_windows monitor
# arrows
icon chevLeft      e5cb chevron_left
icon chevRight     e5cc chevron_right
icon down          e313 keyboard_arrow_down
# launcher
icon search        e8b6 search
# network
icon wifi          e63e wifi
icon wifiOff       e648 wifi_off
icon bluetooth     e1a7 bluetooth
icon bluetoothOff  e1a9 bluetooth_disabled
icon internet      e80b public
icon ethernet      eb2f lan
icon cloud         e2bd cloud
icon cloudDone     e2bf cloud_done
icon cloudOff      e2c1 cloud_off
icon download      f090 file_download
icon downloading   f001 downloading
# sound / display
icon volumeUp      e050 volume_up
icon volumeDown    e04d volume_down
icon volumeMute    e04e volume_mute
icon volumeOff     e04f volume_off
icon mic           e029 mic
icon micOff        e02b mic_off
icon brightness    e1ae brightness_medium
icon image         e3f4 image
# general
icon refresh       e5d5 refresh
icon check         e5ca check
icon add           e145 add
# ----------------------------------------------------------------------------------------

[ -z "$CP" ] && { echo "WARN MaterialSymbolsRounded.codepoints not found: all icons use the built-in numbers [U]"; FALL=$((FALL + 1)); }

TMP=$(mktemp) || exit 1
{
  echo "pragma Singleton"
  echo
  echo "import QtQuick"
  echo "import Quickshell"
  echo
  echo "// GENERATED by gen-icons.sh — haath se mat badlo. Naya icon jodna ho to gen-icons.sh me list badlo."
  echo "Singleton {"
  printf '%s\n' "${LINES[@]}"
  echo "}"
} > "$TMP"

RC=0
for dest in "$@"; do
  mkdir -p "$(dirname "$dest")" && cp -f "$TMP" "$dest" && echo "wrote $dest (${#LINES[@]} icons)" || RC=1
done
rm -f "$TMP"
[ "$RC" -ne 0 ] && exit 1
[ "$FALL" -gt 0 ] && exit 10
exit 0
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/core/qs.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  qs.sh  —  QUICKSHELL CHALANE WALI SCRIPT (with a supervisor)
# ----------------------------------------------------------------------------
#  KYA KARTA HAI : Quickshell ko Snow ke config folder ke saath chalata hai, aur agar wo crash ho jaye to use apne aap
#                  dobara chalu karta hai (notifications, polkit, launcher, power menu sab ek hi process me hain).
#                  5 baar 20 second ke andar crash ho to ruk jata hai aur Hyprland me ek message dikhata hai.
#  USE :
#     qs.sh start                      agar chal nahi raha to chalu karo (Hyprland start par ye chalta hai)
#     qs.sh restart                    band karke dobara chalu (QML file badalne ke baad ye chalao)
#     qs.sh stop                       supervisor aur Quickshell band
#     qs.sh status                     kaun chal raha hai
#     qs.sh ipc call launcher toggle   koi bhi doosra command seedha Quickshell ko jata hai
#  LOG   : ~/.cache/snow/qs.log  (kuch na dikhe to:  tail -40 ~/.cache/snow/qs.log)
# ============================================================================
DIR="$HOME/.config/quickshell/snow"
LOGD="$HOME/.cache/snow"; LOG="$LOGD/qs.log"

# Quickshell ko app-icons ke liye ek asli icon theme chahiye (sirf hicolor me kuch apps ke icon nahi hote)
[ -d /usr/share/icons/Adwaita ] && export QS_ICON_THEME="${QS_ICON_THEME:-Adwaita}"

BIN=$(command -v qs || command -v quickshell) || { echo "[PROBLEM] quickshell is not installed" >&2; exit 1; }
SELF=$(readlink -f "${BASH_SOURCE[0]}")
SCALE="${SNOW_QS_SLEEP_SCALE:-1}"     # tests only: 0 = no waiting between restarts

# the MAIN panels process only (the file manager / download windows are other "qs -p" processes)
main_running() { pgrep -f -- " -p $DIR\$" >/dev/null 2>&1; }
sup_running()  { pgrep -f -- "$SELF supervise" >/dev/null 2>&1; }

supervise() {
  mkdir -p "$LOGD"
  [ -f "$LOG" ] && [ "$(stat -c %s "$LOG" 2>/dev/null || echo 0)" -gt 1048576 ] && tail -n 200 "$LOG" > "$LOG.old" && : > "$LOG"
  fails=0
  while :; do
    t0=$(date +%s)
    "$BIN" -p "$DIR" >> "$LOG" 2>&1 </dev/null 9>&-
    rc=$?
    t1=$(date +%s)
    if [ $((t1 - t0)) -lt 20 ]; then fails=$((fails + 1)); else fails=0; fi
    echo "[$(date '+%F %T')] quickshell stopped (code $rc, ran $((t1 - t0)) s), restart #$fails" >> "$LOG"
    if [ "$fails" -ge 5 ]; then
      echo "[$(date '+%F %T')] giving up: it crashed 5 times in a row. Run: bash $SELF start" >> "$LOG"
      command -v hyprctl >/dev/null 2>&1 && hyprctl notify 3 10000 "rgb(e0625f)" "Snow panels keep crashing - see ~/.cache/snow/qs.log" >/dev/null 2>&1
      exit 1
    fi
    sleep $(( (fails > 0 ? fails * 2 : 1) * SCALE ))
  done
}

launch() { mkdir -p "$LOGD"; setsid nohup bash "$SELF" supervise >/dev/null 2>&1 </dev/null & }
stop_all() {
  pkill -f -- "$SELF supervise" 2>/dev/null
  pkill -f -- " -p $DIR\$" 2>/dev/null
  pkill -f -- " -p $HOME/\.config/snow/(fm|dm|dmask)\$" 2>/dev/null
}

case "${1:-}" in
  supervise) mkdir -p "$LOGD"; exec 9> "$LOGD/qs.lock"; flock -n 9 || exit 0; supervise ;;
  start)   sup_running || { main_running && exit 0; launch; } ;;
  restart) stop_all; sleep $((1 * SCALE)); launch ;;
  stop)    stop_all ;;
  status)  sup_running && echo "supervisor: running" || echo "supervisor: not running"; main_running && echo "panels: running" || echo "panels: not running"; tail -3 "$LOG" 2>/dev/null ;;
  *)       exec "$BIN" -p "$DIR" "$@" ;;
esac
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
post() {
mkdir -p "$HOME/.cache"
if [ -f "$BIN/core/gen-icons.sh" ]; then bash "$BIN/core/gen-icons.sh" "$QS/core/Icons.qml" >/dev/null 2>&1; rc=$?; { [ $rc = 0 ] || [ $rc = 10 ]; } && pass "Icons.qml generated" || fail "Icons.qml could not be generated" "bash ~/.config/snow/bin/core/gen-icons.sh ~/.config/quickshell/snow/core/Icons.qml   (is the icon font installed? bash ~/Snow/Script/05-font.sh)"; fi
}
extra_check() {
have qs || have quickshell && pass "Quickshell is installed" || fail "Quickshell is not installed" "bash ~/Snow/Script/03-hyprland.sh"
[ -s "$QS/core/Icons.qml" ] && pass "Icons.qml exists" || fail "Icons.qml is missing" "bash ~/Snow/Script/06-core.sh"
icons_ok
for n in shell core/Theme core/Sys core/Display osd/Dimmer; do qml_ok "$QS/$n.qml"; done
# fm, dm, dmask and dmvid are separate Quickshell configs and keep their own Theme.qml: all 5 copies must stay identical
for d in fm dm dmask dmvid; do
  [ -f "$HOME/.config/snow/$d/Theme.qml" ] || continue
  cmp -s "$QS/core/Theme.qml" "$HOME/.config/snow/$d/Theme.qml" && pass "$d/Theme.qml is identical to core/Theme.qml" || warn "$d/Theme.qml differs from core/Theme.qml (colours or sizes can look different in that app)" "keep all 4 Theme.qml files the same: copy the newest one over the others (core, fm, dm, dmask), then Files/backup.sh"
done
}
component_main "$@"
