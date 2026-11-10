#!/usr/bin/env bash
# 27-librewolf.sh : Browser: LibreWolf
# Flatpak from Flathub.
#   bash Script/27-librewolf.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/27-librewolf.sh check    read-only check
MOD="27-librewolf"; TITLE="Browser: LibreWolf"
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
flatpak info io.gitlab.librewolf-community >/dev/null 2>&1 && pass "LibreWolf installed" || warn "LibreWolf is not installed" "bash ~/Snow/Script/27-librewolf.sh"
}
CUSTOM_RUN=run_librewolf
run_librewolf() {
step "27 librewolf"
flatpak_app io.gitlab.librewolf-community
summary "$MOD"
}
component_main "$@"
