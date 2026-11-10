#!/usr/bin/env bash
# backup.sh : saves your LIVE Snow files into the Files folder (this folder), as tarballs:
#   original/Snow-original.tar.gz   made ONCE by install.sh (never replaced by a script)
#   latest/Snow-latest.tar.gz       your newest backup
#   Plain-Files/                    the SAME files as plain, VISIBLE files (home/config/quickshell/snow/*.qml, home/config/hypr/*.lua, ...; the leading dot of
#                                   .config / .local / .bashrc is dropped so nothing is hidden). Refreshed by every backup. restore.sh files puts them back.
#   ../Backup/Snow-<date>-<time>.tar.gz   a dated copy of EVERY backup (next to install.sh); nothing in there is replaced or deleted by a script
#   history/Snow-before-restore-*.tar.gz, Snow-before-reset-*.tar.gz   safety copies made by restore.sh / reset.sh
#   bash $FILES_DIR/backup.sh               make / refresh "latest"
#   bash $FILES_DIR/backup.sh --status      only tell if your live files differ from "latest"
#   bash $FILES_DIR/backup.sh --original    (used by install.sh) make the original, only if none exists
#   bash $FILES_DIR/backup.sh --snapshot NAME   (used by restore/reset) copy of the live files into history/, "latest" is not touched
# Only copies files into tarballs. Nothing on your system is changed.
set -u
G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; B=$'\e[1m'; N=$'\e[0m'
FILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; SNOW_DIR="$(dirname "$FILES_DIR")"
ORIG="$FILES_DIR/original/Snow-original.tar.gz"; LATEST="$FILES_DIR/latest/Snow-latest.tar.gz"; HIST="$FILES_DIR/history"; BKDIR="$SNOW_DIR/Backup"; PLAIN="$FILES_DIR/Plain-Files"
MODE="${1:-latest}"; SNAPNAME="${2:-snapshot}"
TS="$(date +%Y%m%d-%H%M%S)"

# ---- what is saved (relative to $HOME). Programs are not saved: install.sh installs them.
HOME_DIRS=( .config/quickshell/snow .config/snow .config/mpv .config/yazi .config/imv )
HOME_FILES=( .bashrc .config/mimeapps.list .config/gtk-3.0/gtk.css .config/gtk-3.0/settings.ini .local/share/gtksourceview-4/styles/snow.xml .local/bin/imv )
# kitty: every *.conf (kitty.conf, snow.conf, snow-keys.conf, snow-theme.conf) ; hypr: *.lua + generated hypridle.conf / hyprlock.conf ; applications: only entries written by Snow (marker "# snow-")
SYSTEM_FILES=( /etc/sddm.conf.d/zz-clock-ring.conf /usr/share/sddm/themes/clock-ring/Main.qml /usr/share/sddm/themes/clock-ring/Ring.qml /usr/share/sddm/themes/clock-ring/metadata.desktop /usr/share/sddm/themes/clock-ring/theme.conf /usr/share/sddm/themes/clock-ring/background.jpg /etc/modprobe.d/blacklist-nouveau.conf /etc/modprobe.d/nvidia-wayland.conf )
PRISTINE=/usr/share/hypr/hyprland.lua      # Hyprland's own default config (from the package)

