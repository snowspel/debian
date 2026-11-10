#!/usr/bin/env bash
# 25-yazi.sh : File browser in the terminal: yazi
# yazi from its official apt repository, the Snow keymap, and EDITOR=mousepad (yazi "Edit"). The kitty Ctrl+C / Ctrl+V pass-through lines are in 04-kitty.
#   bash Script/25-yazi.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/25-yazi.sh check    read-only check
MOD="25-yazi"; TITLE="File browser in the terminal: yazi"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/yazi/keymap.toml|644|0"
)
emit() {
case "$1" in
"u/.config/yazi/keymap.toml")
cat <<'SNOW_FILE_END_4b7d'
# ---- Snow keys: copy / cut / paste / delete ----
[[mgr.prepend_keymap]]
on = "<C-c>"
run = "yank"
desc = "Copy"
[[mgr.prepend_keymap]]
on = "<C-x>"
run = "yank --cut"
desc = "Cut"
[[mgr.prepend_keymap]]
on = "<C-v>"
run = "paste"
desc = "Paste"
[[mgr.prepend_keymap]]
on = "<Delete>"
run = "remove"
desc = "Move to trash"
[[mgr.prepend_keymap]]
on = "<S-Delete>"
run = "remove --permanently"
desc = "Delete permanently"
[[mgr.prepend_keymap]]
on = "<C-w>"
run = "close"
desc = "Close tab / quit"
[[mgr.prepend_keymap]]
on = "<C-Space>"
run = [ "toggle", "arrow 1" ]
desc = "Select file"
[[mgr.prepend_keymap]]
on = "<C-a>"
run = "toggle_all --state=on"
desc = "Select all"
# ---- extra keys ----
[[mgr.prepend_keymap]]
on = "<F2>"
run = "rename --cursor=before_ext"
desc = "Rename"
[[mgr.prepend_keymap]]
on = "<C-n>"
run = "create"
desc = "New file / folder (end the name with / for a folder)"
[[mgr.prepend_keymap]]
on = "<C-f>"
run = "filter --smart"
desc = "Filter files"
[[mgr.prepend_keymap]]
on = "<C-t>"
run = "tab_create --current"
desc = "New tab"
[[mgr.prepend_keymap]]
on = "<A-h>"
run = "hidden toggle"
desc = "Show / hide hidden files"
[[mgr.prepend_keymap]]
on = "<A-Left>"
run = "leave"
desc = "Parent folder"
[[mgr.prepend_keymap]]
on = "<A-Right>"
run = "enter"
desc = "Open folder"
# ---- old keys switched off (q and Esc stay as a safety) ----
[[mgr.prepend_keymap]]
on = "y"
run = "noop"
[[mgr.prepend_keymap]]
on = "x"
run = "noop"
[[mgr.prepend_keymap]]
on = "p"
run = "noop"
[[mgr.prepend_keymap]]
on = "d"
run = "noop"
[[mgr.prepend_keymap]]
on = "D"
run = "noop"
[[mgr.prepend_keymap]]
on = "<Space>"
run = "noop"
# ---- snow-yazi-extra ----
[[mgr.prepend_keymap]]
on = "<A-1>"
run = "cd ~"
desc = "Home"
[[mgr.prepend_keymap]]
on = "<A-2>"
run = "cd ~/Downloads"
desc = "Downloads"
[[mgr.prepend_keymap]]
on = "<A-3>"
run = "cd ~/Documents"
desc = "Documents"
[[mgr.prepend_keymap]]
on = "<A-c>"
run = "copy path"
desc = "Copy full path"
[[mgr.prepend_keymap]]
on = "<A-n>"
run = "copy filename"
desc = "Copy file name"
[[mgr.prepend_keymap]]
on = "<A-o>"
run = "open --interactive"
desc = "Open with..."
[[mgr.prepend_keymap]]
on = "<A-s>"
run = "search --via=fd"
desc = "Search by name"
[[mgr.prepend_keymap]]
on = "<A-g>"
run = "search --via=rg"
desc = "Search text inside files"
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
pre() {
if ! have yazi; then
  echo "Installing yazi (official yazi apt repository)..."
  if curl -fsSL https://yazi-rs.github.io/builds/yazi-keyring.gpg | asroot tee /usr/share/keyrings/yazi-keyring.gpg >/dev/null \
     && echo 'deb [signed-by=/usr/share/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds/ stable main' | asroot tee /etc/apt/sources.list.d/yazi.list >/dev/null \
     && asroot apt-get update >/dev/null 2>&1 && asroot apt-get install -y yazi; then pass "yazi installed"
  else fail "yazi install failed" "internet? then: bash ~/Snow/Script/25-yazi.sh   (see the error above)"; fi
fi
}
post() {
touch "$HOME/.bashrc"
if grep -q 'snow-editor' "$HOME/.bashrc"; then pass "EDITOR already set in ~/.bashrc"; else backup "$HOME/.bashrc"; printf '\n# snow-editor\nexport EDITOR=mousepad\nexport VISUAL=mousepad\n' >> "$HOME/.bashrc" && pass "EDITOR=mousepad added to ~/.bashrc"; fi
}
extra_check() {
have yazi && pass "yazi installed" || fail "yazi is not installed" "bash ~/Snow/Script/25-yazi.sh"
grep -q 'snow-yazi-keys' "$KITTY/snow-keys.conf" 2>/dev/null && pass "kitty passes Ctrl+C/V to yazi" || warn "kitty lines for yazi are missing (Ctrl+C / Ctrl+V would not reach yazi)" "bash ~/Snow/Script/04-kitty.sh   (then open a NEW kitty window)"
grep -q 'snow-editor' "$HOME/.bashrc" 2>/dev/null && pass "EDITOR=mousepad is set in ~/.bashrc" || warn "EDITOR is not set" "bash ~/Snow/Script/25-yazi.sh"
}
component_main "$@"
