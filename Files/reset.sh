#!/usr/bin/env bash
# reset.sh : FULL RESET. After it your desktop is plain: Hyprland's own original hyprland.lua, no Snow panels, no keybinds,
# no app customisations. Installed programs stay installed. NVIDIA files stay.
#   bash $FILES_DIR/reset.sh
# 1) it shows EXACTLY what will be removed, and waits until you type RESET
# 2) it saves everything first (Files/latest + a safety copy in Files/history/Snow-before-reset-<date>.tar.gz); if that fails, nothing is removed
# 3) it asks separately about the login screen (SDDM)
# Get everything back later:  bash $FILES_DIR/restore.sh   (or restore.sh original)
set -u
G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; B=$'\e[1m'; N=$'\e[0m'
FILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; SNOW_DIR="$(dirname "$FILES_DIR")"
PRISTINE=/usr/share/hypr/hyprland.lua
ok() { echo "${G}[PASS]${N} $*"; }; wr() { echo "${Y}[WARN]${N} $*"; }
echo "${B}Full reset${N}"
# the original Hyprland file must be available BEFORE anything is removed
if [ ! -f "$PRISTINE" ]; then
  T="$FILES_DIR/original/Snow-original.tar.gz"
  PRTMP=$(mktemp); if [ -f "$T" ] && tar -xzOf "$T" ./pristine/hyprland.lua > "$PRTMP" 2>/dev/null && [ -s "$PRTMP" ]; then PRISTINE="$PRTMP"
  else echo "${R}[FAIL]${N} Hyprland's original hyprland.lua was not found ($PRISTINE is missing, the original tarball has no copy). Nothing was removed."; exit 1; fi
