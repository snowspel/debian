#!/usr/bin/env bash
# 21-brave-origin.sh : Browser: Brave Origin
# Brave's own install script (flavor origin). Super+B starts brave-origin.
#   bash Script/21-brave-origin.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/21-brave-origin.sh check    read-only check
MOD="21-brave-origin"; TITLE="Browser: Brave Origin"
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
have brave-origin && pass "brave-origin installed" || fail "brave-origin is not installed" "bash ~/Snow/Script/21-brave-origin.sh"
}
CUSTOM_RUN=run_brave_origin
run_brave_origin() {
step "21 brave-origin"
if have brave-origin; then pass "brave-origin found: $(command -v brave-origin)"
else
  ( set -o pipefail; curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh ) && pass "Brave Origin installer finished" || fail "Brave Origin installer failed" "curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh   (internet connection? see the error above)"
  have brave-origin && pass "brave-origin found: $(command -v brave-origin)" || warn "installer ran but 'brave-origin' is not in PATH" "check the command name; Super+B starts brave-origin"
fi
summary "$MOD"
}
component_main "$@"
