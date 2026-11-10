#!/usr/bin/env bash
# 30-mission-center.sh : System monitor: Mission Center
# Flatpak from Flathub.
#   bash Script/30-mission-center.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/30-mission-center.sh check    read-only check
MOD="30-mission-center"; TITLE="System monitor: Mission Center"
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
flatpak info io.missioncenter.MissionCenter >/dev/null 2>&1 && pass "Mission Center installed" || warn "Mission Center is not installed" "bash ~/Snow/Script/30-mission-center.sh"
}
CUSTOM_RUN=run_mission_center
run_mission_center() {
step "30 mission-center"
flatpak_app io.missioncenter.MissionCenter
summary "$MOD"
}
component_main "$@"
