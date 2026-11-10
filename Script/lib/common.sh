# lib/common.sh - shared helpers for every Script/NN-*.sh and for doctor.sh (sourced, not run).
# Every script prints PASS / WARN / FAIL. "[PROBLEM] ..." lines summarise each failure.
# A script can also be run alone:  bash Script/09-launcher.sh   (inside your Snow folder, any folder name; modes: run = default, check, list)

G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; B=$'\e[1m'; N=$'\e[0m'
_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="${SCRIPT_DIR:-$(dirname "$_LIB")}"
SNOW_ROOT="${SNOW_ROOT:-$(dirname "$SCRIPT_DIR")}"
export SNOW_ROOT SCRIPT_DIR
# the Snow folder may have ANY name and be anywhere: its place is taken from where the scripts are. Messages that say ~/Snow show the real place.
SNOW_SHOW="${SNOW_ROOT/#$HOME/~}"; SNOW_SHOW="${SNOW_SHOW// /\\ }"
_sn() { printf '%s' "${1//'~/Snow'/$SNOW_SHOW}"; }
LOGDIR="$SNOW_ROOT/Docs/logs"
MASTER_LOG="$LOGDIR/snow.log"
TS="${SNOW_TS:-$(date +%Y%m%d-%H%M%S)}"
BKROOT="$LOGDIR/replaced/$TS"          # files that a script replaced are copied here first
mkdir -p "$LOGDIR" 2>/dev/null
export PATH="$PATH:/usr/sbin:/sbin"

PASSES=0; WARNS=(); FAILS=()
MOD="${MOD:-snow}"

mlog() { printf '%s [%s] %s\n' "$(date '+%F %T')" "$MOD" "$*" >> "$MASTER_LOG" 2>/dev/null; return 0; }
# doctor.sh collects every result here:  LEVEL|module|message|solution
_res() { [ -n "${SNOW_RESULTS:-}" ] && printf '%s|%s|%s|%s\n' "$1" "$MOD" "$(_sn "$2")" "$(_sn "$3")" >> "$SNOW_RESULTS"; return 0; }
pass() { echo "${G}PASS${N} $*"; PASSES=$((PASSES + 1)); mlog "PASS $*"; _res PASS "$1" ""; }
# warn "message" ["how to fix"]      fail "message" ["how to fix"]
warn() { echo "${Y}WARN${N} $(_sn "$1")"; WARNS+=("$1"); mlog "WARN $1"; _res WARN "$1" "${2:-}"; }
fail() { echo "${R}FAIL${N} $(_sn "$1")"; FAILS+=("$1"); echo "[PROBLEM] $(_sn "$1")"; mlog "FAIL [PROBLEM] $1"; _res FAIL "$1" "${2:-bash ~/Snow/Script/${MOD}.sh   (re-run it; the [PROBLEM] lines name the failing step)}"; }
step() { echo; echo "${B}== $1 ==${N}"; mlog "== $1 =="; }
have() { command -v "$1" >/dev/null 2>&1; }
put()  { mkdir -p "$(dirname "$1")"; cat > "$1"; }

[ "$(id -u)" -eq 0 ] && [ -z "${SNOW_ALLOW_ROOT:-}" ] && { echo "[PROBLEM] do not run as root: run as your normal user (the sudo password is asked inside)"; exit 1; }

# run a command as root: sudo if there is one, else su -c
asroot() {
  if [ "$(id -u)" -eq 0 ]; then "$@"
  elif have sudo; then sudo "$@"
  else su -c "$(printf '%q ' "$@")"; fi
}

installed() { dpkg -s "$1" 2>/dev/null | grep -q '^Status: install ok installed'; }
: "${BIN:=$HOME/.config/snow/bin}"

apt_update() {   # apt-get update that says WHY it failed
  local o
  if o=$(asroot apt-get update 2>&1); then pass "apt-get update"
  else warn "apt-get update failed: $(printf "%s" "$o" | grep -E "^(E:|Err:|W:)" | head -3 | tr "\n" " ")(continuing with the old package lists)"; fi
  return 0
}

