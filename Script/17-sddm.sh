#!/usr/bin/env bash
# 17-sddm.sh : Login screen: SDDM theme clock-ring
# 3-dial clock, date, password line, restart + power-off buttons. Active from the next boot / logout.
#   bash Script/17-sddm.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/17-sddm.sh check    read-only check
MOD="17-sddm"; TITLE="Login screen: SDDM theme clock-ring"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/snow/bin/sddm/sddm-bg.sh|755|0"
  "s|etc/sddm.conf.d/zz-clock-ring.conf|644|0"
  "s|usr/share/sddm/themes/clock-ring/Main.qml|644|0"
  "s|usr/share/sddm/themes/clock-ring/Ring.qml|644|0"
  "s|usr/share/sddm/themes/clock-ring/metadata.desktop|644|0"
  "s|usr/share/sddm/themes/clock-ring/theme.conf|644|0"
)
emit() {
case "$1" in
"u/.config/snow/bin/sddm/sddm-bg.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  sddm-bg.sh  —  LOGIN SCREEN (SDDM) BACKGROUND = your current wallpaper, blurred
# ----------------------------------------------------------------------------
#  Runs by itself after every new wallpaper (wallpaper.sh). Run it by hand:   bash ~/.config/snow/bin/sddm/sddm-bg.sh
#  1) makes a blurred picture of ~/.config/snow/state/wallpaper.current  ->  ~/.cache/snow/sddm-background.jpg   (as you, no admin rights)
#  2) asks the small root helper /usr/local/sbin/snow-sddm-bg to copy it into the SDDM theme (sudo rule: no password for that ONE helper).
#     The helper and the rule are installed by the 19-sddm script (install.sh sddm).  Only that picture can change, nothing else.
#  No wallpaper chosen yet = the login screen uses its dark gradient.
# ============================================================================
set -u
WALL="$HOME/.config/snow/state/wallpaper.current"; OUTD="$HOME/.cache/snow"; OUT="$OUTD/sddm-background.jpg"
HELPER=/usr/local/sbin/snow-sddm-bg
[ -x "$HELPER" ] || { echo "[WARN] login screen helper is missing: run  bash install.sh sddm  inside your Snow folder"; exit 1; }
command -v sudo >/dev/null 2>&1 || { echo "[WARN] sudo is not installed"; exit 1; }
mkdir -p "$OUTD"
if [ -s "$WALL" ]; then
  IM=""; command -v magick >/dev/null 2>&1 && IM=magick; [ -z "$IM" ] && command -v convert >/dev/null 2>&1 && IM=convert
  [ -n "$IM" ] || { echo "[PROBLEM] ImageMagick is not installed (apt package: imagemagick)"; exit 1; }
  "$IM" "${WALL}[0]" -resize 2560x1440^ -gravity center -extent 2560x1440 -blur 0x24 -brightness-contrast -8x0 -modulate 100,90 -quality 90 "$OUT.tmp.jpg" 2>/dev/null \
    && mv -f "$OUT.tmp.jpg" "$OUT" || { rm -f "$OUT.tmp.jpg"; echo "[PROBLEM] ImageMagick could not make the picture"; exit 1; }
  sudo -n "$HELPER" install 2>/dev/null && echo "login screen background updated" || { echo "[WARN] could not install it (sudo rule missing?): run  bash install.sh sddm  inside your Snow folder"; exit 1; }
else
  rm -f "$OUT"; sudo -n "$HELPER" remove 2>/dev/null && echo "no wallpaper: login screen uses the dark gradient" || exit 1
fi
SNOW_FILE_END_4b7d
;;
"s/etc/sddm.conf.d/zz-clock-ring.conf")
cat <<'SNOW_FILE_END_4b7d'
[General]
Numlock=on

[Theme]
Current=clock-ring
SNOW_FILE_END_4b7d
;;
"s/usr/share/sddm/themes/clock-ring/Main.qml")
cat <<'SNOW_FILE_END_4b7d'
import QtQuick 2.15

