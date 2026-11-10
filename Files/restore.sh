#!/usr/bin/env bash
# restore.sh : puts a Files backup back on the system (menus, Hyprland files, kitty, mpv, yazi, settings, ...).
#   bash $FILES_DIR/restore.sh                 asks: 1) LATEST  2) ORIGINAL  3) FILES (the plain folder Files/Plain-Files; with --yes and no name: LATEST)
#   bash $FILES_DIR/restore.sh files           from the plain files in Files/Plain-Files (you may have edited them)
#   bash $FILES_DIR/restore.sh original        from the ORIGINAL (the state right after the clean install)
#   bash $FILES_DIR/restore.sh PATH.tar.gz     from any tarball (for example one in history/)
#   add  --yes  to skip the question.
# Before anything is replaced, your current files are saved as history/Snow-before-restore-<date>.tar.gz .
# Programs are not installed here (that is install.sh). The login screen is only touched if you say yes.
set -u
G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; B=$'\e[1m'; N=$'\e[0m'
FILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; SNOW_DIR="$(dirname "$FILES_DIR")"
YES=0; WHAT=""
for a in "$@"; do case "$a" in --yes) YES=1 ;; *) WHAT="$a" ;; esac; done
if [ -z "$WHAT" ]; then
  if [ -t 0 ] && [ "$YES" != 1 ]; then
    HL="[not found]"; HO="[not found]"
    [ -f "$FILES_DIR/latest/Snow-latest.tar.gz" ] && HL="$(date -r "$FILES_DIR/latest/Snow-latest.tar.gz" '+%Y-%m-%d %H:%M')"
    [ -f "$FILES_DIR/original/Snow-original.tar.gz" ] && HO="$(date -r "$FILES_DIR/original/Snow-original.tar.gz" '+%Y-%m-%d %H:%M')"
    echo "${B}Which backup do you want to restore?${N}"
    echo "  1) LATEST    - your newest saved state   ($HL)"
    echo "  2) ORIGINAL  - state right after the clean install   ($HO)"
    HF="[not found]"; [ -d "$FILES_DIR/Plain-Files/home" ] && HF="$(date -r "$FILES_DIR/Plain-Files" '+%Y-%m-%d %H:%M')"
    echo "  3) FILES     - the plain files in Files/Plain-Files (.qml .lua .json ...)   ($HF)"
    read -r -p "Type 1, 2 or 3 [1]: " c
    case "${c:-1}" in 1|latest|l) WHAT=latest ;; 2|original|o) WHAT=original ;; 3|files|f) WHAT=files ;; *) echo "Cancelled. Nothing changed."; exit 0 ;; esac
  else WHAT=latest; fi
fi
case "$WHAT" in
  latest) TAR="$FILES_DIR/latest/Snow-latest.tar.gz" ;;
  original) TAR="$FILES_DIR/original/Snow-original.tar.gz" ;;
  files) TAR="$FILES_DIR/Plain-Files" ;;
  *) TAR="$WHAT" ;;
esac
if [ "$WHAT" = files ] && [ ! -d "$TAR/home" ]; then echo "${R}${B}Files/Plain-Files is empty${N}: run  bash $FILES_DIR/backup.sh  first (or use latest)."; exit 1; fi
if [ "$WHAT" != files ] && [ ! -f "$TAR" ]; then
  echo "${R}${B}Files is empty${N}: no backup found ($TAR)."
  if ls "$FILES_DIR"/*/*.tar.gz >/dev/null 2>&1; then echo "Other tarballs here:"; ls "$FILES_DIR"/*/*.tar.gz | sed 's/^/  /'; echo "Use:  bash $FILES_DIR/restore.sh PATH"
  else echo "This is a new system or nothing was saved yet. Run first:  bash $SNOW_DIR/install.sh   (it also fills the Files folder)"; fi
  exit 1