VC="trixie"
if [ -r "${SNOW_OSREL:-/etc/os-release}" ]; then VC=$(. "${SNOW_OSREL:-/etc/os-release}"; echo "${VERSION_CODENAME:-trixie}"); fi

# apt_install PKG...   installs what is missing from the normal Debian sources; warns about packages apt does not know.
apt_install() {
  local p cand need=()
  for p in "$@"; do
    installed "$p" && continue
    cand=$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/ {print $2}')
    if [ -z "$cand" ] || [ "$cand" = "(none)" ]; then warn "package $p is not available in your apt sources"; continue; fi
    need+=("$p")
  done
  if [ "${#need[@]}" -gt 0 ]; then
    echo "apt install: ${need[*]}"
    asroot apt-get install -y "${need[@]}" && pass "installed ${need[*]}" || fail "apt could not install ${need[*]}" "sudo apt-get install ${need[*]}   (read the error message above)"
  else
    pass "nothing to install (already there or not available): $*"
  fi
  return 0
}

# apt_install_bp PKG...  same, but ALL in ONE apt run with -t <codename>-backports (Hyprland needs newer libraries from backports at the same time)
apt_install_bp() {
  local p cand need=()
  for p in "$@"; do
    installed "$p" && continue
    cand=$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/ {print $2}')
    if [ -z "$cand" ] || [ "$cand" = "(none)" ]; then warn "package $p is not available in your apt sources (is ${VC}-backports configured?)"; continue; fi
    need+=("$p")
  done
  if [ "${#need[@]}" -gt 0 ]; then
    if [ -z "${SNOW_ALLOW_REMOVE:-}" ] && apt-get -s install -y -t "${VC}-backports" "${need[@]}" 2>/dev/null | grep -q "^Remv"; then
      fail "apt would REMOVE packages to install ${need[*]} from ${VC}-backports: nothing was installed" "apt-get -s install -t ${VC}-backports ${need[*]}   (the Remv lines show what apt would remove)"; return 0
    fi
    echo "apt install (backports): ${need[*]}"
    asroot apt-get install -y -t "${VC}-backports" "${need[@]}" && pass "installed ${need[*]} (backports)" || fail "apt could not install ${need[*]} from ${VC}-backports"
  else
    pass "nothing to install (already there or not available): $*"
  fi
  return 0
}

# backup PATH...   copy to $BKROOT keeping the path below $HOME
backup() {
  local f rel
  for f in "$@"; do
    [ -e "$f" ] || continue
    rel="${f#$HOME/}"; [ "$rel" = "$f" ] && rel="root$f"
    mkdir -p "$BKROOT/$(dirname "$rel")" && cp -a "$f" "$BKROOT/$rel"
  done
}

summary() {
  echo
  echo "${B}SUMMARY [$1]: PASS: $PASSES  WARN: ${#WARNS[@]}  FAIL: ${#FAILS[@]}${N}"
  [ "${#FAILS[@]}" -gt 0 ] && { echo "Failed parts:"; printf '  - %s\n' "${FAILS[@]}"; }
  [ "${#FAILS[@]}" -eq 0 ]
}

# ---------------------------------------------------------------------------------------------
# Component scripts carry their own files. A script defines:
#   ITEMS=( "u|.config/x/y.qml|644|0" ... )   kind u = under $HOME, s = absolute system path (no leading /); mode; keep (1 = never overwrite an existing file: your own settings)
#   emit KEY    prints the file for KEY ("u/<path>" or "s/<path>")
#   pre / post / extra_check   optional functions
# and ends with:  component_main "$@"
# ---------------------------------------------------------------------------------------------
# _emit KEY : the file text of KEY; @HOME@ becomes your home folder (so the files work for any user name)
_emit() { emit "$1" | sed "s#@HOME@#$HOME#g"; }
# same_text A B : equal, ignoring a missing newline at the very end of a file
same_text() { cmp -s <(sed -e '$a\\' "$1" 2>/dev/null) <(sed -e '$a\\' "$2" 2>/dev/null); }
_item_dest() { case "$1" in u) echo "$HOME/$2" ;; *) echo "/$2" ;; esac; }

