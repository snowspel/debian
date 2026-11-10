#!/usr/bin/env bash
# 01-system.sh : System: checks, backports, base packages
# Checks Debian 13, adds trixie-backports, installs the base packages every other script needs.
#   bash Script/01-system.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/01-system.sh check    read-only check
MOD="01-system"; TITLE="System: checks, backports, base packages"
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
grep -rqsE "^[^#]*${VC}-backports" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null && pass "apt source ${VC}-backports is configured" || fail "no ${VC}-backports apt source" "bash ~/Snow/Script/01-system.sh"
for c in jq curl git sudo nmcli bluetoothctl wpctl; do have "$c" && pass "program $c" || warn "program $c not found" "bash ~/Snow/Script/01-system.sh"; done
for s in NetworkManager bluetooth; do [ "$(systemctl is-enabled $s 2>/dev/null)" = enabled ] && pass "service $s enabled" || warn "service $s is not enabled" "sudo systemctl enable --now $s"; done
l=$(sed -n 's/^LANG=//p' /etc/default/locale 2>/dev/null | tr -d '"')
case "$l" in *[Uu][Tt][Ff]-8*|*[Uu][Tt][Ff]8*) pass "system language is UTF-8 ($l)" ;; *) warn "system language is not UTF-8 (LANG=${l:-unset}): Qt logs Compose errors, Hindi file names can break" "sudo update-locale LANG=${l:-en_US}.UTF-8   (check first: locale -a | grep -i utf ; then log out and in)" ;; esac
}
CUSTOM_RUN=run_system
run_system() {
# 00-system : checks, trixie-backports, base packages (network, bluetooth, audio, fonts, tools, login screen, build tools for the NVIDIA module)
step "01 system: checks and base packages"
. /etc/os-release 2>/dev/null
[ "${ID:-?}" = debian ] && pass "Debian ${VERSION_ID:-?} (${VC})" || warn "this is '${ID:-?}', not Debian: package names may not fit"
[ "${VERSION_ID:-}" = 13 ] || warn "Debian 13 (trixie) is what this was made for (found: ${VERSION_ID:-?})"
have sudo || have su || fail "neither sudo nor su found"

# backports (Hyprland, Quickshell, hypridle, hyprlock live there)
if grep -rqsE "^[^#]*${VC}-backports" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
  pass "apt source ${VC}-backports is configured"
else
  echo "deb http://deb.debian.org/debian ${VC}-backports main" | asroot tee /etc/apt/sources.list.d/snow-backports.list >/dev/null \
    && pass "added ${VC}-backports (/etc/apt/sources.list.d/snow-backports.list)" || fail "could not add ${VC}-backports"
fi
apt_update

# base packages (everything the Snow panels, scripts, SDDM theme and apps call)
apt_install \
  sudo curl wget git unzip jq ca-certificates gpg pciutils mokutil \
  network-manager bluez rfkill \
  pipewire pipewire-pulse wireplumber pulseaudio-utils \
  fontconfig fonts-inter fonts-jetbrains-mono fonts-montserrat imagemagick \
  swaybg zenity grim slurp wl-clipboard libnotify-bin \
  sddm qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-window qml6-module-qtquick-layouts \
  linux-headers-amd64 build-essential dkms \
  brightnessctl playerctl \
  xdg-user-dirs xdg-desktop-portal-gtk polkitd

have systemctl && { asroot systemctl enable --now NetworkManager >/dev/null 2>&1; asroot systemctl enable --now bluetooth >/dev/null 2>&1; }
# Bluetooth stays OFF after boot (switch it on in Quick settings)
[ -f /etc/bluetooth/main.conf ] && { asroot sed -i "s/^#\?AutoEnable=.*/AutoEnable=false/" /etc/bluetooth/main.conf; grep -q "^AutoEnable=false" /etc/bluetooth/main.conf || asroot sed -i "/^\[Policy\]/a AutoEnable=false" /etc/bluetooth/main.conf; }
systemctl is-enabled NetworkManager >/dev/null 2>&1 && pass "NetworkManager enabled" || warn "NetworkManager is not enabled"
systemctl is-enabled bluetooth >/dev/null 2>&1 && pass "bluetooth enabled" || warn "bluetooth is not enabled"
summary "$MOD"

}
component_main "$@"