Item {
    id: root

    // ------------------------- THEME / TUNING -------------------------
    property color ink: config.ink ? config.ink : "#F3EEE3"
    property string wallpaper: config.background ? config.background : ""
    property real dimAlpha: 0.52
    property real blurAmount: 0.65
    property real hourXScale: 0.8
    property real hourSize: 180
    property real hourCenterX: 158        // centre of the big hour text, in design pixels (0 = screen edge, 360 = hours ring)
    property real labelDim: 0.28          // opacity of the ring numbers (05, 10, 15...)
    property string fontFamily: "Montserrat"
    // ------------------------------------------------------------------

    readonly property real u: height / 1189
    readonly property real cx: 22 * u
    readonly property real cy: 585 * u
    readonly property real rm: 133 * u
    focus: true
    Component.onCompleted: forceActiveFocus()

    function pad(n) { return (n < 10 ? "0" : "") + n; }
    readonly property int hour12: (now.getHours() + 11) % 12 + 1        // 1..12
    readonly property string ampm: now.getHours() < 12 ? "AM" : "PM"

    // ---------------------------- time ----------------------------
    property var now: new Date()
    property real nowMs: now.getTime()
    property real lastSec: -1
    // 33ms (~30fps) timer: keeps the seconds ring moving smoothly.
    // Text (HH / MM / SS / date) changes only when the real second changes, so ring and text stay in sync.
    Timer {
        interval: 33; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            root.nowMs = d.getTime()
            var s = Math.floor(d.getTime() / 1000)
            if (s !== root.lastSec) { root.lastSec = s; root.now = d }
        }
    }
    readonly property real nowSec: Math.floor(now.getTime() / 1000) - now.getTimezoneOffset() * 60
    property real secPos: nowMs / 1000 - now.getTimezoneOffset() * 60     // float: moves a little every frame
    property real minPos: nowSec / 60
    property real hourPos: Math.floor(nowSec / 3600)
    Behavior on minPos  { NumberAnimation { duration: 1000 } }
    Behavior on hourPos { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    // ---------------------------- auth state ----------------------------
    property string password: ""
    property string status: ""
    property bool failed: false
    property bool busy: false

    // user and session come from the SDDM lists
    ListView {
        id: users
        model: userModel
        currentIndex: userModel.lastIndex
        width: 10; height: 10; opacity: 0; interactive: false; cacheBuffer: 10000
        delegate: Item { required property string name; width: 1; height: 1 }
    }
    ListView {
        id: sessions
        model: sessionModel
        currentIndex: sessionModel.lastIndex
        width: 10; height: 10; opacity: 0; interactive: false; cacheBuffer: 10000
        delegate: Item { required property string name; width: 1; height: 1 }
    }
    readonly property string userName: users.currentItem ? users.currentItem.name : ""
    readonly property string sessionName: sessions.currentItem ? sessions.currentItem.name : ""

    function submit() {
        if (busy || password === "" || userName === "") return;
        failed = false; busy = true; status = "VERIFYING";
        sddm.login(userName, password, sessions.currentIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false; root.failed = true;
            root.status = "TRY AGAIN"; root.password = "";
        }
        function onLoginSucceeded() { root.status = "WELCOME"; }
    }

    // -------------------------- background --------------------------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#1b1420" }
            GradientStop { position: 1; color: "#141830" }
        }
    }
    Image {
        anchors.fill: parent
        asynchronous: true
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0.035, 0.035, 0.07, root.dimAlpha) }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.30) }
            GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.30) }
        }
    }

    component T: Text {
        color: root.ink
        font.family: root.fontFamily
        antialiasing: true
    }

    // ------------------------------ pill ------------------------------
    Rectangle {
        x: 395 * root.u; y: root.cy - 68 * root.u + 7 * root.u
        width: 498 * root.u; height: 136 * root.u; radius: height / 2
        color: Qt.rgba(0, 0, 0, 0.18)
    }
    Rectangle {
        x: 395 * root.u; y: root.cy - 68 * root.u
        width: 498 * root.u; height: 136 * root.u; radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.10)
        border.width: Math.max(1, 1.5 * root.u)
        border.color: Qt.rgba(1, 1, 1, 0.26)
    }
    Rectangle {
        x: 651 * root.u; y: root.cy - 26 * root.u
        width: Math.max(1, 1.5 * root.u); height: 52 * root.u
        color: Qt.rgba(1, 1, 1, 0.35)
    }

    // ----------------------------- rings -----------------------------
    Ring {   // SECONDS
        x: root.cx; y: root.cy
        count: 60; pos: root.secPos
        radius: 760 * root.u; majorLen: 24 * root.u; minorLen: 9 * root.u
        majorWidth: 3 * root.u; minorWidth: 1.5 * root.u
        labelRadius: 703 * root.u; labelSize: 26 * root.u; hideBand: 1.2
        labelAlpha: root.labelDim
        ink: root.ink; fontFamily: root.fontFamily; minorAlpha: 0.5
    }
    Ring {   // MINUTES
        x: root.cx; y: root.cy
        count: 60; pos: root.minPos
        radius: 519 * root.u; majorLen: 32 * root.u; minorLen: 12 * root.u
        majorWidth: 3 * root.u; minorWidth: 1.5 * root.u
        labelRadius: 454 * root.u; labelSize: 30 * root.u; hideBand: 1.9
        labelAlpha: root.labelDim
        ink: root.ink; fontFamily: root.fontFamily; minorAlpha: 0.55
    }
    Ring {   // HOURS (12h)
        x: root.cx; y: root.cy
        count: 12; pos: root.hourPos
        twelveHour: true
        majorEvery: 3; labelEvery: 1
        radius: 362 * root.u; majorLen: 24 * root.u; minorLen: 12 * root.u
        majorWidth: 3 * root.u; minorWidth: 1.5 * root.u
        labelRadius: 316 * root.u; labelSize: 22 * root.u
        labelAlpha: root.labelDim
        ink: root.ink; fontFamily: root.fontFamily; minorAlpha: 0.45
    }

    component Needle: Item {
        property real r
        property real len
        x: root.cx + r - len; y: root.cy; width: len; height: 0
        Rectangle { y: -height / 2; width: parent.width + 6 * root.u; x: -3 * root.u; height: 9 * root.u; radius: height / 2; color: root.ink; opacity: 0.10 }
        Rectangle { y: -height / 2; width: parent.width; height: 3.2 * root.u; color: root.ink }
    }
    Needle { r: 519 * root.u; len: 32 * root.u }
    Needle { r: 760 * root.u; len: 24 * root.u }
    Needle { r: 362 * root.u; len: 24 * root.u }

    // -------------------- big hour + live MM | SS --------------------
    T {
        text: root.pad(root.hour12)
        font.pixelSize: root.hourSize * root.u
        font.weight: Font.Black
        font.letterSpacing: -3 * root.u
        x: root.hourCenterX * root.u - width * root.hourXScale / 2
        y: root.cy - 0.618 * font.pixelSize
        transform: Scale { origin.x: 0; xScale: root.hourXScale }
    }
    T {   // AM / PM (small, under the hour)
        text: root.ampm
        font.pixelSize: 24 * root.u; font.weight: Font.Bold; font.letterSpacing: 5 * root.u
        opacity: 0.85
        x: root.hourCenterX * root.u - width / 2
        y: root.cy + 0.35 * root.hourSize * root.u + 16 * root.u
    }
    T {
        text: root.pad(root.now.getMinutes())
        font.pixelSize: 38 * root.u; font.weight: Font.Bold
        x: 476 * root.u - width / 2; y: root.cy - height / 2
    }
    T {
        text: root.pad(root.now.getSeconds())
        font.pixelSize: 38 * root.u; font.weight: Font.Bold
        x: 725 * root.u - width / 2; y: root.cy - height / 2
    }

    // ----------------------------- date ------------------------------
    Column {
        x: 1060 * root.u
        y: root.cy - height / 2
        spacing: 12 * root.u
        T {
            text: root.now.toLocaleDateString(Qt.locale("en_US"), "dd MMMM yyyy")
            font.pixelSize: 20 * root.u; font.weight: Font.DemiBold; font.letterSpacing: 5.5 * root.u
            opacity: 0.85
        }
        T {
            text: root.now.toLocaleDateString(Qt.locale("en_US"), "dddd").toUpperCase()
            font.pixelSize: 29 * root.u; font.weight: Font.Black; font.letterSpacing: 9 * root.u
        }
    }

    // ------------------------ top-right controls ------------------------
    // Two small round buttons in the corner. Double click to run (no confirm step, no hover text).
    function power(k) {
        if (k === "restart") sddm.reboot(); else sddm.powerOff();
    }

    component RoundBtn: Item {
        id: btn
        property string kind
        property color hoverColor: root.ink
        readonly property bool hot: ma.containsMouse
        width: 28 * root.u; height: 28 * root.u

        Rectangle {
            anchors.fill: parent; radius: width / 2
            color: btn.hot ? btn.hoverColor : Qt.rgba(1, 1, 1, 0.08)
            border.width: Math.max(1, 1.5 * root.u)
            border.color: btn.hot ? btn.hoverColor : Qt.rgba(1, 1, 1, 0.30)
            Behavior on color { ColorAnimation { duration: 140 } }
        }
        Canvas {
            id: cv
            anchors.fill: parent
            antialiasing: true
            property color stroke: btn.hot ? Qt.rgba(0.08, 0.07, 0.10, 1) : root.ink
            onStrokeChanged: requestPaint()
            onWidthChanged: requestPaint()
            Component.onCompleted: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var c = width / 2, r = width * 0.22;
                ctx.lineWidth = Math.max(1.5, width * 0.07);
                ctx.lineCap = "round"; ctx.lineJoin = "round";
                ctx.strokeStyle = cv.stroke;
                ctx.beginPath();
                if (btn.kind === "poweroff") {
                    ctx.arc(c, c + r * 0.08, r, -Math.PI / 2 + 0.62, -Math.PI / 2 - 0.62 + 2 * Math.PI, false);
                    ctx.moveTo(c, c - r * 1.08);
                    ctx.lineTo(c, c - r * 0.10);
                } else {
                    ctx.arc(c, c, r, -Math.PI / 2 + 0.9, -Math.PI / 2 + 2 * Math.PI, false);
                    var h = r * 0.5;
                    ctx.moveTo(c - h, c - r - h);
                    ctx.lineTo(c, c - r);
                    ctx.lineTo(c - h, c - r + h);
                }
                ctx.stroke();
            }
        }
        MouseArea {
            id: ma
            anchors.fill: parent; anchors.margins: -4 * root.u
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onDoubleClicked: root.power(btn.kind)
        }
    }
    Row {
        id: powerRow
        anchors.right: parent.right; anchors.rightMargin: 22 * root.u
        anchors.top: parent.top;     anchors.topMargin: 22 * root.u
        spacing: 12 * root.u
        RoundBtn { kind: "restart" }
        RoundBtn { kind: "poweroff"; hoverColor: "#E8B4A8" }
    }

    // ------------------------ bottom-right login ------------------------
    T {   // user (click for the next user, if there is more than one)
        text: root.userName.toUpperCase()
        font.pixelSize: 15 * root.u; font.weight: Font.ExtraBold; font.letterSpacing: 5.6 * root.u
        opacity: 0.85
        anchors.right: parent.right; anchors.rightMargin: 22 * root.u - 5.6 * root.u
        anchors.bottom: parent.bottom; anchors.bottomMargin: 105 * root.u
        MouseArea {
            anchors.fill: parent; anchors.margins: -8 * root.u
            enabled: users.count > 1
            cursorShape: users.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: users.currentIndex = (users.currentIndex + 1) % users.count
        }
    }
    T {
        text: root.status !== "" ? root.status
            : (root.password.length > 0 ? "•".repeat(Math.min(root.password.length, 40)) : "TYPE PASSWORD")
        color: root.failed ? "#E8B4A8" : root.ink
        opacity: (root.status !== "" || root.password.length > 0) ? 0.95 : 0.5
        font.pixelSize: 15 * root.u; font.weight: Font.DemiBold; font.letterSpacing: 5.6 * root.u
        anchors.right: parent.right; anchors.rightMargin: 22 * root.u - 5.6 * root.u
        anchors.bottom: parent.bottom; anchors.bottomMargin: 60 * root.u
    }
    T {   // session (click for the next session)
        text: root.sessionName.toUpperCase()
        font.pixelSize: 12 * root.u; font.weight: Font.DemiBold; font.letterSpacing: 4.5 * root.u
        opacity: 0.55
        anchors.right: parent.right; anchors.rightMargin: 22 * root.u - 4.5 * root.u
        anchors.bottom: parent.bottom; anchors.bottomMargin: 22 * root.u
        MouseArea {
            anchors.fill: parent; anchors.margins: -8 * root.u
            enabled: sessions.count > 1
            cursorShape: sessions.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: sessions.currentIndex = (sessions.currentIndex + 1) % sessions.count
        }
    }

    // ----------------------------- keyboard -----------------------------
    Keys.onPressed: event => {
        const k = event.key;
        const ctrl = event.modifiers & Qt.ControlModifier;
        if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            root.submit();
        } else if (k === Qt.Key_Escape || (ctrl && k === Qt.Key_U)) {
            root.password = ""; root.status = ""; root.failed = false;
        } else if (k === Qt.Key_Backspace) {
            if (!root.busy) { root.password = root.password.slice(0, -1); root.status = ""; }
        } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32
                   && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
            if (root.busy) { event.accepted = true; return; }
            root.status = ""; root.failed = false;
            root.password += event.text;
        }
        event.accepted = true;
    }
}
SNOW_FILE_END_4b7d
;;
"s/usr/share/sddm/themes/clock-ring/Ring.qml")
cat <<'SNOW_FILE_END_4b7d'
import QtQuick 2.15

