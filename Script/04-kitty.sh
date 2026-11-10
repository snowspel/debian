#!/usr/bin/env bash
# 04-kitty.sh : Terminal: kitty
# The terminal (Super+T): apt kitty, kitty.conf, snow.conf (keeps your own if it exists) and the key file with the yazi pass-through lines.
#   bash Script/04-kitty.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/04-kitty.sh check    read-only check
MOD="04-kitty"; TITLE="Terminal: kitty"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/kitty/kitty.conf|644|0"
  "u|.config/kitty/snow-keys.conf|644|0"
  "u|.config/kitty/snow.conf|644|1"
)
emit() {
case "$1" in
"u/.config/kitty/kitty.conf")
cat <<'SNOW_FILE_END_4b7d'


# snow-begin
include snow.conf
# snow-end
SNOW_FILE_END_4b7d
;;
"u/.config/kitty/snow-keys.conf")
cat <<'SNOW_FILE_END_4b7d'
# ============================================================================
#  snow-keys.conf  —  KITTY ME COPY / PASTE KEYS
# ----------------------------------------------------------------------------
#  Ctrl+C : agar text selected hai to COPY; kuch selected nahi to chalta hua program rok deta hai (normal Ctrl+C)
#  Ctrl+V : paste
#  Ctrl+Shift+C / Ctrl+Shift+V : kitty ke apne copy/paste (kaam karte rehte hain)
#  Beech wala mouse button : mouse se select kiya hua text paste
# ============================================================================
map ctrl+c copy_or_interrupt
map ctrl+v paste_from_clipboard
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
mouse_map middle release ungrabbed paste_from_selection

# snow-yazi-keys: inside yazi, Ctrl+C / Ctrl+V go to yazi (copy / paste files). Other terminals keep the normal copy/paste.
map --when-focus-on title:Yazi ctrl+c
map --when-focus-on title:Yazi ctrl+v
SNOW_FILE_END_4b7d
;;
"u/.config/kitty/snow.conf")
cat <<'SNOW_FILE_END_4b7d'
# snow.conf : terminal look (font, padding, scrollback). Colours come from snow-theme.conf (generated), keys from snow-keys.conf.
font_family      DejaVu Sans Mono
font_size        13.0
window_padding_width 8
enable_audio_bell no
confirm_os_window_close 0
scrollback_lines 10000
include snow-theme.conf
include snow-keys.conf
mouse_hide_wait 0
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
pre() {
apt_install kitty adwaita-icon-theme
mkdir -p "$KITTY"
}
post() {
have kitty && pass "kitty found: $(kitty --version 2>/dev/null | head -1)" || fail "kitty not found" "sudo apt-get install kitty"
}
extra_check() {
have kitty && pass "kitty installed" || fail "kitty is not installed" "sudo apt-get install kitty"
}
component_main "$@"
