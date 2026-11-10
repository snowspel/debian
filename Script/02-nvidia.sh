#!/usr/bin/env bash
# 02-nvidia.sh : NVIDIA driver 590 (open modules)
# Driver from NVIDIA's Debian 13 repository, nouveau blacklisted. Needs a REBOOT afterwards. Run in a text console (Ctrl+Alt+F3).
#   bash Script/02-nvidia.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/02-nvidia.sh check    read-only check
MOD="02-nvidia"; TITLE="NVIDIA driver 590 (open modules)"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "s|etc/modprobe.d/blacklist-nouveau.conf|644|0"
  "s|etc/modprobe.d/nvidia-wayland.conf|644|0"
)
emit() {
case "$1" in
"s/etc/modprobe.d/blacklist-nouveau.conf")
cat <<'SNOW_FILE_END_4b7d'
blacklist nouveau
options nouveau modeset=0
SNOW_FILE_END_4b7d
;;
"s/etc/modprobe.d/nvidia-wayland.conf")
cat <<'SNOW_FILE_END_4b7d'
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
# hardware video decode (VA-API) for browsers/mpv on NVIDIA; Hyprland sets LIBVA_DRIVER_NAME=nvidia and NVD_BACKEND=direct
install_vaapi() { apt_install nvidia-vaapi-driver; }
extra_check() {
if have lspci && lspci 2>/dev/null | grep -qi nvidia; then
  V=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
  case "$V" in 59*) pass "NVIDIA driver $V is running" ;; "") fail "nvidia-smi does not work (driver not loaded)" "reboot; if still broken: nvidia-smi ; dkms status ; sudo dmesg | grep -i nvidia | tail -20   (see the output above)" ;; *) warn "NVIDIA driver $V is running (expected 590: glitches possible)" "bash ~/Snow/Script/02-nvidia.sh" ;; esac
  [ -f /usr/lib/x86_64-linux-gnu/dri/nvidia_drv_video.so ] && pass "VA-API driver (hardware video decode) is installed" || warn "nvidia-vaapi-driver is missing: no hardware video decode" "sudo apt-get install nvidia-vaapi-driver"
  lsmod 2>/dev/null | grep -q '^nouveau' && fail "nouveau is loaded (it must not be)" "bash ~/Snow/Script/02-nvidia.sh   then reboot" || pass "nouveau is not loaded"
  MS=$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null)
  if [ "$MS" = Y ]; then pass "nvidia_drm modeset=Y"
  elif [ -z "$MS" ] && grep -qsE 'nvidia_drm +modeset=1' /etc/modprobe.d/*.conf; then pass "nvidia_drm modeset=1 is configured (the live value needs admin rights to read)"
  else warn "nvidia_drm modeset is not Y" "bash ~/Snow/Script/02-nvidia.sh   then reboot"; fi
else pass "no NVIDIA GPU: nothing to check"; fi
}
CUSTOM_RUN=run_nvidia
run_nvidia() {
# 10-nvidia : NVIDIA driver 590 (open kernel modules) from NVIDIA's official Debian 13 repository, nouveau blacklisted.
# WHY: Debian's own driver is 550. It has no explicit sync, so Hyprland shows broken text / frozen video parts. 590 fixes that.
# Run it in a text console (Ctrl+Alt+F3), not inside the desktop. Needs a REBOOT afterwards.
# Env: SNOW_NVIDIA_BRANCH=590 (or 595)   SNOW_YES=1 (do not ask)   SNOW_FORCE=1 (allow running inside a desktop session)
step "02 nvidia: driver ${SNOW_NVIDIA_BRANCH:-590} (open kernel modules)"
BRANCH="${SNOW_NVIDIA_BRANCH:-590}"
REPO_URL="https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64"
export PATH="$PATH:/usr/sbin:/sbin"
RB="$BKROOT/nvidia-rollback.sh"

if ! have lspci || ! lspci 2>/dev/null | grep -qi 'nvidia'; then
  pass "no NVIDIA GPU found: this module is skipped"; summary "$MOD"; return 0 2>/dev/null || exit 0
fi
CUR=$(head -1 /proc/driver/nvidia/version 2>/dev/null | grep -oE '[0-9]{3}\.[0-9]+(\.[0-9]+)?' | head -1)   # note: the open module line has no number right after 'Module'
echo "    NVIDIA driver running now: ${CUR:-none}"
NRF="$LOGDIR/.need-reboot"
case "$CUR" in "$BRANCH".*) rm -f "$NRF" ;; esac

# the two modprobe files are always (re)installed: they are what stopped nouveau and set modeset/fbdev
install_modprobe() {
  local f changed=0 rc
  for f in blacklist-nouveau.conf nvidia-wayland.conf; do
    payload_sys "etc/modprobe.d/$f" "/etc/modprobe.d/$f"; rc=$?
    [ $rc = 0 ] && changed=1; [ $rc = 1 ] && fail "could not install /etc/modprobe.d/$f"
  done
  [ "$changed" = 1 ] && { asroot update-initramfs -u >/dev/null 2>&1 && pass "modprobe files installed, initramfs updated (nouveau blacklisted)" || fail "update-initramfs failed"; } \
    || pass "modprobe files already in place (nouveau blacklisted, modeset=1 fbdev=1)"
}

case "$CUR" in
  "$BRANCH".*) pass "driver $CUR is already running: nothing to install"; install_modprobe; install_vaapi; summary "$MOD"; return 0 2>/dev/null || exit 0 ;;
esac
if dpkg -l 'nvidia-kernel-open-dkms' 2>/dev/null | grep -q '^ii' && dpkg -l nvidia-driver 2>/dev/null | grep '^ii' | grep -q " ${BRANCH}\."; then
  pass "driver $BRANCH is installed but not running: the modprobe files may be missing, or a reboot is needed"
  install_modprobe
  if [ -f "$NRF" ]; then rm -f "$NRF"; warn "driver $BRANCH is installed but NOT running after a reboot: the other steps continue. Look: nvidia-smi ; dkms status ; lsmod | grep nvidia ; sudo dmesg | grep -i nvidia | tail -20"
  else : > "$NRF"; warn "reboot, then run bash ~/Snow/install.sh again"; fi
  summary "$MOD"; return 0 2>/dev/null || exit 0
fi

# safety: not inside a running desktop
if [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] && [ "${SNOW_FORCE:-0}" != 1 ]; then
  fail "run this in a text console: press Ctrl+Alt+F3, log in, then: bash ~/Snow/install.sh   (or set SNOW_FORCE=1 to override)"
  summary "$MOD"; return 1 2>/dev/null || exit 1
fi
[ "$(uname -m)" = x86_64 ] || { fail "only x86_64 is supported here"; summary "$MOD"; return 1 2>/dev/null || exit 1; }
apt_install "linux-headers-$(uname -r)" dkms build-essential
curl -fsSI -m 20 "$REPO_URL/cuda-keyring_1.1-1_all.deb" >/dev/null 2>&1 && pass "NVIDIA repo reachable" || { fail "cannot reach $REPO_URL (internet?)"; summary "$MOD"; return 1 2>/dev/null || exit 1; }
have mokutil && mokutil --sb-state 2>/dev/null | grep -qi enabled && { fail "Secure Boot is ON: the new module would not load. Turn it off in the BIOS first."; summary "$MOD"; return 1 2>/dev/null || exit 1; }

# rollback script, written BEFORE anything changes
mkdir -p "$BKROOT"
dpkg-query -W -f='${Package}=${Version} ${Status}\n' 2>/dev/null | grep -i -E '^(.*nvidia.*|libcuda.*|libnvcuvid.*|firmware-nvidia.*)=' | grep ' installed$' | awk '{print $1}' > "$BKROOT/nvidia-old-packages.txt"
cat > "$RB" <<RBEOF
#!/usr/bin/env bash
# ROLLBACK to Debian's own NVIDIA driver. Run in a text console (Ctrl+Alt+F3), then reboot.
sudo apt-get purge -y nvidia-open nvidia-kernel-open-dkms nvidia-driver-cuda 'nvidia-driver-pinning-*' cuda-keyring 2>&1 | tail -3
sudo rm -f /etc/apt/sources.list.d/cuda-debian13-x86_64.list /etc/apt/preferences.d/nvidia-driver-pinning* /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-get update
[ -s "$BKROOT/nvidia-old-packages.txt" ] && sudo apt-get install -y --allow-downgrades \$(tr '\n' ' ' < "$BKROOT/nvidia-old-packages.txt") || sudo apt-get install -y nvidia-driver
sudo update-initramfs -u
echo "done: now reboot"
RBEOF
chmod +x "$RB"; pass "rollback script: $RB"

# repo + pin
T=$(mktemp -d)
if installed cuda-keyring; then pass "cuda-keyring already installed"
else
  curl -fsSL -o "$T/k.deb" "$REPO_URL/cuda-keyring_1.1-1_all.deb" && asroot apt-get install -y "$T/k.deb" >/dev/null 2>&1 && pass "cuda-keyring installed" || { fail "could not install the NVIDIA keyring"; rm -rf "$T"; summary "$MOD"; return 1 2>/dev/null || exit 1; }
fi
rm -rf "$T"
asroot apt-get update >/dev/null 2>&1 && pass "apt-get update" || { fail "apt-get update failed"; summary "$MOD"; return 1 2>/dev/null || exit 1; }
apt-cache policy "nvidia-driver-pinning-$BRANCH" 2>/dev/null | awk '/Candidate:/{print $2}' | grep -vq '(none)' || { fail "nvidia-driver-pinning-$BRANCH not found in the NVIDIA repo (try SNOW_NVIDIA_BRANCH=595)"; summary "$MOD"; return 1 2>/dev/null || exit 1; }
asroot apt-get install -y "nvidia-driver-pinning-$BRANCH" >/dev/null 2>&1 && pass "branch pinned to $BRANCH" || { fail "could not install the pin package"; summary "$MOD"; return 1 2>/dev/null || exit 1; }

# dry run: apt may remove NVIDIA/CUDA packages only
PK=(nvidia-driver nvidia-kernel-open-dkms nvidia-driver-cuda nvidia-settings)
SIM=$(apt-get -s install "${PK[@]}" 2>&1)
echo "$SIM" | grep -E '^(Inst|Remv)' | awk '{print $1, $2, $3}' | head -60
echo "$SIM" | grep -q '^E:' && { fail "dry run error: $(echo "$SIM" | grep '^E:' | head -3 | tr '\n' ' ')"; summary "$MOD"; return 1 2>/dev/null || exit 1; }
BAD=$(echo "$SIM" | awk '/^Remv/{print $2}' | grep -v -i -E 'nvidia|cuda|nvcuvid|glx-alternative')
[ -z "$BAD" ] && pass "dry run: apt removes only NVIDIA/CUDA packages" || { fail "dry run would also remove: $(echo "$BAD" | tr '\n' ' ')"; summary "$MOD"; return 1 2>/dev/null || exit 1; }
if [ "${SNOW_YES:-0}" != 1 ]; then
  read -r -p "Type YES (capital letters) to install the NVIDIA $BRANCH driver now: " A
  [ "$A" = YES ] || { warn "not confirmed: nothing installed (repo + pin stay added; undo: bash $RB)"; summary "$MOD"; return 0 2>/dev/null || exit 0; }
fi
asroot env DEBIAN_FRONTEND=noninteractive apt-get install -y "${PK[@]}" && pass "NVIDIA packages installed" || { fail "apt install failed: run bash $RB"; summary "$MOD"; return 1 2>/dev/null || exit 1; }
NEW=$(modinfo -F version nvidia 2>/dev/null | head -1)
case "$NEW" in "$BRANCH".*) pass "kernel module for the next boot: version $NEW" ;; *) fail "modinfo says '${NEW:-none}', not $BRANCH: do NOT reboot, run bash $RB" ;; esac
install_modprobe
install_vaapi
: > "$NRF"
warn "REBOOT now. Then check:  nvidia-smi   and in Hyprland: grep -i 'Starting backend' \$(ls -t /run/user/\$(id -u)/hypr/*/hyprland.log | head -1)   (expect: driver nvidia-drm)"
summary "$MOD"

}
component_main "$@"