// One dial. Ticks/numerals live on a circle around (0,0); the container is rotated
// so that `pos` sits at 3 o'clock (values grow clockwise).
Item {
    id: ring
    required property int count
    property real pos: 0
    property real radius: 100
    property real majorLen: 20
    property real minorLen: 8
    property real majorWidth: 3
    property real minorWidth: 1.5
    property int majorEvery: 5
    property int labelEvery: 5
    property real labelRadius: 60
    property real labelSize: 20
    property real labelAlpha: 0.9
    property real hideBand: 0.5
    property real minorAlpha: 0.55
    property bool twelveHour: false     // numbers 12, 01, 02 ... 11 instead of 00, 01 ... 
    property color ink: "white"
    property string fontFamily: "Montserrat"
    width: 0; height: 0

    Item {
        width: 0; height: 0
        rotation: -(((ring.pos % ring.count) + ring.count) % ring.count) * 360 / ring.count
        Repeater {
            model: ring.count
            delegate: Item {
                id: slot
                required property int index
                readonly property bool major: index % ring.majorEvery === 0
                rotation: index * 360 / ring.count
                Rectangle {
                    x: ring.radius - width
                    y: -height / 2
                    width: slot.major ? ring.majorLen : ring.minorLen
                    height: slot.major ? ring.majorWidth : ring.minorWidth
                    color: ring.ink
                    opacity: slot.major ? 0.92 : ring.minorAlpha
                    antialiasing: true
                }
                Text {
                    readonly property real p: ((ring.pos % ring.count) + ring.count) % ring.count
                    readonly property real dist: ((slot.index - p + 1.5 * ring.count) % ring.count) - ring.count / 2
                    visible: slot.index % ring.labelEvery === 0
                    text: { var n = (ring.twelveHour && slot.index === 0) ? 12 : slot.index; return (n < 10 ? "0" : "") + n }
                    x: ring.labelRadius - width / 2
                    y: -height / 2
                    color: ring.ink
                    opacity: ring.labelAlpha * Math.max(0, Math.min(1, (Math.abs(dist) - ring.hideBand) / 0.5))
                    font.family: ring.fontFamily
                    font.pixelSize: ring.labelSize
                    font.weight: Font.Bold
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"s/usr/share/sddm/themes/clock-ring/metadata.desktop")
cat <<'SNOW_FILE_END_4b7d'
[SddmGreeterTheme]
Name=clock-ring
Description=clock ring login
Author=
Type=sddm-theme
Version=1.0
MainScript=Main.qml
ConfigFile=theme.conf
Theme-Id=clock-ring
Theme-API=2.0
QTVersion=6
QtVersion=6
SNOW_FILE_END_4b7d
;;
"s/usr/share/sddm/themes/clock-ring/theme.conf")
cat <<'SNOW_FILE_END_4b7d'
[General]
background=background.jpg
ink=#F3EEE3
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
extra_check() {
CNT=$(grep -rn '^[[:space:]]*Current=' /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null | grep -c .)
[ "$CNT" = 1 ] && pass "exactly one active Current= line" || fail "$CNT active Current= lines (expected 1)" "bash ~/Snow/Script/17-sddm.sh"
[ "$(systemctl is-enabled sddm.service 2>/dev/null)" = enabled ] && pass "sddm.service is enabled" || fail "sddm.service is not enabled" "sudo systemctl enable -f sddm.service"
[ -f /usr/share/wayland-sessions/hyprland.desktop ] && pass "Hyprland session file found" || warn "no /usr/share/wayland-sessions/hyprland.desktop" "bash ~/Snow/Script/03-hyprland.sh"
[ -x /usr/local/sbin/snow-sddm-bg ] && pass "login background helper installed" || warn "login background helper is missing (the login screen cannot follow the wallpaper)" "bash ~/Snow/Script/17-sddm.sh"
if have sudo; then sudo -n /usr/local/sbin/snow-sddm-bg probe >/dev/null 2>&1; [ $? = 2 ] && pass "sudo rule for the login background helper works" || warn "sudo rule for the login background helper is missing" "bash ~/Snow/Script/17-sddm.sh"; fi
[ -f "$BIN/sddm/sddm-bg.sh" ] && bash -n "$BIN/sddm/sddm-bg.sh" && pass "sddm-bg.sh: syntax ok" || warn "sddm-bg.sh missing or broken" "bash ~/Snow/Script/17-sddm.sh"
}
CUSTOM_RUN=run_sddm
run_sddm() {
# 60-sddm : login screen theme "clock-ring" (3-dial clock, date, password line, restart + power-off buttons). Takes effect at the next boot / logout.
step "17 sddm: login screen theme clock-ring"
T=/usr/share/sddm/themes/clock-ring; CONF_D=/etc/sddm.conf.d; OURS="$CONF_D/zz-clock-ring.conf"
apt_install sddm qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-window qml6-module-qtquick-layouts fonts-montserrat imagemagick
asroot mkdir -p "$T" "$CONF_D"
for f in Main.qml Ring.qml metadata.desktop theme.conf; do payload_sys "usr/share/sddm/themes/clock-ring/$f" "$T/$f"; [ $? = 1 ] && fail "could not install $f"; done
# login background follows the wallpaper: ONE small root helper + ONE sudo rule that allows only that helper without a password
HLP=/usr/local/sbin/snow-sddm-bg; HT="$(mktemp)"
cat > "$HT" <<'SNOW_HELPER_END'
#!/bin/sh
# snow-sddm-bg : tiny root helper of the Snow desktop. It ONLY copies the blurred login picture that the user prepared
# (~/.cache/snow/sddm-background.jpg) into the SDDM theme folder, or removes it. It does nothing else.
#   sudo snow-sddm-bg install | remove      (the user may run it without a password: /etc/sudoers.d/snow-sddm-bg)
T=/usr/share/sddm/themes/clock-ring
U="${SUDO_USER:-}"; [ -n "$U" ] && [ "$U" != root ] || exit 1
case "${1:-install}" in
  remove) [ -d "$T" ] && rm -f "$T/background.jpg"; exit 0 ;;
  install) ;;
  *) exit 2 ;;
esac
H=$(getent passwd "$U" | cut -d: -f6); [ -n "$H" ] || exit 1
[ -d "$T" ] || exit 1
TMP=$(mktemp) || exit 1
trap 'rm -f "$TMP"' EXIT
# read the user's file without following a symlink; at most 20 MB
dd if="$H/.cache/snow/sddm-background.jpg" of="$TMP" iflag=nofollow bs=1M count=21 status=none 2>/dev/null || exit 1
[ "$(stat -c %s "$TMP")" -le 20000000 ] || exit 1
[ "$(head -c 3 "$TMP" | od -An -tx1 | tr -d ' \n')" = ffd8ff ] || exit 1      # must be a JPEG
install -m 644 "$TMP" "$T/background.jpg"
SNOW_HELPER_END
if cmp -s "$HT" "$HLP" 2>/dev/null; then pass "login background helper already in place"; else asroot install -m 755 -o root -g root "$HT" "$HLP" && pass "login background helper installed: $HLP" || fail "could not install $HLP"; fi
rm -f "$HT"
if have sudo && have visudo; then
  ST="$(mktemp)"; echo "$(id -un) ALL=(root) NOPASSWD: $HLP" > "$ST"
  if asroot visudo -cf "$ST" >/dev/null 2>&1; then asroot install -m 440 -o root -g root "$ST" /etc/sudoers.d/snow-sddm-bg && pass "sudo rule installed (only for $HLP)" || fail "could not install /etc/sudoers.d/snow-sddm-bg"; else fail "sudo rule text was not accepted by visudo: nothing installed"; fi
  rm -f "$ST"
else warn "sudo / visudo missing: the login background cannot follow the wallpaper"; fi
write_items
bash "$BIN/sddm/sddm-bg.sh" && pass "login screen background updated from your wallpaper (or dark gradient when none)" || warn "login screen background not made yet (see the message above)"
[ -f "$T/Main.qml" ] && [ -f "$T/Ring.qml" ] && pass "theme installed in $T" || fail "theme files missing in $T"
# only one active Current= line: ours (last file wins); other files are backed up and commented out
for f in /etc/sddm.conf $CONF_D/*.conf; do
  [ -f "$f" ] || continue; [ "$f" = "$OURS" ] && continue
  if grep -Eq '^[[:space:]]*Current=' "$f"; then
    asroot mkdir -p "$BKROOT/root$(dirname "$f")" && asroot cp -a "$f" "$BKROOT/root$f" && asroot chown -R "$(id -un)" "$BKROOT" && asroot sed -i -E 's/^([[:space:]]*Current=)/#\1/' "$f" && pass "commented out Current= in $f (backup: ${BKROOT/#$HOME/~}/root$f)" || fail "could not edit $f"
  fi
done
payload_sys etc/sddm.conf.d/zz-clock-ring.conf "$OURS"; [ $? = 1 ] && fail "could not write $OURS" || pass "$OURS is in place"
CNT=$(grep -rn '^[[:space:]]*Current=' /etc/sddm.conf $CONF_D/*.conf 2>/dev/null | grep -c .)
[ "$CNT" = 1 ] && pass "exactly one active Current= line" || fail "$CNT active Current= lines (expected 1)"
[ "$(systemctl is-enabled sddm.service 2>/dev/null)" = enabled ] && pass "sddm.service is enabled" || { asroot systemctl enable -f sddm.service >/dev/null 2>&1 && pass "sddm.service enabled (login screen from the next boot)" || warn "could not enable sddm.service"; }
[ -f /usr/share/wayland-sessions/hyprland.desktop ] && pass "Hyprland session file found" || warn "no /usr/share/wayland-sessions/hyprland.desktop: install hyprland (Script/03-hyprland.sh)"
summary "$MOD"

}
component_main "$@"
