#!/usr/bin/env bash
# 12-quick-settings.sh : Panel: quick settings
# Super+Tab panel: Wi-Fi, Bluetooth, sound, display, WARP, tray, colours (with its small shared widgets). Default brightness 60% on a fresh install.
#   bash Script/12-quick-settings.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/12-quick-settings.sh check    read-only check
MOD="12-quick-settings"; TITLE="Panel: quick settings"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/hypr/snow-quick-keys.lua|644|0"
  "u|.config/quickshell/snow/quicksettings/BtPanel.qml|644|0"
  "u|.config/quickshell/snow/quicksettings/ColorPicker.qml|644|0"
  "u|.config/quickshell/snow/quicksettings/DisplayPanel.qml|644|0"
  "u|.config/quickshell/snow/quicksettings/NetPanel.qml|644|0"
  "u|.config/quickshell/snow/quicksettings/PowerPanel.qml|644|0"
  "u|.config/quickshell/snow/quicksettings/QuickSettings.qml|644|0"
  "u|.config/quickshell/snow/quicksettings/SoundPanel.qml|644|0"
  "u|.config/quickshell/snow/quicksettings/TrayButton.qml|644|0"
  "u|.config/quickshell/snow/quicksettings/TrayMenu.qml|644|0"
  "u|.config/quickshell/snow/quicksettings/WarpPanel.qml|644|0"
  "u|.config/quickshell/snow/quicksettings/WifiPanel.qml|644|0"
  "u|.config/quickshell/snow/widgets/Card.qml|644|0"
  "u|.config/quickshell/snow/widgets/IconButton.qml|644|0"
  "u|.config/quickshell/snow/widgets/LevelSlider.qml|644|0"
  "u|.config/quickshell/snow/widgets/ListRow.qml|644|0"
  "u|.config/quickshell/snow/widgets/PanelHeader.qml|644|0"
  "u|.config/quickshell/snow/widgets/PillButton.qml|644|0"
  "u|.config/quickshell/snow/widgets/PillField.qml|644|0"
  "u|.config/quickshell/snow/widgets/RailButton.qml|644|0"
  "u|.config/quickshell/snow/widgets/SectionLabel.qml|644|0"
  "u|.config/quickshell/snow/widgets/Segmented.qml|644|0"
  "u|.config/snow/bin/quicksettings/quick.sh|755|0"
  "u|.config/snow/bin/quicksettings/warp.sh|755|0"
  "u|.config/snow/state/quick.json|644|1"
)
emit() {
case "$1" in
"u/.config/hypr/snow-quick-keys.lua")
cat <<'SNOW_FILE_END_4b7d'
-- ============================================================================
--  snow-quick-keys.lua  —  QUICK SETTINGS KI KEY + WALLPAPER AUTOSTART
-- ----------------------------------------------------------------------------
--  Super + Tab = right wali vertical bar (Wi-Fi, Bluetooth, Volume ... )
--  Key badalni ho: "SUPER + Tab" badlo, phir:  hyprctl reload
-- ============================================================================
local home = os.getenv("HOME")
local qs = home .. "/.config/snow/bin/core/qs.sh"

hl.bind("SUPER + Tab", hl.dsp.exec_cmd(qs .. " ipc call quick toggle"))

-- login par saved wallpaper lagao (kuch chuna nahi to kuch nahi hota)
hl.on("hyprland.start", function()
  hl.exec_cmd("bash " .. home .. "/.config/snow/bin/theme/wallpaper.sh start")
end)
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/quicksettings/BtPanel.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  BtPanel.qml  —  BLUETOOTH CARD  (Bluetooth button par right-click; Bluetooth ON hona chahiye)
//  Devices ki list: Pair (naya), Connect (paired), Disconnect (connected). Refresh = naya scan (~8 sec).
//  Paired device par mouse rakho -> "Remove" (2 click: pehle "Sure?"). Kaam fail ho to neeche laal message aata hai.
//  KAAM KAUN KARTA HAI : Sys.qml -> quick.sh -> bluetoothctl
// ============================================================================
import QtQuick
import QtQuick.Layouts
import qs.core
import qs.widgets

