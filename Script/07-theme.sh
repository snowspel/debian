#!/usr/bin/env bash
# 07-theme.sh : Theme: colours, wallpaper, prompt
# theme.sh (ONE base colour + ONE accent, dark/light), kitty colours, wallpaper helper (black wallpaper until you choose one), shell prompt and ls colours.
#   bash Script/07-theme.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/07-theme.sh check    read-only check
MOD="07-theme"; TITLE="Theme: colours, wallpaper, prompt"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/snow/bin/theme/apply-kitty.sh|755|0"
  "u|.config/snow/bin/theme/icon-theme.sh|755|0"
  "u|.config/snow/bin/theme/icons-gen.sh|755|0"
  "u|.config/snow/bin/theme/kitty-palette.sh|755|0"
  "u|.config/snow/bin/theme/theme-css.sh|755|0"
  "u|.config/snow/bin/theme/theme.sh|755|0"
  "u|.config/snow/bin/theme/wallpaper.sh|755|0"
  "u|.config/snow/icons/src-simple/file-archive.svg|644|0"
  "u|.config/snow/icons/src-simple/file-audio.svg|644|0"
  "u|.config/snow/icons/src-simple/file-code.svg|644|0"
  "u|.config/snow/icons/src-simple/file-disk.svg|644|0"
  "u|.config/snow/icons/src-simple/file-doc.svg|644|0"
  "u|.config/snow/icons/src-simple/file-file.svg|644|0"
  "u|.config/snow/icons/src-simple/file-font.svg|644|0"
  "u|.config/snow/icons/src-simple/file-image.svg|644|0"
  "u|.config/snow/icons/src-simple/file-package.svg|644|0"
  "u|.config/snow/icons/src-simple/file-pdf.svg|644|0"
  "u|.config/snow/icons/src-simple/file-script.svg|644|0"
  "u|.config/snow/icons/src-simple/file-sheet.svg|644|0"
  "u|.config/snow/icons/src-simple/file-slides.svg|644|0"
  "u|.config/snow/icons/src-simple/file-text.svg|644|0"
  "u|.config/snow/icons/src-simple/file-video.svg|644|0"
  "u|.config/snow/icons/src-simple/folder-documents.svg|644|0"
  "u|.config/snow/icons/src-simple/folder-downloads.svg|644|0"
  "u|.config/snow/icons/src-simple/folder-music.svg|644|0"
  "u|.config/snow/icons/src-simple/folder-pictures.svg|644|0"
  "u|.config/snow/icons/src-simple/folder-videos.svg|644|0"
  "u|.config/snow/icons/src-simple/folder.svg|644|0"
  "u|.config/snow/icons/src/file-archive.svg|644|0"
  "u|.config/snow/icons/src/file-audio.svg|644|0"
  "u|.config/snow/icons/src/file-code.svg|644|0"
  "u|.config/snow/icons/src/file-disk.svg|644|0"
  "u|.config/snow/icons/src/file-doc.svg|644|0"
  "u|.config/snow/icons/src/file-file.svg|644|0"
  "u|.config/snow/icons/src/file-font.svg|644|0"
  "u|.config/snow/icons/src/file-image.svg|644|0"
  "u|.config/snow/icons/src/file-package.svg|644|0"
  "u|.config/snow/icons/src/file-pdf.svg|644|0"
  "u|.config/snow/icons/src/file-script.svg|644|0"
  "u|.config/snow/icons/src/file-sheet.svg|644|0"
  "u|.config/snow/icons/src/file-slides.svg|644|0"
  "u|.config/snow/icons/src/file-text.svg|644|0"
  "u|.config/snow/icons/src/file-video.svg|644|0"
  "u|.config/snow/icons/src/folder-documents.svg|644|0"
  "u|.config/snow/icons/src/folder-downloads.svg|644|0"
  "u|.config/snow/icons/src/folder-music.svg|644|0"
  "u|.config/snow/icons/src/folder-pictures.svg|644|0"
  "u|.config/snow/icons/src/folder-videos.svg|644|0"
  "u|.config/snow/icons/src/folder.svg|644|0"
  "u|.config/snow/shell/colors.sh|644|0"
  "u|.config/snow/shell/prompt.sh|644|0"
  "u|.config/snow/state/mode|644|1"
  "u|.config/snow/state/theme-state.json|644|1"
  "u|.config/snow/state/theme.json|644|1"
)
emit() {
case "$1" in
"u/.config/snow/bin/theme/apply-kitty.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/bin/bash
# ============================================================================
#  apply-kitty.sh  —  KITTY TERMINAL KE RANG  (theme.json se)
# ----------------------------------------------------------------------------
#  ~/.config/kitty/snow-theme.conf banata hai (theme.json ke rangon se) aur chalte hue kitty ko reload karta hai.
#  theme.sh isse khud chalata hai. Haath se chalana ho:  bash ~/.config/snow/bin/theme/apply-kitty.sh
# ============================================================================
j="$HOME/.config/snow/state/theme.json"
command -v jq >/dev/null 2>&1 || { echo "apply-kitty: jq is not installed (sudo apt install jq)"; exit 1; }
[ -s "$j" ] || { echo "apply-kitty: $j not found"; exit 1; }
c() { jq -r ".$1" "$j"; }
mkdir -p "$HOME/.config/kitty"
out="$HOME/.config/kitty/snow-theme.conf"
cat > "$out" << EOT
foreground $(c text)
background $(c bg)
selection_foreground $(c bg)
selection_background $(c accent)
cursor $(c accent)
url_color $(c accent)
active_tab_foreground $(c text)
active_tab_background $(c accent)
inactive_tab_foreground $(c muted)
inactive_tab_background $(c surface)
color1 $(c danger)
color2 $(c success)
color3 $(c warn)
color4 $(c accent)
color8 $(c muted)
EOT
if [ "$(cat "$HOME/.config/snow/state/mode" 2>/dev/null)" = light ]; then
cat >> "$out" << EOT
color0 $(c text)
color7 $(c muted)
color15 $(c text)
EOT
fi
# baaki ke rang (magenta, cyan, bright 9-14) kitty-palette.sh jodti hai
[ -f "$HOME/.config/snow/bin/theme/kitty-palette.sh" ] && bash "$HOME/.config/snow/bin/theme/kitty-palette.sh" "$out"
# chalte hue kitty ko naya rang le lene ka signal
pkill -USR1 kitty 2>/dev/null
echo "kitty theme updated: $out"
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/theme/icon-theme.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# icon-theme.sh : choose the icon theme (file manager main pane + GTK apps).
#   icon-theme.sh list                 -> JSON {"current":"snow","themes":["snow","Tela",...]}
#   icon-theme.sh set NAME             -> use that theme ("snow" = our own shaded icons, "snow-simple" = Snow Simple flat icons). Prints JSON {"ok":..,"msg":..}
#   icon-theme.sh install FILE.tar.xz  -> unpack a downloaded icon theme (Tela, Papirus, ...) into ~/.local/share/icons
#   icon-theme.sh current              -> name of the active theme
# The choice is kept in ~/.config/snow/state/icon-theme. icons-gen.sh then fills ~/.config/snow/icons from that theme.
CONF="$HOME/.config/snow"; ST="$CONF/state/icon-theme"; DIRS=("$HOME/.local/share/icons" /usr/share/icons)
mkdir -p "$CONF/state"
cur() { local c; c=$(cat "$ST" 2>/dev/null); echo "${c:-snow}"; }
is_theme() { [ -f "$1/index.theme" ] && grep -qiE '^Directories=.*(places|mimetypes|apps)' "$1/index.theme" 2>/dev/null; }
names() {
  echo snow
  echo snow-simple
  for d in "${DIRS[@]}"; do [ -d "$d" ] || continue
    for t in "$d"/*/; do t=${t%/}; n=$(basename "$t"); [ "$n" = hicolor ] && continue; is_theme "$t" && echo "$n"; done
  done | awk '!s[$0]++'
}
json() { printf '{"ok":%s,"msg":%s}\n' "$1" "$(jq -Rn --arg m "$2" '$m')"; }
case "${1:-}" in
  current) cur ;;
  list) jq -nc --arg c "$(cur)" --argjson t "$(names | jq -R . | jq -sc .)" '{current:$c,themes:$t}' ;;
  set)
    n="${2:-}"; [ -n "$n" ] || { json false "no theme name"; exit 2; }
    if [ "$n" != snow ] && [ "$n" != snow-simple ]; then names | grep -qx "$n" || { json false "icon theme '$n' not found (install it first)"; exit 1; }; fi
    printf '%s\n' "$n" > "$ST"
    bash "$CONF/bin/theme/icons-gen.sh" >/dev/null 2>&1
    if [ "$n" != snow ] && [ "$n" != snow-simple ]; then
      for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
        mkdir -p "$(dirname "$f")"; [ -f "$f" ] || printf '[Settings]\n' > "$f"
        grep -q '^\[Settings\]' "$f" || printf '\n[Settings]\n' >> "$f"
        if grep -q '^gtk-icon-theme-name' "$f"; then sed -i "s/^gtk-icon-theme-name.*/gtk-icon-theme-name=$n/" "$f"; else sed -i "/^\[Settings\]/a gtk-icon-theme-name=$n" "$f"; fi
      done
      command -v gsettings >/dev/null 2>&1 && gsettings set org.gnome.desktop.interface icon-theme "$n" >/dev/null 2>&1
    fi
    json true "Icon theme: $n" ;;
  install)
    f="${2:-}"; [ -f "$f" ] || { json false "file not found: $f"; exit 1; }
    mkdir -p "$HOME/.local/share/icons"; tmp=$(mktemp -d)
    tar -xf "$f" -C "$tmp" 2>/dev/null || { rm -rf "$tmp"; json false "could not unpack $f"; exit 1; }
    c=0; for t in "$tmp"/*/; do t=${t%/}; is_theme "$t" || continue
      rm -rf "$HOME/.local/share/icons/$(basename "$t")"; mv "$t" "$HOME/.local/share/icons/"; c=$((c+1)); echo "installed: $(basename "$t")" >&2
    done; rm -rf "$tmp"
    [ "$c" -gt 0 ] && json true "$c icon theme folder(s) installed" || { json false "no icon theme inside $f"; exit 1; } ;;
  *) echo "usage: icon-theme.sh list | current | set NAME | install FILE.tar.xz"; exit 2 ;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/theme/icons-gen.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# icons-gen.sh : makes the universal Snow icon folder  ~/.config/snow/icons/*.svg  from the templates in  ~/.config/snow/icons/src/
#   (colours come from theme.json: ONE base + ONE accent). Called by theme.sh after every colour change; safe to run by hand.
#   Own / ready-made icons: put an .svg with the SAME NAME into  ~/.config/snow/icons/custom/  -> it is copied instead of the template
#   (example: custom/folder.svg, custom/file-pdf.svg). Remove it from custom/ to go back to the Snow look.
#   Names: folder, file-video, file-audio, file-image, file-pdf, file-doc, file-sheet, file-slides, file-text, file-script, file-code,
#          file-archive, file-package, file-disk, file-font, file-file
CONF="$HOME/.config/snow"; IC="$CONF/icons"; SRC="$IC/src"; TJ="$CONF/state/theme.json"
command -v jq >/dev/null 2>&1 || { echo "[PROBLEM] jq missing"; exit 1; }
[ -s "$TJ" ] || { echo "[PROBLEM] theme.json missing (run theme.sh apply first)"; exit 1; }
[ -d "$SRC" ] || { echo "[PROBLEM] $SRC missing"; exit 1; }
mix() { local a=${1#\#} b=${2#\#} p=$3; printf '#%02x%02x%02x' $(( (16#${a:0:2}*(100-p)+16#${b:0:2}*p)/100 )) $(( (16#${a:2:2}*(100-p)+16#${b:2:2}*p)/100 )) $(( (16#${a:4:2}*(100-p)+16#${b:4:2}*p)/100 )); }
j() { jq -r ".$1" "$TJ"; }
ACC=$(j accent); BG=$(j bg); SUR=$(j surface); HI=$(j surfaceHi); TINT=$(j tint)
RIM=$(mix "$HI" "$ACC" 45); HL=$(mix "$HI" "$TINT" 16); BG3=$(mix "$SUR" "#000000" 55); A1=$(mix "$ACC" "#ffffff" 35); A3=$(mix "$ACC" "#000000" 22)
mkdir -p "$IC/custom"; n=0
# icon theme chosen with icon-theme.sh (state/icon-theme): "snow" = our own templates, "snow-simple" = our flat Breeze-style set (icons/src-simple), any other name = icons taken from that theme
THEME=$(cat "$CONF/state/icon-theme" 2>/dev/null); THEME=${THEME:-snow}; TDIR=""
[ "$THEME" = snow-simple ] && [ -d "$IC/src-simple" ] && SRC="$IC/src-simple"
if [ "$THEME" != snow ] && [ "$THEME" != snow-simple ]; then for d in "$HOME/.local/share/icons/$THEME" "/usr/share/icons/$THEME"; do [ -d "$d" ] && { TDIR="$d"; break; }; done; fi
find_icon() {   # names... -> path of the best svg of the theme (scalable first)
  local nm p
  for nm in "$@"; do
    p=$(find -L "$TDIR" -name "$nm.svg" 2>/dev/null | awk '{s=($0 ~ /scalable/)?0:($0 ~ /\/(64|48|32)\//)?1:2; print s" "$0}' | sort -n | head -1 | cut -d' ' -f2-)
    [ -n "$p" ] && { echo "$p"; return 0; }
  done; return 1
}
themed_names() {   # kind -> icon names of the freedesktop naming standard
  case "$1" in
    folder) echo folder ;; folder-documents) echo "folder-documents folder" ;; folder-downloads) echo "folder-download folder-downloads folder" ;;
    folder-pictures) echo "folder-pictures folder-image folder" ;; folder-music) echo "folder-music folder" ;; folder-videos) echo "folder-videos folder-video folder" ;; file-video) echo "video-x-generic" ;; file-audio) echo "audio-x-generic" ;; file-image) echo "image-x-generic" ;;
    file-pdf) echo "application-pdf x-office-document" ;; file-doc) echo "x-office-document application-msword" ;; file-sheet) echo "x-office-spreadsheet" ;;
    file-slides) echo "x-office-presentation" ;; file-text) echo "text-x-generic text-plain" ;; file-script) echo "text-x-script application-x-shellscript text-x-generic" ;;
    file-code) echo "text-x-source text-x-csrc text-x-generic" ;; file-archive) echo "package-x-generic application-x-archive application-zip" ;;
    file-package) echo "application-x-deb package-x-generic" ;; file-disk) echo "application-x-cd-image media-optical" ;; file-font) echo "font-x-generic application-x-font-ttf" ;;
    *) echo "text-x-generic application-octet-stream" ;;
  esac
}
for f in "$SRC"/*.svg; do
  b=$(basename "$f")
  k=${b%.svg}; src=""
  [ -n "$TDIR" ] && src=$(find_icon $(themed_names "$k"))
  if [ -f "$IC/custom/$b" ]; then cp "$IC/custom/$b" "$IC/$b.tmp"
  elif [ -n "$src" ]; then cp -L "$src" "$IC/$b.tmp"
  else sed -e "s/@BG1@/$HI/g" -e "s/@HL@/$HL/g" -e "s/@BG3@/$BG3/g" -e "s/@BG2@/$SUR/g" -e "s/@RIM@/$RIM/g" -e "s/@FG@/$ACC/g" \
           -e "s/@A1@/$A1/g" -e "s/@A2@/$ACC/g" -e "s/@A3@/$A3/g" \
           -e "s/@F1@/$HI/g" -e "s/@F2@/$SUR/g" -e "s/@F3@/$BG/g" -e "s/@TINT@/$TINT/g" "$f" > "$IC/$b.tmp"; fi
  [ -s "$IC/$b.tmp" ] && mv -f "$IC/$b.tmp" "$IC/$b" && n=$((n+1)) || rm -f "$IC/$b.tmp"
done
echo "icons: $n files in $IC"
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/theme/kitty-palette.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  kitty-palette.sh  —  KITTY KE BAAKI RANG (magenta, cyan, 6 "bright")
# ----------------------------------------------------------------------------
#  apply-kitty.sh (theme.json se base rang likhne ke baad) isse chalata hai: bash kitty-palette.sh ~/.config/kitty/snow-theme.conf
#  Ye kitty ke 5, 6, 9..14 number ke rang file ke end me jodta hai — Dark/Light ke hisaab se.
#  Rang 1 2 3 4 8 (laal hara peela accent muted) pehle se theme.json se aate hain. Isse ls, git, htop, vim sab ke rang theme se milte hain.
#  Light mode me rang gehre, Dark me halke (pastel). Rang badalna ho to neeche mag= / cyn= wali line.
# ============================================================================
out="${1:-}"; j="$HOME/.config/snow/state/theme.json"
[ -n "$out" ] && [ -f "$out" ] && [ -s "$j" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
# do rang milao: #a aur #b, b ka kitna percent
mix() {   # #a #b percent_of_b -> #rrggbb
  local a=${1#\#} b=${2#\#} p=$3
  printf '#%02x%02x%02x' $(( (16#${a:0:2} * (100 - p) + 16#${b:0:2} * p) / 100 )) \
                         $(( (16#${a:2:2} * (100 - p) + 16#${b:2:2} * p) / 100 )) \
                         $(( (16#${a:4:2} * (100 - p) + 16#${b:4:2} * p) / 100 ))
}
# theme.json se ek rang padho
c() { jq -r ".$1 // empty" "$j"; }
# kya ye #RRGGBB hai?
ok() { [[ "${1:-}" =~ ^#[0-9a-fA-F]{6}$ ]]; }
red=$(c danger); grn=$(c success); yel=$(c warn); acc=$(c accent)
ok "$red" || red="#e0625f"; ok "$grn" || grn="#5fba7d"; ok "$yel" || yel="#e0a84a"; ok "$acc" || acc="#d4af37"
if [ "$(cat "$HOME/.config/snow/state/mode" 2>/dev/null)" = light ]; then
  mag="#8e44ad"; cyn="#17808f"; to="#000000"; p=18      # light: darker colours, "bright" = a bit darker still
else
  mag="#c586e0"; cyn="#56c2d6"; to="#ffffff"; p=22      # dark: pastel colours, "bright" = lighter
fi
{
  echo "# kitty-palette.sh"
  echo "color5 $mag"
  echo "color6 $cyn"
  echo "color9 $(mix "$red" "$to" $p)"
  echo "color10 $(mix "$grn" "$to" $p)"
  echo "color11 $(mix "$yel" "$to" $p)"
  echo "color12 $(mix "$acc" "$to" $p)"
  echo "color13 $(mix "$mag" "$to" $p)"
  echo "color14 $(mix "$cyn" "$to" $p)"
} >> "$out"
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/theme/theme-css.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# theme-css.sh : writes ~/.config/snow/state/theme.css (GTK 3 + GTK 4 colour names) from theme.json.
#   The same colours are written into ~/.config/gtk-3.0/gtk.css and ~/.config/gtk-4.0/gtk.css (block between snow-css-begin / snow-css-end).
#   Called by theme.sh after every colour change. Nothing else is written.
CONF="$HOME/.config/snow"; TJ="$CONF/state/theme.json"; OUT="$CONF/state/theme.css"
command -v jq >/dev/null 2>&1 || exit 1
[ -s "$TJ" ] || exit 1
j() { jq -r ".$1" "$TJ"; }
ACC=$(j accent); BG=$(j bg); SUR=$(j surface); HI=$(j surfaceHi); TX=$(j text); MU=$(j muted); WA=$(j warn); DA=$(j danger); OK=$(j success); TINT=$(j tint)
h=${ACC#\#}; L=$(( (299*16#${h:0:2} + 587*16#${h:2:2} + 114*16#${h:4:2}) * 1000 / 255000 ))
if [ "$L" -gt 550 ]; then AFG="#14161b"; else AFG="#ffffff"; fi
tmp=$(mktemp) || exit 1
cat > "$tmp" <<CSS
/* generated by theme-css.sh from theme.json - do not edit */
/* GTK 4 / libadwaita names */
@define-color accent_bg_color $ACC;
@define-color accent_fg_color $AFG;
@define-color accent_color $ACC;
@define-color destructive_bg_color $DA;
@define-color destructive_fg_color #ffffff;
@define-color destructive_color $DA;
@define-color success_bg_color $OK;
@define-color success_color $OK;
@define-color warning_bg_color $WA;
@define-color warning_color $WA;
@define-color error_bg_color $DA;
@define-color error_color $DA;
@define-color window_bg_color $BG;
@define-color window_fg_color $TX;
@define-color view_bg_color $SUR;
@define-color view_fg_color $TX;
@define-color headerbar_bg_color $SUR;
@define-color headerbar_fg_color $TX;
@define-color headerbar_border_color $HI;
@define-color card_bg_color $SUR;
@define-color card_fg_color $TX;
@define-color popover_bg_color $HI;
@define-color popover_fg_color $TX;
@define-color dialog_bg_color $SUR;
@define-color dialog_fg_color $TX;
@define-color sidebar_bg_color $SUR;
@define-color sidebar_fg_color $TX;
@define-color sidebar_backdrop_color $BG;
@define-color secondary_sidebar_bg_color $BG;
@define-color secondary_sidebar_fg_color $TX;
/* GTK 3 (Adwaita / adw-gtk3) names */
@define-color theme_bg_color $BG;
@define-color theme_fg_color $TX;
@define-color theme_base_color $SUR;
@define-color theme_text_color $TX;
@define-color theme_selected_bg_color $ACC;
@define-color theme_selected_fg_color $AFG;
@define-color theme_unfocused_bg_color $BG;
@define-color theme_unfocused_fg_color $MU;
@define-color theme_unfocused_base_color $SUR;
@define-color theme_unfocused_text_color $MU;
@define-color theme_unfocused_selected_bg_color $ACC;
@define-color theme_unfocused_selected_fg_color $AFG;
@define-color insensitive_bg_color $SUR;
@define-color insensitive_fg_color $MU;
@define-color borders $HI;
@define-color unfocused_borders $HI;
@define-color warning_color $WA;
@define-color error_color $DA;
@define-color success_color $OK;
CSS
mkdir -p "$(dirname "$OUT")"; cat "$tmp" > "$OUT"
# the colours are written INTO gtk-3.0/gtk.css and gtk-4.0/gtk.css (our marked block only, rest of the file kept).
# (an @import of the file above can fail silently in sandboxed apps, so the content itself is copied)
for g in "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"; do
  mkdir -p "$(dirname "$g")"; t2=$(mktemp) || continue
  { echo "/* snow-css-begin */"; cat "$tmp"; echo "/* snow-css-end */"; [ -f "$g" ] && sed '/snow-css-begin/,/snow-css-end/d' "$g"; } > "$t2"
  cat "$t2" > "$g"; rm -f "$t2"
done
rm -f "$tmp"
echo "theme.css written: $OUT (and copied into gtk-3.0/gtk.css + gtk-4.0/gtk.css)"
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/theme/theme.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  theme.sh  —  POORE DESKTOP KA RANG  (ek Base rang + ek Accent rang + Dark/Light)
# ----------------------------------------------------------------------------
#  KAISE BADLE:
#    bash ~/.config/snow/bin/theme/theme.sh base   '#000000'     background rang
#    bash ~/.config/snow/bin/theme/theme.sh accent '#d4af37'     highlight rang
#    bash ~/.config/snow/bin/theme/theme.sh mode dark|light|toggle
#    bash ~/.config/snow/bin/theme/theme.sh apply | init | status
#  (Quick settings -> Brightness par right-click -> Display card me ye sab buttons se bhi hota hai.)
#  FILES (~/.config/snow):
#    theme-state.json   tumhari pasand {mode, base, accent}  <- yahi asli "source"
#    theme.json         GENERATED: baaki sab shades Base + Accent se calculate hoke yahan aate hain
#    mode               GENERATED: sirf shabd dark ya light
#  KYA APNE AAP BADALTA HAI: Quickshell panels (turant), kitty (reload), GTK apps (agli baar khulne par), hyprlock.
#  KYA NAHI: mpv ka rang (agli video par), SDDM login screen, Brave ka accent.
# ============================================================================
set -u

CONF="$HOME/.config/snow"
STATE="$CONF/state/theme-state.json"
TJ="$CONF/state/theme.json"
MODEF="$CONF/state/mode"
OLDPAL="$CONF/palette.json"      # only read once, to take over the colours of version 1

command -v jq >/dev/null 2>&1 || { echo "[PROBLEM] jq is not installed (sudo apt install jq)"; exit 1; }
mkdir -p "$CONF"

# write stdin into a file IN PLACE (same inode), so the panels' file watchers keep working. An empty input changes nothing.
# stdin ko file me usi jagah likho (naya file nahi) taaki QML ka file-watcher chalta rahe. Khali input = kuch nahi badlta.
write_inplace() {
  local tmp; tmp=$(mktemp) || return 1
  cat > "$tmp"
  if [ -s "$tmp" ]; then cat "$tmp" > "$1"; rm -f "$tmp"; return 0; fi
  rm -f "$tmp"; return 1
}

# kya ye "#RRGGBB" rang hai?
is_hex() { [[ "${1:-}" =~ ^#[0-9a-fA-F]{6}$ ]]; }

# rang ki chamak 0..1000 (light/dark pehchanne ke liye)
lum() {   # #rrggbb -> brightness 0..1000
  local h=${1#\#} r g b
  r=$((16#${h:0:2})); g=$((16#${h:2:2})); b=$((16#${h:4:2}))
  echo $(( (299 * r + 587 * g + 114 * b) * 1000 / 255000 ))
}

# do rang milao: #a aur #b, b ka kitna percent
mix() {   # #a #b percent_of_b -> #rrggbb
  local a=${1#\#} b=${2#\#} p=$3 r g bl
  r=$(( (16#${a:0:2} * (100 - p) + 16#${b:0:2} * p) / 100 ))
  g=$(( (16#${a:2:2} * (100 - p) + 16#${b:2:2} * p) / 100 ))
  bl=$(( (16#${a:4:2} * (100 - p) + 16#${b:4:2} * p) / 100 ))
  printf '#%02x%02x%02x' "$r" "$g" "$bl"
}

# rang ko gehra karo
darken() { mix "$1" "#000000" $((100 - $2)); }   # darken #hex to $2 percent of its brightness

# all the shades of one set, calculated from the background colour
# Background se baaki saare shades (surface, text, muted ...) calculate karo
build_set() {   # bg -> JSON
  local bg=$1 surface hi text muted tint warn danger success
  if [ "$(lum "$bg")" -gt 550 ]; then      # light background: dark text
    surface=$(mix "$bg" "#ffffff" 85); hi=$(mix "$bg" "#000000" 5)
    text=$(mix "#1a1b1f" "$bg" 8); muted=$(mix "$text" "$bg" 48); tint="#000000"
    warn="#b7791f"; danger="#c2413d"; success="#2f8f57"
  else                                      # dark background: light text
    surface=$(mix "$bg" "#ffffff" 5); hi=$(mix "$bg" "#ffffff" 11)
    text=$(mix "$bg" "#ffffff" 91); muted=$(mix "$bg" "#ffffff" 52); tint="#ffffff"
    warn="#e0a84a"; danger="#e0625f"; success="#5fba7d"
  fi
  jq -n --arg bg "$bg" --arg surface "$surface" --arg surfaceHi "$hi" --arg text "$text" --arg muted "$muted" \
        --arg tint "$tint" --arg warn "$warn" --arg danger "$danger" --arg success "$success" \
    '{bg:$bg, surface:$surface, surfaceHi:$surfaceHi, text:$text, muted:$muted, warn:$warn, danger:$danger, success:$success, tint:$tint}'
}

# create the state file, or take over the colours of version 1 / of the current theme.json
# theme-state.json na ho ya kharab ho to purane theme.json se bana lo
ensure_state() {
  if [ -s "$STATE" ] && jq -e '((.base // "") | test("^#[0-9a-fA-F]{6}$")) and ((.accent // "") | test("^#[0-9a-fA-F]{6}$"))' "$STATE" >/dev/null 2>&1; then
    return 0
  fi
  local mode base acc
  mode=$(jq -r '.mode // "dark"' "$STATE" 2>/dev/null); case "$mode" in dark|light) ;; *) mode=dark ;; esac
  base=$(jq -r '.base // empty' "$STATE" 2>/dev/null)
  is_hex "$base" || base=$(jq -r '.dark.bg // empty' "$OLDPAL" 2>/dev/null)
  is_hex "$base" || { [ "$mode" = dark ] && base=$(jq -r '.bg // empty' "$TJ" 2>/dev/null); }
  is_hex "$base" || base="#14161b"
  acc=$(jq -r '.accent // empty' "$STATE" 2>/dev/null)
  if ! is_hex "$acc" && [ -n "$acc" ]; then acc=$(jq -r --arg a "$acc" '.accents[$a] // empty' "$OLDPAL" 2>/dev/null); fi
  is_hex "$acc" || acc=$(jq -r '.accents.gold // empty' "$OLDPAL" 2>/dev/null)
  is_hex "$acc" || acc=$(jq -r '.accent // empty' "$TJ" 2>/dev/null)
  # the panels' built-in blue is not a colour that was chosen
  if ! is_hex "$acc" || [ "$(printf '%s' "$acc" | tr 'A-F' 'a-f')" = "#5b7fd6" ]; then acc="#d4af37"; fi
  jq -n --arg m "$mode" --arg b "$base" --arg a "$acc" '{mode:$m, base:$b, accent:$a}' | write_inplace "$STATE"
}

# theme-state.json me ek key badlo
set_state() {   # key value
  ensure_state
  jq --arg k "$1" --arg v "$2" '.[$k] = $v' "$STATE" | write_inplace "$STATE"
}

# theme-state.json -> theme.json + mode file
gen() {
  ensure_state || return 1
  local mode base acc bg use
  mode=$(jq -r '.mode' "$STATE"); base=$(jq -r '.base' "$STATE"); acc=$(jq -r '.accent' "$STATE")
  if [ "$mode" = light ]; then bg=$(mix "$base" "#ffffff" 94); else bg=$base; fi
  use=$acc
  # a very light accent would be invisible on a light background: use a darker version of it there
  if [ "$(lum "$bg")" -gt 550 ] && [ "$(lum "$acc")" -gt 800 ]; then use=$(darken "$acc" 62); fi
  build_set "$bg" | jq --arg a "$use" '. + {accent: $a}' | write_inplace "$TJ" \
    || { echo "[PROBLEM] could not write theme.json"; return 1; }
  printf '%s\n' "$mode" | write_inplace "$MODEF"
}

# GTK apps ke settings.ini me dark/light flag likho
gtk_set() {   # settings.ini  1|0
  local f="$1" v="$2"
  mkdir -p "$(dirname "$f")"
  [ -f "$f" ] || printf '[Settings]\n' > "$f"
  grep -q '^\[Settings\]' "$f" || printf '\n[Settings]\n' >> "$f"
  if grep -q '^gtk-application-prefer-dark-theme' "$f"; then
    sed -i "s/^gtk-application-prefer-dark-theme.*/gtk-application-prefer-dark-theme=$v/" "$f"
  else
    sed -i "/^\[Settings\]/a gtk-application-prefer-dark-theme=$v" "$f"
  fi
}

# GTK, kitty, hyprlock sab ko naya theme do
apply_all() {
  local mode v scheme
  mode=$(jq -r '.mode' "$STATE")
  if [ "$mode" = light ]; then v=0; scheme=prefer-light; else v=1; scheme=prefer-dark; fi
  gtk_set "$HOME/.config/gtk-3.0/settings.ini" "$v"
  gtk_set "$HOME/.config/gtk-4.0/settings.ini" "$v"
  if command -v gsettings >/dev/null 2>&1 && gsettings get org.gnome.desktop.interface color-scheme >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme "$scheme" >/dev/null 2>&1
  fi
  [ -f "$CONF/bin/theme/icons-gen.sh" ] && bash "$CONF/bin/theme/icons-gen.sh" >/dev/null 2>&1
  [ -f "$CONF/bin/theme/theme-css.sh" ] && bash "$CONF/bin/theme/theme-css.sh" >/dev/null 2>&1
  [ -f "$CONF/bin/theme/apply-kitty.sh" ] && bash "$CONF/bin/theme/apply-kitty.sh" >/dev/null 2>&1
  [ -f "$CONF/bin/power/lock.sh" ] && bash "$CONF/bin/power/lock.sh" gen >/dev/null 2>&1
  echo "theme: $mode, base $(jq -r '.base' "$STATE"), accent $(jq -r '.accent' "$STATE")  (panels follow at once, kitty reloads, GTK apps: open them again)"
}

usage() { echo "usage: theme.sh base '#RRGGBB' | accent '#RRGGBB' | mode dark|light|toggle | apply | init | status"; exit 2; }

case "${1:-}" in
  mode)
    ensure_state
    case "${2:-}" in
      dark|light) set_state mode "$2" ;;
      toggle) if [ "$(jq -r '.mode' "$STATE")" = light ]; then set_state mode dark; else set_state mode light; fi ;;
      *) usage ;;
    esac
    gen && apply_all ;;
  base|accent)
    c=$(printf '%s' "${2:-}" | tr 'A-F' 'a-f')
    is_hex "$c" || { echo "[PROBLEM] '${2:-}' is not a colour. Use the form #RRGGBB, for example #d4af37"; exit 2; }
    set_state "$1" "$c"
    gen && apply_all ;;
  apply) gen && apply_all ;;
  init)  ensure_state && echo "state: $(jq -c . "$STATE")" ;;
  status)
    ensure_state; echo "state:"; cat "$STATE"
    [ -s "$TJ" ] && { echo "theme.json:"; cat "$TJ"; }
    for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
      [ -f "$f" ] && echo "$f: $(grep '^gtk-application-prefer-dark-theme' "$f")"
    done ;;
  *) usage ;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/theme/wallpaper.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# ============================================================================
#  wallpaper.sh  —  DESKTOP WALLPAPER  (swaybg se)
# ----------------------------------------------------------------------------
#  wallpaper.sh pick        file-chooser (zenity) kholo, picture chuno aur laga do
#  wallpaper.sh set FILE    ye picture lagao
#  wallpaper.sh start       apply the saved picture at Hyprland start; if none was chosen yet, a plain BLACK wallpaper is set
#  The chosen picture is kept in ~/.config/snow/state/wallpaper.current (Files/backup.sh saves it).
#  (Display card me wallpaper icon dabane par "pick" chalta hai.)
# ============================================================================
set -u
CONF_DIR="$HOME/.config/snow"
CUR="$CONF_DIR/state/wallpaper.current"

# saved picture ko swaybg se lagao; purana swaybg baad me band (screen khali na ho)
apply() {
  command -v swaybg >/dev/null 2>&1 || { echo "[PROBLEM] swaybg is not installed (apt package: swaybg)"; return 1; }
  local old bg; old=$(pgrep -x swaybg | tr '\n' ' ')
  # no picture chosen yet -> plain black wallpaper
  if [ -s "$CUR" ]; then bg=(-i "$CUR" -m fill); else bg=(-c "#000000" -m solid_color); fi
  nohup swaybg "${bg[@]}" </dev/null >/dev/null 2>&1 &
  sleep 0.4
  [ -n "$old" ] && kill $old 2>/dev/null
  return 0
}

# picture copy karke saved jagah rakho aur lagao
setfile_core() {
  [ -f "$1" ] || { echo "[PROBLEM] not a file: $1"; return 2; }
  mkdir -p "$CONF_DIR"
  cp -f "$1" "$CUR"
  apply
}

# snow-lock-bg: naya wallpaper lagte hi lock screen ka blur background bhi naya
setfile() {
  setfile_core "$1" || return $?
  bash "$HOME/.config/snow/bin/power/lock.sh" gen >/dev/null 2>&1
  # login screen (SDDM) background follows too (blur + install takes a few seconds, so in the background)
  [ -f "$HOME/.config/snow/bin/sddm/sddm-bg.sh" ] && { bash "$HOME/.config/snow/bin/sddm/sddm-bg.sh" >/dev/null 2>&1 & }
}

case "${1:-}" in
  pick)
    command -v zenity >/dev/null 2>&1 || { echo "[PROBLEM] zenity is not installed"; exit 1; }
    f=$(zenity --file-selection --title="Choose wallpaper" --file-filter="Images | *.png *.jpg *.jpeg *.webp *.bmp" 2>/dev/null) || exit 0
    [ -n "$f" ] && setfile "$f"
    ;;
  set)   setfile "${2:-}" ;;
  start) apply ;;
  *) echo "usage: wallpaper.sh pick | set FILE | start"; exit 2 ;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-archive.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><path d="M14 21a4 4 0 0 1 4-4h10l5 6h13a4 4 0 0 1 4 4v18a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4Z" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M32 27v4M32 35v4" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><rect x="29" y="41" width="6" height="7" rx="1.8" fill="@FG@"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-audio.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><path d="M28 43V21l16-4v22" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><circle cx="23.5" cy="43.5" r="5" fill="@FG@"/><circle cx="39.5" cy="39.5" r="5" fill="@FG@"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-code.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><path d="M26 21l-11 11 11 11M38 21l11 11-11 11" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M34 18l-4 28" stroke="@FG@" stroke-width="2.6" stroke-linecap="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-disk.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><circle cx="32" cy="32" r="15" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><circle cx="32" cy="32" r="4" fill="@FG@"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-doc.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><path d="M22 14h13l9 9v25a2 2 0 0 1-2 2H22a2 2 0 0 1-2-2V16a2 2 0 0 1 2-2Z" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M35 14v9h9" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M26 31h12M26 37h12M26 43h8" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-file.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><path d="M22 14h13l9 9v25a2 2 0 0 1-2 2H22a2 2 0 0 1-2-2V16a2 2 0 0 1 2-2Z" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M35 14v9h9" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-font.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><path d="M19 46L32 17l13 29M24 36h16" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-image.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><rect x="16" y="18" width="32" height="28" rx="4" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><circle cx="25" cy="27" r="3" fill="@FG@"/><path d="M17 42l9-8 6 5 7-8 9 9" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-package.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><path d="M32 15l15 8v18l-15 8-15-8V23Z" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M17 23l15 8 15-8M32 31v18" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-pdf.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><path d="M22 14h13l9 9v25a2 2 0 0 1-2 2H22a2 2 0 0 1-2-2V16a2 2 0 0 1 2-2Z" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M35 14v9h9" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M26 38h12M26 43h8" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-script.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><path d="M20 22l12 10-12 10" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M35 44h11" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-sheet.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><rect x="17" y="17" width="30" height="30" rx="4" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M17 27h30M17 37h30M27 17v30M37 17v30" stroke="@FG@" stroke-width="2.4"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-slides.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><rect x="15" y="18" width="34" height="23" rx="3" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M32 41v6M25 47h14" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M24 33l5-5 4 4 6-7" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-text.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><path d="M20 22h24M20 30h24M20 38h24M20 46h14" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/file-video.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64" fill="none">
<path d="M18 5h21l11 11v39a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4V9a4 4 0 0 1 4-4Z" fill="@BG1@" stroke="@RIM@" stroke-width="1.5" stroke-linejoin="round"/>
<path d="M39 5v7a4 4 0 0 0 4 4h7Z" fill="@RIM@"/>
<g transform="translate(14.1 20) scale(0.56)"><path d="M25 20.5v23a1.5 1.5 0 0 0 2.3 1.3l18-11.5a1.5 1.5 0 0 0 0-2.6l-18-11.5a1.5 1.5 0 0 0-2.3 1.3Z" fill="@FG@"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/folder-documents.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64"><defs><linearGradient xlink:href="#a" id="b" x1="65.965" y1="58.048" x2="65.965" y2="16.036" gradientUnits="userSpaceOnUse" gradientTransform="translate(384.571 483.798)"/><linearGradient id="a"><stop stop-color="@A2@"/><stop offset="1" stop-color="@A1@"/></linearGradient></defs><g fill-rule="evenodd" stroke-linejoin="round"><path d="M30.388 6.618H8.69c-2.662 0-4.803 2.195-4.803 4.916v28.331c0 2.722 2.141 4.914 4.803 4.914h46.616c2.662 0 4.806-2.192 4.806-4.914V16.008h-.028c-.08-2.65-2.167-4.769-4.778-4.769H35.01z" fill="@A3@" stroke-width=".814"/><path d="M30.164 16.21l-3.108 1.538-3.646 1.806H6.853c-.704 0-1.373.142-1.981.4-.37.158-.665.431-.984.668v1.643c.32-.237.614-.51.984-.667a5.042 5.042 0 0 1 1.98-.401H25.29z" fill-opacity=".235" stroke-width=".814"/><path d="M414.735 500.008l-4.874 4.986h-18.436c-2.817 0-5.067 2.285-5.154 5.143h-.031v25.741c0 2.936 2.313 5.302 5.185 5.302h50.296c2.871 0 5.183-2.366 5.183-5.302V505.31c0-2.936-2.312-5.302-5.183-5.302z" fill="url(#b)" stroke-width=".878" transform="translate(-384.571 -483.798)"/><path d="M62.332 50.72c0 .733-.144 1.432-.406 2.067a5.299 5.299 0 0 1-1.11 1.684 5.165 5.165 0 0 1-1.647 1.134 5.084 5.084 0 0 1-2.02.416H6.852a5.095 5.095 0 0 1-2.022-.416 5.166 5.166 0 0 1-1.647-1.134 5.298 5.298 0 0 1-1.11-1.684 5.413 5.413 0 0 1-.405-2.068v1.361c0 2.936 2.313 5.302 5.184 5.302H57.15c2.872 0 5.183-2.366 5.183-5.302z" opacity=".4" fill-opacity=".235" stroke-width=".878"/><path d="M30.162 16.211l-4.872 4.986H6.853c-2.817 0-5.066 2.285-5.152 5.143h-.033v1.361h.033a5.455 5.455 0 0 1 .444-2.009 5.294 5.294 0 0 1 1.108-1.632 5.117 5.117 0 0 1 1.619-1.099 5.044 5.044 0 0 1 1.98-.403H27.025l1.775-3.587.644-1.303.002-.002.01-.013z" fill="#fff" fill-opacity=".235" stroke-width=".878"/><path d="M30.388 6.618l1.033 2.534 1.466 3.587H55.307a4.67 4.67 0 0 1 1.836.373c.564.24 1.073.588 1.502 1.019.43.43.778.943 1.026 1.515.247.57.394 1.2.414 1.862h.028v-1.5h-.028c-.08-2.65-2.167-4.769-4.778-4.769H35.01z" fill="#fff" fill-opacity=".235" stroke-width=".814"/></g><g transform="translate(20 28) scale(0.24)" fill="@F3@" stroke="@F3@" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round" opacity="0.75"><path d="M25 10h32l18 18v58a4 4 0 0 1-4 4H25a4 4 0 0 1-4-4V14a4 4 0 0 1 4-4Z" fill="none"/><path d="M57 10v18h18" fill="none"/><path d="M34 50h32M34 64h32M34 78h20" fill="none"/></g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/folder-downloads.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64"><defs><linearGradient xlink:href="#a" id="b" x1="65.965" y1="58.048" x2="65.965" y2="16.036" gradientUnits="userSpaceOnUse" gradientTransform="translate(384.571 483.798)"/><linearGradient id="a"><stop stop-color="@A2@"/><stop offset="1" stop-color="@A1@"/></linearGradient></defs><g fill-rule="evenodd" stroke-linejoin="round"><path d="M30.388 6.618H8.69c-2.662 0-4.803 2.195-4.803 4.916v28.331c0 2.722 2.141 4.914 4.803 4.914h46.616c2.662 0 4.806-2.192 4.806-4.914V16.008h-.028c-.08-2.65-2.167-4.769-4.778-4.769H35.01z" fill="@A3@" stroke-width=".814"/><path d="M30.164 16.21l-3.108 1.538-3.646 1.806H6.853c-.704 0-1.373.142-1.981.4-.37.158-.665.431-.984.668v1.643c.32-.237.614-.51.984-.667a5.042 5.042 0 0 1 1.98-.401H25.29z" fill-opacity=".235" stroke-width=".814"/><path d="M414.735 500.008l-4.874 4.986h-18.436c-2.817 0-5.067 2.285-5.154 5.143h-.031v25.741c0 2.936 2.313 5.302 5.185 5.302h50.296c2.871 0 5.183-2.366 5.183-5.302V505.31c0-2.936-2.312-5.302-5.183-5.302z" fill="url(#b)" stroke-width=".878" transform="translate(-384.571 -483.798)"/><path d="M62.332 50.72c0 .733-.144 1.432-.406 2.067a5.299 5.299 0 0 1-1.11 1.684 5.165 5.165 0 0 1-1.647 1.134 5.084 5.084 0 0 1-2.02.416H6.852a5.095 5.095 0 0 1-2.022-.416 5.166 5.166 0 0 1-1.647-1.134 5.298 5.298 0 0 1-1.11-1.684 5.413 5.413 0 0 1-.405-2.068v1.361c0 2.936 2.313 5.302 5.184 5.302H57.15c2.872 0 5.183-2.366 5.183-5.302z" opacity=".4" fill-opacity=".235" stroke-width=".878"/><path d="M30.162 16.211l-4.872 4.986H6.853c-2.817 0-5.066 2.285-5.152 5.143h-.033v1.361h.033a5.455 5.455 0 0 1 .444-2.009 5.294 5.294 0 0 1 1.108-1.632 5.117 5.117 0 0 1 1.619-1.099 5.044 5.044 0 0 1 1.98-.403H27.025l1.775-3.587.644-1.303.002-.002.01-.013z" fill="#fff" fill-opacity=".235" stroke-width=".878"/><path d="M30.388 6.618l1.033 2.534 1.466 3.587H55.307a4.67 4.67 0 0 1 1.836.373c.564.24 1.073.588 1.502 1.019.43.43.778.943 1.026 1.515.247.57.394 1.2.414 1.862h.028v-1.5h-.028c-.08-2.65-2.167-4.769-4.778-4.769H35.01z" fill="#fff" fill-opacity=".235" stroke-width=".814"/></g><g transform="translate(20 28) scale(0.24)" fill="@F3@" stroke="@F3@" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round" opacity="0.75"><path d="M50 10v50M29 42l21 21 21-21" fill="none"/><path d="M15 66v18a4 4 0 0 0 4 4h62a4 4 0 0 0 4-4V66" fill="none"/></g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/folder-music.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64"><defs><linearGradient xlink:href="#a" id="b" x1="65.965" y1="58.048" x2="65.965" y2="16.036" gradientUnits="userSpaceOnUse" gradientTransform="translate(384.571 483.798)"/><linearGradient id="a"><stop stop-color="@A2@"/><stop offset="1" stop-color="@A1@"/></linearGradient></defs><g fill-rule="evenodd" stroke-linejoin="round"><path d="M30.388 6.618H8.69c-2.662 0-4.803 2.195-4.803 4.916v28.331c0 2.722 2.141 4.914 4.803 4.914h46.616c2.662 0 4.806-2.192 4.806-4.914V16.008h-.028c-.08-2.65-2.167-4.769-4.778-4.769H35.01z" fill="@A3@" stroke-width=".814"/><path d="M30.164 16.21l-3.108 1.538-3.646 1.806H6.853c-.704 0-1.373.142-1.981.4-.37.158-.665.431-.984.668v1.643c.32-.237.614-.51.984-.667a5.042 5.042 0 0 1 1.98-.401H25.29z" fill-opacity=".235" stroke-width=".814"/><path d="M414.735 500.008l-4.874 4.986h-18.436c-2.817 0-5.067 2.285-5.154 5.143h-.031v25.741c0 2.936 2.313 5.302 5.185 5.302h50.296c2.871 0 5.183-2.366 5.183-5.302V505.31c0-2.936-2.312-5.302-5.183-5.302z" fill="url(#b)" stroke-width=".878" transform="translate(-384.571 -483.798)"/><path d="M62.332 50.72c0 .733-.144 1.432-.406 2.067a5.299 5.299 0 0 1-1.11 1.684 5.165 5.165 0 0 1-1.647 1.134 5.084 5.084 0 0 1-2.02.416H6.852a5.095 5.095 0 0 1-2.022-.416 5.166 5.166 0 0 1-1.647-1.134 5.298 5.298 0 0 1-1.11-1.684 5.413 5.413 0 0 1-.405-2.068v1.361c0 2.936 2.313 5.302 5.184 5.302H57.15c2.872 0 5.183-2.366 5.183-5.302z" opacity=".4" fill-opacity=".235" stroke-width=".878"/><path d="M30.162 16.211l-4.872 4.986H6.853c-2.817 0-5.066 2.285-5.152 5.143h-.033v1.361h.033a5.455 5.455 0 0 1 .444-2.009 5.294 5.294 0 0 1 1.108-1.632 5.117 5.117 0 0 1 1.619-1.099 5.044 5.044 0 0 1 1.98-.403H27.025l1.775-3.587.644-1.303.002-.002.01-.013z" fill="#fff" fill-opacity=".235" stroke-width=".878"/><path d="M30.388 6.618l1.033 2.534 1.466 3.587H55.307a4.67 4.67 0 0 1 1.836.373c.564.24 1.073.588 1.502 1.019.43.43.778.943 1.026 1.515.247.57.394 1.2.414 1.862h.028v-1.5h-.028c-.08-2.65-2.167-4.769-4.778-4.769H35.01z" fill="#fff" fill-opacity=".235" stroke-width=".814"/></g><g transform="translate(20 28) scale(0.24)" fill="@F3@" stroke="@F3@" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round" opacity="0.75"><path d="M38 74V22l44-11v52" fill="none"/><circle cx="27" cy="76" r="12"/><circle cx="71" cy="64" r="12"/></g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/folder-pictures.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64"><defs><linearGradient xlink:href="#a" id="b" x1="65.965" y1="58.048" x2="65.965" y2="16.036" gradientUnits="userSpaceOnUse" gradientTransform="translate(384.571 483.798)"/><linearGradient id="a"><stop stop-color="@A2@"/><stop offset="1" stop-color="@A1@"/></linearGradient></defs><g fill-rule="evenodd" stroke-linejoin="round"><path d="M30.388 6.618H8.69c-2.662 0-4.803 2.195-4.803 4.916v28.331c0 2.722 2.141 4.914 4.803 4.914h46.616c2.662 0 4.806-2.192 4.806-4.914V16.008h-.028c-.08-2.65-2.167-4.769-4.778-4.769H35.01z" fill="@A3@" stroke-width=".814"/><path d="M30.164 16.21l-3.108 1.538-3.646 1.806H6.853c-.704 0-1.373.142-1.981.4-.37.158-.665.431-.984.668v1.643c.32-.237.614-.51.984-.667a5.042 5.042 0 0 1 1.98-.401H25.29z" fill-opacity=".235" stroke-width=".814"/><path d="M414.735 500.008l-4.874 4.986h-18.436c-2.817 0-5.067 2.285-5.154 5.143h-.031v25.741c0 2.936 2.313 5.302 5.185 5.302h50.296c2.871 0 5.183-2.366 5.183-5.302V505.31c0-2.936-2.312-5.302-5.183-5.302z" fill="url(#b)" stroke-width=".878" transform="translate(-384.571 -483.798)"/><path d="M62.332 50.72c0 .733-.144 1.432-.406 2.067a5.299 5.299 0 0 1-1.11 1.684 5.165 5.165 0 0 1-1.647 1.134 5.084 5.084 0 0 1-2.02.416H6.852a5.095 5.095 0 0 1-2.022-.416 5.166 5.166 0 0 1-1.647-1.134 5.298 5.298 0 0 1-1.11-1.684 5.413 5.413 0 0 1-.405-2.068v1.361c0 2.936 2.313 5.302 5.184 5.302H57.15c2.872 0 5.183-2.366 5.183-5.302z" opacity=".4" fill-opacity=".235" stroke-width=".878"/><path d="M30.162 16.211l-4.872 4.986H6.853c-2.817 0-5.066 2.285-5.152 5.143h-.033v1.361h.033a5.455 5.455 0 0 1 .444-2.009 5.294 5.294 0 0 1 1.108-1.632 5.117 5.117 0 0 1 1.619-1.099 5.044 5.044 0 0 1 1.98-.403H27.025l1.775-3.587.644-1.303.002-.002.01-.013z" fill="#fff" fill-opacity=".235" stroke-width=".878"/><path d="M30.388 6.618l1.033 2.534 1.466 3.587H55.307a4.67 4.67 0 0 1 1.836.373c.564.24 1.073.588 1.502 1.019.43.43.778.943 1.026 1.515.247.57.394 1.2.414 1.862h.028v-1.5h-.028c-.08-2.65-2.167-4.769-4.778-4.769H35.01z" fill="#fff" fill-opacity=".235" stroke-width=".814"/></g><g transform="translate(20 28) scale(0.24)" fill="@F3@" stroke="@F3@" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round" opacity="0.75"><rect x="11" y="18" width="78" height="64" rx="10" fill="none"/><circle cx="33" cy="41" r="7"/><path d="M13 74l25-23 16 14 14-16 19 21" fill="none"/></g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/folder-videos.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64"><defs><linearGradient xlink:href="#a" id="b" x1="65.965" y1="58.048" x2="65.965" y2="16.036" gradientUnits="userSpaceOnUse" gradientTransform="translate(384.571 483.798)"/><linearGradient id="a"><stop stop-color="@A2@"/><stop offset="1" stop-color="@A1@"/></linearGradient></defs><g fill-rule="evenodd" stroke-linejoin="round"><path d="M30.388 6.618H8.69c-2.662 0-4.803 2.195-4.803 4.916v28.331c0 2.722 2.141 4.914 4.803 4.914h46.616c2.662 0 4.806-2.192 4.806-4.914V16.008h-.028c-.08-2.65-2.167-4.769-4.778-4.769H35.01z" fill="@A3@" stroke-width=".814"/><path d="M30.164 16.21l-3.108 1.538-3.646 1.806H6.853c-.704 0-1.373.142-1.981.4-.37.158-.665.431-.984.668v1.643c.32-.237.614-.51.984-.667a5.042 5.042 0 0 1 1.98-.401H25.29z" fill-opacity=".235" stroke-width=".814"/><path d="M414.735 500.008l-4.874 4.986h-18.436c-2.817 0-5.067 2.285-5.154 5.143h-.031v25.741c0 2.936 2.313 5.302 5.185 5.302h50.296c2.871 0 5.183-2.366 5.183-5.302V505.31c0-2.936-2.312-5.302-5.183-5.302z" fill="url(#b)" stroke-width=".878" transform="translate(-384.571 -483.798)"/><path d="M62.332 50.72c0 .733-.144 1.432-.406 2.067a5.299 5.299 0 0 1-1.11 1.684 5.165 5.165 0 0 1-1.647 1.134 5.084 5.084 0 0 1-2.02.416H6.852a5.095 5.095 0 0 1-2.022-.416 5.166 5.166 0 0 1-1.647-1.134 5.298 5.298 0 0 1-1.11-1.684 5.413 5.413 0 0 1-.405-2.068v1.361c0 2.936 2.313 5.302 5.184 5.302H57.15c2.872 0 5.183-2.366 5.183-5.302z" opacity=".4" fill-opacity=".235" stroke-width=".878"/><path d="M30.162 16.211l-4.872 4.986H6.853c-2.817 0-5.066 2.285-5.152 5.143h-.033v1.361h.033a5.455 5.455 0 0 1 .444-2.009 5.294 5.294 0 0 1 1.108-1.632 5.117 5.117 0 0 1 1.619-1.099 5.044 5.044 0 0 1 1.98-.403H27.025l1.775-3.587.644-1.303.002-.002.01-.013z" fill="#fff" fill-opacity=".235" stroke-width=".878"/><path d="M30.388 6.618l1.033 2.534 1.466 3.587H55.307a4.67 4.67 0 0 1 1.836.373c.564.24 1.073.588 1.502 1.019.43.43.778.943 1.026 1.515.247.57.394 1.2.414 1.862h.028v-1.5h-.028c-.08-2.65-2.167-4.769-4.778-4.769H35.01z" fill="#fff" fill-opacity=".235" stroke-width=".814"/></g><g transform="translate(20 28) scale(0.24)" fill="@F3@" stroke="@F3@" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round" opacity="0.75"><rect x="9" y="20" width="82" height="60" rx="11" fill="none"/><path d="M42 36v28l24-14Z"/></g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src-simple/folder.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64"><defs><linearGradient xlink:href="#a" id="b" x1="65.965" y1="58.048" x2="65.965" y2="16.036" gradientUnits="userSpaceOnUse" gradientTransform="translate(384.571 483.798)"/><linearGradient id="a"><stop stop-color="@A2@"/><stop offset="1" stop-color="@A1@"/></linearGradient></defs><g fill-rule="evenodd" stroke-linejoin="round"><path d="M30.388 6.618H8.69c-2.662 0-4.803 2.195-4.803 4.916v28.331c0 2.722 2.141 4.914 4.803 4.914h46.616c2.662 0 4.806-2.192 4.806-4.914V16.008h-.028c-.08-2.65-2.167-4.769-4.778-4.769H35.01z" fill="@A3@" stroke-width=".814"/><path d="M30.164 16.21l-3.108 1.538-3.646 1.806H6.853c-.704 0-1.373.142-1.981.4-.37.158-.665.431-.984.668v1.643c.32-.237.614-.51.984-.667a5.042 5.042 0 0 1 1.98-.401H25.29z" fill-opacity=".235" stroke-width=".814"/><path d="M414.735 500.008l-4.874 4.986h-18.436c-2.817 0-5.067 2.285-5.154 5.143h-.031v25.741c0 2.936 2.313 5.302 5.185 5.302h50.296c2.871 0 5.183-2.366 5.183-5.302V505.31c0-2.936-2.312-5.302-5.183-5.302z" fill="url(#b)" stroke-width=".878" transform="translate(-384.571 -483.798)"/><path d="M62.332 50.72c0 .733-.144 1.432-.406 2.067a5.299 5.299 0 0 1-1.11 1.684 5.165 5.165 0 0 1-1.647 1.134 5.084 5.084 0 0 1-2.02.416H6.852a5.095 5.095 0 0 1-2.022-.416 5.166 5.166 0 0 1-1.647-1.134 5.298 5.298 0 0 1-1.11-1.684 5.413 5.413 0 0 1-.405-2.068v1.361c0 2.936 2.313 5.302 5.184 5.302H57.15c2.872 0 5.183-2.366 5.183-5.302z" opacity=".4" fill-opacity=".235" stroke-width=".878"/><path d="M30.162 16.211l-4.872 4.986H6.853c-2.817 0-5.066 2.285-5.152 5.143h-.033v1.361h.033a5.455 5.455 0 0 1 .444-2.009 5.294 5.294 0 0 1 1.108-1.632 5.117 5.117 0 0 1 1.619-1.099 5.044 5.044 0 0 1 1.98-.403H27.025l1.775-3.587.644-1.303.002-.002.01-.013z" fill="#fff" fill-opacity=".235" stroke-width=".878"/><path d="M30.388 6.618l1.033 2.534 1.466 3.587H55.307a4.67 4.67 0 0 1 1.836.373c.564.24 1.073.588 1.502 1.019.43.43.778.943 1.026 1.515.247.57.394 1.2.414 1.862h.028v-1.5h-.028c-.08-2.65-2.167-4.769-4.778-4.769H35.01z" fill="#fff" fill-opacity=".235" stroke-width=".814"/></g></svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-archive.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<path d="M14 21a4 4 0 0 1 4-4h10l5 6h13a4 4 0 0 1 4 4v18a4 4 0 0 1-4 4H18a4 4 0 0 1-4-4Z" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M32 27v4M32 35v4" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><rect x="29" y="41" width="6" height="7" rx="1.8" fill="@FG@"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-audio.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<path d="M28 43V21l16-4v22" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><circle cx="23.5" cy="43.5" r="5" fill="@FG@"/><circle cx="39.5" cy="39.5" r="5" fill="@FG@"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-code.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<path d="M26 21l-11 11 11 11M38 21l11 11-11 11" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M34 18l-4 28" stroke="@FG@" stroke-width="2.6" stroke-linecap="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-disk.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<circle cx="32" cy="32" r="15" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><circle cx="32" cy="32" r="4" fill="@FG@"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-doc.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<path d="M22 14h13l9 9v25a2 2 0 0 1-2 2H22a2 2 0 0 1-2-2V16a2 2 0 0 1 2-2Z" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M35 14v9h9" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M26 31h12M26 37h12M26 43h8" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-file.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<path d="M22 14h13l9 9v25a2 2 0 0 1-2 2H22a2 2 0 0 1-2-2V16a2 2 0 0 1 2-2Z" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M35 14v9h9" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-font.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<path d="M19 46L32 17l13 29M24 36h16" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-image.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<rect x="16" y="18" width="32" height="28" rx="4" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><circle cx="25" cy="27" r="3" fill="@FG@"/><path d="M17 42l9-8 6 5 7-8 9 9" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-package.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<path d="M32 15l15 8v18l-15 8-15-8V23Z" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M17 23l15 8 15-8M32 31v18" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-pdf.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<path d="M22 14h13l9 9v25a2 2 0 0 1-2 2H22a2 2 0 0 1-2-2V16a2 2 0 0 1 2-2Z" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M35 14v9h9" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M26 38h12M26 43h8" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-script.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<path d="M20 22l12 10-12 10" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M35 44h11" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-sheet.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<rect x="17" y="17" width="30" height="30" rx="4" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M17 27h30M17 37h30M27 17v30M37 17v30" stroke="@FG@" stroke-width="2.4"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-slides.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<rect x="15" y="18" width="34" height="23" rx="3" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M32 41v6M25 47h14" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M24 33l5-5 4 4 6-7" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-text.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<path d="M20 22h24M20 30h24M20 38h24M20 46h14" stroke="@FG@" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/file-video.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
<defs>
<radialGradient id="b" cx="0.36" cy="0.24" r="0.95"><stop offset="0" stop-color="@HL@"/><stop offset="0.5" stop-color="@BG1@"/><stop offset="1" stop-color="@BG3@"/></radialGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@RIM@"/><stop offset="1" stop-color="@RIM@" stop-opacity="0.15"/></linearGradient>
</defs>
<circle cx="32" cy="36" r="27" fill="#000" opacity="0.20"/>
<circle cx="32" cy="34.5" r="27" fill="#000" opacity="0.22"/>
<circle cx="32" cy="32" r="27" fill="url(#b)" stroke="url(#r)" stroke-width="1.4"/>
<path d="M12 27a21 21 0 0 1 40 0c-8-5-32-5-40 0Z" fill="@TINT@" opacity="0.07"/>
<g transform="translate(8.96 8.96) scale(0.72)">
<path d="M25 20.5v23a1.5 1.5 0 0 0 2.3 1.3l18-11.5a1.5 1.5 0 0 0 0-2.6l-18-11.5a1.5 1.5 0 0 0-2.3 1.3Z" fill="@FG@"/>
</g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/folder-documents.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="512" height="512" viewBox="0 0 512 512" fill="none">
  <defs>
    <linearGradient id="back" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@A1@"/><stop offset="0.45" stop-color="@A2@"/><stop offset="1" stop-color="@A3@"/></linearGradient>
    <linearGradient id="front" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@F1@"/><stop offset="0.55" stop-color="@F2@"/><stop offset="1" stop-color="@F3@"/></linearGradient>
  </defs>
  <path d="M40 100.2Q40 65 84 65H240Q268 65 284 77.8L314 101.8H462Q506 101.8 506 137V412.2Q506 447.4 462 447.4H84Q40 447.4 40 412.2Z" fill="url(#back)"/>
  <path d="M12 161Q12 125.8 56 125.8H252Q280 125.8 296 138.6L326 162.6H468Q506 162.6 506 197.8V412.2Q506 447.4 468 447.4H56Q12 447.4 12 412.2Z" fill="url(#front)" stroke="@A2@" stroke-width="6" stroke-linejoin="round"/>
  <path d="M28 145Q28 133.8 42 133.8H248Q268 133.8 282 145L302 162.6H468Q490 162.6 490 177Q340 172.2 160 172.2Q40 169 28 145Z" fill="@TINT@" opacity="0.07"/>
  <defs>
    <linearGradient id="gg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@A1@"/><stop offset="0.5" stop-color="@A2@"/><stop offset="1" stop-color="@A3@"/></linearGradient>
    <g id="gl" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round"><path d="M25 10h32l18 18v58a4 4 0 0 1-4 4H25a4 4 0 0 1-4-4V14a4 4 0 0 1 4-4Z" fill="none"/><path d="M57 10v18h18" fill="none"/><path d="M34 50h32M34 64h32M34 78h20" fill="none"/></g>
  </defs>
  <g transform="translate(176 223) scale(1.6)">
    <use xlink:href="#gl" transform="translate(2.6 3.8)" fill="#000" stroke="#000" opacity="0.7"/>
    <use xlink:href="#gl" transform="translate(-0.9 -1.1)" fill="@A1@" stroke="@A1@" opacity="0.9"/>
    <use xlink:href="#gl" fill="url(#gg)" stroke="url(#gg)"/>
  </g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/folder-downloads.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="512" height="512" viewBox="0 0 512 512" fill="none">
  <defs>
    <linearGradient id="back" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@A1@"/><stop offset="0.45" stop-color="@A2@"/><stop offset="1" stop-color="@A3@"/></linearGradient>
    <linearGradient id="front" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@F1@"/><stop offset="0.55" stop-color="@F2@"/><stop offset="1" stop-color="@F3@"/></linearGradient>
  </defs>
  <path d="M40 100.2Q40 65 84 65H240Q268 65 284 77.8L314 101.8H462Q506 101.8 506 137V412.2Q506 447.4 462 447.4H84Q40 447.4 40 412.2Z" fill="url(#back)"/>
  <path d="M12 161Q12 125.8 56 125.8H252Q280 125.8 296 138.6L326 162.6H468Q506 162.6 506 197.8V412.2Q506 447.4 468 447.4H56Q12 447.4 12 412.2Z" fill="url(#front)" stroke="@A2@" stroke-width="6" stroke-linejoin="round"/>
  <path d="M28 145Q28 133.8 42 133.8H248Q268 133.8 282 145L302 162.6H468Q490 162.6 490 177Q340 172.2 160 172.2Q40 169 28 145Z" fill="@TINT@" opacity="0.07"/>
  <defs>
    <linearGradient id="gg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@A1@"/><stop offset="0.5" stop-color="@A2@"/><stop offset="1" stop-color="@A3@"/></linearGradient>
    <g id="gl" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round"><path d="M50 10v50M29 42l21 21 21-21" fill="none"/><path d="M15 66v18a4 4 0 0 0 4 4h62a4 4 0 0 0 4-4V66" fill="none"/></g>
  </defs>
  <g transform="translate(176 223) scale(1.6)">
    <use xlink:href="#gl" transform="translate(2.6 3.8)" fill="#000" stroke="#000" opacity="0.7"/>
    <use xlink:href="#gl" transform="translate(-0.9 -1.1)" fill="@A1@" stroke="@A1@" opacity="0.9"/>
    <use xlink:href="#gl" fill="url(#gg)" stroke="url(#gg)"/>
  </g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/folder-music.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="512" height="512" viewBox="0 0 512 512" fill="none">
  <defs>
    <linearGradient id="back" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@A1@"/><stop offset="0.45" stop-color="@A2@"/><stop offset="1" stop-color="@A3@"/></linearGradient>
    <linearGradient id="front" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@F1@"/><stop offset="0.55" stop-color="@F2@"/><stop offset="1" stop-color="@F3@"/></linearGradient>
  </defs>
  <path d="M40 100.2Q40 65 84 65H240Q268 65 284 77.8L314 101.8H462Q506 101.8 506 137V412.2Q506 447.4 462 447.4H84Q40 447.4 40 412.2Z" fill="url(#back)"/>
  <path d="M12 161Q12 125.8 56 125.8H252Q280 125.8 296 138.6L326 162.6H468Q506 162.6 506 197.8V412.2Q506 447.4 468 447.4H56Q12 447.4 12 412.2Z" fill="url(#front)" stroke="@A2@" stroke-width="6" stroke-linejoin="round"/>
  <path d="M28 145Q28 133.8 42 133.8H248Q268 133.8 282 145L302 162.6H468Q490 162.6 490 177Q340 172.2 160 172.2Q40 169 28 145Z" fill="@TINT@" opacity="0.07"/>
  <defs>
    <linearGradient id="gg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@A1@"/><stop offset="0.5" stop-color="@A2@"/><stop offset="1" stop-color="@A3@"/></linearGradient>
    <g id="gl" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round"><path d="M38 74V22l44-11v52" fill="none"/><circle cx="27" cy="76" r="12"/><circle cx="71" cy="64" r="12"/></g>
  </defs>
  <g transform="translate(176 223) scale(1.6)">
    <use xlink:href="#gl" transform="translate(2.6 3.8)" fill="#000" stroke="#000" opacity="0.7"/>
    <use xlink:href="#gl" transform="translate(-0.9 -1.1)" fill="@A1@" stroke="@A1@" opacity="0.9"/>
    <use xlink:href="#gl" fill="url(#gg)" stroke="url(#gg)"/>
  </g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/folder-pictures.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="512" height="512" viewBox="0 0 512 512" fill="none">
  <defs>
    <linearGradient id="back" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@A1@"/><stop offset="0.45" stop-color="@A2@"/><stop offset="1" stop-color="@A3@"/></linearGradient>
    <linearGradient id="front" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@F1@"/><stop offset="0.55" stop-color="@F2@"/><stop offset="1" stop-color="@F3@"/></linearGradient>
  </defs>
  <path d="M40 100.2Q40 65 84 65H240Q268 65 284 77.8L314 101.8H462Q506 101.8 506 137V412.2Q506 447.4 462 447.4H84Q40 447.4 40 412.2Z" fill="url(#back)"/>
  <path d="M12 161Q12 125.8 56 125.8H252Q280 125.8 296 138.6L326 162.6H468Q506 162.6 506 197.8V412.2Q506 447.4 468 447.4H56Q12 447.4 12 412.2Z" fill="url(#front)" stroke="@A2@" stroke-width="6" stroke-linejoin="round"/>
  <path d="M28 145Q28 133.8 42 133.8H248Q268 133.8 282 145L302 162.6H468Q490 162.6 490 177Q340 172.2 160 172.2Q40 169 28 145Z" fill="@TINT@" opacity="0.07"/>
  <defs>
    <linearGradient id="gg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@A1@"/><stop offset="0.5" stop-color="@A2@"/><stop offset="1" stop-color="@A3@"/></linearGradient>
    <g id="gl" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round"><rect x="11" y="18" width="78" height="64" rx="10" fill="none"/><circle cx="33" cy="41" r="7"/><path d="M13 74l25-23 16 14 14-16 19 21" fill="none"/></g>
  </defs>
  <g transform="translate(176 223) scale(1.6)">
    <use xlink:href="#gl" transform="translate(2.6 3.8)" fill="#000" stroke="#000" opacity="0.7"/>
    <use xlink:href="#gl" transform="translate(-0.9 -1.1)" fill="@A1@" stroke="@A1@" opacity="0.9"/>
    <use xlink:href="#gl" fill="url(#gg)" stroke="url(#gg)"/>
  </g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/folder-videos.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="512" height="512" viewBox="0 0 512 512" fill="none">
  <defs>
    <linearGradient id="back" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@A1@"/><stop offset="0.45" stop-color="@A2@"/><stop offset="1" stop-color="@A3@"/></linearGradient>
    <linearGradient id="front" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@F1@"/><stop offset="0.55" stop-color="@F2@"/><stop offset="1" stop-color="@F3@"/></linearGradient>
  </defs>
  <path d="M40 100.2Q40 65 84 65H240Q268 65 284 77.8L314 101.8H462Q506 101.8 506 137V412.2Q506 447.4 462 447.4H84Q40 447.4 40 412.2Z" fill="url(#back)"/>
  <path d="M12 161Q12 125.8 56 125.8H252Q280 125.8 296 138.6L326 162.6H468Q506 162.6 506 197.8V412.2Q506 447.4 468 447.4H56Q12 447.4 12 412.2Z" fill="url(#front)" stroke="@A2@" stroke-width="6" stroke-linejoin="round"/>
  <path d="M28 145Q28 133.8 42 133.8H248Q268 133.8 282 145L302 162.6H468Q490 162.6 490 177Q340 172.2 160 172.2Q40 169 28 145Z" fill="@TINT@" opacity="0.07"/>
  <defs>
    <linearGradient id="gg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@A1@"/><stop offset="0.5" stop-color="@A2@"/><stop offset="1" stop-color="@A3@"/></linearGradient>
    <g id="gl" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="20" width="82" height="60" rx="11" fill="none"/><path d="M42 36v28l24-14Z"/></g>
  </defs>
  <g transform="translate(176 223) scale(1.6)">
    <use xlink:href="#gl" transform="translate(2.6 3.8)" fill="#000" stroke="#000" opacity="0.7"/>
    <use xlink:href="#gl" transform="translate(-0.9 -1.1)" fill="@A1@" stroke="@A1@" opacity="0.9"/>
    <use xlink:href="#gl" fill="url(#gg)" stroke="url(#gg)"/>
  </g>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/icons/src/folder.svg")
cat <<'SNOW_FILE_END_4b7d'
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512" fill="none">
  <defs>
    <linearGradient id="back" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@A1@"/><stop offset="0.45" stop-color="@A2@"/><stop offset="1" stop-color="@A3@"/></linearGradient>
    <linearGradient id="front" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="@F1@"/><stop offset="0.55" stop-color="@F2@"/><stop offset="1" stop-color="@F3@"/></linearGradient>
  </defs>
  <path d="M40 100.2Q40 65 84 65H240Q268 65 284 77.8L314 101.8H462Q506 101.8 506 137V412.2Q506 447.4 462 447.4H84Q40 447.4 40 412.2Z" fill="url(#back)"/>
  <path d="M12 161Q12 125.8 56 125.8H252Q280 125.8 296 138.6L326 162.6H468Q506 162.6 506 197.8V412.2Q506 447.4 468 447.4H56Q12 447.4 12 412.2Z" fill="url(#front)" stroke="@A2@" stroke-width="6" stroke-linejoin="round"/>
  <path d="M28 145Q28 133.8 42 133.8H248Q268 133.8 282 145L302 162.6H468Q490 162.6 490 177Q340 172.2 160 172.2Q40 169 28 145Z" fill="@TINT@" opacity="0.07"/>
</svg>
SNOW_FILE_END_4b7d
;;
"u/.config/snow/shell/colors.sh")
cat <<'SNOW_FILE_END_4b7d'
# ============================================================================
#  colors.sh  —  TERMINAL ME COMMANDS KE OUTPUT KO RANG  (ls, grep, diff, ip, man pages)
# ----------------------------------------------------------------------------
#  ~/.bashrc ke end me ye file load hoti hai (the line is added by 07-theme.sh).
#  Ye terminal ke 16 rangon ka use karti hai, isliye theme + kitty-palette.sh ke saath rang apne aap badalte hain.
#  BAND KARNA HO : ~/.bashrc me "# snow colors" wali line ke aage "#" laga do.
#  KYA KYA: ls (folders = accent, programs = hara, links = firozi ...), grep (match = peela), man pages (headings = accent).
# ============================================================================
[[ $- == *i* ]] || return 0
[ "${TERM:-dumb}" = dumb ] && return 0
# ls: folders = accent, executables = green, links = cyan, archives = red, pictures / video = magenta
command -v dircolors >/dev/null 2>&1 && eval "$(dircolors -b)"
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='grep -F --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'
# grep: match = yellow, file name = magenta, line number = green, separator = cyan
export GREP_COLORS='mt=01;33:fn=35:ln=32:se=36'
# man pages (less): headings = accent, options / underlined words = green, search hit / status line = cyan, errors = red
export LESS="${LESS:--R}"
export GROFF_NO_SGR=1
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;34m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_us=$'\e[4;32m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_so=$'\e[1;36m'
export LESS_TERMCAP_se=$'\e[0m'
SNOW_FILE_END_4b7d
;;
"u/.config/snow/shell/prompt.sh")
cat <<'SNOW_FILE_END_4b7d'
# ============================================================================
#  prompt.sh  —  TERMINAL KA RANG-BIRANGA PROMPT   [user@host folder]$  aur neeche  └─>
# ----------------------------------------------------------------------------
#  ~/.bashrc ke end me ye file load hoti hai (install.sh line jodta hai).
#  4 rang: user = accent, computer ka naam = firozi (cyan), folder = hara, brackets/@ = halka.
#  Rang terminal ke apne rangon se aate hain, isliye theme badalne par ye bhi badal jaata hai:
#      34 = accent rang   90 = halka (muted)   32 hara   33 peela   35 baingani   36 firozi   31 laal
#  Kisi rang ko badalna ho to neeche ke number (34 / 36 / 32 / 90) badlo. "1;" ka matlab bold.
#  PROMPT KA SHAPE badalna ho: neeche PS1 line.  \u = user,  \h = computer ka naam,  \W = folder,  \n = nayi line
# ============================================================================
[[ $- == *i* ]] || return 0              # sirf interactive terminal me
[ "${TERM:-dumb}" = dumb ] && return 0
_snow_acc='\[\e[1;34m\]'    # user ka naam aur $   (accent, bold)
_snow_acc2='\[\e[36m\]'     # computer ka naam      (firozi / cyan)
_snow_dir='\[\e[32m\]'      # folder ka naam        (hara)
_snow_dim='\[\e[90m\]'      # [ @ ] aur arrow       (halka)
_snow_off='\[\e[0m\]'       # rang band
PS1="${_snow_dim}[${_snow_off}${_snow_acc}\u${_snow_off}${_snow_dim}@${_snow_off}${_snow_acc2}\h${_snow_off} ${_snow_dir}\W${_snow_off}${_snow_dim}]${_snow_off}${_snow_acc}\\\$${_snow_off} \n${_snow_dim}  └─>${_snow_off} "
unset _snow_acc _snow_acc2 _snow_dir _snow_dim _snow_off
SNOW_FILE_END_4b7d
;;
"u/.config/snow/state/mode")
cat <<'SNOW_FILE_END_4b7d'
dark
SNOW_FILE_END_4b7d
;;
"u/.config/snow/state/theme-state.json")
cat <<'SNOW_FILE_END_4b7d'
{
  "mode": "dark",
  "base": "#000000",
  "accent": "#cebb82"
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/state/theme.json")
cat <<'SNOW_FILE_END_4b7d'
{
  "bg": "#000000",
  "surface": "#0c0c0c",
  "surfaceHi": "#1c1c1c",
  "text": "#e8e8e8",
  "muted": "#848484",
  "warn": "#e0a84a",
  "danger": "#e0625f",
  "success": "#5fba7d",
  "tint": "#ffffff",
  "accent": "#cebb82"
}
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
pre() {
apt_install jq swaybg imagemagick
}
post() {
touch "$HOME/.bashrc"; backup "$HOME/.bashrc"
grep -q 'snow/shell/prompt.sh' "$HOME/.bashrc" && pass "~/.bashrc already loads the snow prompt" || { printf '\n# snow prompt\n[ -f ~/.config/snow/shell/prompt.sh ] && . ~/.config/snow/shell/prompt.sh\n' >> "$HOME/.bashrc" && pass "snow prompt added to ~/.bashrc"; }
grep -q 'snow/shell/colors.sh' "$HOME/.bashrc" && pass "~/.bashrc already loads the snow colours" || { printf '\n# snow colors\n[ -f ~/.config/snow/shell/colors.sh ] && . ~/.config/snow/shell/colors.sh\n' >> "$HOME/.bashrc" && pass "snow colours (ls, grep, man) added to ~/.bashrc"; }
# the colour block of the postponed GTK/Qt theme test is removed again (only our own block)
for f in "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"; do if grep -q snow-theme-begin "$f" 2>/dev/null; then backup "$f"; sed -i '/snow-theme-begin/,/snow-theme-end/d' "$f"; [ -s "$f" ] || rm -f "$f"; pass "old Snow colour block removed from ${f/#$HOME/~}"; fi; done
rm -f "$HOME/.config/qt5ct/colors/snow.conf" "$HOME/.config/qt6ct/colors/snow.conf"
# GTK 3 + GTK 4 apps read the Snow colours: one @import line at the top of gtk.css (only our marked block; the rest of the file is kept)
for f in "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"; do mkdir -p "$(dirname "$f")"; [ -f "$f" ] && backup "$f"; tmp=$(mktemp); { printf '/* snow-css-begin */\n@import url("file://%s/.config/snow/state/theme.css");\n/* snow-css-end */\n' "$HOME"; [ -f "$f" ] && sed '/snow-css-begin/,/snow-css-end/d' "$f"; } > "$tmp"; cat "$tmp" > "$f"; rm -f "$tmp"; pass "GTK colours linked in ${f/#$HOME/~} (theme.css)"; done
if have jq && [ -f "$BIN/theme/theme.sh" ]; then bash "$BIN/theme/theme.sh" apply >/dev/null 2>&1 && pass "theme applied (colours, kitty, lock screen)" || warn "theme.sh apply failed" "bash ~/.config/snow/bin/theme/theme.sh apply   (see the error above)"; fi
}
extra_check() {
have jq && pass "jq installed" || fail "jq is missing" "sudo apt-get install jq"
[ -s "$CONF/state/theme.json" ] && pass "theme.json exists" || fail "theme.json is missing" "bash ~/Snow/Script/07-theme.sh"
for s in theme/theme.sh theme/apply-kitty.sh theme/kitty-palette.sh theme/wallpaper.sh theme/icons-gen.sh theme/theme-css.sh theme/icon-theme.sh; do [ -f "$BIN/$s" ] || continue; bash -n "$BIN/$s" && pass "$s: syntax ok" || fail "$s: syntax error" "bash ~/Snow/Script/${MOD}.sh"; done
[ -s "$CONF/icons/folder.svg" ] && pass "universal icon folder ready (~/.config/snow/icons)" || fail "icon folder is empty" "bash ~/.config/snow/bin/theme/icons-gen.sh"
[ -s "$CONF/state/theme.css" ] && pass "theme.css exists (GTK colours)" || fail "theme.css missing" "bash ~/.config/snow/bin/theme/theme-css.sh"
}
component_main "$@"
