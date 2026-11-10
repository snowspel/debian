#!/usr/bin/env bash
# 08-power-menu.sh : Panel: power menu + idle/lock
# Super+Esc power menu, screen lock, idle timers (hypridle), clean-up helper. Settings: power.json.
#   bash Script/08-power-menu.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/08-power-menu.sh check    read-only check
MOD="08-power-menu"; TITLE="Panel: power menu + idle/lock"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/quickshell/snow/powermenu/PowerMenu.qml|644|0"
  "u|.config/snow/bin/power/cleanup.sh|755|0"
  "u|.config/snow/bin/power/idle.sh|755|0"
  "u|.config/snow/bin/power/lock.sh|755|0"
  "u|.config/snow/bin/power/power.sh|755|0"
  "u|.config/snow/state/power.json|644|1"
)
emit() {
case "$1" in
"u/.config/quickshell/snow/powermenu/PowerMenu.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  PowerMenu.qml  —  POWER MENU  (Super+Escape)
// ----------------------------------------------------------------------------
//  DIKHTA KYA HAI : Screen ke upar-beech me SIRF EK gol icon. Koi text, koi arrow nahi.
//  KAISE CHALTA HAI:
//     - Khulte hi icon = "Shut down". Enter dabao = PC band.
//     - Left / Right key YA mouse ka wheel (icon ke upar) = Restart / Log out badalta hai.
//     - Icon par click ya Enter = chalao.   Esc ya bahar click = band.
//  KAAM KAUN KARTA HAI : ~/.config/snow/bin/power/power.sh  (power.sh do shutdown|restart|logout)
//  KHOLNE KI KEY : ~/.config/hypr/snow-panel-keys.lua me "SUPER + Escape" (wahan se badlo).
//  BADLO (SETTINGS) : circleSize, topGap neeche.
// ============================================================================
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core

Scope {
    id: root

    // ---------------- SETTINGS (yahan badlo) ----------------
    readonly property int circleSize: 84      // gol icon ki size
    readonly property int topGap: 48          // screen ke upar se doori

    // ---------------- haalat ----------------
    property bool open: false                 // menu khula hai?
    property int cur: 0                       // 0 = Shut down, 1 = Restart, 2 = Log out
    property int wheelAcc: 0                  // mouse wheel ka jodh (ek step = 120)
    property bool single: false               // true = sirf "Shut down" (badla nahi ja sakta)

    readonly property string home: Quickshell.env("HOME")
    readonly property string powerSh: home + "/.config/snow/bin/power/power.sh"

    // 3 kaam. Naya kaam jodna ho to yahan ek line badhao (power.sh me bhi uska "do" kaam chahiye).
    readonly property var modes: [
        { id: "shutdown", icon: Icons.power },
        { id: "restart",  icon: Icons.restart },
        { id: "logout",   icon: Icons.logout }
    ]

    function step(d: int): void {
        if (single) return
        cur = (cur + d + modes.length) % modes.length
    }

    function dismiss(): void { open = false }

    function run(id: string): void {
        dismiss()
        Quickshell.execDetached(["bash", powerSh, "do", id])
    }

    onOpenChanged: if (open) { cur = 0; wheelAcc = 0 }       // har baar Shut down se shuru

    // bahar se kholne-band karne ke commands (hyprland key inhe chalati hai)
    IpcHandler {
        target: "power"
        function toggle(): void { if (root.open) root.dismiss(); else { root.single = false; root.open = true } }
        function show(): void { root.single = false; root.open = true }
        function ask(): void { root.single = true; root.open = true }
        function hide(): void { root.dismiss() }
    }

    PanelWindow {
        id: win
        visible: root.open
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }     // poori screen (bahar click pakadne ke liye)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "snow-power"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // keyboard focus kabhi kabhi der se milta hai, isliye 80ms baad dobara maangte hain
        onVisibleChanged: if (visible) { keys.forceActiveFocus(); focusTimer.restart() }
        Timer { id: focusTimer; interval: 80; onTriggered: keys.forceActiveFocus() }

        Item {
            id: keys
            anchors.fill: parent
            focus: true

            // ---- keyboard ----
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    root.dismiss(); event.accepted = true
                } else if (event.key === Qt.Key_Left) {
                    root.step(-1); event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    root.step(1); event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.run(root.modes[root.cur].id); event.accepted = true
                }
            }

            // bahar kahin bhi click = band
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: root.dismiss()
            }

            // ---------- wo EK gol icon ----------
            Rectangle {
                antialiasing: true
                id: circle
                width: root.circleSize
                height: root.circleSize
                radius: width / 2
                y: root.topGap
                anchors.horizontalCenter: parent.horizontalCenter
                color: Qt.alpha(Theme.surface, circleArea.containsMouse ? 0.95 : 0.88)
                border.width: 1
                border.color: Theme.hairline
                scale: circleArea.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: 90 } }
                Behavior on color { ColorAnimation { duration: Theme.hoverMs } }

                // halki parchhai
                Rectangle { antialiasing: true; z: -1; x: -4; y: 0; width: parent.width + 8; height: parent.height + 8; radius: width / 2; color: Qt.rgba(0, 0, 0, 0.07) }

                // hover par accent ka halka gola
                Rectangle {
                    antialiasing: true
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.alpha(Theme.accent, 0.14)
                    opacity: circleArea.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.hoverMs } }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.modes[root.cur].icon
                    font.family: Theme.iconFont
                    font.pixelSize: 40
                    // Shut down par mouse aaye to icon laal
                    color: circleArea.containsMouse && root.modes[root.cur].id === "shutdown" ? Theme.danger : Theme.text
                }

                MouseArea {
                    id: circleArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.run(root.modes[root.cur].id)
                    onWheel: (wheel) => {
                        root.wheelAcc += wheel.angleDelta.y
                        if (root.wheelAcc >= 120) { root.step(-1); root.wheelAcc = 0 }
                        else if (root.wheelAcc <= -120) { root.step(1); root.wheelAcc = 0 }
                        wheel.accepted = true
                    }
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/power/cleanup.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  cleanup.sh  —  EK-CLICK SAFAI  (Power card -> Clean-up)
# ----------------------------------------------------------------------------
#  SABSE PEHLE sab kuch DIKHATA hai. Tum Enter dabaoge tabhi kuch hoga (Ctrl+C = cancel).
#  KYA KARTA HAI:
#    1) Hataye gaye programs (KDE, old bars and launchers ...) ke bache hue config folders -> TRASH FOLDER me MOVE
#       (~/.local/share/snow-cleanup-trash/<time>) — delete nahi, wapas rakh sakte ho. 30 din baad purane trash folder hatte hain.
#    2) Caches (thumbnails, pip, shader cache ...) aur system Trash saaf
#    3) Purane journal logs (14 din se purane), apt download cache
#    4) Unused packages — SIRF tab jab list me koi system-jaisa package na ho (NVIDIA/GLX/kernel/hypr/quickshell ...).
#       Plain "apt autoremove" KABHI nahi chalta: sirf wahi exact packages jo tumne preview me dekhe.
#  NAYA FOLDER LIST ME JODNA HO: neeche LEFT=( ... ) me ek line badhao.
# ============================================================================
set -u
B=$'\e[1m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; N=$'\e[0m'
say()  { printf '%s\n' "$*"; }
size() { du -sh "$1" 2>/dev/null | cut -f1; }
TRASH="$HOME/.local/share/snow-cleanup-trash/$(date +%Y%m%d-%H%M%S)"

# ---- hataye gaye programs ke bache folders (sirf ye hi MOVE hote hain) ----
LEFT=(
  "$HOME/.config/kdeglobals" "$HOME/.config/kwinrc" "$HOME/.config/kwinrulesrc" "$HOME/.config/plasmarc" "$HOME/.config/plasma-localerc"
  "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "$HOME/.config/powerdevilrc" "$HOME/.config/systemsettingsrc" "$HOME/.config/kded5rc" "$HOME/.config/kded6rc"
  "$HOME/.config/dolphinrc" "$HOME/.config/kwalletrc" "$HOME/.config/baloofilerc" "$HOME/.config/kscreenlockerrc" "$HOME/.config/ksplashrc" "$HOME/.config/kcminputrc"
  "$HOME/.local/share/dolphin" "$HOME/.local/share/kwin" "$HOME/.local/share/plasma" "$HOME/.local/share/kscreen" "$HOME/.local/share/baloo" "$HOME/.local/share/kded6" "$HOME/.local/share/kded5"
  "$HOME/.cache/plasmashell" "$HOME/.cache/kwin" "$HOME/.cache/ksycoca6_en_US" "$HOME/.cache/baloo"
  "$HOME/.config/vim" "$HOME/.vim" "$HOME/.viminfo" "$HOME/.config/zutty" "$HOME/.config/dunst" "$HOME/.config/mako" "$HOME/.config/waybar" "$HOME/.config/wofi" "$HOME/.config/rofi"
)
# ---- caches (ye phir apne aap ban jaate hain) ----
CACHE=("$HOME/.cache/thumbnails" "$HOME/.cache/pip" "$HOME/.cache/fontconfig" "$HOME/.cache/mesa_shader_cache" "$HOME/.cache/qtshadercache-x86_64-little_endian-lp64" "$HOME/.cache/qmlcache")

# in naamon wala package hum kabhi nahi hatate (system toot sakta hai)
PROT='nvidia|glx|linux-image|linux-headers|firmware|hypr|quickshell|sddm|pipewire|wireplumber|mesa|network|bluez|polkit|systemd|libc6|xorg|wayland|qt6|qml|cuda|nvcuvid|nvenc|libgl|libegl|libdrm|libgbm|vulkan|flatpak|gvfs|thunar|libva|libvdpau|dbus|grub|initramfs|dkms|mpv|kitty'

say "${B}Snow clean-up${N}"
say "Nothing is changed before you press Enter."; say

# ---------------- PREVIEW ----------------
say "${B}1) Leftover folders (will be MOVED -> $TRASH)${N}"
FOUND=()
for p in "${LEFT[@]}"; do [ -e "$p" ] && FOUND+=("$p"); done
if [ "${#FOUND[@]}" -eq 0 ]; then say "   nothing found"; else for p in "${FOUND[@]}"; do say "   $(size "$p")  $p"; done; fi

say; say "${B}2) Caches and junk${N}"
for p in "${CACHE[@]}"; do [ -e "$p" ] && say "   $(size "$p")  $p"; done
[ -d "$HOME/.local/share/Trash" ] && say "   $(size "$HOME/.local/share/Trash")  Trash"
say "   old journal logs (older than 14 days), apt download cache, unused Flatpak runtimes"

say; say "${B}3) Unused packages${N}"
APT=0; LIST=""; RC=""
if command -v apt-get >/dev/null 2>&1; then
  LIST=$(apt-get -s autoremove --purge 2>/dev/null | awk '/^Purg /{print $2}')
  if [ -z "$LIST" ]; then say "   nothing to remove"
  elif printf '%s\n' "$LIST" | grep -Eqi "$PROT"; then
    say "   ${Y}This list contains system-like packages, so the package clean-up is SKIPPED for safety:${N}"
    printf '%s\n' "$LIST" | sed 's/^/     /'
    say "   (Check this list before you continue.)"
  else
    say "   will be removed: $(printf '%s' "$LIST" | tr '\n' ' ')"; APT=1
  fi
  RC=$(dpkg -l 2>/dev/null | awk '/^rc/{print $2}' | grep -Evi "$PROT" | tr '\n' ' ')
  RCSKIP=$(dpkg -l 2>/dev/null | awk '/^rc/{print $2}' | grep -Ei "$PROT" | tr '\n' ' ')
  [ -n "$RCSKIP" ] && say "   ${Y}leftover settings of system-like packages are kept:${N} $RCSKIP"
  [ -n "$RC" ] && say "   leftover settings of removed packages (will be purged): $RC"
fi

say; printf '%s' "${B}Press Enter to clean up, Ctrl+C to cancel: ${N}"; read -r _

# ---------------- KAAM ----------------
BEFORE=$(df --output=avail -B1 "$HOME" | tail -1)

if [ "${#FOUND[@]}" -gt 0 ]; then
  mkdir -p "$TRASH"
  for p in "${FOUND[@]}"; do
    mv -- "$p" "$TRASH/$(printf '%s' "${p#"$HOME"/}" | tr '/' '_')" 2>/dev/null && say "${G}[PASS]${N} moved $p" || say "${R}[FAIL]${N} could not move: $p"
  done
  say "       (to get them back, look here: $TRASH)"
fi
for p in "${CACHE[@]}"; do [ -e "$p" ] && rm -rf "$p" && say "${G}[PASS]${N} cache cleaned: $p"; done
[ -d "$HOME/.local/share/Trash" ] && { rm -rf "$HOME/.local/share/Trash/files" "$HOME/.local/share/Trash/info" 2>/dev/null; say "${G}[PASS]${N} Trash emptied"; }
# 30 din se purane clean-up trash folders hatao
find "$HOME/.local/share/snow-cleanup-trash" -mindepth 1 -maxdepth 1 -mtime +30 -exec rm -rf {} + 2>/dev/null
command -v flatpak >/dev/null 2>&1 && { flatpak uninstall --unused -y >/dev/null 2>&1 && say "${G}[PASS]${N} unused Flatpak runtimes removed" || say "${Y}[WARN]${N} flatpak: skip"; }

if command -v sudo >/dev/null 2>&1; then
  say; say "Admin password may be asked (for apt and logs):"
  if sudo -v; then
    sudo journalctl --vacuum-time=14d >/dev/null 2>&1 && say "${G}[PASS]${N} old journal logs removed"
    sudo apt-get clean && say "${G}[PASS]${N} apt cache cleaned"
    if [ "$APT" = 1 ]; then
      # list wahi honi chahiye jo preview me dikhi thi, aur usme koi protected naam na ho
      NOW=$(apt-get -s autoremove --purge 2>/dev/null | awk '/^Purg /{print $2}')
      if [ "$NOW" = "$LIST" ] && ! printf '%s\n' "$NOW" | grep -Eqi "$PROT"; then
        # plain autoremove nahi: sirf wahi exact packages
        # shellcheck disable=SC2086
        sudo apt-get purge -y $LIST >/dev/null 2>&1 && say "${G}[PASS]${N} unused packages removed" || say "${R}[FAIL]${N} package purge fail"
      else
        say "${Y}[WARN]${N} the list changed after the preview: package clean-up SKIPPED"
      fi
    fi
    # shellcheck disable=SC2086
    [ -n "${RC:-}" ] && { sudo dpkg --purge $RC >/dev/null 2>&1 && say "${G}[PASS]${N} leftover settings purged"; }
  else
    say "${Y}[WARN]${N} no admin rights: the system part is skipped"
  fi
fi

AFTER=$(df --output=avail -B1 "$HOME" | tail -1)
say; say "${B}Done.${N} About $(( (AFTER - BEFORE) / 1048576 )) MB of space freed."

say; say "${B}You can check these folders in ~/.config yourself (they were not touched):${N}"
for d in "$HOME"/.config/*/; do
  n=$(basename "$d")
  case "$n" in snow|hypr|quickshell|kitty|mpv|gtk-*|pulse|imv|Thunar|xfce4*|dconf|fcitx*|systemd|autostart|xdg-desktop-portal|user-dirs*|BraveSoftware|Mousepad|mousepad|xarchiver|LocalSend|cef_user_data|flatpak|wireplumber|pipewire|gtk|Code|menus|procps|glib-2.0|ibus|fontconfig|environment.d|gnome|gvfs|enchant) continue ;; esac
  command -v "$n" >/dev/null 2>&1 && continue
  say "   $n  ($(size "$d"))"
done
say; printf 'Press Enter to close. '; read -r _
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/power/idle.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  idle.sh  —  PURANA NAAM (sirf power.sh ko aage bhejta hai)
# ----------------------------------------------------------------------------
#  Purani Hyprland autostart / settings "idle.sh" bulati ho to wo bhi chale — isliye ye rakhi hai.
#  Asli kaam power.sh karta hai:  idle.sh set <key> <min> | gen | start | status
# ============================================================================
exec bash "$HOME/.config/snow/bin/power/power.sh" "$@"
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/power/lock.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  lock.sh  —  LOCK SCREEN (hyprlock) KA CONFIG BANANA + SCREEN LOCK KARNA
# ----------------------------------------------------------------------------
#  lock.sh gen   ~/.config/hypr/hyprlock.conf banata hai THEME ke rangon se (theme.json se)
#  lock.sh now   screen abhi lock karo
#  BACKGROUND    : abhi ka wallpaper (~/.config/snow/state/wallpaper.current) BLUR hoke lock screen par aata hai.
#                  Wallpaper nahi chuna ho to sada kala/theme rang. wallpaper.sh har naya wallpaper lagane par "lock.sh gen" chalata hai.
#  theme.sh har theme badalne ke baad "lock.sh gen" khud chalata hai — hyprlock.conf haath se mat badlo.
#  LOOK BADLNA HO: neeche CONF ke andar ke numbers (font_size, size, rounding) badlo, phir  lock.sh gen  chalao.
# ============================================================================
set -u
TJ="$HOME/.config/snow/state/theme.json"
OUT="$HOME/.config/hypr/hyprlock.conf"
WP="$HOME/.config/snow/state/wallpaper.current"
BLUR_PASSES=3      # BADLO: blur kitna (1 halka ... 4 bahut)
BLUR_SIZE=8
BRIGHTNESS=0.65    # BADLO: 1.0 = asli roshni, kam = thoda gehra (clock saaf dikhe)

# wallpaper ko sahi extension (png/jpg/webp) wale link se do: hyprlock extension dekhta hai. Na mile to khali (sada rang)
bgpath() {
  local magic ext=""
  rm -f "$HOME"/.config/snow/state/lock-bg.* 2>/dev/null
  [ -s "$WP" ] || return 1
  magic=$(head -c 12 "$WP" | od -An -tx1 | tr -d ' \n')
  case "$magic" in
    89504e47*) ext=png ;;
    ffd8ff*) ext=jpg ;;
    52494646????????57454250) ext=webp ;;
  esac
  [ -n "$ext" ] || return 1
  ln -sf "$WP" "$HOME/.config/snow/state/lock-bg.$ext" && echo "$HOME/.config/snow/state/lock-bg.$ext"
}

# theme.json se ek rang padho, '#' hata ke (hyprlock ko rgb(RRGGBB) chahiye)
col() { jq -r ".$1 // empty" "$TJ" 2>/dev/null | tr -d '#'; }

case "${1:-gen}" in
  now) pidof hyprlock >/dev/null 2>&1 || { bash "$0" gen >/dev/null 2>&1; exec hyprlock; } ;;
  gen)
    command -v jq >/dev/null 2>&1 || { echo "[WARN] jq is not installed, hyprlock.conf was not created"; exit 0; }
    [ -s "$TJ" ] || { echo "[WARN] theme.json is missing, hyprlock.conf was not created"; exit 0; }
    bg=$(col bg); surf=$(col surface); text=$(col text); muted=$(col muted); acc=$(col accent); dan=$(col danger); ok=$(col success)
    # kuch khali ho to ye default rang
    : "${bg:=14161b}" "${surf:=1b1e25}" "${text:=e6e8ee}" "${muted:=8b91a1}" "${acc:=d4af37}" "${dan:=e0625f}" "${ok:=5fba7d}"
    mkdir -p "$(dirname "$OUT")"
    img=$(bgpath) || img=""
    if [ -n "$img" ]; then
      BGLINES="    path = $img
    blur_passes = $BLUR_PASSES
    blur_size = $BLUR_SIZE
    brightness = $BRIGHTNESS
    vibrancy = 0.15"
    else BGLINES="    # (wallpaper nahi mila: sada rang)"; fi
    cat > "$OUT" <<CONF
# lock.sh ne theme.json se banayi — haath se mat badlo: theme badlo.
general {
    hide_cursor = true
    ignore_empty_input = true
}

background {
    monitor =
$BGLINES
    color = rgb($bg)
}

# bada samay (12-ghante, jaise 3:20)
label {
    monitor =
    text = cmd[update:1000] date +%-I:%M
    color = rgb($text)
    font_size = 96
    font_family = Inter
    position = 0, 160
    halign = center
    valign = center
}

# tareekh
label {
    monitor =
    text = cmd[update:60000] date "+%A, %d %B"
    color = rgb($muted)
    font_size = 18
    font_family = Inter
    position = 0, 80
    halign = center
    valign = center
}

# password box
input-field {
    monitor =
    size = 280, 52
    rounding = 26
    outline_thickness = 2
    outer_color = rgb($acc)
    inner_color = rgb($surf)
    font_color = rgb($text)
    check_color = rgb($ok)
    fail_color = rgb($dan)
    font_family = Inter
    placeholder_text = <span foreground="##$muted">Password</span>
    fail_text = <span foreground="##$dan">Wrong password</span>
    dots_size = 0.25
    dots_spacing = 0.3
    dots_center = true
    fade_on_empty = false
    hide_input = false
    position = 0, -20
    halign = center
    valign = center
}
CONF
    echo "lock: $OUT likh di" ;;
  *) echo "usage: lock.sh gen | now"; exit 2 ;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/power/power.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  power.sh  —  POWER KE SAARE KAAM (shutdown, sleep, lock, idle timers) + JAANCH (diag/test)
# ----------------------------------------------------------------------------
#  USE :
#     power.sh do <kaam>          kaam = shutdown | restart | logout | sleep | lock | screenoff | screenon | cleanup
#     power.sh set <key> <min>    idle timer badlo. key = screenOff | lock | sleep.  min = 0 matlab "kabhi nahi"
#     power.sh gen                ~/.config/hypr/hypridle.conf banao (power.json se)
#     power.sh start              gen + hypridle dobara chalu (Hyprland start par apne aap)
#     power.sh status             abhi ke timers dikhao
#     power.sh diag               timer kyun nahi chal raha? — sab kuch jaanch ke dikhata hai (full output, useful for troubleshooting)
#     power.sh test               8-second idle test (12 sec mouse/keyboard ko haath mat lagao)
#  FILES :
#     ~/.config/snow/state/power.json         timers yahan save hote hain  {"screenOff":0,"lock":0,"sleep":0}
#     ~/.config/hypr/hypridle.conf      GENERATED — haath se mat badlo (power.json badlo)
#  LOGS (kuch na chale to yahan dekho):
#     ~/.cache/snow-power.log           har kaam ka record (kya chala, dpms theek hua ya nahi)
#     ~/.cache/snow-hypridle.log        hypridle ka apna output
#  SCREEN OFF : sach me band hui ya nahi, ye "hyprctl monitors -j" se verify hota hai; 3 alag syntax try hote hain.
#  KHUL JAANA : "screen off" ke baad mouse/key se wapas on (on-resume = screenon).
#  QML (PowerMenu / PowerPanel) isi script ko chalate hain.
# ============================================================================
set -u

CONF_DIR="$HOME/.config/snow"
CONF="$CONF_DIR/state/power.json"
IDLE_CONF="$HOME/.config/hypr/hypridle.conf"
SELF="$CONF_DIR/bin/power/power.sh"
LOG="$HOME/.cache/snow-power.log"
IDLE_LOG="$HOME/.cache/snow-hypridle.log"
mkdir -p "$HOME/.cache"

# ~/.cache/snow-power.log me ek line likho
log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG"; }

# make sure hyprctl / hyprlock can find the running Hyprland even if we were started oddly
# Hyprland ke environment variables na mile to dhundh lo (script alag se chali ho tab bhi hyprctl kaam kare)
ensure_env() {
  : "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"; export XDG_RUNTIME_DIR
  if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -d "$XDG_RUNTIME_DIR/hypr" ]; then
    local d
    d=$(ls -1t "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -1)
    [ -n "$d" ] && export HYPRLAND_INSTANCE_SIGNATURE="$d"
  fi
  if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    local s
    s=$(cd "$XDG_RUNTIME_DIR" 2>/dev/null && ls -1 wayland-[0-9]* 2>/dev/null | grep -v '\.lock$' | head -1)
    [ -n "$s" ] && export WAYLAND_DISPLAY="$s"
  fi
}

# sirf screenOff / lock / sleep maanya
valid_key() { case "$1" in screenOff|lock|sleep) return 0 ;; *) return 1 ;; esac; }

# power.json na ho to sab "Never" (0) ke saath bana do
ensure_conf() {
  mkdir -p "$CONF_DIR"
  if [ ! -s "$CONF" ]; then
    printf '{\n  "screenOff": 0,\n  "lock": 0,\n  "sleep": 0\n}\n' > "$CONF"
  fi
}

# json se ek timer (minute) padho; gadbad ho to 0
get_min() {
  local v
  v=$(jq -r --arg k "$1" '.[$k] // 0' "$CONF" 2>/dev/null)
  case "$v" in ''|*[!0-9]*) v=0 ;; esac
  echo "$v"
}

# power.json -> hypridle.conf
gen() {
  command -v jq >/dev/null 2>&1 || { echo "[PROBLEM] jq is not installed"; return 1; }
  ensure_conf
  local s l z tmp
  s=$(get_min screenOff); l=$(get_min lock); z=$(get_min sleep)
  mkdir -p "$(dirname "$IDLE_CONF")"
  tmp="$IDLE_CONF.snow-tmp"
  {
    echo "# generated by power.sh from ~/.config/snow/state/power.json - do not edit by hand"
    echo "general {"
    echo "    lock_cmd = pidof hyprlock || hyprlock"
    echo "    before_sleep_cmd = loginctl lock-session"
    echo "}"
    if [ "$s" -gt 0 ]; then
      printf '\nlistener {\n    timeout = %s\n    on-timeout = bash %s do screenoff\n    on-resume = bash %s do screenon\n}\n' "$((s * 60))" "$SELF" "$SELF"
    fi
    if [ "$l" -gt 0 ]; then
      printf '\nlistener {\n    timeout = %s\n    on-timeout = bash %s do lock\n}\n' "$((l * 60))" "$SELF"
    fi
    if [ "$z" -gt 0 ]; then
      printf '\nlistener {\n    timeout = %s\n    on-timeout = bash %s do sleep\n}\n' "$((z * 60))" "$SELF"
    fi
  } > "$tmp" && mv "$tmp" "$IDLE_CONF"
  log "gen: screenOff=$s lock=$l sleep=$z"
}

# hypridle band karke naye config ke saath dobara chalao (output log me save)
restart_idle() {
  command -v hypridle >/dev/null 2>&1 || { echo "[PROBLEM] hypridle is not installed"; log "hypridle missing"; return 1; }
  ensure_env
  pkill -x hypridle 2>/dev/null
  sleep 0.3
  nohup hypridle -c "$IDLE_CONF" </dev/null >"$IDLE_LOG" 2>&1 9>&- &
  sleep 0.8
  if pgrep -x hypridle >/dev/null 2>&1; then log "hypridle started"; else log "hypridle DID NOT start, see $IDLE_LOG"; echo "[PROBLEM] hypridle did not start: see $IDLE_LOG"; return 1; fi
}

# ek timer badlo (json + hypridle.conf + restart)
set_val() {
  valid_key "$1" || { echo "[PROBLEM] bad key: $1"; return 2; }
  case "$2" in ''|*[!0-9]*) echo "[PROBLEM] minutes must be a whole number"; return 2 ;; esac
  [ "$2" -le 1440 ] || { echo "[PROBLEM] max 1440 minutes"; return 2; }
  command -v jq >/dev/null 2>&1 || { echo "[PROBLEM] jq is not installed"; return 1; }
  ensure_conf
  local tmp
  tmp=$(mktemp) || return 1
  if jq --arg k "$1" --argjson v "$2" '.[$k] = $v' "$CONF" > "$tmp" && [ -s "$tmp" ]; then
    cat "$tmp" > "$CONF"   # in place (same inode) so the panel's file watcher keeps working
    rm -f "$tmp"
  else
    rm -f "$tmp"
    echo "[PROBLEM] power.json could not be updated (left unchanged)"
    return 1
  fi
  log "set $1=$2"
  gen && restart_idle
}

# screen abhi on hai ya off ("hyprctl monitors -j" se)
dpms_state() {   # prints: off / on / unknown
  local j
  j=$(hyprctl monitors -j 2>/dev/null | jq -r '[.[].dpmsStatus] | if length==0 then "unknown" elif all(.==false) then "off" else "on" end' 2>/dev/null)
  echo "${j:-unknown}"
}

# screen on/off — jab tak sach me state na badle tab tak alag-alag syntax try karta hai
dpms() {   # dpms on|off : tries the known syntaxes until the state really changes
  local want="$1" out
  ensure_env
  hyprctl dispatch dpms "$want" >/dev/null 2>&1
  sleep 0.4; [ "$(dpms_state)" = "$want" ] && { log "dpms $want ok (dispatch dpms)"; return 0; }
  hyprctl dispatch "hl.dsp.dpms({ action = \"$want\" })" >/dev/null 2>&1
  sleep 0.4; [ "$(dpms_state)" = "$want" ] && { log "dpms $want ok (lua action)"; return 0; }
  hyprctl dispatch "hl.dsp.dpms(\"$want\")" >/dev/null 2>&1
  sleep 0.4; [ "$(dpms_state)" = "$want" ] && { log "dpms $want ok (lua string)"; return 0; }
  out=$(hyprctl dispatch dpms "$want" 2>&1)
  log "dpms $want FAILED, state=$(dpms_state), last answer: $out"
  return 1
}

# ek kaam chalao
do_action() {
  ensure_env
  log "do $1"
  case "$1" in
    shutdown)  systemctl poweroff ;;
    restart)   systemctl reboot ;;
    logout)
      out=$(hyprctl dispatch exit 2>&1)
      case "$out" in *ok*) ;; *) hyprctl dispatch 'hl.dsp.exit()' ;; esac ;;
    sleep)     systemctl suspend || log "systemctl suspend FAILED" ;;
    lock)
      if ! pidof hyprlock >/dev/null 2>&1; then
        nohup hyprlock </dev/null >>"$HOME/.cache/snow-hyprlock.log" 2>&1 9>&- &
      fi
      ;;
    screenoff) dpms off ;;
    screenon)  dpms on ;;
    cleanup)   kitty --title "Snow clean-up" bash "$HOME/.config/snow/bin/power/cleanup.sh" >/dev/null 2>&1 & ;;
    probe)     log "probe fired" ;;
    *) echo "[PROBLEM] unknown action: $1"; return 2 ;;
  esac
}

# jaanch: programs, timers, hypridle chal raha hai?, autostart hook, screen state, logs
diag() {
  ensure_env
  local p
  echo "== programs =="
  for p in hypridle hyprlock jq hyprctl; do command -v "$p" >/dev/null 2>&1 && echo "OK   $p: $(command -v "$p")" || echo "MISSING $p"; done
  echo "== timers (power.json) =="; ensure_conf; cat "$CONF"
  echo "== hypridle.conf =="; cat "$IDLE_CONF" 2>/dev/null || echo "MISSING $IDLE_CONF"
  echo "== hypridle process =="
  p=$(pgrep -x hypridle | head -1)
  if [ -n "$p" ]; then
    echo "running, pid $p"
    tr '\0' '\n' < "/proc/$p/environ" 2>/dev/null | grep -E '^(HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY)=' | sed 's/^/   its env: /'
    echo "   our env: HYPRLAND_INSTANCE_SIGNATURE=${HYPRLAND_INSTANCE_SIGNATURE:-}  WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
  else echo "NOT RUNNING"; fi
  pgrep -a 'swayidle|xidlehook|hypridle' | sed 's/^/   idle tool: /'
  echo "== autostart hook =="
  grep -rn "power.sh" "$HOME/.config/hypr" 2>/dev/null | grep -i start | sed 's/^/   /' || true
  echo "== screen power state =="; echo "dpms: $(dpms_state)"
  echo "== hypridle output ($IDLE_LOG) =="; tail -15 "$IDLE_LOG" 2>/dev/null || echo "(none yet)"
  echo "== power log ($LOG) =="; tail -15 "$LOG" 2>/dev/null || echo "(none yet)"
}

# 8 second ka idle test: hypridle sach me timer fire karta hai ya nahi
test_idle() {
  command -v hypridle >/dev/null 2>&1 || { echo "[PROBLEM] hypridle is not installed"; return 1; }
  ensure_env
  local tc mark
  tc=$(mktemp); mark="probe-$$"
  printf 'listener {\n    timeout = 8\n    on-timeout = bash %s do probe\n}\n' "$SELF" > "$tc"
  : > "$LOG.mark"
  pkill -x hypridle 2>/dev/null; sleep 0.3
  echo "TEST: do not touch the mouse / keyboard for the next 12 seconds ..."
  nohup hypridle -c "$tc" </dev/null >"$IDLE_LOG.test" 2>&1 9>&- &
  local hp=$!
  sleep 13
  kill "$hp" 2>/dev/null; rm -f "$tc" "$LOG.mark"
  local ok=0
  tail -3 "$LOG" 2>/dev/null | grep -q 'probe fired' && ok=1
  restart_idle
  if [ "$ok" = 1 ]; then echo "RESULT: PASS - hypridle idle detection works (the timer fired)."; return 0; fi
  echo "RESULT: FAIL - the timer did not fire after 8 s of idle."
  echo "  Reasons: an app is blocking idle (video / browser tab / mpv running?), or hypridle did not connect to Wayland."
  echo "  hypridle output:"; sed 's/^/    /' "$IDLE_LOG.test" 2>/dev/null | tail -8
  return 1
}

case "${1:-}" in
  do)     do_action "${2:-}" ;;
  set)    set_val "${2:-}" "${3:-}" ;;
  gen)    gen ;;
  start)  gen && restart_idle ;;
  status) ensure_conf; cat "$CONF" ;;
  diag)   diag ;;
  test)   test_idle ;;
  *)      echo "usage: power.sh do <action> | set <key> <minutes> | gen | start | status | diag | test"; exit 2 ;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/state/power.json")
cat <<'SNOW_FILE_END_4b7d'
{
  "screenOff": 0,
  "lock": 0,
  "sleep": 0
}
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
pre() {
apt_install hypridle hyprlock jq
}
post() {
if have jq && [ -f "$BIN/power/power.sh" ]; then bash "$BIN/power/power.sh" gen >/dev/null 2>&1 && pass "idle timers (hypridle.conf) generated" || warn "power.sh gen failed" "bash ~/.config/snow/bin/power/power.sh gen"; fi
}
extra_check() {
for n in powermenu/PowerMenu; do qml_ok "$QS/$n.qml"; done
for s in power/cleanup.sh power/idle.sh power/lock.sh power/power.sh; do [ -f "$BIN/$s" ] || continue; bash -n "$BIN/$s" && pass "$s: syntax ok" || fail "$s: syntax error" "bash ~/Snow/Script/${MOD}.sh"; done
}
component_main "$@"