Card {
    id: p

    contentHeight: col.implicitHeight

    onVisibleChanged: if (visible) { Sys.btMsg = ""; Sys.loadBt(); Sys.scanBt() }     // khulte hi scan

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 12

        PanelHeader {
            icon: Icons.bluetooth
            title: "Bluetooth"
            subtitle: Sys.btScanning ? "Scanning…" : "Devices"
            IconButton { size: 32; icon: Icons.refresh; tip: "Scan"; onClicked: Sys.scanBt() }
        }

        Text {
            visible: Sys.btList.length === 0
            text: Sys.btScanning ? "Looking for devices…" : "No devices found"
            font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall; color: Theme.muted
        }

        ListView {
            visible: Sys.btList.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 264)
            clip: true
            spacing: 2
            model: Sys.btList
            boundsBehavior: Flickable.StopAtBounds

            delegate: ListRow {
                id: row
                required property var modelData
                readonly property bool busy: Sys.btBusyMac === modelData.mac
                property bool removeArmed: false
                Timer { id: disarm; interval: 3000; onTriggered: row.removeArmed = false }

                width: ListView.view.width
                icon: Icons.bluetooth
                iconColor: modelData.connected ? Theme.accent : Theme.text
                title: modelData.name
                subtitle: busy ? "Working…" : (modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "Available"))
                subtitleColor: modelData.connected ? Theme.success : Theme.muted
                selected: modelData.connected

                PillButton {                                     // Remove: 2 click (pehle "Sure?")
                    visible: (row.modelData.paired || row.modelData.connected) && !row.busy && (row.hovered || row.removeArmed)
                    text: row.removeArmed ? "Sure?" : "Remove"
                    kind: row.removeArmed ? "danger" : "ghost"
                    onClicked: {
                        if (row.removeArmed) { row.removeArmed = false; disarm.stop(); Sys.btAction("bt-remove", row.modelData.mac) }
                        else { row.removeArmed = true; disarm.restart() }
                    }
                }
                PillButton {
                    text: row.modelData.connected ? "Disconnect" : (row.modelData.paired ? "Connect" : "Pair")
                    kind: row.modelData.connected ? "ghost" : "primary"
                    onClicked: {
                        if (row.busy) return
                        Sys.btAction(row.modelData.connected ? "bt-disconnect" : (row.modelData.paired ? "bt-connect" : "bt-pair"), row.modelData.mac)
                    }
                }
            }
        }

        // ---------- error (pair / connect / remove fail ho to) ----------
        Text {
            visible: Sys.btMsg !== ""
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: Sys.btMsg
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsSmall
            color: Theme.danger
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/quicksettings/ColorPicker.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  ColorPicker.qml  —  CHHOTA COLOUR PICKER  (Display card me Base / Accent chunne ke liye)
// ----------------------------------------------------------------------------
//  3 hisse: (1) bada chauk: left-right = saturation, upar-neeche = brightness
//           (2) neeche patti: hue (rang ki kism)    (3) hex code box (#rrggbb) + chhota preview
//  Signals:  previewed(hex) = mouse hilate waqt (sirf dekhne ke liye)
//            committed(hex) = mouse chhodne par YA hex box me Enter (ab lagu karo)
//  Isko seedha mat badlo — DisplayPanel.qml isko use karta hai.
// ============================================================================
import QtQuick
import qs.core
import qs.widgets

Item {
    id: root

    property string value: "#ffffff"     // picker jo rang dikhaye (#rrggbb)
    property real h: 0                   // hue 0..1
    property real s: 0                   // saturation 0..1
    property real v: 1                   // brightness 0..1
    property bool dragging: false
    readonly property string live: hexOf(h, s, v)

    signal previewed(string hex)
    signal committed(string hex)

    implicitHeight: col.implicitHeight

    function clamp(x: real): real { return Math.max(0, Math.min(1, x)) }

    function hex2(n: real): string {
        const t = Math.max(0, Math.min(255, Math.round(n * 255))).toString(16)
        return t.length < 2 ? "0" + t : t
    }

    function hexOf(hh: real, ss: real, vv: real): string {
        const c = Qt.hsva(hh, ss, vv, 1.0)
        return "#" + hex2(c.r) + hex2(c.g) + hex2(c.b)
    }

    // #rrggbb ko h/s/v me todna. Galat code ho to false.
    function setHex(hx: string): bool {
        if (!/^#[0-9a-fA-F]{6}$/.test(hx)) return false
        const c = Qt.color(hx)
        if (c.hsvSaturation > 0 && c.hsvHue >= 0) h = c.hsvHue      // grey ho to purana hue rakho
        s = c.hsvSaturation
        v = c.hsvValue
        return true
    }

    onValueChanged: if (!dragging) setHex(value)
    Component.onCompleted: setHex(value)

    Column {
        id: col
        width: parent.width
        spacing: 10

        // ---------- (1) bada chauk ----------
        Rectangle {
            antialiasing: true
            id: sv
            width: parent.width
            height: 96
            radius: Theme.rTile - 2
            color: Qt.hsva(root.h, 1.0, 1.0, 1.0)

            Rectangle {                               // left = safed
                antialiasing: true
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#ffffffff" }
                    GradientStop { position: 1.0; color: "#00ffffff" }
                }
            }
            Rectangle {                               // neeche = kala
                antialiasing: true
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#00000000" }
                    GradientStop { position: 1.0; color: "#ff000000" }
                }
            }

            Rectangle {                               // gola nishaan
                width: 16; height: 16; radius: 8
                color: "#ffffff"
                x: root.s * sv.width - 8
                y: (1 - root.v) * sv.height - 8
                Rectangle { antialiasing: true; anchors.centerIn: parent; width: 12; height: 12; radius: 6; color: root.live }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor
                function pick(mx: real, my: real): void {
                    root.s = root.clamp(mx / width)
                    root.v = 1 - root.clamp(my / height)
                    root.previewed(root.live)
                }
                onPressed: (mouse) => { root.dragging = true; pick(mouse.x, mouse.y) }
                onPositionChanged: (mouse) => { if (pressed) pick(mouse.x, mouse.y) }
                onReleased: { root.dragging = false; root.committed(root.live) }
            }
        }

        // ---------- (2) hue patti ----------
        Rectangle {
            antialiasing: true
            id: hb
            width: parent.width
            height: 12
            radius: 6
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.000; color: "#ff0000" }
                GradientStop { position: 0.167; color: "#ffff00" }
                GradientStop { position: 0.333; color: "#00ff00" }
                GradientStop { position: 0.500; color: "#00ffff" }
                GradientStop { position: 0.667; color: "#0000ff" }
                GradientStop { position: 0.833; color: "#ff00ff" }
                GradientStop { position: 1.000; color: "#ff0000" }
            }

            Rectangle {
                width: 16; height: 16; radius: 8
                color: "#ffffff"
                y: -2
                x: root.h * hb.width - 8
                Rectangle { antialiasing: true; anchors.centerIn: parent; width: 12; height: 12; radius: 6; color: Qt.hsva(root.h, 1.0, 1.0, 1.0) }
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -4
                anchors.bottomMargin: -4
                cursorShape: Qt.PointingHandCursor
                function pick(mx: real): void {
                    root.h = root.clamp(mx / width)
                    root.previewed(root.live)
                }
                onPressed: (mouse) => { root.dragging = true; pick(mouse.x) }
                onPositionChanged: (mouse) => { if (pressed) pick(mouse.x) }
                onReleased: { root.dragging = false; root.committed(root.live) }
            }
        }

        // ---------- (3) preview + hex box ----------
        Row {
            spacing: 8
            Rectangle {                               // preview gola
                width: 34; height: 34; radius: 17
                color: root.live
                border.width: 2
                border.color: Theme.hairline
            }
            PillField {
                width: col.width - 42
                height: 34
                maximumLength: 7
                text: root.live
                onAccepted: {
                    let t = text.trim()
                    if (t.charAt(0) !== "#") t = "#" + t
                    if (root.setHex(t)) root.committed(root.live)
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/quicksettings/DisplayPanel.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  DisplayPanel.qml  —  DISPLAY CARD  (Brightness button par right-click)
// ----------------------------------------------------------------------------
//  Isme: Brightness slider | Dark/Light | Wallpaper | Base aur Accent rang chunna.
//  Rang yahan set nahi hote: picker chhodte hi theme.sh chalta hai, wo theme.json likhta hai
//  aur saare panels / kitty / GTK apps apne aap badal jaate hain.
//  Mouse wheel sirf brightness slider par mouse rakhne se chalta hai (card ke baaki hisse par nahi).
//  KAAM KAUN KARTA HAI : theme.sh (rang), wallpaper.sh (wallpaper), Display.qml (brightness)
// ============================================================================
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core
import qs.widgets

Card {
    id: p

    signal wallpaperRequested()
    contentHeight: col.implicitHeight

    readonly property string home: Quickshell.env("HOME")
    readonly property string themeSh: home + "/.config/snow/bin/theme/theme.sh"

    // ---- abhi ka theme (theme-state.json se aata hai) ----
    property string curMode: "dark"
    property string curBase: "#000000"
    property string curAccent: "#d4af37"
    property string editing: ""               // "", "base" ya "accent": picker kis rang ko badal raha hai
    readonly property bool isDark: curMode !== "light"
    readonly property var colorButtons: [
        { id: "base",   label: "Base" },
        { id: "accent", label: "Accent" }
    ]

    function runTheme(args: var): void {
        Quickshell.execDetached(["bash", themeSh].concat(args))
    }

    // chip ke andar ka rang: picker khula ho to live rang, warna saved rang
    function dotColor(id: string): string {
        if (editing === id) return picker.live
        return id === "base" ? curBase : curAccent
    }

    onVisibleChanged: if (!visible) editing = ""

    FileView {
        path: p.home + "/.config/snow/state/theme-state.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()

        adapter: JsonAdapter {
            property string mode: "dark"
            property string base: "#000000"
            property string accent: "#d4af37"
            onModeChanged: p.curMode = mode
            onBaseChanged: p.curBase = base
            onAccentChanged: p.curAccent = accent
        }
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 12

        PanelHeader { icon: Icons.brightness; title: "Display"; subtitle: "Brightness " + Display.brightness + "%" }

        // ---------- brightness ----------
        SectionLabel { text: "Brightness" }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text { text: Icons.brightness; font.family: Theme.iconFont; font.pixelSize: 20; color: Theme.text }
            LevelSlider {
                Layout.fillWidth: true
                from: Display.minLevel
                to: 100
                value: Display.brightness
                onMoved: (v) => Display.setBrightness(v)
            }
            Text {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: Display.brightness + "%"
                font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall; color: Theme.muted
            }
        }

        // ---------- dark/light + wallpaper ----------
        SectionLabel { text: "Appearance" }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Segmented {
                Layout.fillWidth: true
                model: [ { id: "dark", label: "Dark" }, { id: "light", label: "Light" } ]
                current: p.curMode
                onPicked: (id) => { p.curMode = id; p.runTheme(["mode", id]) }
            }
            IconButton { size: 34; icon: Icons.image; tip: "Wallpaper"; onClicked: p.wallpaperRequested() }
        }

        // ---------- Base / Accent ----------
        SectionLabel { text: "Colours" }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: p.colorButtons
                delegate: Rectangle {
                    antialiasing: true
                    id: cb
                    required property var modelData
                    readonly property bool open: p.editing === cb.modelData.id
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: Theme.rTile
                    color: open ? Theme.accentSoft : (cbArea.containsMouse ? Theme.hover : Theme.field)
                    Behavior on color { ColorAnimation { duration: Theme.hoverMs } }

                    Rectangle {                           // rang ka gola
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22; height: 22; radius: 11
                        color: p.dotColor(cb.modelData.id)
                        border.width: 2
                        border.color: Theme.hairline
                    }
                    Column {
                        x: 40
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: cb.modelData.label; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall; color: Theme.text }
                        Text { text: p.dotColor(cb.modelData.id); font.family: Theme.uiFont; font.pixelSize: 10; color: Theme.muted }
                    }
                    MouseArea {
                        id: cbArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: p.editing = cb.open ? "" : cb.modelData.id
                    }
                }
            }
        }

        // ---------- picker (Base ya Accent dabane par neeche khulta hai) ----------
        ColorPicker {
            id: picker
            visible: p.editing !== ""
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            value: p.editing === "base" ? p.curBase : p.curAccent
            onCommitted: (hex) => {
                if (p.editing === "base") p.curBase = hex
                else if (p.editing === "accent") p.curAccent = hex
                p.runTheme([p.editing, hex])
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/quicksettings/NetPanel.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  NetPanel.qml  —  NETWORK INFO CARD  (Network button par sirf mouse rakho)
//  Dikhata hai: Connected/Disconnected, Ethernet ya Wi-Fi, naam, IP, WARP on/off.
//  Sirf padhne ke liye — koi button nahi. Data Sys.qml se aata hai.
// ============================================================================
import QtQuick
import QtQuick.Layouts
import qs.core
import qs.widgets

Card {
    id: p

    width: 288
    contentHeight: col.implicitHeight

    // (naam, value) ki list — sirf wahi lines jo maujood hain
    readonly property var rows: {
        const n = Sys.net
        const r = []
        r.push({ k: "Type", v: n.type === "ethernet" ? "Ethernet" : (n.type === "wifi" ? "Wi-Fi" : "None") })
        if (n.name) r.push({ k: "Connection", v: n.name })
        if (n.ip) r.push({ k: "IP address", v: n.ip })
        if (Sys.wifi.ssid) r.push({ k: "Wi-Fi", v: Sys.wifi.ssid })
        if (n.connectivity) r.push({ k: "Internet", v: n.connectivity === "full" ? "OK" : n.connectivity })
        if (Sys.warp.installed) r.push({ k: "Cloudflare WARP", v: Sys.warp.state === "connected" ? "On" : (Sys.warp.state === "connecting" ? "Connecting" : "Off") })
        return r
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 10

        RowLayout {
            spacing: 8
            Rectangle {
                antialiasing: true
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: 4
                color: Sys.net.state === "connected" ? Theme.success : Theme.danger
            }
            Text {
                text: Sys.net.state === "connected" ? "Connected" : "Disconnected"
                font.family: Theme.uiFont
                font.pixelSize: Theme.fsTitle
                font.weight: Font.DemiBold
                color: Theme.text
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.hairline }

        Repeater {
            model: p.rows
            delegate: RowLayout {
                id: r
                required property var modelData
                Layout.fillWidth: true
                Text {
                    text: r.modelData.k
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fsSmall
                    color: Theme.muted
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: r.modelData.v
                    elide: Text.ElideRight
                    Layout.maximumWidth: 160
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fsBody
                    color: Theme.text
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/quicksettings/PowerPanel.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  PowerPanel.qml  —  POWER CARD  (Power button par right-click)
// ----------------------------------------------------------------------------
//  Upar   : header (Power) + EK line me 4 gol icon buttons: Log out, Sleep, Restart, Lock (naam = mouse rakhne par).
//  Beech  : "Auto power-saving" — 3 idle timers (Screen off / Lock / Sleep kitne minute baad). Row dabao = dropdown list khulti hai.
//  Neeche : Clean-up (abhi karo) + chhota hint. Shut down yahan nahi hai: Power button ko 2 baar click karo.
//  Timer values ~/.config/snow/state/power.json me save hoti hain (power.sh likhta hai, hypridle.conf bhi banata hai).
//  BADLO : choices (neeche) = dropdown me kaun kaun se minute dikhein. 0 = Never.
//  Rang / kone / font sab Theme.qml se — yahan koi fixed rang nahi.
// ============================================================================
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core
import qs.widgets

Card {
    id: root

    width: 320
    signal actionRequested(string id)         // QuickSettings ko batata hai: kaun sa kaam chalana hai

    // ---- timers (minutes, 0 = Never) ----
    property int tScreenOff: 0
    property int tLock: 0
    property int tSleep: 0
    property string ddKey: ""                 // kaun sa timer-row khula hai ("" = koi nahi)

    readonly property string home: Quickshell.env("HOME")
    readonly property string powerSh: home + "/.config/snow/bin/power/power.sh"

    readonly property var timerRows: [
        { key: "screenOff", label: "Turn off screen", icon: Icons.monitor },
        { key: "lock",      label: "Lock screen",     icon: Icons.lock },
        { key: "sleep",     label: "Sleep",           icon: Icons.sleep }
    ]
    readonly property var choices: [0, 1, 5, 10, 15, 30, 60]           // BADLO: dropdown ke minute

    contentHeight: col.implicitHeight

    function minutesText(m: int): string {
        if (m === 0) return "Never"
        if (m === 60) return "1 hour"
        return m + " min"
    }

    function valueFor(key: string): int {
        if (key === "screenOff") return tScreenOff
        if (key === "lock") return tLock
        return tSleep
    }

    // value badlo + power.sh ko batao (wo json likhta hai aur hypridle dobara chalata hai)
    function setTimer(key: string, m: int): void {
        if (key === "screenOff") tScreenOff = m
        else if (key === "lock") tLock = m
        else tSleep = m
        Quickshell.execDetached(["bash", powerSh, "set", key, String(m)])
    }

    onVisibleChanged: if (!visible) ddKey = ""

    FileView {
        path: root.home + "/.config/snow/state/power.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()

        adapter: JsonAdapter {
            property int screenOff: 0
            property int lock: 0
            property int sleep: 0
            onScreenOffChanged: root.tScreenOff = screenOff
            onLockChanged: root.tLock = lock
            onSleepChanged: root.tSleep = sleep
        }
    }

    // ---- gol icon button (sirf icon; naam mouse rakhne par upar dikhta hai) ----
    component RoundAction: Item {
        id: ra
        property string icon: ""
        property string label: ""
        property bool danger: false
        signal clicked()

        readonly property color tone: danger ? Theme.danger : Theme.text

        implicitWidth: 52
        implicitHeight: 52

        Rectangle {
            anchors.centerIn: parent
            width: 52; height: 52; radius: 26
            antialiasing: true
            color: rma.pressed ? Theme.pressed
                 : (rma.containsMouse ? (ra.danger ? Qt.alpha(Theme.danger, 0.16) : Theme.hover) : Theme.field)
            border.width: 1
            border.color: (rma.containsMouse && ra.danger) ? Qt.alpha(Theme.danger, 0.45) : Theme.hairline
            scale: rma.pressed ? 0.94 : 1.0
            Behavior on scale { NumberAnimation { duration: 80 } }
            Behavior on color { ColorAnimation { duration: Theme.hoverMs } }
            Behavior on border.color { ColorAnimation { duration: Theme.hoverMs } }
            Text {
                anchors.centerIn: parent
                text: ra.icon
                font.family: Theme.iconFont
                renderType: Text.NativeRendering
                font.pixelSize: 24
                color: (rma.containsMouse || ra.danger) ? (ra.danger ? Theme.danger : Theme.accent) : Theme.text
                Behavior on color { ColorAnimation { duration: Theme.hoverMs } }
            }
        }
        Rectangle {
            visible: ra.tipOn
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height + 4
            z: 30
            width: tl.width + 18; height: 24; radius: 8
            antialiasing: true
            color: Qt.alpha(Theme.bg, 0.98)
            border.width: 1
            border.color: Theme.hairline
            Text { id: tl; anchors.centerIn: parent; text: ra.label; font.family: Theme.uiFont; font.pixelSize: Theme.fsTiny; color: Theme.text }
        }
        property bool tipOn: false
        Timer { id: rtt; interval: 300; onTriggered: ra.tipOn = rma.containsMouse }
        MouseArea {
            id: rma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: { if (containsMouse) rtt.restart(); else ra.tipOn = false }
            onClicked: { root.ddKey = ""; ra.clicked() }
        }
    }

    // ---- bada action button: gol icon + naam (Clean-up) ----
    component ActionTile: Rectangle {
        id: tile
        property string icon: ""
        property string label: ""
        property bool danger: false
        signal clicked()

        readonly property color tone: danger ? Theme.danger : Theme.accent

        implicitHeight: 56
        radius: Theme.rTile
        antialiasing: true
        color: ta.pressed ? Theme.pressed
             : (ta.containsMouse ? (danger ? Qt.alpha(Theme.danger, 0.14) : Theme.hover) : Theme.field)
        border.width: 1
        border.color: (ta.containsMouse && danger) ? Qt.alpha(Theme.danger, 0.40) : Theme.hairline
        scale: ta.pressed ? 0.97 : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }
        Behavior on color { ColorAnimation { duration: Theme.hoverMs } }
        Behavior on border.color { ColorAnimation { duration: Theme.hoverMs } }

        Rectangle {
            id: badge
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 34; height: 34; radius: 17
            antialiasing: true
            color: Qt.alpha(tile.tone, ta.containsMouse ? 0.22 : 0.14)
            Behavior on color { ColorAnimation { duration: Theme.hoverMs } }
            Text {
                anchors.centerIn: parent
                text: tile.icon
                font.family: Theme.iconFont
                renderType: Text.NativeRendering
                font.pixelSize: 20
                color: tile.tone
            }
        }
        Text {
            anchors.left: badge.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: tile.label
            elide: Text.ElideRight
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsBody
            font.weight: Font.Medium
            color: Theme.text
        }
        MouseArea {
            id: ta
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: { root.ddKey = ""; tile.clicked() }
        }
    }

    // klick card ke khali hisse par = khuli dropdown band (sabse neeche rehta hai)
    MouseArea { anchors.fill: parent; z: -1; enabled: root.ddKey !== ""; onClicked: root.ddKey = "" }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 10

        // ---------- header ----------
        PanelHeader { icon: Icons.power; title: "Power" }

        // ---------- session: ek line, sirf gol icons ----------
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 0
            Item { Layout.fillWidth: true }
            RoundAction { icon: Icons.logout;  label: "Log out"; onClicked: root.actionRequested("logout") }
            Item { Layout.fillWidth: true }
            RoundAction { icon: Icons.sleep;   label: "Sleep";   onClicked: root.actionRequested("sleep") }
            Item { Layout.fillWidth: true }
            RoundAction { icon: Icons.restart; label: "Restart"; danger: true; onClicked: root.actionRequested("restart") }
            Item { Layout.fillWidth: true }
            RoundAction { icon: Icons.lock;    label: "Lock";    onClicked: root.actionRequested("lock") }
            Item { Layout.fillWidth: true }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.hairline }

        // ---------- idle timers ----------
        SectionLabel { text: "Auto power-saving" }

        Repeater {
            model: root.timerRows
            delegate: ColumnLayout {
                id: tr
                required property var modelData
                readonly property bool isOpen: root.ddKey === tr.modelData.key
                readonly property int val: root.valueFor(tr.modelData.key)
                Layout.fillWidth: true
                spacing: 6
                z: tr.isOpen ? 50 : 0               // khuli dropdown baaki rows ke upar dikhe

                // row: icon + naam + abhi ki value + chevron
                Rectangle {
                    antialiasing: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: Theme.rTile
                    color: tr.isOpen ? Theme.accentSoft : (rowArea.containsMouse ? Theme.hover : Theme.field)
                    border.width: 1
                    border.color: tr.isOpen ? Qt.alpha(Theme.accent, 0.35) : Theme.hairline
                    Behavior on color { ColorAnimation { duration: Theme.hoverMs } }
                    Behavior on border.color { ColorAnimation { duration: Theme.hoverMs } }

                    Text {
                        id: rowIcon
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: tr.modelData.icon
                        font.family: Theme.iconFont; font.pixelSize: 20
                        color: tr.isOpen ? Theme.accent : Theme.muted
                    }
                    Text {
                        anchors.left: rowIcon.right
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: tr.modelData.label
                        font.family: Theme.uiFont; font.pixelSize: Theme.fsBody
                        color: Theme.text
                    }
                    Text {
                        anchors.right: chev.left
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.minutesText(tr.val)
                        font.family: Theme.uiFont; font.pixelSize: Theme.fsBody
                        font.weight: tr.val === 0 ? Font.Normal : Font.DemiBold
                        color: tr.val === 0 ? Theme.muted : Theme.accent
                    }
                    Text {
                        id: chev
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icons.down
                        font.family: Theme.iconFont; font.pixelSize: 20
                        color: Theme.muted
                        rotation: tr.isOpen ? 180 : 0
                        Behavior on rotation { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.ddKey = tr.isOpen ? "" : tr.modelData.key
                    }

                    // ---- dropdown list (row ke neeche floating) ----
                    Rectangle {
                        visible: tr.isOpen
                        x: parent.width - width
                        y: -height - 6                  // list opens UPWARDS (the power card sits low on the screen)
                        z: 60
                        width: 150
                        height: ddCol.implicitHeight + 10
                        radius: Theme.rTile
                        antialiasing: true
                        color: Theme.surface
                        border.width: 1
                        border.color: Theme.hairline
                        Rectangle { antialiasing: true; z: -1; x: -2; y: 4; width: parent.width + 4; height: parent.height + 4; radius: parent.radius + 2; color: Qt.rgba(0, 0, 0, 0.12) }
                        Column {
                            id: ddCol
                            x: 5; y: 5
                            width: parent.width - 10
                            spacing: 2
                            Repeater {
                                model: root.choices
                                delegate: Rectangle {
                                    id: opt
                                    required property var modelData
                                    readonly property bool on: opt.modelData === tr.val
                                    width: ddCol.width
                                    height: 32
                                    radius: Theme.rChip
                                    antialiasing: true
                                    color: on ? Theme.accentSoft : (optArea.containsMouse ? Theme.hover : "transparent")
                                    Text {
                                        x: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.minutesText(opt.modelData)
                                        font.family: Theme.uiFont; font.pixelSize: Theme.fsBody
                                        font.weight: opt.on ? Font.DemiBold : Font.Normal
                                        color: opt.on ? Theme.accent : Theme.text
                                    }
                                    Text {
                                        visible: opt.on
                                        anchors.right: parent.right
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Icons.check
                                        font.family: Theme.iconFont; renderType: Text.NativeRendering; font.pixelSize: 18
                                        color: Theme.accent
                                    }
                                    MouseArea {
                                        id: optArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.setTimer(tr.modelData.key, opt.modelData); root.ddKey = "" }
                                    }
                                }
                            }
                        }
                    }
                }

            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.hairline }

        // ---------- clean-up ----------
        ActionTile {
            Layout.fillWidth: true
            icon: Icons.clean
            label: "Clean-up"
            onClicked: root.actionRequested("cleanup")
        }

    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/quicksettings/QuickSettings.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  QuickSettings.qml  —  RIGHT WALI VERTICAL BAR + uske panels  (Super+Tab)
// ----------------------------------------------------------------------------
//  DIKHTA KYA HAI : Screen ke right-beech me patli floating bar. Upar se neeche 4 group:
//      [ Wi-Fi  Bluetooth  Network(WARP) ]  —  [ Volume  Brightness ]  —  [ tray icons ]  —  [ Power ]
//  HAR BUTTON KA KAAM (left click / right click / scroll):
//      Wi-Fi        on-off          | list kholo (connect, forget, hidden network)
//      Bluetooth    on-off          | devices list (pair, connect)
//      Network      WARP on-off     | WARP card (mode)       | mouse rakho = network info card
//      Volume       mute            | sound card (devices)   | scroll = volume +-5
//      Brightness   —               | display card (theme, wallpaper)  | scroll = brightness +-5
//      Power        1st click: laal "dobara click" haalat, 2nd click: shutdown | right-click = power card
//      Tray icons   left = app jagao | right = unka menu (hamara themed TrayMenu card; sub-menu bhi)
//  BAND KAISE KARO : Esc (pehle card band, phir bar) ya bahar kahin bhi click.
//  KHOLNE KI KEY   : ~/.config/hypr/snow-quick-keys.lua  ("SUPER + Tab")
//
//  SETTINGS (yahan badlo)
//    barWidth, btn, rightMargin  : bar ki chaudai / button size / screen ke right se doori
//    cardGap                     : bar aur card ke beech ki jagah
//  Naya button jodna ho: barCol ke andar ek RailButton block copy karo, aur
//  niche "panels" me uska card jodo (toggleFrom("naam", button) se khulta hai).
// ============================================================================
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import qs.core
import qs.widgets

Scope {
    id: root

    // ---------------- SETTINGS (yahan badlo) ----------------
    readonly property int barWidth: 64
    readonly property int rightMargin: 20
    readonly property int cardGap: 12

    // ---------------- haalat ----------------
    property bool open: false
    property string panel: ""            // khula hua card: "", "wifi", "bt", "sound", "display", "power", "warp", "tray"
    property var trayItem: null          // jis tray app ka menu khula hai
    property real panelY: 0              // card kis unchai par khule (button ke barabar)
    property bool netHover: false        // network button par mouse (info card)
    property real netY: 0
    property bool powerArm: false        // power button ek baar dabaya, doosre click ka intezaar
    readonly property string home: Quickshell.env("HOME")
    readonly property string bin: home + "/.config/snow/bin"

    function dismiss(): void { open = false }

    // card screen se bahar na nikle
    function clampY(y: real, h: real): real {
        return Math.max(16, Math.min(keys.height - h - 16, y - 12))
    }

    // button par right-click: uska card kholo (dobara click = band)
    function toggleFrom(name: string, item: Item): void {
        if (panel === name) { panel = ""; return }
        panelY = item.mapToItem(keys, 0, 0).y
        panel = name
    }

    // tray icon par right-click: us app ka menu card kholo
    function openTray(item: var, btn: Item): void {
        panelY = btn.mapToItem(keys, 0, 0).y
        trayItem = item
        panel = "tray"
    }

    onOpenChanged: {
        Sys.polling = open                         // bar khuli = status refresh chalu
        if (open) barEnter.restart()
        if (!open) { panel = ""; trayItem = null; netHover = false; powerArm = false }
    }

    IpcHandler {
        target: "quick"
        function toggle(): void { if (root.open) root.dismiss(); else root.open = true }
        function show(): void { root.open = true }
        function hide(): void { root.dismiss() }
    }

    Timer { id: netTimer; interval: 300; onTriggered: root.netHover = false }      // network card hover ke baad 0.3s me band
    Timer { id: armTimer; interval: 3000; onTriggered: root.powerArm = false }     // 3 second me dobara click na ho to arm khatam

    PanelWindow {
        id: win
        visible: root.open
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "snow-quick"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: if (visible) keys.forceActiveFocus()

        Item {
            id: keys
            anchors.fill: parent
            focus: true

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    if (root.panel !== "") root.panel = ""       // pehle card band
                    else root.dismiss()                          // phir bar
                    event.accepted = true
                }
            }

            // bahar kahin bhi click (left/right/middle) = sab band
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: root.dismiss()
            }

            // =================== VERTICAL BAR ===================
            Rectangle {
                antialiasing: true
                id: bar
                width: root.barWidth
                height: barCol.implicitHeight + 20
                radius: Theme.rRail
                x: keys.width - width - root.rightMargin
                y: (keys.height - height) / 2
                color: Theme.railBg
                border.width: 1
                border.color: Theme.hairline

                // parchhai
                Repeater {
                    model: 3
                    delegate: Rectangle {
                        antialiasing: true
                        required property int index
                        z: -1
                        x: -(index + 1) * 4
                        y: -(index + 1) * 4 + 6
                        width: bar.width + (index + 1) * 8
                        height: bar.height + (index + 1) * 8
                        radius: bar.radius + (index + 1) * 4
                        color: Qt.rgba(0, 0, 0, 0.05)
                    }
                }

                // khulte waqt halka slide + fade
                transform: Translate { id: barSlide; x: 0 }
                ParallelAnimation {
                    id: barEnter
                    NumberAnimation { target: bar; property: "opacity"; from: 0; to: 1; duration: Theme.animMs }
                    NumberAnimation { target: barSlide; property: "x"; from: 10; to: 0; duration: Theme.animMs; easing.type: Easing.OutCubic }
                }

                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: { root.panel = ""; root.netHover = false } }   // bar par click = card band, bar khuli rehti hai

                ColumnLayout {
                    id: barCol
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 10
                    spacing: 4

                    // ---------- GROUP 1: connectivity ----------
                    RailButton {
                        id: bWifi
                        Layout.alignment: Qt.AlignHCenter
                        icon: Sys.wifi.enabled ? Icons.wifi : Icons.wifiOff
                        active: Sys.wifi.present && Sys.wifi.enabled
                        dim: !Sys.wifi.present
                        tipOn: root.panel !== "wifi"
                        tip: !Sys.wifi.present ? "No Wi-Fi adapter" : "Wi-Fi · " + (Sys.wifi.enabled ? (Sys.wifi.ssid !== "" ? Sys.wifi.ssid : "On") : "Off")
                        onClicked: { root.panel = ""; if (Sys.wifi.present) Sys.act(["wifi", Sys.wifi.enabled ? "off" : "on"]) }
                        onRightClicked: if (Sys.wifi.present && Sys.wifi.enabled) root.toggleFrom("wifi", bWifi)
                    }

                    RailButton {
                        id: bBt
                        Layout.alignment: Qt.AlignHCenter
                        icon: Sys.bt.enabled ? Icons.bluetooth : Icons.bluetoothOff
                        active: Sys.bt.present && Sys.bt.enabled
                        dim: !Sys.bt.present
                        tipOn: root.panel !== "bt"
                        tip: !Sys.bt.present ? "No Bluetooth adapter" : "Bluetooth · " + (Sys.bt.enabled ? "On" : "Off")
                        onClicked: { root.panel = ""; if (Sys.bt.present) Sys.act(["bt", Sys.bt.enabled ? "off" : "on"]) }
                        onRightClicked: if (Sys.bt.present && Sys.bt.enabled) root.toggleFrom("bt", bBt)
                    }

                    RailButton {
                        id: bNet
                        Layout.alignment: Qt.AlignHCenter
                        // WARP installed ho to badal ka icon (tick = WARP on, cut = off); nahi to ethernet / globe.
                        // Neeche-daayein chhota bindu = internet: hara = online, laal = offline.
                        icon: !Sys.warp.installed ? (Sys.net.eth ? Icons.ethernet : Icons.internet)
                            : (Sys.warp.state === "connected" ? Icons.cloudDone : (Sys.warp.state === "connecting" ? Icons.cloud : Icons.cloudOff))
                        active: Sys.warp.installed && Sys.warp.state === "connected"
                        badge: Sys.net.state === "connected" ? Theme.success : Theme.danger
                        tipOn: false                                   // iska apna hover card hai
                        onClicked: { root.panel = ""; if (Sys.warp.installed) Sys.warpAct(["toggle"]) }
                        onRightClicked: if (Sys.warp.installed) root.toggleFrom("warp", bNet)
                        onHoverEntered: {
                            netTimer.stop()
                            root.netY = bNet.mapToItem(keys, 0, 0).y
                            root.netHover = true
                        }
                        onHoverExited: netTimer.restart()
                    }

                    Rectangle { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4; Layout.bottomMargin: 4; Layout.preferredWidth: 24; Layout.preferredHeight: 1; color: Theme.hairline }

                    // ---------- GROUP 2: levels ----------
                    RailButton {
                        id: bVol
                        Layout.alignment: Qt.AlignHCenter
                        icon: Sys.muted ? Icons.volumeOff : (Sys.vol < 34 ? Icons.volumeMute : (Sys.vol < 67 ? Icons.volumeDown : Icons.volumeUp))
                        level: Sys.muted ? 0 : Sys.vol / 100
                        tipOn: root.panel !== "sound"
                        tip: Sys.muted ? "Volume · Muted" : "Volume · " + Sys.vol + "%"
                        onClicked: { root.panel = ""; Sys.toggleMute() }
                        onRightClicked: root.toggleFrom("sound", bVol)
                        onWheeled: (dy) => Sys.setVol(Sys.vol + (dy > 0 ? 5 : -5))
                    }

                    RailButton {
                        id: bBri
                        Layout.alignment: Qt.AlignHCenter
                        icon: Icons.brightness
                        level: Display.brightness / 100
                        tipOn: root.panel !== "display"
                        tip: "Brightness · " + Display.brightness + "%"
                        onClicked: root.panel = ""
                        onRightClicked: root.toggleFrom("display", bBri)
                        onWheeled: (dy) => Display.setBrightness(Display.brightness + (dy > 0 ? 5 : -5))
                    }

                    // ---------- downloads: sirf jab kuch download ho raha ho / line me ho. Click = download manager (Super+D) ----------
                    RailButton {
                        id: bDl
                        visible: Sys.dl.active + Sys.dl.waiting > 0
                        Layout.alignment: Qt.AlignHCenter
                        icon: Sys.dl.active > 0 ? Icons.downloading : Icons.download
                        active: Sys.dl.speed > 0
                        level: Sys.dl.frac
                        tipOn: true
                        tip: "Downloads · " + Sys.fmtSpeed(Sys.dl.speed) + " · " + Sys.dl.active + " active" + (Sys.dl.waiting > 0 ? ", " + Sys.dl.waiting + " waiting" : "")
                        onClicked: { root.panel = ""; Quickshell.execDetached(["bash", root.bin + "/downloads/dm.sh"]) }
                    }

                    // ---------- GROUP 3: system tray (sirf jab koi app tray me ho) ----------
                    Rectangle {
                        visible: SystemTray.items.values.length > 0
                        Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4; Layout.bottomMargin: 4
                        Layout.preferredWidth: 24; Layout.preferredHeight: 1; color: Theme.hairline
                    }

                    Repeater {
                        model: SystemTray.items
                        delegate: TrayButton {
                            id: tb
                            Layout.alignment: Qt.AlignHCenter
                            onMenuRequested: root.openTray(tb.modelData, tb)
                            onActivated: root.panel = ""
                        }
                    }

                    // ---------- GROUP 4: power ----------
                    Rectangle { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4; Layout.bottomMargin: 4; Layout.preferredWidth: 24; Layout.preferredHeight: 1; color: Theme.hairline }

                    RailButton {
                        id: bPower
                        Layout.alignment: Qt.AlignHCenter
                        icon: Icons.power
                        armed: root.powerArm
                        tipOn: root.panel !== "power"
                        tip: root.powerArm ? "Click again to shut down" : "Power"
                        // 1st click = "arm" (laal), 2nd click 3 second ke andar = shutdown
                        onClicked: {
                            root.panel = ""
                            if (root.powerArm) {
                                root.powerArm = false
                                root.dismiss()
                                Quickshell.execDetached(["bash", root.bin + "/power/power.sh", "do", "shutdown"])
                            } else {
                                root.powerArm = true
                                armTimer.restart()
                            }
                        }
                        onRightClicked: root.toggleFrom("power", bPower)
                    }
                }
            }

            // =================== CARDS (bar ke left me) ===================
            // Har card: x = bar ke left me cardGap chhodke, y = jis button se khula uske barabar (screen ke andar)
            NetPanel {
                visible: root.open && root.netHover && root.panel === ""
                x: bar.x - root.cardGap - width
                y: root.clampY(root.netY, height)
                onHoveringChanged: if (hovering) netTimer.stop(); else netTimer.restart()
            }

            WarpPanel {
                visible: root.open && root.panel === "warp"
                x: bar.x - root.cardGap - width
                y: root.clampY(root.panelY, height)
            }

            WifiPanel {
                visible: root.open && root.panel === "wifi" && Sys.wifi.enabled
                x: bar.x - root.cardGap - width
                y: root.clampY(root.panelY, height)
            }

            BtPanel {
                visible: root.open && root.panel === "bt" && Sys.bt.enabled
                x: bar.x - root.cardGap - width
                y: root.clampY(root.panelY, height)
            }

            SoundPanel {
                visible: root.open && root.panel === "sound"
                x: bar.x - root.cardGap - width
                y: root.clampY(root.panelY, height)
            }

            PowerPanel {
                visible: root.open && root.panel === "power"
                x: bar.x - root.cardGap - width
                y: root.clampY(root.panelY, height)
                onActionRequested: (id) => {
                    root.dismiss()
                    Quickshell.execDetached(["bash", root.bin + "/power/power.sh", "do", id])
                }
            }

            TrayMenu {
                visible: root.open && root.panel === "tray" && root.trayItem !== null
                item: root.trayItem
                x: bar.x - root.cardGap - width
                y: root.clampY(root.panelY, height)
                onCloseRequested: root.dismiss()
            }

            DisplayPanel {
                visible: root.open && root.panel === "display"
                x: bar.x - root.cardGap - width
                y: root.clampY(root.panelY, height)
                onWallpaperRequested: {
                    root.dismiss()
                    Quickshell.execDetached(["bash", root.bin + "/theme/wallpaper.sh", "pick"])
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/quicksettings/SoundPanel.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  SoundPanel.qml  —  SOUND CARD  (Volume button par right-click)
//  Volume slider (mouse wheel sirf slider par mouse rakhne se chalta hai), Mute button,
//  OUTPUT (speakers) aur INPUT (mic) device chunna. Chuna hua device par tick.
//  Mic ka apna slider + mute button bhi hai (INPUT device ki list ke upar); mic laga na ho to wo grey + band rehta hai ("No mic").
//  KAAM KAUN KARTA HAI : Sys.qml -> quick.sh -> wpctl / pactl
// ============================================================================
import QtQuick
import QtQuick.Layouts
import qs.core
import qs.widgets

Card {
    id: p

    contentHeight: col.implicitHeight

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 12

        PanelHeader {
            icon: Icons.volumeUp
            title: "Sound"
            subtitle: Sys.muted ? "Muted" : "Volume " + Sys.vol + "%"
            IconButton { size: 32; icon: Icons.volumeOff; tip: Sys.muted ? "Unmute" : "Mute"; active: Sys.muted; danger: true; onClicked: Sys.toggleMute() }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text { text: Sys.muted ? Icons.volumeOff : Icons.volumeUp; font.family: Theme.iconFont; font.pixelSize: 20; color: Theme.text }
            LevelSlider { Layout.fillWidth: true; value: Sys.vol; onMoved: (v) => Sys.setVol(v) }
            Text {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: Sys.vol + "%"
                font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall; color: Theme.muted
            }
        }

        SectionLabel { text: "Output device" }
        Repeater {
            model: Sys.audio.sinks
            delegate: ListRow {
                id: dev
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 40
                title: modelData.desc || modelData.name
                selected: modelData.name === Sys.audio.sink
                onClicked: Sys.act(["sink-set", modelData.name])
                Text { visible: dev.selected; text: Icons.check; font.family: Theme.iconFont; font.pixelSize: 18; color: Theme.accent }
            }
        }

        SectionLabel { text: "Input device (mic)" }
        RowLayout {                                      // mic ka mute + volume (mic na ho to band)
            enabled: Sys.audio.micPresent
            opacity: enabled ? 1 : 0.45
            Layout.fillWidth: true
            spacing: 10
            IconButton { size: 28; icon: Sys.micMuted ? Icons.micOff : Icons.mic; tip: Sys.micMuted ? "Unmute mic" : "Mute mic"; active: Sys.micMuted; danger: true; onClicked: Sys.toggleMicMute() }
            LevelSlider { Layout.fillWidth: true; value: Sys.micVol; onMoved: (v) => Sys.setMicVol(v) }
            Text {
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignRight
                text: !Sys.audio.micPresent ? "No mic" : (Sys.micMuted ? "Muted" : Sys.micVol + "%")
                font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall; color: Theme.muted
            }
        }
        Repeater {
            model: Sys.audio.sources
            delegate: ListRow {
                id: mic
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 40
                title: modelData.desc || modelData.name
                selected: modelData.name === Sys.audio.source
                onClicked: Sys.act(["source-set", modelData.name])
                Text { visible: mic.selected; text: Icons.check; font.family: Theme.iconFont; font.pixelSize: 18; color: Theme.accent }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/quicksettings/TrayButton.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  TrayButton.qml  —  system tray ka ek app icon (for example LocalSend)
// ----------------------------------------------------------------------------
//  Left click = app ko jagao | Right click = uska menu (hamara themed TrayMenu.qml) | Middle click = doosra kaam
//  BADLO : implicitWidth/Height (size), icon size (implicitSize).
// ============================================================================
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core

Item {
    id: t

    required property var modelData     // tray ka item (Quickshell deta hai)
    signal activated()                  // left click par app jagi (QuickSettings khula card band karta hai)
    signal menuRequested()              // menu dikhana hai (QuickSettings TrayMenu card kholta hai)

    implicitWidth: 44
    implicitHeight: 44
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        antialiasing: true
        color: area.pressed ? Theme.pressed : (area.containsMouse ? Theme.hover : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.hoverMs } }
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: 22
        source: t.modelData.icon
    }

    property bool tipShown: false
    Timer { id: tipTimer; interval: 350; onTriggered: t.tipShown = area.containsMouse }

    Rectangle {
        antialiasing: true
        visible: t.tipShown
        anchors.right: parent.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: tt.width + 22
        height: 28
        radius: 8
        color: Qt.alpha(Theme.bg, 0.98)
        border.width: 1
        border.color: Theme.hairline
        Text {
            id: tt
            anchors.centerIn: parent
            text: t.modelData.tooltipTitle || t.modelData.title || t.modelData.id || ""
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsTiny
            color: Theme.text
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onEntered: tipTimer.restart()
        onExited: t.tipShown = false
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                t.modelData.secondaryActivate()
            } else if (mouse.button === Qt.RightButton || t.modelData.onlyMenu) {
                if (t.modelData.hasMenu) t.menuRequested()      // hamara menu card
            } else {
                t.activated(); t.modelData.activate()
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/quicksettings/TrayMenu.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  TrayMenu.qml  —  TRAY APP KA MENU, HAMARI THEME ME  (tray icon par right-click)
// ----------------------------------------------------------------------------
//  KYA HAI   : Pehle app ka apna (system wala) menu khulta tha — wo hamara theme use nahi karta tha aur options chalte nahi the.
//              Ab menu ke entries Quickshell se padh ke hum khud Card me dikhate hain, theme ke saath.
//  KAISE CHALTA HAI :
//     - Entry par click = us entry ka kaam chalta hai (entry.triggered()) aur poori bar band ho jati hai.
//     - ">" wale entry = sub-menu: click karo to andar jata hai; upar "<" se wapas.
//     - Check / radio wale entry par tick dikhta hai. Disabled entry phiki hoti hai.
//  DATA KAHAN SE : QsMenuOpener (Quickshell) — item.menu ke children deta hai.
//  SUB-MENU KI YAAD : hum entry object ko nahi, sirf uska NUMBER (index) yaad rakhte hain (path = [2, 0] matlab 3rd entry ke andar 1st entry).
//                     Kyunki app ka menu badalte hi Quickshell naye entry objects bana deta hai — purana object pakadne se menu khali/atak jata tha.
//  BADLO : width, row ki unchai (rowH), max unchai (maxH).
// ============================================================================
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.widgets

Card {
    id: p

    // ---------------- SETTINGS (yahan badlo) ----------------
    width: 280
    readonly property int rowH: 38          // ek entry ki unchai
    readonly property int maxH: 420         // menu isse lamba ho to scroll

    property var item: null                 // tray ka item (QuickSettings deta hai)
    property var path: []                   // sub-menu ka raasta: entry numbers ki list. [] = main menu
    signal closeRequested()                 // kaam hone ke baad bar band karo

    contentHeight: col.implicitHeight

    onItemChanged: path = []
    onVisibleChanged: if (!visible) path = []

    // path ke hisaab se entry dhundho: opener ke children me se index i wali entry
    function entryAt(op, i): var {
        const v = (op && op.children) ? op.children.values : null
        return (v && i >= 0 && i < v.length) ? v[i] : null
    }

    // 4 level tak sub-menu: har level ka opener pichhle level ke chuni hui entry ko kholta hai
    QsMenuOpener { id: o0; menu: p.item && p.item.hasMenu ? p.item.menu : null }
    QsMenuOpener { id: o1; menu: p.path.length > 0 ? p.entryAt(o0, p.path[0]) : null }
    QsMenuOpener { id: o2; menu: p.path.length > 1 ? p.entryAt(o1, p.path[1]) : null }
    QsMenuOpener { id: o3; menu: p.path.length > 2 ? p.entryAt(o2, p.path[2]) : null }

    // abhi jo menu dikh raha hai uska opener
    readonly property var cur: p.path.length === 0 ? o0 : (p.path.length === 1 ? o1 : (p.path.length === 2 ? o2 : o3))
    // sub-menu ke andar ho to uska naam (header ke liye)
    readonly property string subTitle: {
        if (p.path.length === 0) return ""
        const prev = p.path.length === 1 ? o0 : (p.path.length === 2 ? o1 : o2)
        const e = p.entryAt(prev, p.path[p.path.length - 1])
        return e ? e.text : ""
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 8

        // ---------- header: app ka naam (+ sub-menu me wapas jaane ka button) ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            IconButton { visible: p.path.length > 0; size: 30; icon: Icons.chevLeft; tip: "Back"; onClicked: p.path = p.path.slice(0, -1) }
            Text {
                Layout.fillWidth: true
                text: p.path.length > 0 ? p.subTitle : (p.item ? (p.item.tooltipTitle || p.item.title || p.item.id || "") : "")
                elide: Text.ElideRight
                font.family: Theme.uiFont
                font.pixelSize: Theme.fsTitle
                font.weight: Font.DemiBold
                color: Theme.text
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.hairline }

        // ---------- entries ----------
        ListView {
            id: lv
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, p.maxH)
            clip: true
            spacing: 2
            model: p.cur ? p.cur.children : null
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: ent
                required property var modelData
                required property int index
                readonly property bool sep: modelData.isSeparator
                width: ListView.view.width
                height: sep ? 9 : p.rowH

                // separator = patli line
                Rectangle {
                    visible: ent.sep
                    anchors.verticalCenter: parent.verticalCenter
                    x: 8
                    width: parent.width - 16
                    height: 1
                    color: Theme.hairline
                }

                ListRow {
                    visible: !ent.sep
                    width: parent.width
                    implicitHeight: p.rowH
                    title: ent.modelData.text
                    opacity: ent.modelData.enabled ? 1.0 : 0.45
                    onClicked: {
                        if (!ent.modelData.enabled) return
                        if (ent.modelData.hasChildren) {
                            p.path = p.path.concat([ent.index])      // sub-menu me jao (sirf number yaad)
                        } else {
                            ent.modelData.triggered()                // asli kaam
                            p.closeRequested()
                        }
                    }
                    // daayein taraf: tick (check/radio) ya ">" (sub-menu)
                    Text {
                        visible: ent.modelData.buttonType !== QsMenuButtonType.None && ent.modelData.checkState === Qt.Checked
                        text: Icons.check
                        font.family: Theme.iconFont
                        font.pixelSize: 18
                        color: Theme.accent
                    }
                    Text {
                        visible: ent.modelData.hasChildren
                        text: Icons.chevRight
                        font.family: Theme.iconFont
                        font.pixelSize: 20
                        color: Theme.muted
                    }
                }
            }
        }

        Text {
            visible: lv.count === 0
            text: "No actions"
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsSmall
            color: Theme.muted
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/quicksettings/WarpPanel.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  WarpPanel.qml  —  CLOUDFLARE WARP CARD  (Network button par right-click)
//  Status, ek bada Connect/Disconnect button, aur mode: WARP / WARP + DoH / DoH only.
//  Sab kaam ~/.config/snow/bin/quicksettings/warp.sh karta hai (Sys.warpAct se).
// ============================================================================
import QtQuick
import QtQuick.Layouts
import qs.core
import qs.widgets

Card {
    id: p

    width: 300
    contentHeight: col.implicitHeight

    readonly property string st: Sys.warp.state
    readonly property bool on: st === "connected"
    // Naya mode jodna ho to yahan ek line badhao (warp.sh me bhi mode chahiye)
    readonly property var modes: [
        { id: "warp",     label: "WARP" },
        { id: "warp+doh", label: "WARP+DoH" },
        { id: "doh",      label: "DoH" }
    ]

    function stateText(): string {
        if (st === "connected") return "Connected"
        if (st === "connecting") return "Connecting…"
        if (st === "unregistered") return "Not registered yet"
        if (st === "nosvc") return "Service not running"
        return "Disconnected"
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 12

        // ---- header ----
        PanelHeader {
            icon: p.on ? Icons.cloudDone : Icons.cloudOff
            active: p.on
            title: "Cloudflare WARP"
            subtitle: p.stateText()
            subtitleColor: p.on ? Theme.success : Theme.muted
        }

        // ---- connect / disconnect ----
        PillButton {
            Layout.fillWidth: true
            implicitHeight: 38
            height: 38
            kind: (p.on || p.st === "connecting") ? "danger" : "primary"
            text: (p.on || p.st === "connecting") ? "Disconnect" : (p.st === "unregistered" ? "Register & connect" : "Connect")
            onClicked: if (p.st !== "nosvc") Sys.warpAct([p.on || p.st === "connecting" ? "off" : "on"])
        }

        // ---- warp-svc band ho to madad ka text ----
        Text {
            visible: p.st === "nosvc"
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "warp-svc is not running. In a terminal: sudo systemctl enable --now warp-svc"
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsSmall
            color: Theme.warn
        }

        SectionLabel { text: "Mode" }

        Segmented {
            Layout.fillWidth: true
            model: p.modes
            current: Sys.warp.mode
            onPicked: (id) => Sys.warpAct(["mode", id])
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/quicksettings/WifiPanel.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  WifiPanel.qml  —  WI-FI CARD  (Wi-Fi button par right-click; Wi-Fi ON hona chahiye)
// ----------------------------------------------------------------------------
//  KYA KAR SAKTE HO:
//    - networks ki list dekho, search karo (upar ka search box)
//    - Connect / Disconnect (row par mouse rakho to button dikhta hai)
//    - Forget = saved network aur uska password hata do
//    - "+" = hidden network (naam + password)
//    - Naye secured network par pehle password poochta hai; galat password = laal "Wrong password"
//  KAAM KAUN KARTA HAI : Sys.qml -> quick.sh -> nmcli
// ============================================================================
import QtQuick
import QtQuick.Layouts
import qs.core
import qs.widgets

Card {
    id: p

    contentHeight: col.implicitHeight

    property string filter: ""          // search me jo likha
    property bool hiddenOpen: false     // "+" wala hidden-network form khula hai?

    // Secured + naya network = pehle password; baaki sab seedhe connect
    function tryConnect(n): void {
        if (n.secure && !n.saved) { Sys.connectMsg = ""; Sys.needPassFor = n.ssid; pw.focusInput() }
        else Sys.connectWifi(n.ssid, "")
    }

    // search ke hisaab se filter ki hui list
    readonly property var shown: {
        const q = filter.trim().toLowerCase()
        return Sys.wifiList.filter(n => q === "" || n.ssid.toLowerCase().indexOf(q) >= 0)
    }

    // card khulte hi: saaf karo aur naya scan chalao
    onVisibleChanged: {
        if (visible) {
            filter = ""; search.text = ""; pw.text = ""
            hiddenOpen = false; hs.text = ""; hp.text = ""
            Sys.needPassFor = ""; Sys.connectMsg = ""
            Sys.loadWifi(); Sys.scanWifi()
        }
    }

    Connections {
        target: Sys
        function onNeedPassForChanged() { pw.text = "" }
        function onConnectMsgChanged() { if (Sys.connectMsg === "Wrong password") { pw.text = ""; pw.focusInput() } }
        function onWifiConnected() { p.hiddenOpen = false; hs.text = ""; hp.text = "" }
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 12

        // ---------- header ----------
        PanelHeader {
            icon: Icons.wifi
            title: "Wi-Fi"
            subtitle: Sys.wifiBusy ? "Scanning…" : (Sys.wifi.ssid !== "" ? "Connected to " + Sys.wifi.ssid : "Not connected")
            IconButton { size: 32; icon: Icons.add; tip: "Hidden network"; active: p.hiddenOpen
                onClicked: { p.hiddenOpen = !p.hiddenOpen; Sys.needPassFor = ""; Sys.connectMsg = ""; if (p.hiddenOpen) hs.focusInput() } }
            IconButton { size: 32; icon: Icons.refresh; tip: "Scan"; onClicked: Sys.scanWifi() }
        }

        PillField { id: search; Layout.fillWidth: true; placeholder: "Search networks"; onTextChanged: p.filter = text }

        Text {
            visible: p.shown.length === 0
            text: Sys.wifiBusy ? "Looking for networks…" : "No networks found"
            font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall; color: Theme.muted
        }

        // ---------- networks ki list ----------
        ListView {
            id: lv
            visible: p.shown.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 252)
            clip: true
            spacing: 2
            model: p.shown
            boundsBehavior: Flickable.StopAtBounds

            delegate: ListRow {
                id: row
                required property var modelData
                readonly property bool busy: Sys.connecting && Sys.pendingSsid === modelData.ssid

                width: ListView.view.width
                icon: Icons.wifi
                iconColor: modelData.active ? Theme.accent : Theme.text
                title: modelData.ssid
                subtitle: busy ? "Connecting…" : (modelData.active ? "Connected" : (modelData.saved ? "Saved" : (modelData.secure ? "Secured" : "Open")))
                subtitleColor: modelData.active ? Theme.success : Theme.muted
                selected: modelData.active
                onClicked: if (!modelData.active) p.tryConnect(modelData)

                // signal ki taakat (4 patti) + lock (password wala network)
                Item {
                    visible: row.modelData.secure
                    width: 16; height: 16
                    Text { anchors.centerIn: parent; text: Icons.lock; font.family: Theme.iconFont; font.pixelSize: 14; color: Theme.muted }
                }
                Item {
                    id: bars
                    readonly property int level: Math.max(1, Math.min(4, Math.ceil(row.modelData.signal / 25)))
                    width: 18; height: 16
                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            required property int index
                            x: index * 5
                            width: 3
                            height: 4 + index * 4
                            y: bars.height - height
                            radius: 1
                            color: index < bars.level ? (row.modelData.active ? Theme.accent : Theme.text) : Theme.hairline
                        }
                    }
                }

                // daayein taraf ke buttons (mouse rakho ya connected ho tabhi dikhte hain)
                PillButton {
                    visible: row.modelData.saved && row.hovered && !row.modelData.active
                    text: "Forget"
                    kind: "ghost"
                    onClicked: Sys.forgetWifi(row.modelData.ssid)
                }
                PillButton {
                    visible: row.hovered || row.modelData.active
                    text: row.modelData.active ? "Disconnect" : "Connect"
                    kind: row.modelData.active ? "ghost" : "primary"
                    onClicked: row.modelData.active ? Sys.disconnectWifi() : p.tryConnect(row.modelData)
                }
            }
        }

        // ---------- hidden network form ("+") ----------
        ColumnLayout {
            visible: p.hiddenOpen
            Layout.fillWidth: true
            spacing: 8
            SectionLabel { text: "Hidden network" }
            PillField { id: hs; Layout.fillWidth: true; placeholder: "Network name (SSID)"; onAccepted: hp.focusInput() }
            PillField { id: hp; Layout.fillWidth: true; placeholder: "Password (empty = open network)"; password: true
                onAccepted: Sys.connectHidden(hs.text, text) }
            PillButton {
                Layout.fillWidth: true
                implicitHeight: 36
                height: 36
                text: "Connect"
                busy: Sys.connecting
                onClicked: Sys.connectHidden(hs.text, hp.text)
            }
        }

        // ---------- password poochna ----------
        ColumnLayout {
            visible: Sys.needPassFor !== ""
            Layout.fillWidth: true
            spacing: 8
            SectionLabel { text: "Password for " + Sys.needPassFor }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                PillField { id: pw; Layout.fillWidth: true; placeholder: "Password"; password: true
                    onAccepted: Sys.connectWifi(Sys.needPassFor, text) }
                PillButton { implicitHeight: 36; height: 36; text: "Connect"; busy: Sys.connecting
                    onClicked: Sys.connectWifi(Sys.needPassFor, pw.text) }
            }
        }

        // ---------- error ----------
        Text {
            visible: Sys.connectMsg !== ""
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: Sys.connectMsg
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsSmall
            color: Theme.danger
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/widgets/Card.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  Card.qml  —  FLOATING CARD (har chhote panel ka "dabba")
// ----------------------------------------------------------------------------
//  KYA HAI   : Gol kone wala card, halki border, halki parchhai (shadow), aur khulte waqt
//              halka fade + upar se neeche slide.
//  KAHAN USE : WifiPanel, BtPanel, SoundPanel, DisplayPanel, PowerPanel, WarpPanel, NetPanel.
//  KAISE USE : Card { contentHeight: col.implicitHeight   // andar ke content ki height
//                     ColumnLayout { id: col; width: parent.width ... } }
//  BADLO     : width (card ki chaudai), pad (andar ki jagah). Rang/kone Theme.qml se aate hain.
// ============================================================================
import QtQuick
import qs.core

Rectangle {
    antialiasing: true
    id: root

    // ---- SETTINGS ----
    width: 336                          // card ki chaudai (pixel)
    property real pad: Theme.pad        // andar ki jagah

    // ---- andar ka content isi me ayega ----
    default property alias content: inner.data
    property real contentHeight: 0      // andar ka content kitna lamba hai (har panel ye batata hai)

    readonly property bool hovering: hh.hovered   // mouse card ke upar hai?
    signal wheeled(int dy)                        // card ke kisi bhi hisse par scroll

    height: contentHeight + pad * 2
    radius: Theme.rCard
    color: Theme.cardBg
    border.width: 1
    border.color: Theme.hairline

    // parchhai: 3 halki parten, card ke peeche
    Repeater {
        model: 3
        delegate: Rectangle {
            antialiasing: true
            required property int index
            z: -1
            x: -(index + 1) * 3
            y: -(index + 1) * 3 + 5
            width: root.width + (index + 1) * 6
            height: root.height + (index + 1) * 6
            radius: root.radius + (index + 1) * 3
            color: Qt.rgba(0, 0, 0, 0.045)
        }
    }

    // khulte waqt: halka fade + 6px neeche se upar
    transform: Translate { id: slide; y: 0 }
    ParallelAnimation {
        id: enter
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: Theme.animMs }
        NumberAnimation { target: slide; property: "y"; from: 6; to: 0; duration: Theme.animMs; easing.type: Easing.OutCubic }
    }
    onVisibleChanged: if (visible) enter.restart()

    // card ke upar click/scroll peeche wale "bahar click = band" area tak na jaye
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onWheel: (wheel) => { root.wheeled(wheel.angleDelta.y); wheel.accepted = true }
    }

    HoverHandler { id: hh }

    Item {
        id: inner
        x: root.pad
        y: root.pad
        width: parent.width - root.pad * 2
        height: parent.height - root.pad * 2
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/widgets/IconButton.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  IconButton.qml  —  ek icon wala square-gol button (card ke andar use hota hai)
// ----------------------------------------------------------------------------
//  Use: IconButton { icon: Icons.refresh; tip: "Refresh"; onClicked: ... }
//  Options:
//    size    : button ki size (default 32)
//    active  : true = accent rang me dikhao (ON jaisa)
//    danger  : true = hover par laal
//    tip     : mouse rakhne par neeche chhota naam dikhta hai
// ============================================================================
import QtQuick
import qs.core

Item {
    id: root

    property string icon: ""
    property string tip: ""
    property real size: 32
    property bool active: false
    property bool danger: false
    signal clicked()

    width: size
    height: size

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        antialiasing: true
        color: root.active ? Theme.accentSoft
             : (area.pressed ? Theme.pressed : (area.containsMouse ? (root.danger ? Qt.alpha(Theme.danger, 0.18) : Theme.hover) : Theme.field))
        scale: area.pressed ? 0.95 : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }
        Behavior on color { ColorAnimation { duration: Theme.hoverMs } }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.iconFont
        font.pixelSize: Math.round(root.size * 0.56)
        color: root.active ? Theme.accent : ((root.danger && area.containsMouse) ? Theme.danger : Theme.text)
    }

    // naam wali chhoti patti (neeche)
    Rectangle {
        antialiasing: true
        visible: root.tip !== "" && root.tipShown
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height + 6
        z: 20
        width: tt.width + 20
        height: 24
        radius: 8
        color: Qt.alpha(Theme.bg, 0.98)
        border.width: 1
        border.color: Theme.hairline
        Text {
            id: tt
            anchors.centerIn: parent
            text: root.tip
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsTiny
            color: Theme.text
        }
    }

    property bool tipShown: false
    Timer { id: tipTimer; interval: 350; onTriggered: root.tipShown = area.containsMouse }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onContainsMouseChanged: { if (containsMouse) tipTimer.restart(); else root.tipShown = false }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/widgets/LevelSlider.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  LevelSlider.qml  —  patla slider (volume / brightness ke liye)
// ----------------------------------------------------------------------------
//  Use: LevelSlider { from: 0; to: 100; value: 50; onMoved: (v) => ... }
//  Mouse wheel bhi kaam karta hai (wheelStep = ek scroll me kitna badle).
//  BADLO : trackHeight (patli patti), knob (gola).
// ============================================================================
import QtQuick
import qs.core

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real wheelStep: 5
    signal moved(real v)

    readonly property real frac: Math.max(0, Math.min(1, (value - from) / (to - from)))
    readonly property bool hot: area.containsMouse || area.pressed
    property real trackHeight: 4
    property real knob: 14

    implicitHeight: 24

    function setAt(px: real): void {
        const f = Math.max(0, Math.min(1, px / width))
        root.moved(from + (to - from) * f)
    }

    // peeche ki patti
    Rectangle {
        antialiasing: true
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.hot ? root.trackHeight + 2 : root.trackHeight
        radius: height / 2
        color: Qt.alpha(Theme.tint, 0.12)
        Behavior on height { NumberAnimation { duration: 90 } }
    }
    // bhari hui patti
    Rectangle {
        antialiasing: true
        anchors.verticalCenter: parent.verticalCenter
        width: track.width * root.frac
        height: track.height
        radius: height / 2
        color: Theme.accent
    }
    // gola (sirf hover / dabate waqt dikhta hai)
    Rectangle {
        antialiasing: true
        anchors.verticalCenter: parent.verticalCenter
        x: track.width * root.frac - width / 2
        width: root.knob
        height: root.knob
        radius: width / 2
        color: Theme.text
        opacity: root.hot ? 1 : 0
        scale: root.hot ? 1 : 0.6
        Behavior on opacity { NumberAnimation { duration: 90 } }
        Behavior on scale { NumberAnimation { duration: 90 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: (mouse) => root.setAt(mouse.x)
        onPositionChanged: (mouse) => { if (pressed) root.setAt(mouse.x) }
        onWheel: (wheel) => {
            root.moved(Math.max(root.from, Math.min(root.to, root.value + (wheel.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep))))
            wheel.accepted = true
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/widgets/ListRow.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  ListRow.qml  —  list ki ek line: icon + title + chhota subtitle + daayein taraf buttons
// ----------------------------------------------------------------------------
//  Wi-Fi network, Bluetooth device, Sound device — teeno isi row se bante hain.
//  Use:
//    ListRow {
//        icon: Icons.wifi;  title: "MyWifi";  subtitle: "Connected";  subtitleColor: Theme.success
//        selected: false                       // true = halka accent background
//        onClicked: ...                        // poori row par click
//        PillButton { text: "Connect" }        // <- ye bachche daayein taraf (trailing) me jate hain
//    }
//  BADLO : height / icon size neeche.
// ============================================================================
import QtQuick
import qs.core

Rectangle {
    antialiasing: true
    id: root

    property string icon: ""
    property color iconColor: Theme.text
    property string title: ""
    property string subtitle: ""
    property color subtitleColor: Theme.muted
    property bool selected: false
    property bool showTrailing: true          // false = buttons chhupao
    default property alias trailing: trail.data
    signal clicked()

    // HoverHandler isliye: andar ke button par mouse jaye tab bhi row "hovered" rahe (button gayab na ho)
    readonly property bool hovered: hv.hovered
    HoverHandler { id: hv }

    implicitHeight: 52
    height: implicitHeight
    radius: Theme.rTile - 2
    color: selected ? Theme.accentSoft : (hv.hovered ? Theme.hover : "transparent")
    Behavior on color { ColorAnimation { duration: Theme.hoverMs } }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    Text {
        visible: root.icon !== ""
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        font.family: Theme.iconFont
        font.pixelSize: 22
        color: root.iconColor
    }

    Column {
        x: root.icon !== "" ? 46 : 12
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - (trail.visible ? trail.width + 16 : 12)
        spacing: 1
        Text {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsBody
            color: Theme.text
        }
        Text {
            visible: root.subtitle !== ""
            width: parent.width
            text: root.subtitle
            elide: Text.ElideRight
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsTiny
            color: root.subtitleColor
        }
    }

    Row {
        id: trail
        visible: root.showTrailing && children.length > 0
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/widgets/PanelHeader.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  PanelHeader.qml  —  HAR QUICK-SETTINGS CARD KA EK JAISA HEADER
// ----------------------------------------------------------------------------
//  Gol icon badge (left) + title (+ chhota subtitle) + right kone me action buttons.
//  Use:  PanelHeader { icon: Icons.wifi; title: "Wi-Fi"; subtitle: "Connected to ..."
//                      IconButton { icon: Icons.refresh; onClicked: ... } }      // andar ke buttons = top-right kone me
//  Options: icon, title, subtitle (khali = nahi dikhta), subtitleColor, active (false = badge phika)
// ============================================================================
import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property color subtitleColor: Theme.muted
    property bool active: true
    default property alias actions: actionRow.data

    Layout.fillWidth: true
    spacing: 10

    Rectangle {
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        radius: 18
        antialiasing: true
        color: root.active ? Theme.accentSoft : Theme.field
        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: Theme.iconFont
            renderType: Text.NativeRendering
            font.pixelSize: 21
            color: root.active ? Theme.accent : Theme.muted
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Text {
            Layout.fillWidth: true
            text: root.title
            elide: Text.ElideRight
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsTitle
            font.weight: Font.DemiBold
            color: Theme.text
        }
        Text {
            visible: root.subtitle !== ""
            Layout.fillWidth: true
            text: root.subtitle
            elide: Text.ElideRight
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsTiny
            color: root.subtitleColor
        }
    }

    Row {
        id: actionRow
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        spacing: 6
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/widgets/PillButton.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  PillButton.qml  —  text wala goli (pill) button: Connect / Disconnect / Forget ...
// ----------------------------------------------------------------------------
//  kind:  "primary" = accent rang (mukhya kaam)   "ghost" = halka (doosra kaam)   "danger" = laal
//  BADLO : height / font size neeche.
// ============================================================================
import QtQuick
import qs.core

Rectangle {
    antialiasing: true
    id: root

    property string text: ""
    property string kind: "primary"        // "primary" | "ghost" | "danger"
    property bool busy: false              // true = "..." dikhao
    signal clicked()

    implicitWidth: label.implicitWidth + 28
    implicitHeight: 30
    width: implicitWidth
    height: implicitHeight
    radius: height / 2

    readonly property color base: kind === "primary" ? Theme.accent : (kind === "danger" ? Qt.alpha(Theme.danger, 0.20) : Theme.hover)

    color: area.pressed ? Qt.darker(base, 1.12) : (area.containsMouse ? Qt.lighter(base, 1.10) : base)
    opacity: busy ? 0.7 : 1.0
    Behavior on color { ColorAnimation { duration: Theme.hoverMs } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.busy ? "…" : root.text
        font.family: Theme.uiFont
        font.pixelSize: Theme.fsSmall
        font.weight: Font.Medium
        color: root.kind === "primary" ? Theme.accentText : (root.kind === "danger" ? Theme.danger : Theme.text)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (!root.busy) root.clicked()
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/widgets/PillField.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  PillField.qml  —  goli (pill) text box: search, password, hex code ...
// ----------------------------------------------------------------------------
//  Use: PillField { placeholder: "Search"; onAccepted: ... }     (Enter dabane par accepted aata hai)
//       password: true  = type kiya hua bindu (•) dikhta hai
//  text padhne ke liye: field.text       focus dene ke liye: field.focusInput()
// ============================================================================
import QtQuick
import qs.core

Rectangle {
    antialiasing: true
    id: root

    property string placeholder: ""
    property bool password: false
    property alias text: input.text
    property alias maximumLength: input.maximumLength
    signal accepted()

    function focusInput(): void { input.forceActiveFocus() }

    implicitHeight: 36
    height: implicitHeight
    radius: height / 2
    color: Theme.field
    border.width: 1
    border.color: input.activeFocus ? Qt.alpha(Theme.accent, 0.7) : "transparent"
    Behavior on border.color { ColorAnimation { duration: Theme.hoverMs } }

    Text {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text === ""
        text: root.placeholder
        font.family: Theme.uiFont
        font.pixelSize: Theme.fsBody
        color: Theme.muted
    }

    TextInput {
        id: input
        x: 14
        width: parent.width - 28
        anchors.verticalCenter: parent.verticalCenter
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        passwordCharacter: "•"
        font.family: Theme.uiFont
        font.pixelSize: Theme.fsBody
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentText
        clip: true
        onAccepted: root.accepted()
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/widgets/RailButton.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  RailButton.qml  —  right wali vertical bar ka ek button
// ----------------------------------------------------------------------------
//  Bar me Wi-Fi, Bluetooth, Network, Volume, Brightness, Power sab isi se bante hain.
//  Options (property):
//    icon      : Icons.xxx
//    active    : true = ON (halka accent background + accent icon)
//    dim       : true = adapter nahi mila, icon phika
//    level     : 0..1 = icon ke chaaron taraf patla progress arc (volume / brightness). -1 = nahi
//    levelColor: arc ka rang
//    badge     : chhota status bindu (jaise internet green/red). "transparent" = nahi
//    armed     : true = laal "dobara click karo" haalat (power button)
//    tip       : mouse rakhne par left me naam dikhta hai
//  Signals: clicked, rightClicked, wheeled(dy), hoverEntered, hoverExited
//  BADLO : implicitWidth/Height (button ki size), radius (kone), icon size (font.pixelSize).
// ============================================================================
import QtQuick
import QtQuick.Shapes
import qs.core

Item {
    id: root

    property string icon: ""
    property bool active: false
    property bool dim: false
    property real level: -1
    property color levelColor: Theme.accent
    property color badge: "transparent"
    property bool armed: false
    property string tip: ""
    property bool tipOn: true

    signal clicked()
    signal rightClicked()
    signal wheeled(int dy)
    signal hoverEntered()
    signal hoverExited()

    implicitWidth: 44
    implicitHeight: 44
    width: implicitWidth
    height: implicitHeight

    // ---- background ----
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        antialiasing: true
        color: root.armed ? Qt.alpha(Theme.danger, 0.20)
             : (root.active ? Theme.accentSoft
             : (area.pressed ? Theme.pressed : (area.containsMouse ? Theme.hover : "transparent")))
        scale: area.pressed ? 0.94 : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }
        Behavior on color { ColorAnimation { duration: Theme.hoverMs } }
    }

    // ---- patla level arc (sirf volume / brightness me) ----
    property real shown: Math.max(0, Math.min(1, level))
    Behavior on shown { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Shape {
        visible: root.level >= 0
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer     // smooth (anti-aliased) ring, no pixel steps
        ShapePath {                                   // peeche ka halka gola
            strokeColor: Qt.alpha(Theme.tint, 0.10)
            strokeWidth: 1.5
            fillColor: "transparent"
            PathAngleArc { centerX: 22; centerY: 22; radiusX: 20; radiusY: 20; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {                                   // bhara hua hissa
            strokeColor: root.levelColor
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 22; centerY: 22; radiusX: 20; radiusY: 20; startAngle: -90; sweepAngle: 360 * root.shown }
        }
    }

    // ---- icon ----
    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.iconFont
        renderType: Text.NativeRendering
        font.pixelSize: 22
        color: root.armed ? Theme.danger : (root.active ? Theme.accent : (root.dim ? Theme.muted : Theme.text))
        opacity: root.dim ? 0.5 : 1.0
    }

    // ---- chhota status bindu (neeche-daayein kone me) ----
    Rectangle {
        antialiasing: true
        visible: root.badge.a > 0
        x: parent.width - width - 5
        y: parent.height - height - 5
        width: 9
        height: 9
        radius: 4.5
        color: root.badge
        border.width: 2
        border.color: Theme.railBg
    }

    // ---- tooltip (left me, 350ms ruk ke) ----
    property bool tipShown: false
    Timer { id: tipTimer; interval: 350; onTriggered: root.tipShown = area.containsMouse }

    Rectangle {
        antialiasing: true
        visible: root.tipOn && root.tip !== "" && root.tipShown
        anchors.right: parent.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: tt.width + 22
        height: 28
        radius: 8
        color: Qt.alpha(Theme.bg, 0.98)
        border.width: 1
        border.color: Theme.hairline
        Text {
            id: tt
            anchors.centerIn: parent
            text: root.tip
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsTiny
            color: Theme.text
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => { if (mouse.button === Qt.RightButton) root.rightClicked(); else root.clicked() }
        onWheel: (wheel) => { root.wheeled(wheel.angleDelta.y); wheel.accepted = true }
        onEntered: { tipTimer.restart(); root.hoverEntered() }
        onExited: { root.tipShown = false; root.hoverExited() }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/widgets/SectionLabel.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  SectionLabel.qml  —  chhota "BADE AKSHAR" wala heading (jaise OUTPUT DEVICE)
//  BADLO : font.pixelSize / letterSpacing neeche.
// ============================================================================
import QtQuick
import qs.core

Text {
    font.family: Theme.uiFont
    font.pixelSize: 10
    font.weight: Font.DemiBold
    font.letterSpacing: 1.2
    color: Theme.muted
    // text ko apne aap BADE AKSHAR me dikhata hai
    Component.onCompleted: text = text.toUpperCase()
}
SNOW_FILE_END_4b7d
;;
"u/.config/quickshell/snow/widgets/Segmented.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  Segmented.qml  —  "ya ye ya wo" wala toggle  (jaise [ Dark | Light ] ya [ WARP | WARP+DoH | DoH ])
// ----------------------------------------------------------------------------
//  Use: Segmented { model: [ {id:"dark", label:"Dark"}, {id:"light", label:"Light"} ]
//                   current: "dark"; onPicked: (id) => ... }
//  BADLO : height (unchai), font size.
// ============================================================================
import QtQuick
import qs.core

Rectangle {
    antialiasing: true
    id: root

    property var model: []
    property string current: ""
    signal picked(string id)

    implicitHeight: 34
    height: implicitHeight
    radius: height / 2
    color: Theme.field

    Row {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 2

        Repeater {
            model: root.model
            delegate: Rectangle {
                antialiasing: true
                id: seg
                required property var modelData
                readonly property bool on: seg.modelData.id === root.current
                width: (root.width - 6 - (root.model.length - 1) * 2) / Math.max(1, root.model.length)
                height: root.height - 6
                radius: height / 2
                color: on ? Theme.accentSoft : (sa.containsMouse ? Theme.hover : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.hoverMs } }

                Text {
                    anchors.centerIn: parent
                    text: seg.modelData.label
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fsSmall
                    font.weight: seg.on ? Font.DemiBold : Font.Normal
                    color: seg.on ? Theme.accent : Theme.text
                }
                MouseArea {
                    id: sa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(seg.modelData.id)
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/quicksettings/quick.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  quick.sh  —  QUICK SETTINGS KA PICHHE WALA ENGINE  (Wi-Fi, Bluetooth, Volume, Brightness)
# ----------------------------------------------------------------------------
#  QML (Sys.qml) isse chalata hai; ye JSON text wapas deta hai. Jaroorat: jq.
#  Terminal se test karne ke liye:   bash ~/.config/snow/bin/quicksettings/quick.sh status
#  KAMAND LIST:
#    status                         Wi-Fi/Bluetooth/Internet/Volume ki poori haalat (JSON)
#    wifi on|off | wifi-scan | wifi-list | wifi-connect SSID | wifi-connect-hidden SSID | wifi-forget SSID | wifi-disconnect
#    bt on|off | bt-scan | bt-list | bt-pair MAC | bt-connect MAC | bt-disconnect MAC
#    vol-set N | vol-mute | mic-set N | mic-mute | sink-set NAME | source-set NAME | set-brightness N
#  WI-FI PASSWORD (SECURITY): password kabhi command-line me nahi jata (ps me dikhta). Sys.qml use environment variable
#    SNOW_WIFI_PW me deta hai; yahan se nmcli ko ek private temp file (mode 600, $XDG_RUNTIME_DIR) ke zariye jata hai
#    aur turant mita di jati hai.
#  SAVED NETWORK: koi bhi connect koshish saved profile ko KABHI nahi hatati (sirf "Forget" hatata hai).
#    Jo profile isi koshish ne banayi ho aur fail ho jaye, wahi wapas hata di jati hai.
# ============================================================================
set -u
QCONF="$HOME/.config/snow/state/quick.json"
have() { command -v "$1" >/dev/null 2>&1; }
# nmcli ke text me ":" ko "\:" likha hota hai; ye usse alag pehchan deta hai
esc() { sed 's/\\:/\x01/g'; }      # nmcli -t escapes ':' inside values as '\:'

# SAB KUCH EK JSON ME: wifi, bt, net, audio. nmcli/bluetoothctl/wpctl/pactl se padhta hai. Jo tool na ho use chhod deta hai.
status() {
  local wifi_present=false wifi_on=false bt_present=false bt_on=false
  local net_state=disconnected net_type=none net_name="" net_ip="" net_conn="" eth=false wifi_ssid=""
  local vol=0 muted=false aud=false mvol=0 mmuted=false mic_ok=false sink="" source="" sinks='[]' sources='[]'
  local devs line dev=""

  if have nmcli; then
    devs=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device 2>/dev/null | esc)
    printf '%s\n' "$devs" | awk -F: '$2=="wifi"{f=1} END{exit !f}' && wifi_present=true
    [ "$(nmcli radio wifi 2>/dev/null)" = "enabled" ] && wifi_on=true
    line=$(printf '%s\n' "$devs" | awk -F: '$2=="ethernet" && $3=="connected"{print; exit}')
    if [ -n "$line" ]; then
      eth=true; net_state=connected; net_type=ethernet; dev=${line%%:*}
      net_name=$(printf '%s' "$line" | cut -d: -f4 | tr '\001' ':')
    fi
    line=$(printf '%s\n' "$devs" | awk -F: '$2=="wifi" && $3=="connected"{print; exit}')
    if [ -n "$line" ]; then
      wifi_ssid=$(printf '%s' "$line" | cut -d: -f4 | tr '\001' ':')
      if [ "$eth" = false ]; then net_state=connected; net_type=wifi; net_name=$wifi_ssid; dev=${line%%:*}; fi
    fi
    [ -n "$dev" ] && net_ip=$(nmcli -g IP4.ADDRESS device show "$dev" 2>/dev/null | head -1 | cut -d/ -f1)
    net_conn=$(nmcli -g CONNECTIVITY general 2>/dev/null)
  fi

  if have bluetoothctl; then
    local show; show=$(bluetoothctl show 2>/dev/null)
    if printf '%s' "$show" | grep -q '^Controller'; then
      bt_present=true
      printf '%s' "$show" | grep -q 'Powered: yes' && bt_on=true
    fi
  fi

  if have wpctl; then
    local v; v=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    if [ -n "$v" ]; then
      aud=true
      vol=$(printf '%s' "$v" | awk '{printf "%d", $2*100+0.5}')
      case "$v" in *MUTED*) muted=true ;; esac
    fi
    v=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)          # mic ki volume / mute
    if [ -n "$v" ]; then
      mvol=$(printf '%s' "$v" | awk '{printf "%d", $2*100+0.5}')
      case "$v" in *MUTED*) mmuted=true ;; esac
    fi
  fi
  if have pactl; then
    sink=$(pactl get-default-sink 2>/dev/null); source=$(pactl get-default-source 2>/dev/null)
    sinks=$(pactl --format=json list sinks 2>/dev/null | jq -c '[.[] | {name: .name, desc: .description}]' 2>/dev/null)
    local srcjson; srcjson=$(pactl --format=json list sources 2>/dev/null)
    sources=$(printf '%s' "$srcjson" | jq -c '[.[] | select(.name | endswith(".monitor") | not) | {name: .name, desc: .description}]' 2>/dev/null)
    # mic sach me laga hai? default source asli mic ho aur uska active port "not available" (khali jack) na ho
    mic_ok=$(printf '%s' "$srcjson" | jq -r --arg s "$source" '[.[] | select(.name == $s and (.name | endswith(".monitor") | not))] | if length == 0 then false else (.[0] as $d | (($d.ports // []) | map(select(.name == $d.active_port)) | ((.[0].availability // "") != "not available"))) end' 2>/dev/null)
    [ "$mic_ok" = true ] || mic_ok=false
    [ -n "$sinks" ] || sinks='[]'; [ -n "$sources" ] || sources='[]'
  fi

  jq -n -c \
    --argjson wp "$wifi_present" --argjson wo "$wifi_on" --argjson bp "$bt_present" --argjson bo "$bt_on" \
    --arg ns "$net_state" --arg nt "$net_type" --arg nn "$net_name" --arg ni "$net_ip" --arg nc "$net_conn" \
    --argjson eth "$eth" --arg ws "$wifi_ssid" \
    --argjson aud "$aud" --argjson vol "$vol" --argjson mu "$muted" --argjson mvol "$mvol" --argjson mmu "$mmuted" --argjson mp "$mic_ok" \
    --arg sink "$sink" --arg source "$source" --argjson sinks "$sinks" --argjson sources "$sources" \
    '{wifi:{present:$wp,enabled:$wo,ssid:$ws}, bt:{present:$bp,enabled:$bo},
      net:{state:$ns,type:$nt,name:$nn,ip:$ni,connectivity:$nc,eth:$eth},
      audio:{present:$aud,vol:$vol,muted:$mu,micVol:$mvol,micMuted:$mmu,micPresent:$mp,sink:$sink,source:$source,sinks:$sinks,sources:$sources}}'
}

# Wi-Fi networks ki list (JSON): ssid, signal, secure, saved, active. Ek naam ka ek hi entry (sabse tez signal).
wifi_list() {
  have nmcli || { echo '[]'; return; }
  local saved
  saved=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | esc | awk -F: '$2=="802-11-wireless"{print $1}' | tr '\001' ':')
  nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan no 2>/dev/null | esc \
    | awk -F: '$2!=""{print $1"\t"$2"\t"$3"\t"$4}' | tr '\001' ':' \
    | jq -R -s -c --arg saved "$saved" '
        ($saved | split("\n") | map(select(length > 0))) as $sv
        | split("\n") | map(select(length > 0) | split("\t"))
        | map({active: (.[0] == "*"), ssid: .[1], signal: (.[2] | tonumber? // 0),
               secure: ((.[3] // "") | (. != "" and . != "--")), saved: (.[1] as $s | ($sv | index($s)) != null)})
        | group_by(.ssid) | map(sort_by([(.active | not), -.signal]) | .[0])
        | sort_by([(.active | not), -.signal])'
}

# ---- Wi-Fi connect. The password NEVER goes on a command line (ps shows command lines):
#      the panel hands it over in the environment variable SNOW_WIFI_PW, and nmcli gets it through a private temp file
#      (nmcli "passwd-file", mode 600, in $XDG_RUNTIME_DIR, deleted right after the call).
#      A saved profile is NEVER deleted here (only "Forget" does that). A profile that THIS attempt created is removed again if the attempt fails.
wifi_uuid() {    # uuid of a saved Wi-Fi profile whose name is this SSID ("" = none)
  local s; s=$(printf '%s' "$1" | tr ':' '\001')
  nmcli -t -f NAME,UUID,TYPE connection show 2>/dev/null | esc | awk -F: -v s="$s" '$3=="802-11-wireless" && $1==s {print $2; exit}'
}
wifi_sec() {     # security text of this SSID from the last scan ("" = not in the list, "--" = open)
  local s; s=$(printf '%s' "$1" | tr ':' '\001')
  nmcli -t -f SSID,SECURITY device wifi list --rescan no 2>/dev/null | esc | awk -F: -v s="$s" '$1==s {print $2; exit}'
}
wifi_kind() {    # security text -> open | wpa-psk | sae | unsupported
  case "$1" in
    ""|"--") echo open ;;
    *802.1X*|*EAP*|*WEP*) echo unsupported ;;
    *WPA3*) case "$1" in *WPA2*|*WPA1*) echo wpa-psk ;; *) echo sae ;; esac ;;
    *WPA*) echo wpa-psk ;;
    *) echo open ;;          # OWE and anything unknown: nmcli decides (device wifi connect)
  esac
}
wifi_dev() { nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}'; }
wifi_pwfile() {  # wifi_pwfile PASSWORD : private file with the password line, prints its path
  local f
  f=$(umask 077; mktemp "${XDG_RUNTIME_DIR:-/tmp}/snow-wifi.XXXXXX") || return 1
  printf '802-11-wireless-security.psk:%s\n' "$1" > "$f"
  printf '%s' "$f"
}
wifi_up() {      # wifi_up UUID [PASSWORD] -> sets OUT and RC
  local pwf=""
  if [ -n "${2:-}" ]; then
    pwf=$(wifi_pwfile "$2") || { OUT="could not write the private password file"; RC=1; return 0; }
    PWF="$pwf"
    OUT=$(nmcli -w 25 connection up uuid "$1" passwd-file "$pwf" 2>&1); RC=$?
    rm -f "$pwf"; PWF=""
  else
    OUT=$(nmcli -w 25 connection up uuid "$1" 2>&1); RC=$?
  fi
  return 0
}
wifi_json() {    # wifi_json RC OUT HAD_PASSWORD : the answer for the panel
  local rc="$1" out="$2" had="$3" last
  if [ "$rc" -eq 0 ]; then jq -n -c '{ok:true}'; return; fi
  if printf '%s' "$out" | grep -qiE 'secrets were required|no secrets|802\.1X'; then
    if [ "$had" = 1 ]; then jq -n -c '{ok:false,need:"password",wrong:true}'; else jq -n -c '{ok:false,need:"password",wrong:false}'; fi
    return
  fi
  last=$(printf '%s\n' "$out" | sed 's/^Error: *//' | grep -v '^$' | tail -n1)
  jq -n -c --arg m "Could not connect${last:+: $last}" '{ok:false,msg:$m}'
}
wifi_add() {     # wifi_add SSID KEYMGMT HIDDEN(0|1) -> prints the uuid of the NEW profile ("" = failed)
  local ssid="$1" kind="$2" hid="$3" dev add uuid
  dev=$(wifi_dev)
  local args=(connection add type wifi con-name "$ssid" ifname "${dev:-*}" ssid "$ssid")
  [ "$hid" = 1 ] && args+=(802-11-wireless.hidden yes)
  [ "$kind" != open ] && args+=(wifi-sec.key-mgmt "$kind")
  add=$(nmcli "${args[@]}" 2>&1) || return 0
  uuid=$(printf '%s' "$add" | grep -oE '[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}' | head -n1)
  [ -n "$uuid" ] || uuid=$(wifi_uuid "$ssid")
  printf '%s' "$uuid"
}

# Wi-Fi connect. Jawab JSON: {ok:true} | {need:"password",wrong:true/false} | {msg:"..."}
wifi_connect() {
  local ssid="${1:-}" pass="${SNOW_WIFI_PW:-}" had=0 old new sec kind
  unset SNOW_WIFI_PW
  [ -n "$pass" ] && had=1
  [ -n "$ssid" ] || { jq -n -c '{ok:false,msg:"No network name"}'; return; }
  trap '[ -n "${PWF:-}" ] && rm -f "$PWF"' EXIT
  old=$(wifi_uuid "$ssid")
  if [ -n "$old" ]; then                     # saved network: use its profile, never delete it here
    wifi_up "$old" "$pass"
    wifi_json "$RC" "$OUT" "$had"; return
  fi
  sec=$(wifi_sec "$ssid"); kind=$(wifi_kind "$sec")
  [ -z "$sec" ] && [ "$had" = 1 ] && kind=wpa-psk    # not in the scan list but a password was typed: assume WPA2
  if [ "$kind" = unsupported ]; then jq -n -c '{ok:false,msg:"This Wi-Fi type (WEP / enterprise) is not supported here"}'; return; fi
  if [ "$kind" = open ]; then
    OUT=$(nmcli -w 25 device wifi connect "$ssid" 2>&1); RC=$?
    if [ "$RC" -ne 0 ]; then new=$(wifi_uuid "$ssid"); [ -n "$new" ] && nmcli connection delete uuid "$new" >/dev/null 2>&1; fi   # there was no profile before, so this one is ours
    wifi_json "$RC" "$OUT" 0; return
  fi
  [ "$had" = 1 ] || { jq -n -c '{ok:false,need:"password",wrong:false}'; return; }     # secured and not saved: ask for the password first
  new=$(wifi_add "$ssid" "$kind" 0)
  [ -n "$new" ] || { jq -n -c '{ok:false,msg:"Could not create the Wi-Fi profile"}'; return; }
  wifi_up "$new" "$pass"
  [ "$RC" -ne 0 ] && nmcli connection delete uuid "$new" >/dev/null 2>&1              # this attempt made it, so a failed attempt removes it
  wifi_json "$RC" "$OUT" 1
}

# Hidden network se connect (naam + password)
wifi_connect_hidden() {
  local ssid="${1:-}" pass="${SNOW_WIFI_PW:-}" had=0 old new kind=open
  unset SNOW_WIFI_PW
  [ -n "$pass" ] && had=1
  [ -n "$ssid" ] || { jq -n -c '{ok:false,msg:"Enter the network name"}'; return; }
  trap '[ -n "${PWF:-}" ] && rm -f "$PWF"' EXIT
  old=$(wifi_uuid "$ssid")
  if [ -n "$old" ]; then
    nmcli connection modify uuid "$old" 802-11-wireless.hidden yes >/dev/null 2>&1
    wifi_up "$old" "$pass"
  else
    [ "$had" = 1 ] && kind=wpa-psk
    new=$(wifi_add "$ssid" "$kind" 1)
    [ -n "$new" ] || { jq -n -c '{ok:false,msg:"Could not create the Wi-Fi profile"}'; return; }
    wifi_up "$new" "$pass"
    [ "$RC" -ne 0 ] && nmcli connection delete uuid "$new" >/dev/null 2>&1
  fi
  if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -qiE 'secrets were required|no secrets|802\.1X'; then
    if [ "$had" = 1 ]; then jq -n -c '{ok:false,msg:"Wrong password (or the network name is wrong)"}'
    else jq -n -c '{ok:false,msg:"This network needs a password: type it in the second box"}'; fi
    return
  fi
  wifi_json "$RC" "$OUT" "$had"
}
wifi_forget() {   # remove the saved profile (and with it the saved password)
  local ssid="$1"
  [ -n "$ssid" ] || { echo "{}"; return; }
  while nmcli connection delete id "$ssid" >/dev/null 2>&1; do :; done
  echo "{}"
}

wifi_disconnect() {
  local d; d=$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')
  [ -n "$d" ] && nmcli device disconnect "$d" >/dev/null 2>&1
  echo '{}'
}

# Bluetooth devices ki list (JSON): mac, name, paired, connected
bt_list() {
  have bluetoothctl || { echo '[]'; return; }
  local out='[]' mac name info paired conn
  while read -r _ mac name; do
    [ -n "$mac" ] || continue
    info=$(bluetoothctl info "$mac" 2>/dev/null)
    paired=false; conn=false
    printf '%s' "$info" | grep -q 'Paired: yes' && paired=true
    printf '%s' "$info" | grep -q 'Connected: yes' && conn=true
    out=$(jq -c --arg mac "$mac" --arg name "$name" --argjson p "$paired" --argjson c "$conn" \
          '. + [{mac:$mac,name:$name,paired:$p,connected:$c}]' <<<"$out")
  done < <(bluetoothctl devices 2>/dev/null)
  jq -c 'sort_by([(.connected | not), (.paired | not), .name])' <<<"$out"
}

# Bluetooth address sahi shape ka ho (AA:BB:CC:DD:EE:FF) — bluetoothctl ko kuch aur kabhi nahi jata
valid_mac() { [[ "${1:-}" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; }

# Bluetooth kaam ka jawab: {"ok":true}  ya  {"ok":false,"msg":"..."}  (msg panel me laal text me dikhta hai)
bt_json() {
  if [ "$1" = ok ]; then echo '{"ok":true}'; else jq -nc --arg m "$2" '{ok:false,msg:$m}'; fi
}

# naya device pair + trust + connect (lagbhag 12 second lagte hain)
bt_pair() {
  valid_mac "${1:-}" || { bt_json no "Bad Bluetooth address"; return; }
  local mac=$1 info
  { printf 'agent NoInputNoOutput\ndefault-agent\npair %s\n' "$mac"; sleep 8
    printf 'trust %s\nconnect %s\n' "$mac" "$mac"; sleep 4; printf 'quit\n'; } | bluetoothctl >/dev/null 2>&1
  info=$(bluetoothctl info "$mac" 2>/dev/null)
  if ! printf '%s' "$info" | grep -q 'Paired: yes'; then
    bt_json no "Pairing failed. Put the device in pairing mode and try again (devices that ask for a PIN cannot be paired here)."
  elif ! printf '%s' "$info" | grep -q 'Connected: yes'; then
    bt_json no "Paired, but could not connect. Turn the device on and press Connect."
  else
    bt_json ok
  fi
}

bt_connect() {
  valid_mac "${1:-}" || { bt_json no "Bad Bluetooth address"; return; }
  local out; out=$(timeout 25 bluetoothctl connect "$1" 2>&1)
  if printf '%s' "$out" | grep -qi 'Connection successful'; then bt_json ok
  else bt_json no "Could not connect. Is the device on and nearby?"; fi
}

bt_disconnect() {
  valid_mac "${1:-}" || { bt_json no "Bad Bluetooth address"; return; }
  local out; out=$(timeout 15 bluetoothctl disconnect "$1" 2>&1)
  if printf '%s' "$out" | grep -qi 'success'; then bt_json ok
  else bt_json no "Could not disconnect."; fi
}

# paired device ko poori tarah hatao (dobara use karna ho to phir se Pair karna padega)
bt_remove() {
  valid_mac "${1:-}" || { bt_json no "Bad Bluetooth address"; return; }
  local out; out=$(timeout 15 bluetoothctl remove "$1" 2>&1)
  if printf '%s' "$out" | grep -qi 'removed'; then bt_json ok
  else bt_json no "Could not remove the device."; fi
}

# software brightness ka level ~/.config/snow/state/quick.json me save karo (20..100)
set_brightness() {
  case "${1:-}" in ''|*[!0-9]*) echo "[PROBLEM] brightness must be a number"; return 2 ;; esac
  local n=$1; [ "$n" -lt 20 ] && n=20; [ "$n" -gt 100 ] && n=100
  mkdir -p "$(dirname "$QCONF")"
  local cur='{}'; [ -s "$QCONF" ] && cur=$(cat "$QCONF")
  jq --argjson b "$n" '.brightness = $b' <<<"$cur" > "$QCONF.tmp" 2>/dev/null && cat "$QCONF.tmp" > "$QCONF"
  rm -f "$QCONF.tmp"
}

case "${1:-}" in
  status)          status ;;
  wifi)            nmcli radio wifi "${2:-on}" >/dev/null 2>&1; echo '{}' ;;
  wifi-scan)       nmcli device wifi rescan >/dev/null 2>&1; echo '{}' ;;
  wifi-list)       wifi_list ;;
  wifi-connect)    wifi_connect "${2:-}" "${3:-}" ;;
  wifi-connect-hidden) wifi_connect_hidden "${2:-}" "${3:-}" ;;
  wifi-disconnect) wifi_disconnect ;;
  wifi-forget)     wifi_forget "${2:-}" ;;
  bt)              if [ "${2:-on}" = on ]; then rfkill unblock bluetooth 2>/dev/null; fi; bluetoothctl power "${2:-on}" >/dev/null 2>&1; echo '{}' ;;
  bt-scan)         bluetoothctl --timeout 8 scan on >/dev/null 2>&1; echo '{}' ;;
  bt-list)         bt_list ;;
  bt-pair)         bt_pair "${2:-}" ;;
  bt-connect)      bt_connect "${2:-}" ;;
  bt-disconnect)   bt_disconnect "${2:-}" ;;
  bt-remove)       bt_remove "${2:-}" ;;
  vol-set)         wpctl set-volume @DEFAULT_AUDIO_SINK@ "${2:-50}%" ;;
  vol-mute)        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  mic-set)         wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "${2:-50}%" ;;
  mic-mute)        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
  sink-set)        pactl set-default-sink "${2:-}" ;;
  source-set)      pactl set-default-source "${2:-}" ;;
  set-brightness)  set_brightness "${2:-}" ;;
  *) echo "usage: quick.sh status|wifi|wifi-scan|wifi-list|wifi-connect|wifi-disconnect|bt|bt-scan|bt-list|bt-pair|bt-connect|bt-disconnect|vol-set|vol-mute|mic-set|mic-mute|sink-set|source-set|set-brightness"; exit 2 ;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/quicksettings/warp.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  warp.sh  —  CLOUDFLARE WARP KO CHALANE WALI SCRIPT  (warp-cli ke upar)
# ----------------------------------------------------------------------------
#  USE:
#    warp.sh status            ek line JSON: {"installed":true,"state":"connected|connecting|disconnected|unregistered|nosvc|none","mode":"warp|warp+doh|doh|..."}
#    warp.sh on                pehli baar register karke connect
#    warp.sh off               disconnect
#    warp.sh toggle            on <-> off
#    warp.sh mode warp|warp+doh|doh
#  QML (Sys.qml / WarpPanel) isi ko chalate hain.
#  NOTE: warp-cli ke shabd WARP ke versions me thode badalte hain, isliye naya aur purana dono tareeke try hote hain. [U]
#  AGAR KUCH NA HO:  warp-cli --accept-tos status   aur   sudo systemctl status warp-svc
# ============================================================================
export PATH="$PATH:/usr/bin:/bin"
have() { command -v "$1" >/dev/null 2>&1; }
# warp-cli ko license-accept ke saath, 20 second ke timeout me chalata hai
cli() { timeout "${T:-20}" warp-cli --accept-tos "$@" 2>&1; }

# warp-cli status ke text se ek shabd banata hai (connected / connecting / disconnected / unregistered / nosvc)
state() {
  local out low
  out=$(T=6 cli status); low=$(printf '%s' "$out" | tr 'A-Z' 'a-z')
  case "$low" in
    *"unable to connect"*|*"daemon"*"not running"*|*"service is not running"*) echo nosvc ;;
    *"registration missing"*|*"missing registration"*|*"not registered"*|*"registration not found"*) echo unregistered ;;
    *disconnected*) echo disconnected ;;
    *connecting*|*"happy eyeballs"*|*pending*) echo connecting ;;
    *connected*) echo connected ;;
    *) echo disconnected ;;
  esac
}

