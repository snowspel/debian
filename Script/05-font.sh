#!/usr/bin/env bash
# 05-font.sh : Font: Material Symbols Rounded (all panel icons)
# The icon font used by every panel and by mpv. It is stored inside lib/payload-font.sh.
#   bash Script/05-font.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/05-font.sh check    read-only check
MOD="05-font"; TITLE="Font: Material Symbols Rounded (all panel icons)"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
)
emit() {
case "$1" in
*) return 1 ;;
esac
}
extra_check() {
fc-list 2>/dev/null | grep -qi "Material Symbols Rounded" && pass "font Material Symbols Rounded" || fail "font Material Symbols Rounded missing (icons would be empty boxes)" "bash ~/Snow/Script/05-font.sh"
fc-list 2>/dev/null | grep -qi "Inter" && pass "font Inter" || warn "font Inter missing" "sudo apt-get install fonts-inter"
fc-list 2>/dev/null | grep -qi "JetBrains Mono" && pass "font JetBrains Mono" || warn "font JetBrains Mono missing" "sudo apt-get install fonts-jetbrains-mono"
}
CUSTOM_RUN=run_font
run_font() {
# 30-fonts : Material Symbols Rounded (all icons of the panels and mpv) -> /usr/local/share/fonts/material-symbols (the font is inside lib/payload-font.sh)
step "05 fonts: Material Symbols Rounded"
DST=/usr/local/share/fonts/material-symbols
have xz || apt_install xz-utils
if [ ! -f "$SNOW_ROOT/Script/lib/payload-font.sh" ]; then
  fail "Script/lib/payload-font.sh is missing (it carries the icon font): copy the complete Snow folder again from the original archive"
else
  . "$SNOW_ROOT/Script/lib/payload-font.sh"
  FT="$(mktemp -d)"
  if payload_font_extract "$FT" 2>/dev/null && [ -s "$FT/MaterialSymbolsRounded.ttf" ]; then
    if ! cmp -s "$FT/MaterialSymbolsRounded.ttf" "$DST/MaterialSymbolsRounded.ttf" 2>/dev/null; then
      asroot mkdir -p "$DST" && asroot install -m 644 "$FT/MaterialSymbolsRounded.ttf" "$DST/MaterialSymbolsRounded.ttf" && pass "font installed to $DST" || fail "could not install the font"
    else pass "font already installed in $DST"; fi
    [ -s "$FT/MaterialSymbolsRounded.codepoints" ] && asroot install -m 644 "$FT/MaterialSymbolsRounded.codepoints" "$DST/" 2>/dev/null
    have fc-cache && asroot fc-cache -f >/dev/null 2>&1
  else fail "could not unpack the font from payload-font.sh (need xz, base64, tar)"; fi
  rm -rf "$FT"
fi
fc-list 2>/dev/null | grep -qi "Material Symbols Rounded" && pass "fontconfig lists 'Material Symbols Rounded'" || fail "fontconfig does not list Material Symbols Rounded (icons would be empty boxes)"
fc-list 2>/dev/null | grep -qi "Inter" && pass "font Inter found" || warn "font Inter not found (sudo apt install fonts-inter)"
fc-list 2>/dev/null | grep -qi "JetBrains Mono" && pass "font JetBrains Mono found" || warn "font JetBrains Mono not found (sudo apt install fonts-jetbrains-mono)"
summary "$MOD"

}
component_main "$@"
