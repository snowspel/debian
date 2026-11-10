#!/usr/bin/env bash
# install.sh : installs / restores the WHOLE Snow desktop on Debian 13. Everything it needs is inside the Script folder.
#   bash install.sh
# That is all. On a new PC use a text console (Ctrl+Alt+F3). If it asks for a reboot after the NVIDIA driver, reboot and run the same command again.
# Scripts run in PRIORITY ORDER (the number in the file name). One script failing never stops the others.
# At the end it fills the Files folder (original + latest backup) and runs doctor.sh for the final report.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOTQ="${ROOT// /\\ }"
case "${1:-}" in
  -V|--version) echo "Snow $(cat "$ROOT/VERSION" 2>/dev/null || echo unknown)"; exit 0 ;;
  -h|--help) sed -n '2,6p' "$ROOT/install.sh" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac
export SNOW_ROOT="$ROOT" SCRIPT_DIR="$ROOT/Script" SNOW_YES=1
G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; B=$'\e[1m'; N=$'\e[0m'
[ "$(id -u)" -eq 0 ] && { echo "[PROBLEM] do not run as root: run as your normal user (the sudo password is asked inside)"; exit 1; }
[ -f "$ROOT/Script/lib/common.sh" ] || { echo "[PROBLEM] Script/lib/common.sh is missing: the Snow folder is incomplete."; exit 1; }
MODS=("$ROOT"/Script/[0-9][0-9]-*.sh)
SEL=()
if [ "$#" = 0 ]; then SEL=("${MODS[@]}")
else for w in "$@"; do hit=0; for m in "${MODS[@]}"; do case "$(basename "$m" .sh)" in *"$w"*) SEL+=("$m"); hit=1 ;; esac; done; [ "$hit" = 1 ] || { echo "[PROBLEM] no script matches '$w'"; exit 1; }; done; fi
export SNOW_TS="$(date +%Y%m%d-%H%M%S)"
LOGDIR="$ROOT/Docs/logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/install-$SNOW_TS.log"
echo "Snow install: ${#SEL[@]} script(s). Log: $LOG"
echo "This installs packages, the NVIDIA driver and the login screen. Your sudo password is asked."
sudo -v 2>/dev/null || true
REP="$LOGDIR/.report-$SNOW_TS"; : > "$REP"
{
for m in "${SEL[@]}"; do
  b=$(basename "$m" .sh)
  bash "$m" run
  rc=$?
  if [ $rc -eq 0 ]; then echo "PASS  $b" >> "$REP"; else echo "FAIL  $b" >> "$REP"; fi
  if [ "$b" = "02-nvidia" ] && [ -f "$LOGDIR/.need-reboot" ]; then
    echo; echo "STOP: the NVIDIA driver was installed. REBOOT now, then run the same command again:  bash $ROOTQ/install.sh   (finished steps are quick the second time)"
    sed 's/^/  /' "$REP"; exit 2
  fi
done
echo; echo "=== RESULT ==="; sed 's/^/  /' "$REP"
} 2>&1 | tee -a "$LOG"
RC=${PIPESTATUS[0]}
[ "$RC" = 2 ] && exit 2
# ---- Files folder: the ORIGINAL (once, only when everything passed) and the first LATEST backup
if [ "$#" = 0 ]; then
  if grep -q '^FAIL' "$REP"; then
    echo "${Y}Some scripts failed: the ORIGINAL backup is not made yet (it must be a clean state). Fix the problems (see below), run  bash $ROOTQ/install.sh  again.${N}"
    bash "$ROOT/Files/backup.sh" 2>&1 | tail -3
  else
    bash "$ROOT/Files/backup.sh" --original 2>&1 | tee -a "$LOG"
    bash "$ROOT/Files/backup.sh" 2>&1 | tee -a "$LOG"
  fi
  echo; bash "$ROOT/doctor.sh"
else
  echo "(partial run: doctor.sh was not started. Check with:  bash $ROOTQ/doctor.sh)"
fi
grep -q '^FAIL' "$REP" && exit 1
rm -f "$REP"
echo "All scripts passed. Reboot once, log in to Hyprland, then run:  bash $ROOTQ/doctor.sh"
exit 0