stage_live() {   # stage_live DIR : copies the live files into DIR/home, DIR/system, DIR/pristine
  local d="$1" f x
  mkdir -p "$d/home" "$d/system" "$d/pristine"
  cd "$HOME" || return 1
  for x in "${HOME_DIRS[@]}"; do [ -d "$x" ] && find "$x" -type f ! -name Icons.qml ! -name 'dm-session*' ! -name '*.bak*' ! -name '*.before-*' ! -name '*-bak' ! -name '*.orig' ! -name '*~' -print0 | while IFS= read -r -d '' f; do cp -a --parents "$f" "$d/home/"; done; done
  for x in "${HOME_FILES[@]}"; do [ -e "$x" ] || [ -L "$x" ] && cp -a --parents "$x" "$d/home/"; done
  for f in .config/kitty/*.conf .config/hypr/*.lua .config/hypr/hypridle.conf .config/hypr/hyprlock.conf; do
    case "$f" in */bkp-*|*.bak*|*.before-*|*'~') continue ;; esac
    [ -f "$f" ] && cp -a --parents "$f" "$d/home/"
  done
  for f in .local/share/applications/*.desktop; do [ -f "$f" ] && grep -q '^# snow-' "$f" && cp -a --parents "$f" "$d/home/"; done
  for f in "${SYSTEM_FILES[@]}"; do [ -f "$f" ] && cp -a --parents "$f" "$d/system/" 2>/dev/null; done
  [ -f "$PRISTINE" ] && cp -a "$PRISTINE" "$d/pristine/hyprland.lua"
  return 0
}
tree_hash() { ( cd "$1" && find home system -type f 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; sha256sum < "$f" | cut -d' ' -f1; done | sha256sum | cut -d' ' -f1 ); }
make_tar() {     # make_tar STAGEDIR OUTFILE
  local st="$1" out="$2" n h
  n=$(find "$st/home" -type f | wc -l); h=$(tree_hash "$st")
  { echo "snow-files-tarball"; echo "date: $(date '+%F %T')"; echo "host: $(hostname 2>/dev/null)"; echo "hyprland: $(hyprland --version 2>/dev/null | head -1)"; echo "files-in-home: $n"; echo "hash: $h"; } > "$st/INFO.txt"
  mkdir -p "$(dirname "$out")" && tar -C "$st" -czf "$out.tmp" . && mv -f "$out.tmp" "$out"
}
mirror_current() {   # mirror_current STAGEDIR : plain, visible copy of the staged files in Files/Plain-Files (home/.config -> home/config, ...)
  local d="$PLAIN" e n ok=1
  rm -rf "$d.new" && mkdir -p "$d.new/home" || ok=0
  for e in "$1"/home/.[!.]* "$1"/home/*; do [ -e "$e" ] || [ -L "$e" ] || continue; n="$(basename "$e")"; cp -a "$e" "$d.new/home/${n#.}" || ok=0; done
  cp -a "$1/system" "$1/pristine" "$1/INFO.txt" "$d.new/" 2>/dev/null
  printf '%s\n' "PLAIN COPY of your Snow files (made by Files/backup.sh, nothing here is used by Snow itself)." "home/config  = ~/.config   (hidden folder: the leading dot is dropped here so you can see it)" "home/local   = ~/.local" "home/bashrc  = ~/.bashrc" "system/      = login screen files (/etc, /usr/share)" "" "You may read or edit files here. Put them back on your PC with:  bash restore.sh files" "(the next Files/backup.sh refreshes this folder from your live system)." > "$d.new/README.txt"
  [ "$ok" = 1 ] && rm -rf "$d" && mv "$d.new" "$d" && echo "${G}[PASS]${N} plain copy of your files: Files/Plain-Files/ ($(find "$d/home" -type f | wc -l) files)" || echo "${R}[FAIL]${N} could not write Files/Plain-Files"
}
dated_copy() {   # dated_copy FILE LABEL : copy into Snow/Backup with date + time (never replaced)
  mkdir -p "$BKDIR" && cp -f "$1" "$BKDIR/Snow-$2$TS.tar.gz" && echo "${G}[PASS]${N} dated copy: Backup/Snow-$2$TS.tar.gz"
}
hash_of() { tar -xzOf "$1" ./INFO.txt 2>/dev/null | sed -n 's/^hash: //p'; }

ST="$(mktemp -d)"; trap 'rm -rf "$ST"' EXIT
stage_live "$ST" || { echo "${R}[FAIL]${N} could not read your home folder"; exit 1; }
NF=$(find "$ST/home" -type f | wc -l)
if [ "$NF" -lt 3 ]; then
  echo "${R}[FAIL]${N} only $NF Snow files found on this system: nothing to save. (A new PC? run: bash $SNOW_DIR/install.sh)"; exit 1
fi
HASH=$(tree_hash "$ST")

case "$MODE" in
  --status)
    [ -f "$LATEST" ] || { echo "${Y}[WARN]${N} there is no latest backup yet:  bash $FILES_DIR/backup.sh"; exit 3; }
    [ "$(hash_of "$LATEST")" = "$HASH" ] && { echo "${G}[PASS]${N} your live files are identical to the latest backup"; exit 0; }
    echo "${Y}[WARN]${N} your live files changed since the latest backup:  bash $FILES_DIR/backup.sh"; exit 3 ;;
  --original)
    if [ -f "$ORIG" ]; then echo "${G}[PASS]${N} the original already exists (it is never replaced): $ORIG"; exit 0; fi
    make_tar "$ST" "$ORIG" && echo "${G}[PASS]${N} original made: $ORIG  ($NF files)" || { echo "${R}[FAIL]${N} could not make the original"; exit 1; }
    dated_copy "$ORIG" original-
    exit 0 ;;
  --snapshot)
    mkdir -p "$HIST"; make_tar "$ST" "$HIST/Snow-$SNAPNAME-$TS.tar.gz" && echo "${G}[PASS]${N} safety copy of your live files: history/Snow-$SNAPNAME-$TS.tar.gz" || { echo "${R}[FAIL]${N} safety copy failed"; exit 1; }
    exit 0 ;;
  latest|"")
    echo "${B}Backup -> $LATEST${N}  ($NF files)"
    if [ -f "$LATEST" ]; then
      if [ "$(hash_of "$LATEST")" = "$HASH" ]; then echo "${G}[PASS]${N} nothing changed since the latest backup: no new file made"; [ -f "$PLAIN/INFO.txt" ] || mirror_current "$ST"; exit 0; fi
      [ -d "$BKDIR" ] && ls "$BKDIR"/Snow-2*.tar.gz >/dev/null 2>&1 || dated_copy "$LATEST" "$(date -r "$LATEST" +%Y%m%d-%H%M%S)-old-" >/dev/null
    fi
    make_tar "$ST" "$LATEST" && echo "${G}[PASS]${N} latest backup made ($(du -h "$LATEST" | cut -f1))" || { echo "${R}[FAIL]${N} backup failed"; exit 1; }
    dated_copy "$LATEST" ""
    mirror_current "$ST"
    [ -f "$ORIG" ] || echo "${Y}[WARN]${N} there is no original yet: it is made by install.sh when everything passed"
    echo "Copy the whole Snow folder to a USB stick / cloud." ;;
  *) echo "usage: bash backup.sh [--status|--original|--snapshot NAME]"; exit 2 ;;
esac
