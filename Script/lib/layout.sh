# lib/layout.sh - moves an OLD flat Snow layout into the folder layout (once; safe to run again). Sourced by common.sh and Files/restore.sh.
#   panels : ~/.config/quickshell/snow/{shell.qml,core,widgets,quicksettings,launcher,powermenu,osd,notifications,polkit}
#   helpers: ~/.config/snow/bin/<group>/NAME.sh      settings/state: ~/.config/snow/state/      shell snippets: ~/.config/snow/shell/
# Your settings are MOVED (not lost). Replaced old files are kept inside the Snow folder: Docs/logs/replaced/layout-<time>/
# A full safety copy is made first: Files/history/Snow-before-layout-<time>.tar.gz
_LAY_QML="Theme:core Sys:core Display:core Icons:core Card:widgets IconButton:widgets LevelSlider:widgets ListRow:widgets PillButton:widgets PillField:widgets RailButton:widgets SectionLabel:widgets Segmented:widgets QuickSettings:quicksettings BtPanel:quicksettings ColorPicker:quicksettings DisplayPanel:quicksettings NetPanel:quicksettings PowerPanel:quicksettings SoundPanel:quicksettings TrayButton:quicksettings TrayMenu:quicksettings WarpPanel:quicksettings WifiPanel:quicksettings Launcher:launcher PowerMenu:powermenu Notifs:notifications PolkitDialog:polkit WorkspaceOsd:osd ClockOsd:osd OsdPopup:osd Dimmer:osd"
_LAY_BIN="qs:core gen-icons:core defaults:core theme:theme apply-kitty:theme kitty-palette:theme wallpaper:theme power:power idle:power lock:power cleanup:power quick:quicksettings warp:quicksettings workspace:osd screenshot:screenshot sddm-bg:sddm snow-mpv:mpv fm:filemanager fm-ls:filemanager fm-op:filemanager fm-side:filemanager fm-dev:filemanager fm-trash:filemanager fm-info:filemanager fm-open:filemanager fm-find:filemanager fm-icon:filemanager fm-default:filemanager fm-style:filemanager"
_LAY_STATE="theme.json theme-state.json mode power.json quick.json wallpaper.current hidden-apps.txt fm-pins fm-state.json"
_LAY_SHELL="prompt.sh colors.sh"
_LAY_SED='s#\.config/snow/bin/qs\.sh#.config/snow/bin/core/qs.sh#g;s#\.config/snow/bin/gen-icons\.sh#.config/snow/bin/core/gen-icons.sh#g;s#\.config/snow/bin/app-icons\.sh#.config/snow/bin/core/app-icons.sh#g;s#\.config/snow/bin/defaults\.sh#.config/snow/bin/core/defaults.sh#g;s#\.config/snow/bin/theme\.sh#.config/snow/bin/theme/theme.sh#g;s#\.config/snow/bin/apply-kitty\.sh#.config/snow/bin/theme/apply-kitty.sh#g;s#\.config/snow/bin/kitty-palette\.sh#.config/snow/bin/theme/kitty-palette.sh#g;s#\.config/snow/bin/wallpaper\.sh#.config/snow/bin/theme/wallpaper.sh#g;s#\.config/snow/bin/power\.sh#.config/snow/bin/power/power.sh#g;s#\.config/snow/bin/idle\.sh#.config/snow/bin/power/idle.sh#g;s#\.config/snow/bin/lock\.sh#.config/snow/bin/power/lock.sh#g;s#\.config/snow/bin/cleanup\.sh#.config/snow/bin/power/cleanup.sh#g;s#\.config/snow/bin/quick\.sh#.config/snow/bin/quicksettings/quick.sh#g;s#\.config/snow/bin/warp\.sh#.config/snow/bin/quicksettings/warp.sh#g;s#\.config/snow/bin/workspace\.sh#.config/snow/bin/osd/workspace.sh#g;s#\.config/snow/bin/screenshot\.sh#.config/snow/bin/screenshot/screenshot.sh#g;s#\.config/snow/bin/sddm-bg\.sh#.config/snow/bin/sddm/sddm-bg.sh#g;s#\.config/snow/bin/snow-mpv\.sh#.config/snow/bin/mpv/snow-mpv.sh#g;s#\.config/snow/bin/fm\.sh#.config/snow/bin/filemanager/fm.sh#g;s#\.config/snow/bin/fm-ls\.sh#.config/snow/bin/filemanager/fm-ls.sh#g;s#\.config/snow/bin/fm-op\.sh#.config/snow/bin/filemanager/fm-op.sh#g;s#\.config/snow/bin/fm-side\.sh#.config/snow/bin/filemanager/fm-side.sh#g;s#\.config/snow/bin/fm-dev\.sh#.config/snow/bin/filemanager/fm-dev.sh#g;s#\.config/snow/bin/fm-trash\.sh#.config/snow/bin/filemanager/fm-trash.sh#g;s#\.config/snow/bin/fm-info\.sh#.config/snow/bin/filemanager/fm-info.sh#g;s#\.config/snow/bin/fm-open\.sh#.config/snow/bin/filemanager/fm-open.sh#g;s#\.config/snow/bin/fm-find\.sh#.config/snow/bin/filemanager/fm-find.sh#g;s#\.config/snow/bin/fm-icon\.sh#.config/snow/bin/filemanager/fm-icon.sh#g;s#\.config/snow/bin/fm-default\.sh#.config/snow/bin/filemanager/fm-default.sh#g;s#\.config/snow/bin/fm-style\.sh#.config/snow/bin/filemanager/fm-style.sh#g;s#\.config/snow/theme\.json\b#.config/snow/state/theme.json#g;s#\.config/snow/theme-state\.json\b#.config/snow/state/theme-state.json#g;s#\.config/snow/mode\b#.config/snow/state/mode#g;s#\.config/snow/power\.json\b#.config/snow/state/power.json#g;s#\.config/snow/quick\.json\b#.config/snow/state/quick.json#g;s#\.config/snow/wallpaper\.current\b#.config/snow/state/wallpaper.current#g;s#\.config/snow/hidden-apps\.txt\b#.config/snow/state/hidden-apps.txt#g;s#\.config/snow/fm-pins\b#.config/snow/state/fm-pins#g;s#\.config/snow/fm-state\.json\b#.config/snow/state/fm-state.json#g;s#\.config/snow/prompt\.sh\b#.config/snow/shell/prompt.sh#g;s#\.config/snow/colors\.sh\b#.config/snow/shell/colors.sh#g'