# abhi ka WARP mode padhta hai
mode() {
  local s low
  s=$(T=6 cli settings list 2>/dev/null); [ -z "$s" ] && s=$(T=6 cli settings 2>/dev/null)
  low=$(printf '%s' "$s" | tr 'A-Z' 'a-z' | grep -m1 'mode')
  case "$low" in
    *dnsoverhttps*|*doh*) case "$low" in *warp*) case "$low" in *"warp+doh"*|*withdns*|*"warp with"*) echo "warp+doh" ;; *) echo "doh" ;; esac ;; *) echo doh ;; esac ;;
    *proxy*) echo proxy ;;
    *warp*) echo warp ;;
    "") echo "" ;;
    *) echo other ;;
  esac
}

case "${1:-}" in
  status)
    if ! have warp-cli; then echo '{"installed":false,"state":"none","mode":""}'; exit 0; fi
    st=$(state); md=""; [ "$st" = connected ] || [ "$st" = disconnected ] && md=$(mode)
    printf '{"installed":true,"state":"%s","mode":"%s"}\n' "$st" "$md" ;;
  on)
    have warp-cli || { echo "[PROBLEM] warp-cli is not installed (run install.sh warp from your Snow folder)"; exit 1; }
    st=$(state)
    [ "$st" = nosvc ] && { echo "[PROBLEM] warp-svc is not running: sudo systemctl enable --now warp-svc"; exit 1; }
    if [ "$st" = unregistered ]; then cli registration new >/dev/null || cli register >/dev/null || { echo "[PROBLEM] WARP registration failed"; exit 1; }; fi
    cli connect ;;
  off) cli disconnect ;;
  toggle) st=$(state); case "$st" in connected|connecting) cli disconnect ;; *) "$0" on ;; esac ;;
  mode)
    case "${2:-}" in warp|warp+doh|doh) ;; *) echo "usage: warp.sh mode warp|warp+doh|doh"; exit 2 ;; esac
    cli mode "$2" || cli set-mode "$2" ;;
  *) echo "usage: warp.sh status|on|off|toggle|mode M"; exit 2 ;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/state/quick.json")
cat <<'SNOW_FILE_END_4b7d'
{
  "brightness": 60
}
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
pre() {
apt_install network-manager bluez brightnessctl playerctl pipewire-pulse pulseaudio-utils
}
extra_check() {
for n in widgets/PanelHeader quicksettings/QuickSettings quicksettings/BtPanel quicksettings/ColorPicker quicksettings/DisplayPanel quicksettings/NetPanel quicksettings/PowerPanel quicksettings/SoundPanel quicksettings/TrayButton quicksettings/TrayMenu quicksettings/WarpPanel quicksettings/WifiPanel widgets/Card widgets/IconButton widgets/LevelSlider widgets/ListRow widgets/PillButton widgets/PillField widgets/RailButton widgets/SectionLabel widgets/Segmented; do qml_ok "$QS/$n.qml"; done
for s in quicksettings/quick.sh quicksettings/warp.sh; do [ -f "$BIN/$s" ] || continue; bash -n "$BIN/$s" && pass "$s: syntax ok" || fail "$s: syntax error" "bash ~/Snow/Script/${MOD}.sh"; done
}
component_main "$@"
