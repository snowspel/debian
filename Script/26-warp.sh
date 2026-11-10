#!/usr/bin/env bash
# 26-warp.sh : Cloudflare WARP
# Official Cloudflare apt repo, warp-svc, device registration. Does NOT connect by itself (cloud icon in quick settings).
#   bash Script/26-warp.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/26-warp.sh check    read-only check
MOD="26-warp"; TITLE="Cloudflare WARP"
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
have warp-cli && pass "warp-cli installed" || fail "warp-cli missing" "bash ~/Snow/Script/26-warp.sh"
systemctl is-active warp-svc >/dev/null 2>&1 && pass "warp-svc is running" || warn "warp-svc is not running" "sudo systemctl enable --now warp-svc"
}
CUSTOM_RUN=run_warp
run_warp() {
# 55-warp : Cloudflare WARP (official apt repo of Cloudflare, supports Debian 13 trixie). Installs cloudflare-warp, starts warp-svc, registers the device.
# It does NOT connect by itself: use the cloud icon in the quick settings (Super+Tab), click = connect / disconnect, right-click = WARP card.
step "26 warp: Cloudflare WARP"
KEY=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg; LST=/etc/apt/sources.list.d/cloudflare-client.list
if ! have warp-cli; then
  have gpg || apt_install gpg
  if [ ! -s "$KEY" ]; then
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | asroot gpg --yes --dearmor --output "$KEY" && pass "Cloudflare signing key added" || fail "could not download/add the Cloudflare key"
  else pass "Cloudflare signing key already there"; fi
  echo "deb [signed-by=$KEY] https://pkg.cloudflareclient.com/ $VC main" | asroot tee "$LST" >/dev/null && pass "apt source written: $LST ($VC)" || fail "could not write $LST"
  apt_update
  apt_install cloudflare-warp
else pass "warp-cli already installed"; fi
if have warp-cli; then
  asroot systemctl enable --now warp-svc >/dev/null 2>&1; sleep 2
  systemctl is-active warp-svc >/dev/null 2>&1 && pass "warp-svc is running" || fail "warp-svc is not running (sudo systemctl status warp-svc)"
  ST=$(bash "$HOME/.config/snow/bin/quicksettings/warp.sh" status 2>/dev/null || bash "$HOME/.config/snow/bin/quicksettings/warp.sh" status)
  case "$ST" in *unregistered*) timeout 30 warp-cli --accept-tos registration new >/dev/null 2>&1 || timeout 30 warp-cli --accept-tos register >/dev/null 2>&1; ST=$(bash "$HOME/.config/snow/bin/quicksettings/warp.sh" status) ;; esac
  case "$ST" in ""|*unregistered*|*nosvc*) fail "WARP is not ready: ${ST:-no answer from warp.sh}" ;; *) pass "WARP ready: $ST" ;; esac
fi
summary "$MOD"

}
component_main "$@"