layout_old_found() {
  local q="$HOME/.config/quickshell/snow" c="$HOME/.config/snow" f
  [ -f "$q/Theme.qml" ] && return 0
  [ -f "$q/Card.qml" ] && return 0
  for f in "$c"/bin/*.sh; do [ -f "$f" ] && return 0; done
  for f in $_LAY_STATE $_LAY_SHELL; do [ -e "$c/$f" ] && return 0; done
  [ -d "$c/mpv" ] && return 0
  return 1
}

# layout_fix_text FILE... : rewrites old Snow paths inside small text files (hypr lua, hypridle.conf, launcher entries, .bashrc)
layout_fix_text() {
  local f
  for f in "$@"; do
    [ -f "$f" ] && [ ! -L "$f" ] || continue
    grep -qE '\.config/snow/' "$f" 2>/dev/null || continue
    sed -i -E "$_LAY_SED" "$f" 2>/dev/null
  done
}

layout_migrate() {
  layout_old_found || return 0
  [ -n "${SNOW_MIGRATING:-}" ] && return 0
  export SNOW_MIGRATING=1
  local root ts lb q c t d n s g snap mods m
  root="${SNOW_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
  ts="${SNOW_TS:-$(date +%Y%m%d-%H%M%S)}"; lb="$root/Docs/logs/replaced/layout-$ts"
  q="$HOME/.config/quickshell/snow"; c="$HOME/.config/snow"
  echo; echo "== moving to the new folder layout (one time) =="
  mkdir -p "$root/Files/history" "$lb" || { echo "[PROBLEM] cannot write inside the Snow folder: nothing was changed"; return 1; }
  snap="$root/Files/history/Snow-before-layout-$ts.tar.gz"
  ( cd "$HOME" && tar -czf "$snap" .config/quickshell/snow .config/snow .config/hypr .bashrc 2>/dev/null ) && echo "PASS safety copy: ${snap/#$HOME/~}" || { echo "[PROBLEM] safety copy failed: nothing was changed"; rm -f "$snap"; return 1; }
  # 1. settings / state: moved (kept)
  mkdir -p "$c/state" "$c/shell"
  for t in $_LAY_STATE; do [ -e "$c/$t" ] && [ ! -e "$c/state/$t" ] && mv "$c/$t" "$c/state/$t"; done
  for t in $_LAY_SHELL; do [ -e "$c/$t" ] && [ ! -e "$c/shell/$t" ] && mv "$c/$t" "$c/shell/$t"; done
  for t in "$c"/lock-bg.* "$c"/.default-volume-done; do [ -e "$t" ] || [ -L "$t" ] || continue; mv "$t" "$c/state/" 2>/dev/null; done
  # 2. old flat panels + helpers: copied to the Snow folder (backup), then removed (the new files are written below)
  for n in $_LAY_QML; do t="${n%%:*}"; [ -f "$q/$t.qml" ] || continue; mkdir -p "$lb/quickshell"; mv "$q/$t.qml" "$lb/quickshell/$t.qml"; done
  for n in $_LAY_BIN; do s="${n%%:*}"; [ -f "$c/bin/$s.sh" ] || continue; mkdir -p "$lb/bin"; mv "$c/bin/$s.sh" "$lb/bin/$s.sh"; done
  for t in "$c/bin/mpv-setup.sh" "$c/mpv"; do [ -e "$t" ] || continue; mkdir -p "$lb/old"; mv "$t" "$lb/old/"; done
  echo "PASS old files moved into ${lb/#$HOME/~}"
  # 3. text files that name old paths
  layout_fix_text "$HOME/.bashrc" "$HOME"/.config/hypr/*.lua "$HOME"/.config/hypr/hypridle.conf "$HOME"/.local/share/applications/*.desktop
  # 4. write the new files of every script that owns panels / helpers (no downloads, no apt)
  mods="06-core 07-theme 08-power-menu 09-launcher 10-workspace-osd 11-clock-osd 12-quick-settings 13-volume-osd 14-notifications 15-polkit-agent 16-screenshot 19-file-manager 17-sddm 24-mpv 18-hyprland-config"
  for m in $mods; do
    [ -f "$SCRIPT_DIR/$m.sh" ] || { echo "[PROBLEM] missing script $m.sh"; continue; }
    bash "$SCRIPT_DIR/$m.sh" files >/dev/null 2>&1 && echo "PASS $m files in the new place" || echo "[PROBLEM] $m: files could not be written (bash ${SCRIPT_DIR/#$HOME/~}/$m.sh)"
  done
  # 5. generated files
  local B2="$c/bin"
  [ -f "$B2/core/gen-icons.sh" ] && bash "$B2/core/gen-icons.sh" "$q/core/Icons.qml" >/dev/null 2>&1
  command -v jq >/dev/null 2>&1 && [ -f "$B2/theme/theme.sh" ] && bash "$B2/theme/theme.sh" apply >/dev/null 2>&1
  command -v jq >/dev/null 2>&1 && [ -f "$B2/power/power.sh" ] && bash "$B2/power/power.sh" gen >/dev/null 2>&1
  # 6. a live session gets the new files at once
  if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
    [ -f "$B2/core/qs.sh" ] && bash "$B2/core/qs.sh" restart >/dev/null 2>&1; hyprctl reload >/dev/null 2>&1
  fi
  echo "PASS layout moved. UNDO: bash $root/Files/restore.sh  (choose the safety copy) or: tar -xzf '$snap' -C \$HOME after deleting ~/.config/quickshell/snow and ~/.config/snow"
  unset SNOW_MIGRATING
  return 0
}