# write_items : writes every user file (kind u). Files marked keep stay when they exist. hyprland.lua is written last.
write_items() {
  local it kind dest mode keep d t n=0 k=0 same=0 ps
  for ps in 1 2; do
  for it in "${ITEMS[@]}"; do
    IFS='|' read -r kind dest mode keep <<< "$it"; [ "$kind" = u ] || continue
    case "$dest" in */hyprland.lua) [ "$ps" = 1 ] && continue ;; *) [ "$ps" = 2 ] && continue ;; esac
    d="$HOME/$dest"
    if [ "$keep" = 1 ] && [ -s "$d" ]; then k=$((k + 1)); continue; fi
    t="$(mktemp)"
    _emit "u/$dest" > "$t" || { fail "this script has no data for $dest"; rm -f "$t"; continue; }
    if same_text "$t" "$d"; then same=$((same + 1)); else
      backup "$d"; mkdir -p "$(dirname "$d")"; [ -L "$d" ] && rm -f "$d"; cat "$t" > "$d" && n=$((n + 1)) || fail "could not write $d"
    fi
    rm -f "$t"; chmod "$mode" "$d" 2>/dev/null
  done
  done
  [ "${#ITEMS[@]}" -gt 0 ] && pass "files written: $n, already identical: $same, kept (your own settings): $k"
  return 0
}
# payload_sys KEY DEST [MODE] : writes one system file (admin rights) from emit; returns 0 when it changed, 2 when it was already identical, 1 on error
payload_sys() {
  local t rc; t="$(mktemp)"
  _emit "s/$1" > "$t" || { rm -f "$t"; fail "this script has no data for $1"; return 1; }
  if same_text "$t" "$2"; then rm -f "$t"; return 2; fi
  asroot mkdir -p "$(dirname "$2")" && asroot install -m "${3:-644}" "$t" "$2"; rc=$?; rm -f "$t"; return $rc
}

# comp_check : read-only. Compares the live files with this script's copy (and, when doctor.sh sets SNOW_CMP_ROOT, with the Files backup).
comp_check() {
  local it kind dest mode keep d t miss=0 diff=0 same=0 fdiff=0 fmiss=0 ref
  for it in "${ITEMS[@]}"; do
    IFS='|' read -r kind dest mode keep <<< "$it"; d=$(_item_dest "$kind" "$dest")
    t="$(mktemp)"; _emit "$kind/$dest" > "$t" 2>/dev/null
    if [ ! -e "$d" ]; then miss=$((miss + 1)); warn "missing: ${d/#$HOME/~}" "bash ~/Snow/Script/${MOD}.sh"
    elif same_text "$t" "$d"; then same=$((same + 1))
    else diff=$((diff + 1)); [ "$keep" = 1 ] || warn "changed since this script was made: ${d/#$HOME/~}" "fine if you changed it on purpose. Then run: bash ~/Snow/Files/backup.sh  and update Script/${MOD}.sh to match"; fi
    if [ -n "${SNOW_CMP_ROOT:-}" ] && [ "$kind" = u ]; then
      ref="$SNOW_CMP_ROOT/home/$dest"
      if [ ! -e "$ref" ]; then fmiss=$((fmiss + 1)); [ "$keep" = 1 ] || warn "Files backup does not have ${d/#$HOME/~}" "bash ~/Snow/Files/backup.sh"
      elif ! same_text "$t" "$ref" && [ "$keep" != 1 ]; then fdiff=$((fdiff + 1)); warn "Files backup differs from the Script version: ${d/#$HOME/~}" "if the Files version is the good one, update Script/${MOD}.sh to match it; if the Script version is the good one: bash ~/Snow/Files/restore.sh"; fi
    fi
    rm -f "$t"
  done
  [ "${#ITEMS[@]}" -gt 0 ] && [ $miss = 0 ] && [ $diff = 0 ] && pass "all ${#ITEMS[@]} files are in place and identical to the script"
  [ "${#ITEMS[@]}" -gt 0 ] && [ $miss = 0 ] && [ $diff != 0 ] && pass "all files exist ($same identical, $diff changed by you)"
  declare -F extra_check >/dev/null && extra_check
  return 0
}

