#!/usr/bin/env bash
# 03-hyprland.sh : Hyprland + Quickshell
# Hyprland, hypridle, hyprlock, portal, launcher helper and Quickshell from trixie-backports (one apt run).
#   bash Script/03-hyprland.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/03-hyprland.sh check    read-only check
MOD="03-hyprland"; TITLE="Hyprland + Quickshell"
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
for c in hyprland hyprlock hypridle; do have "$c" && pass "program $c" || fail "program $c not found" "bash ~/Snow/Script/03-hyprland.sh"; done
have qs || have quickshell && pass "program qs/quickshell" || fail "qs/quickshell not found" "bash ~/Snow/Script/03-hyprland.sh"
}
CUSTOM_RUN=run_hyprland
run_hyprland() {
# 20-hyprland : Hyprland, hypridle, hyprlock, polkit agent, portal and Quickshell from trixie-backports.
step "03 hyprland: Hyprland + Quickshell (trixie-backports)"
grep -rqsE "^[^#]*${VC}-backports" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null || fail "no ${VC}-backports source: run Script/01-system.sh first"
# ONE apt run: Hyprland needs newer libraries (libxkbcommon0 >= 1.12.3) from backports at the same time
apt_install_bp hyprland hyprland-guiutils hypridle hyprlock hyprpolkitagent xdg-desktop-portal-hyprland quickshell
have hyprland && pass "Hyprland: $(hyprland --version 2>/dev/null | head -1)" || fail "hyprland command not found"
{ have qs || have quickshell; } && pass "Quickshell: $( (qs --version || quickshell --version) 2>&1 | head -1)" || fail "no qs/quickshell command"
[ -x /usr/libexec/hyprpolkitagent ] && pass "hyprpolkitagent found (only a fallback: the Snow polkit agent PolkitDialog.qml is the real one)" || warn "/usr/libexec/hyprpolkitagent not found"
summary "$MOD"

}
component_main "$@"