fi
DIRS=( .config/quickshell/snow .config/snow .config/mpv .config/yazi .config/imv )
echo; echo "${Y}${B}Step 2: this will happen:${N}"
for d in "${DIRS[@]}"; do [ -e "$HOME/$d" ] && echo "  remove folder   ~/$d"; done
for f in "$HOME"/.config/hypr/*.lua; do [ -f "$f" ] && [ "$(basename "$f")" != hyprland.lua ] && echo "  remove          ~/.config/hypr/$(basename "$f")"; done
echo "  REPLACE         ~/.config/hypr/hyprland.lua  with Hyprland's original ($PRISTINE)"
for f in "$HOME/.config/hypr/hypridle.conf" "$HOME/.config/hypr/hyprlock.conf" "$HOME/.local/share/gtksourceview-4/styles/snow.xml"; do [ -e "$f" ] && echo "  remove          ~${f#$HOME}"; done
for f in "$HOME"/.config/kitty/snow*.conf; do [ -f "$f" ] && echo "  remove          ~${f#$HOME}"; done
grep -q '^# snow-begin' "$HOME/.config/kitty/kitty.conf" 2>/dev/null && echo "  remove          ~/.config/kitty/kitty.conf (Snow's; kitty uses its own defaults)"
for f in "$HOME"/.local/share/applications/*.desktop; do [ -f "$f" ] && grep -q '^# snow-' "$f" && echo "  remove          ~${f#$HOME}"; done
[ -L "$HOME/.local/bin/imv" ] && echo "  remove          ~/.local/bin/imv (link)"
grep -q 'snow-theme-begin' "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null && echo "  edit            ~/.config/gtk-3.0/gtk.css and gtk-4.0/gtk.css (only the Snow colour block is removed); remove ~/.config/qt5ct|qt6ct/colors/snow.conf"
grep -q 'snow-mousepad-begin' "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null && echo "  edit            ~/.config/gtk-3.0/gtk.css (only the Snow block is removed)"
grep -qE '^# snow( prompt| colors)|^# snow-editor' "$HOME/.bashrc" 2>/dev/null && echo "  edit            ~/.bashrc (only the Snow lines are removed)"
echo "  stop            panels (quickshell), wallpaper (swaybg) and the download engine (aria2; unfinished downloads stay on disk)"
echo "  NOT touched     installed programs, default apps (~/.config/mimeapps.list), NVIDIA / modprobe files, your documents, pictures, downloads"
echo "Everything above is saved FIRST in Files/latest and Files/history (if that fails, nothing is removed). Get it back:  bash $FILES_DIR/restore.sh"
read -r -p "Type RESET to continue (anything else = cancel): " a
[ "$a" = RESET ] || { echo "Cancelled. Nothing was changed."; exit 0; }
echo "Saving everything first..."
bash "$FILES_DIR/backup.sh" --snapshot before-reset || { echo "${R}Safety copy failed: reset stopped. Nothing was removed.${N}"; exit 1; }
bash "$FILES_DIR/backup.sh" || { echo "${R}Backup failed: reset stopped. Nothing was removed.${N}"; exit 1; }


pkill -x qs 2>/dev/null; pkill -x quickshell 2>/dev/null; pkill -x swaybg 2>/dev/null; pkill -f "aria2c.*rpc-listen-port=6899" 2>/dev/null
for d in "${DIRS[@]}"; do rm -rf "${HOME:?}/$d"; done
for f in "$HOME"/.config/hypr/*.lua; do [ -f "$f" ] && [ "$(basename "$f")" != hyprland.lua ] && rm -f "$f"; done
rm -f "$HOME/.config/hypr/hypridle.conf" "$HOME/.config/hypr/hyprlock.conf" "$HOME/.local/share/gtksourceview-4/styles/snow.xml" "$HOME"/.config/kitty/snow*.conf
grep -q '^# snow-begin' "$HOME/.config/kitty/kitty.conf" 2>/dev/null && rm -f "$HOME/.config/kitty/kitty.conf"
for f in "$HOME"/.local/share/applications/*.desktop; do [ -f "$f" ] && grep -q '^# snow-' "$f" && rm -f "$f"; done
[ -L "$HOME/.local/bin/imv" ] && rm -f "$HOME/.local/bin/imv"
command -v gsettings >/dev/null 2>&1 && gsettings reset org.xfce.mousepad.preferences.view color-scheme 2>/dev/null
for f in "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"; do [ -f "$f" ] && { sed -i '/snow-theme-begin/,/snow-theme-end/d' "$f"; [ -s "$f" ] || rm -f "$f"; }; done
rm -f "$HOME/.config/qt5ct/colors/snow.conf" "$HOME/.config/qt6ct/colors/snow.conf"
if [ -f "$HOME/.config/gtk-3.0/gtk.css" ]; then sed -i -e '/^\/\* snow-mousepad-begin/,/^\/\* snow-mousepad-end/d' -e '/snow-fm-begin/,/snow-fm-end/d' "$HOME/.config/gtk-3.0/gtk.css"; [ -s "$HOME/.config/gtk-3.0/gtk.css" ] || rm -f "$HOME/.config/gtk-3.0/gtk.css"; fi
if [ -f "$HOME/.bashrc" ]; then sed -i -e '/^# snow prompt$/,+1d' -e '/^# snow colors$/,+1d' -e '/^# snow-editor$/,+2d' "$HOME/.bashrc"; fi
mkdir -p "$HOME/.config/hypr" && cp -f "$PRISTINE" "$HOME/.config/hypr/hyprland.lua" && ok "hyprland.lua is Hyprland's original again" || echo "${R}[FAIL]${N} could not write hyprland.lua"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1
ok "Snow panels, keybinds, settings and app customisations removed"
[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 && ok "Hyprland reloaded with the original config"

# login screen: separate question
S1=/etc/sddm.conf.d/zz-clock-ring.conf; S2=/usr/share/sddm/themes/clock-ring
if [ -e "$S1" ] || [ -d "$S2" ] || [ -e /usr/local/sbin/snow-sddm-bg ]; then
  echo; echo "${Y}Login screen (SDDM):${N} the Snow theme clock-ring is installed:"; [ -e "$S1" ] && echo "  remove $S1"; [ -d "$S2" ] && echo "  remove folder $S2"; [ -e /usr/local/sbin/snow-sddm-bg ] && echo "  remove /usr/local/sbin/snow-sddm-bg and /etc/sudoers.d/snow-sddm-bg (the login background helper and its sudo rule)"
  echo "  (SDDM then uses its default theme; the other SDDM config files are not touched. The theme is also in Files/latest.)"
  read -r -p "Reset the login screen too? (asks for your sudo password) [y/N] " b
  if [ "$b" = y ] || [ "$b" = Y ]; then sudo rm -f "$S1" /usr/local/sbin/snow-sddm-bg /etc/sudoers.d/snow-sddm-bg && sudo rm -rf "$S2" && ok "login screen theme removed (active from the next boot)"; else echo "Login screen left as it is."; fi
fi
rm -f "${PRTMP:-}" 2>/dev/null
echo; echo "${G}${B}Reset done.${N} Log out and in (or reboot). To get everything back:  bash $FILES_DIR/restore.sh   (or: bash $SNOW_DIR/install.sh on a new system)"
