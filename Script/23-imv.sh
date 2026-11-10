#!/usr/bin/env bash
# 23-imv.sh : Image viewer: imv
# Debian calls the program imv-wayland: ~/.local/bin/imv is a small launcher. One picture opened = the other pictures of the folder are loaded too: Left / Right arrow = previous / next. Background is black.
#   bash Script/23-imv.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/23-imv.sh check    read-only check
MOD="23-imv"; TITLE="Image viewer: imv"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.local/bin/imv|755|0"
  "u|.local/share/applications/imv.desktop|644|0"
  "u|.config/imv/config|644|1"
)
emit() {
case "$1" in
"u/.local/bin/imv")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# imv : Snow's launcher for the image viewer (Debian's program is called imv-wayland).
#   imv PICTURE   opens the picture AND loads all pictures of the same folder: Left / Right arrow = previous / next picture.
#   imv A B C ... / imv FOLDER   works as usual (only what you name).
IMV=/usr/bin/imv-wayland
[ -x "$IMV" ] || IMV="$(command -v imv-wayland 2>/dev/null || command -v imv-x11 2>/dev/null)"
[ -n "$IMV" ] || { echo "[PROBLEM] imv is not installed (apt package: imv)"; exit 1; }
if [ "$#" -eq 1 ] && [ -f "$1" ]; then
  f="$(realpath -- "$1")"; d="$(dirname -- "$f")"; list=(); found=0
  while IFS= read -r -d '' x; do list+=("$x"); [ "$x" = "$f" ] && found=1; done < <(find "$d" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.tif' -o -iname '*.tiff' -o -iname '*.avif' -o -iname '*.svg' -o -iname '*.jxl' -o -iname '*.heic' \) -print0 | sort -zV)
  if [ "$found" = 1 ] && [ "${#list[@]}" -gt 1 ]; then exec "$IMV" -n "$f" "${list[@]}"; fi
fi
exec "$IMV" "$@"
SNOW_FILE_END_4b7d
;;
"u/.local/share/applications/imv.desktop")
cat <<'SNOW_FILE_END_4b7d'
[Desktop Entry]
Type=Application
Name=imv
GenericName=Image viewer
Comment=Image viewer (Snow: Left / Right arrow = next / previous picture of the folder)
Exec=@HOME@/.local/bin/imv %F
Icon=imv
Terminal=false
Categories=Graphics;Viewer;
MimeType=image/png;image/jpeg;image/webp;image/gif;image/bmp;image/tiff;image/avif;image/svg+xml;
# snow-imv
SNOW_FILE_END_4b7d
;;
"u/.config/imv/config")
cat <<'SNOW_FILE_END_4b7d'
[options]
background = 000000
scaling_mode = shrink
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
pre() {
apt_install imv
[ -L "$HOME/.local/bin/imv" ] && rm -f "$HOME/.local/bin/imv"
}
post() {
for t in image/png image/jpeg image/webp image/gif image/bmp image/tiff image/avif image/svg+xml; do xdg-mime default imv.desktop $t 2>/dev/null; done
have imv-wayland && pass "imv-wayland found" || fail "imv-wayland not found" "sudo apt-get install imv"
}
extra_check() {
have imv-wayland && pass "imv installed" || fail "imv is not installed" "bash ~/Snow/Script/23-imv.sh"
[ -x "$HOME/.local/bin/imv" ] && bash -n "$HOME/.local/bin/imv" && pass "imv launcher ok" || warn "imv launcher missing" "bash ~/Snow/Script/23-imv.sh"
}
component_main "$@"
