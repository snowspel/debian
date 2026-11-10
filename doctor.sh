#!/usr/bin/env bash
# doctor.sh : read-only health check of the whole Snow system. Changes nothing.
#   bash $ROOT/doctor.sh
# It asks every script in Script/ to check itself, compares Files with Script, writes a log (Docs/logs/doctor-<date>.log)
# and ends with a FINAL REPORT: every warning / problem with its solution.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOTQ="${ROOT// /\\ }"
case "${1:-}" in
  -V|--version) echo "Snow $(cat "$ROOT/VERSION" 2>/dev/null || echo unknown)"; exit 0 ;;
  -h|--help) sed -n '2,5p' "$ROOT/doctor.sh" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac
export SNOW_ROOT="$ROOT" SCRIPT_DIR="$ROOT/Script"
G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; B=$'\e[1m'; N=$'\e[0m'
[ "$(id -u)" -eq 0 ] && { echo "[PROBLEM] do not run as root"; exit 1; }
TS="$(date +%Y%m%d-%H%M%S)"; export SNOW_TS="$TS"
mkdir -p "$ROOT/Docs/logs"; LOG="$ROOT/Docs/logs/doctor-$TS.log"
RES="$(mktemp)"; CMP="$(mktemp -d)"; export SNOW_RESULTS="$RES"
trap 'rm -rf "$RES" "$CMP"' EXIT
{
echo "${B}Snow doctor $(cat "$ROOT/VERSION" 2>/dev/null)  $(date '+%F %T')${N}"
# Files vs Script: the latest Files backup is unpacked once; every script compares its own copy with it
LT="$ROOT/Files/latest/Snow-latest.tar.gz"
if [ -f "$LT" ] && tar -xzf "$LT" -C "$CMP" 2>/dev/null; then export SNOW_CMP_ROOT="$CMP"; echo "Files/latest found: it is compared with the scripts."
else echo "${Y}Files/latest is not there yet: Files is not compared with Script.${N}"; printf 'WARN|Files|no latest backup in Files|bash ~/Snow/Files/backup.sh   (or bash ~/Snow/install.sh on a new system)\n' >> "$RES"; fi
for f in backup.sh restore.sh reset.sh; do [ -f "$ROOT/Files/$f" ] && printf 'PASS|Files|Files/%s present||\n' "$f" >> "$RES" || printf 'FAIL|Files|Files/%s is missing|restore the Snow folder from your USB / cloud copy\n' "$f" >> "$RES"; done
[ -f "$ROOT/Files/Plain-Files/INFO.txt" ] && printf 'PASS|Files|Files/Plain-Files (plain copy of your files) exists||\n' >> "$RES" || printf 'WARN|Files|Files/Plain-Files (plain copy of your files) is missing|bash ~/Snow/Files/backup.sh\n' >> "$RES"
[ -f "$ROOT/Files/original/Snow-original.tar.gz" ] && printf 'PASS|Files|original backup exists||\n' >> "$RES" || printf 'WARN|Files|no original backup yet (it is made by install.sh when everything passed)|bash ~/Snow/install.sh\n' >> "$RES"
if [ -f "$ROOT/Files/backup.sh" ]; then bash "$ROOT/Files/backup.sh" --status >/dev/null 2>&1; case $? in 0) printf 'PASS|Files|live files are identical to Files/latest||\n' >> "$RES" ;; 3) printf 'WARN|Files|your live files changed since the latest backup|bash ~/Snow/Files/backup.sh\n' >> "$RES" ;; esac; fi
for m in "$ROOT"/Script/[0-9][0-9]-*.sh; do
  bash "$m" check 2>&1 | grep -vE '^$'
done
echo
# live session
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
  { pgrep -x qs >/dev/null || pgrep -x quickshell >/dev/null; } && printf 'PASS|session|Quickshell is running||\n' >> "$RES" || printf 'FAIL|session|Quickshell is not running|bash ~/.config/snow/bin/core/qs.sh restart\n' >> "$RES"
  pgrep -x swaybg >/dev/null && printf 'PASS|session|wallpaper (swaybg) is running||\n' >> "$RES" || printf 'WARN|session|swaybg is not running (no wallpaper chosen yet?)|choose a wallpaper in the quick settings panel (Super+Tab)\n' >> "$RES"
else printf 'WARN|session|not inside Hyprland: live checks skipped|log in to Hyprland and run doctor.sh again\n' >> "$RES"; fi
P=$(grep -c '^PASS|' "$RES"); W=$(grep -c '^WARN|' "$RES"); F=$(grep -c '^FAIL|' "$RES")
sed -i "s#~/Snow#$ROOTQ#g" "$RES"   # messages say the real place of this folder (any folder name works)
echo "${B}==================== FINAL REPORT ====================${N}"
echo "PASS: $P   WARN: $W   FAIL: $F"
if [ $((W + F)) = 0 ]; then echo "${G}${B}Everything is fine.${N}"; else
  echo
  grep -E '^(FAIL|WARN)\|' "$RES" | awk '!seen[$0]++' | while IFS='|' read -r lvl mod msg fix; do
    c=$Y; [ "$lvl" = FAIL ] && c=$R
    echo "${c}${lvl}${N}  [$mod] $msg"; echo "      SOLUTION: ${fix:-re-run the script named in brackets and read its output}"
  done
fi
echo "Log: $LOG"
} 2>&1 | tee "$LOG"
[ "$(grep -c '^FAIL|' "$RES")" = 0 ]