[ -f "$_LIB/layout.sh" ] && . "$_LIB/layout.sh"
component_main() {
  case "${1:-run}" in
    run)   declare -F layout_migrate >/dev/null && layout_migrate
           if [ -n "${CUSTOM_RUN:-}" ]; then "$CUSTOM_RUN"; else step "${MOD}: ${TITLE:-}"; declare -F pre >/dev/null && pre; write_items; declare -F post >/dev/null && post; summary "$MOD"; fi ;;
    files) write_items ;;   # only writes this script's files (used by the layout move)
    check) step "check ${MOD}: ${TITLE:-}"; comp_check; summary "$MOD" ;;
    list)  for it in "${ITEMS[@]}"; do echo "${it%%|*}: $(echo "$it" | cut -d'|' -f2)"; done ;;
    *)     echo "usage: bash ${MOD}.sh [run|check|list]"; exit 2 ;;
  esac
}

# flatpak_app ID : installs one Flathub app (adds the Flathub remote first)
flatpak_app() {
  have flatpak || apt_install flatpak
  have flatpak || { fail "flatpak is not installed" "sudo apt-get install flatpak"; return 0; }
  asroot flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1
  if flatpak info "$1" >/dev/null 2>&1; then pass "flatpak $1 already installed"
  else flatpak install -y --noninteractive flathub "$1" && pass "flatpak $1 installed" || fail "flatpak $1 could not be installed" "flatpak install -y flathub $1   (internet connection? see the error above)"; fi
  return 0
}
# reload_live : restart the panels and reload Hyprland when this script runs inside a Hyprland session
reload_live() {
  if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && have hyprctl; then
    [ -f "$BIN/qs.sh" ] && bash "$BIN/qs.sh" restart >/dev/null 2>&1 && pass "panels restarted"
    hyprctl reload >/dev/null 2>&1 && pass "Hyprland reloaded"
  else pass "not inside Hyprland: everything starts at the next login"; fi
}

# qml_ok FILE : brace check that ignores "strings" and // comments. A mismatch is only a WARN (the Quickshell log is the real judge).
qml_ok() {
  local f="$1" o c
  [ -f "$f" ] || return 0
  o=$(sed -E 's/"([^"\\]|\\.)*"//g; s#//.*##' "$f" | tr -cd '{' | wc -c); c=$(sed -E 's/"([^"\\]|\\.)*"//g; s#//.*##' "$f" | tr -cd '}' | wc -c)
  [ "$o" = "$c" ] && pass "$(basename "$f"): braces balanced" || warn "$(basename "$f"): { and } counts differ ($o / $c): maybe a false alarm" "qs -p ~/.config/quickshell/snow  (look for red errors) or: tail -40 ~/.cache/snow/qs.log"
}
# icons_ok : every Icons.<name> used by a panel (outside comments) must exist in the generated Icons.qml
icons_ok() {
  local QSD="$HOME/.config/quickshell/snow" n bad=0
  for n in $(find "$QSD" -name '*.qml' -type f -exec cat {} + 2>/dev/null | sed -E 's#//.*##' | grep -oE 'Icons\.[a-zA-Z][A-Za-z0-9]*' | sort -u | sed 's/Icons\.//'); do
    [ "$n" = qml ] && continue
    grep -q "property string $n:" "$QSD/core/Icons.qml" 2>/dev/null || { fail "Icons.$n is used by a panel but not generated" "bash ~/Snow/Script/06-core.sh"; bad=1; }
  done
  [ $bad = 0 ] && pass "every icon used by the panels exists in Icons.qml"
  return 0
}
