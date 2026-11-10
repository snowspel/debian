#!/usr/bin/env bash
# 29-localsend.sh : File sharing: LocalSend
# Flatpak from Flathub.
#   bash Script/29-localsend.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/29-localsend.sh check    read-only check
MOD="29-localsend"; TITLE="File sharing: LocalSend"
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
flatpak info org.localsend.localsend_app >/dev/null 2>&1 && pass "LocalSend installed" || warn "LocalSend is not installed" "bash ~/Snow/Script/29-localsend.sh"
}
CUSTOM_RUN=run_localsend
run_localsend() {
step "29 localsend"
flatpak_app org.localsend.localsend_app
summary "$MOD"
}
component_main "$@"
