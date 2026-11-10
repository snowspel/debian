#!/usr/bin/env bash
# 16-screenshot.sh : OSD: screenshots
# Super+S area, Super+Shift+S full screen -> ~/Pictures/Screenshot and clipboard.
#   bash Script/16-screenshot.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/16-screenshot.sh check    read-only check
MOD="16-screenshot"; TITLE="OSD: screenshots"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/hypr/snow-shot-keys.lua|644|0"
  "u|.config/snow/bin/screenshot/screenshot.sh|755|0"
)
emit() {
case "$1" in
"u/.config/hypr/snow-shot-keys.lua")
cat <<'SNOW_FILE_END_4b7d'
-- ============================================================================
--  snow-shot-keys.lua  —  SCREENSHOT KEYS
-- ----------------------------------------------------------------------------
--  Super + S           mouse se area chuno (Esc = cancel)
--  Super + Shift + S   poori screen
--  Screenshot ~/Pictures/Screenshot me save + clipboard me copy (screenshot.sh).
-- ============================================================================
local home = os.getenv("HOME")
local sh = "bash " .. home .. "/.config/snow/bin/screenshot/screenshot.sh"

hl.bind("SUPER + S", hl.dsp.exec_cmd(sh .. " area"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(sh .. " full"))
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/screenshot/screenshot.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  screenshot.sh  —  SCREENSHOT  (Wayland / Hyprland)
# ----------------------------------------------------------------------------
#  screenshot.sh area      mouse se rectangle kheencho (Esc = cancel)       key: Super+S
#  screenshot.sh full      poori screen                                      key: Super+Shift+S
#  Har screenshot ~/Pictures/Screenshot/Screenshot_YYYYMMDD_HHMMSS.png me save hota hai AUR clipboard me copy.
#  Tools: grim (photo), slurp (area chunna), wl-copy (clipboard). Keys: ~/.config/hypr/snow-shot-keys.lua
# ============================================================================
set -u
DIR="$HOME/Pictures/Screenshot"
mkdir -p "$DIR"
FILE="$DIR/Screenshot_$(date +%Y%m%d_%H%M%S).png"

# chhota pop-up message (notify-send ho to)
note() { command -v notify-send >/dev/null 2>&1 && notify-send -a Screenshot "$1" "$2" >/dev/null 2>&1; return 0; }

# file bani? clipboard me copy + message
finish() {
  if [ ! -s "$FILE" ]; then note "Screenshot failed" "nothing was saved"; echo "[PROBLEM] screenshot failed"; rm -f "$FILE"; exit 1; fi
  wl-copy --type image/png < "$FILE" >/dev/null 2>&1
  note "Screenshot saved" "$FILE"
  echo "saved: $FILE"
}

case "${1:-}" in
  area)
    pgrep -x slurp >/dev/null 2>&1 && exit 0      # a picker is already open
    geo=$(slurp 2>/dev/null) || exit 0             # Esc = cancelled: just stop
    [ -n "$geo" ] || exit 0
    sleep 0.15                                     # let the picker overlay disappear before the picture
    grim -g "$geo" "$FILE"
    finish ;;
  full)
    grim "$FILE"
    finish ;;
  *) echo "usage: screenshot.sh area | full"; exit 2 ;;
esac
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
pre() {
apt_install grim slurp wl-clipboard
mkdir -p "$HOME/Pictures/Screenshot"
}
extra_check() {
for s in screenshot/screenshot.sh; do [ -f "$BIN/$s" ] || continue; bash -n "$BIN/$s" && pass "$s: syntax ok" || fail "$s: syntax error" "bash ~/Snow/Script/${MOD}.sh"; done
}
component_main "$@"