fi
ST="$(mktemp -d)"; trap 'rm -rf "$ST"' EXIT
if [ "$WHAT" = files ]; then   # plain folder -> same layout as a tarball (home/config -> home/.config)
  mkdir -p "$ST/home" "$ST/system" "$ST/pristine"
  for e in "$TAR"/home/*; do [ -e "$e" ] || [ -L "$e" ] || continue; cp -a "$e" "$ST/home/.$(basename "$e")"; done
  [ -d "$TAR/system" ] && cp -a "$TAR/system/." "$ST/system/"
  cp -a "$TAR/INFO.txt" "$ST/" 2>/dev/null; echo "plain files of $(date -r "$TAR" '+%F %T')" >> "$ST/INFO.txt"
else
  tar -xzf "$TAR" -C "$ST" || { echo "${R}[FAIL]${N} cannot open $TAR (damaged?)"; exit 1; }
fi
echo "${B}Restore <- $TAR${N}"; sed 's/^/  /' "$ST/INFO.txt" 2>/dev/null | grep -v '^  hash'
if [ "$YES" != 1 ]; then read -r -p "Replace your current Snow files with these? [y/N] " a; [ "$a" = y ] || [ "$a" = Y ] || { echo "Cancelled. Nothing changed."; exit 0; }; fi
bash "$FILES_DIR/backup.sh" --snapshot before-restore || echo "${Y}[WARN]${N} no safety copy could be made (maybe nothing to save yet): continuing"
BAD=0
ok() { echo "${G}[PASS]${N} $*"; }; wr() { echo "${Y}[WARN]${N} $*"; }; bad() { echo "${R}[FAIL]${N} $*"; BAD=$((BAD + 1)); }
H="$ST/home"; cd "$H" 2>/dev/null || { bad "the tarball has no home part"; exit 1; }

# whole folders are replaced (so a file that is not in the backup disappears)
for d in .config/quickshell/snow .config/snow .config/mpv .config/yazi .config/imv; do
  [ -d "$H/$d" ] || continue
  rm -rf "$HOME/$d" && mkdir -p "$HOME/$d" && cp -a "$H/$d/." "$HOME/$d/" && ok "$d/" || bad "could not restore $d"
done
# single files (hyprland.lua LAST: Hyprland reloads by itself when it changes)
find . -type f ! -path './.config/quickshell/snow/*' ! -path './.config/snow/*' ! -path './.config/mpv/*' ! -path './.config/yazi/*' ! -path './.config/imv/*' ! -name hyprland.lua | sed 's|^\./||' | while IFS= read -r f; do
  mkdir -p "$HOME/$(dirname "$f")"; cp -a "$H/$f" "$HOME/$f" || echo "${R}[FAIL]${N} could not restore $f"
done
[ -L "$H/.local/bin/imv" ] && { mkdir -p "$HOME/.local/bin"; cp -a "$H/.local/bin/imv" "$HOME/.local/bin/imv"; }
ok "single files (kitty, hypr, settings, launcher entries)"
[ -f "$H/.config/hypr/hyprland.lua" ] && { cp -a "$H/.config/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua" && ok "hyprland.lua (last)" || bad "could not restore hyprland.lua"; }
find "$HOME/.config/snow/bin" -name "*.sh" -type f -exec chmod +x {} + 2>/dev/null
# an OLD flat-layout backup is moved into the folder layout (same safety copy + undo as install.sh)
if [ -f "$SNOW_DIR/Script/lib/layout.sh" ]; then . "$SNOW_DIR/Script/lib/layout.sh"; SCRIPT_DIR="$SNOW_DIR/Script" SNOW_ROOT="$SNOW_DIR" layout_migrate; fi

# generated files + live reload
BIN="$HOME/.config/snow/bin"
[ -f "$BIN/core/gen-icons.sh" ] && { bash "$BIN/core/gen-icons.sh" "$HOME/.config/quickshell/snow/core/Icons.qml" >/dev/null 2>&1; rc=$?; { [ $rc = 0 ] || [ $rc = 10 ]; } && ok "Icons.qml generated" || bad "Icons.qml could not be generated (is the icon font installed? bash $SNOW_DIR/Script/05-font.sh)"; }
command -v jq >/dev/null 2>&1 && [ -f "$BIN/theme/theme.sh" ] && { bash "$BIN/theme/theme.sh" apply >/dev/null 2>&1 && ok "theme applied" || wr "theme.sh apply failed"; }
command -v jq >/dev/null 2>&1 && [ -f "$BIN/power/idle.sh" ] && bash "$BIN/power/idle.sh" gen >/dev/null 2>&1 && ok "idle timers generated"
if [ -f "$HOME/.local/share/gtksourceview-4/styles/snow.xml" ] && command -v gsettings >/dev/null 2>&1; then gsettings set org.xfce.mousepad.preferences.view color-scheme snow 2>/dev/null && ok "Mousepad colour scheme selected"; fi
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
  [ -f "$BIN/core/qs.sh" ] && bash "$BIN/core/qs.sh" restart >/dev/null 2>&1 && ok "panels restarted"
  hyprctl reload >/dev/null 2>&1 && ok "Hyprland reloaded"
else wr "not inside Hyprland: everything starts at the next login"; fi

# login screen (needs admin rights): only when you say yes
if [ -d "$ST/system/usr/share/sddm" ] || [ -d "$ST/system/etc/sddm.conf.d" ]; then
  echo; echo "The backup also holds the login screen files (SDDM theme clock-ring). NVIDIA / modprobe files are never touched here."
  a=n; [ "$YES" = 1 ] && a=n || read -r -p "Restore the login screen files too? (asks for your sudo password) [y/N] " a
  if [ "$a" = y ] || [ "$a" = Y ]; then
    ( cd "$ST/system" && find usr/share/sddm etc/sddm.conf.d -type f 2>/dev/null | while IFS= read -r f; do sudo install -D -m 644 "$f" "/$f" && echo "${G}[PASS]${N} /$f"; done )
  else echo "Login screen left as it is."; fi
fi
echo; [ "$BAD" = 0 ] && echo "${G}${B}Restore done.${N}  Your previous files: Files/history/ (Snow-before-restore-*)" || echo "${R}${B}Restore finished with $BAD problem(s)${N}: see the [FAIL] lines above"
[ "$BAD" = 0 ]
