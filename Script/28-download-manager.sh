#!/usr/bin/env bash
# 28-download-manager.sh : Downloads: Snow download manager (aria2)
# Own compact download manager: aria2 engine + a Quickshell window (Super+D). Queue, start / pause / resume / stop, folder, speed. The engine starts at login, so unfinished downloads continue.
#   bash Script/28-download-manager.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/28-download-manager.sh check    read-only check
MOD="28-download-manager"; TITLE="Downloads: Snow download manager (aria2)"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/snow/bin/downloads/dm-ask.sh|755|0"
  "u|.config/snow/bin/downloads/dm-conf.sh|755|0"
  "u|.config/snow/bin/downloads/dm-hook.sh|755|0"
  "u|.config/snow/bin/downloads/dm-pick-host.sh|755|0"
  "u|.config/snow/bin/downloads/dm-pickdir.sh|755|0"
  "u|.config/snow/bin/downloads/dm-rpc.sh|755|0"
  "u|.config/snow/bin/downloads/dm-save.sh|755|0"
  "u|.config/snow/bin/downloads/dm.sh|755|0"
  "u|.config/snow/bin/downloads/dm-notify.sh|755|0"
  "u|.config/snow/bin/downloads/dm-on-complete.sh|755|0"
  "u|.config/snow/bin/downloads/dm-on-error.sh|755|0"
  "u|.config/snow/bin/downloads/dm-on-pause.sh|755|0"
  "u|.config/snow/bin/downloads/dm-video.sh|755|0"
  "u|.config/snow/bin/downloads/dm-vsave.sh|755|0"
  "u|.config/snow/dm/DmBtn.qml|644|0"
  "u|.config/snow/dm/DmField.qml|644|0"
  "u|.config/snow/dm/Theme.qml|644|0"
  "u|.config/snow/dm/shell.qml|644|0"
  "u|.config/snow/dmvid/DmBtn.qml|644|0"
  "u|.config/snow/dmvid/DmField.qml|644|0"
  "u|.config/snow/dmvid/Theme.qml|644|0"
  "u|.config/snow/dmvid/shell.qml|644|0"
  "u|.config/snow/dmask/DmBtn.qml|644|0"
  "u|.config/snow/dmask/DmField.qml|644|0"
  "u|.config/snow/dmask/Theme.qml|644|0"
  "u|.config/snow/dmask/shell.qml|644|0"
  "u|.config/snow/state/dm.json|644|1"
  "u|.local/share/applications/snow-downloads.desktop|644|0"
)
emit() {
case "$1" in
"u/.config/snow/bin/downloads/dm-ask.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-ask.sh GID : "Ask where to save". Opens the Snow file manager in "choose a folder" mode for ONE new download (it waits paused),
#   then sets that folder for the download and starts it. Cancel = the download is removed. Called by dm-hook.sh (one chooser at a time).
STATE="$HOME/.config/snow/state"; JSON="$STATE/dm.json"; RPC="$HOME/.config/snow/bin/downloads/dm-rpc.sh"; G="${1:-}"
[ -n "$G" ] || exit 2
item=$(bash "$RPC" status | jq -c --arg g "$G" '.items[]? | select(.gid==$g)' 2>/dev/null)
[ -n "$item" ] || exit 0
name=$(jq -r '.name // ""' <<<"$item"); [ -n "$name" ] || { u=$(jq -r '.uri // ""' <<<"$item"); name="${u%%\?*}"; name="${name##*/}"; case "$u" in magnet:*) name="magnet link" ;; esac; }
start=$(jq -r '.lastdir // .dir // empty' "$JSON" 2>/dev/null); [ -d "$start" ] || start=$(jq -r '.dir // ""' <<<"$item"); [ -d "$start" ] || start="$HOME/Downloads"; [ -d "$start" ] || start="$HOME"
echo "$G" >> "$STATE/dm-decided"
BIN=$(command -v qs || command -v quickshell) || { bash "$RPC" resume "$G" >/dev/null; exit 0; }
mkdir -p "$HOME/.cache/snow"
out=$(mktemp "${TMPDIR:-/tmp}/snow-dm-pick.XXXXXX")
FM_START="$start" FM_PICK=dir FM_PICK_TITLE="Choose a folder for: ${name:-download}" FM_PICK_OUT="$out" "$BIN" -p "$HOME/.config/snow/fm" >"$HOME/.cache/snow/dm-pick.log" 2>&1 </dev/null
d=$(head -n1 "$out" 2>/dev/null); rm -f -- "$out"
if [ -n "$d" ] && [ -d "$d" ]; then
  # the few bytes that were saved in the engine's own folder before the pause are removed (only a tiny file of THIS download)
  op=$(jq -r '.path // ""' <<<"$item"); od=$(jq -r '.dir // ""' <<<"$item"); dn=$(jq -r '.done // 0' <<<"$item")
  if [ "$d" != "$od" ] && [ -n "$op" ] && [ -f "$op" ] && [ "${dn%.*}" -lt 4194304 ] 2>/dev/null; then rm -f -- "$op" "$op.aria2"; fi
  bash "$RPC" dir "$G" "$d" >/dev/null; bash "$RPC" resume "$G" >/dev/null
  [ -s "$JSON" ] && jq --arg d "$d" '.lastdir=$d' "$JSON" > "$JSON.new" && mv -f "$JSON.new" "$JSON"
else
  bash "$RPC" remove "$G" >/dev/null
fi
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm-conf.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-conf.sh : settings of the Snow download manager (file ~/.config/snow/state/dm.json). Applied to the running engine at once.
#   dm-conf.sh set dir FOLDER      where downloads are saved (empty = your Downloads folder)
#   dm-conf.sh set max N           how many downloads run at the same time (1-10); the others wait in the queue
#   dm-conf.sh set conn N          connections per download (1-16)
#   dm-conf.sh set limit N         speed limit for everything in KB per second (a whole number); 0 = no limit
#   dm-conf.sh batch JSON          several settings at once, e.g. '{"dir":"/x","max":3,"limit":500,"ask":"on"}' (used by the Save button of the window)
#   dm-conf.sh set ask on|off      ask where to save every new download (folder chooser); works at once
#   dm-conf.sh set nstart|nstop|ndone|nerror on|off   notifications: download starts / stops (pause) / finishes / fails (see dm-notify.sh)
#   dm-conf.sh set ytauto on|off   update yt-dlp by itself once a week
#   dm-conf.sh set vq best|1080|720|audio   quality of video downloads (YouTube ...)
#   dm-conf.sh get                 prints the settings as JSON
STATE="$HOME/.config/snow/state"; JSON="$STATE/dm.json"; RPC="$HOME/.config/snow/bin/downloads/dm-rpc.sh"
mkdir -p "$STATE"; [ -s "$JSON" ] || echo '{"dir":"","max":3,"conn":8,"limit":"0","ask":true,"vq":"best"}' > "$JSON"
fail() { jq -nc --arg e "$1" '{ok:false,error:$e}'; exit 0; }
[ "${1:-}" = get ] && { cat "$JSON"; exit 0; }
if [ "${1:-}" = batch ]; then
  err=""
  while IFS=$'\t' read -r bk bv; do
    [ -n "$bk" ] || continue
    r=$(bash "${BASH_SOURCE[0]}" set "$bk" "$bv"); [ "$(jq -r '.ok // false' <<<"$r" 2>/dev/null)" = true ] || err=$(jq -r --arg k "$bk" '$k + ": " + (.error // "not saved")' <<<"$r" 2>/dev/null)
  done < <(jq -r 'to_entries[] | [.key, (.value|tostring)] | @tsv' <<<"${2:-{\}}" 2>/dev/null)
  if [ -n "$err" ]; then jq -nc --arg e "$err" '{ok:false,error:$e}'; else echo '{"ok":true}'; fi
  exit 0
fi
[ "${1:-}" = set ] || { echo "usage: dm-conf.sh set dir|max|conn|limit|ask|nstart|nstop|ndone|nerror|ytauto|vq VALUE | batch JSON | get"; exit 2; }
k="${2:-}"; v="${3:-}"; opt=""; val=""
if [[ "$k" =~ ^(ask|nstart|nstop|ndone|nerror|ytauto)$ ]]; then
  case "$v" in on|true|1) b=true ;; off|false|0) b=false ;; *) fail "on or off" ;; esac
  jq --arg k "$k" --argjson b "$b" '.[$k]=$b' "$JSON" > "$JSON.new" && mv -f "$JSON.new" "$JSON" || fail "could not save the setting"
  echo '{"ok":true}'; exit 0
fi
if [ "$k" = limit ]; then
  case "$v" in ''|*[!0-9]*) fail "a whole number: KB per second (0 = no limit)" ;; esac
  v=$((10#$v)); [ "$v" -le 10000000 ] || fail "that number is too big"
  val=0; [ "$v" -gt 0 ] && val="${v}K"
  jq --arg v "$val" '.limit=$v' "$JSON" > "$JSON.new" && mv -f "$JSON.new" "$JSON" || fail "could not save the setting"
  SEC="$(cat "$STATE/dm-secret" 2>/dev/null)"
  curl -s -m 3 -H 'Content-Type: application/json' --data-binary "$(jq -nc --arg t "token:$SEC" --arg v "$val" '{jsonrpc:"2.0",id:"snow",method:"aria2.changeGlobalOption",params:[$t,{"max-overall-download-limit":$v}]}')" "http://127.0.0.1:${DM_PORT:-6899}/jsonrpc" >/dev/null 2>&1
  echo '{"ok":true}'; exit 0
fi
if [ "$k" = vq ]; then
  case "$v" in best|1080|720|audio) ;; *) fail "best, 1080, 720 or audio" ;; esac
  jq --arg v "$v" '.vq=$v' "$JSON" > "$JSON.new" && mv -f "$JSON.new" "$JSON" || fail "could not save the setting"
  echo '{"ok":true}'; exit 0
fi
case "$k" in
  dir) v="${v/#\~/$HOME}"; if [ -n "$v" ]; then mkdir -p "$v" 2>/dev/null && [ -w "$v" ] || fail "cannot write to that folder"; case "$v" in /*) ;; *) fail "give the full folder path (it starts with /)" ;; esac; fi
       opt="dir"; val="${v:-$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads")}" ;;
  max)  case "$v" in ''|*[!0-9]*) fail "a number from 1 to 10" ;; esac; { [ "$v" -ge 1 ] && [ "$v" -le 10 ]; } || fail "a number from 1 to 10"; opt="max-concurrent-downloads"; val="$v" ;;
  conn) case "$v" in ''|*[!0-9]*) fail "a number from 1 to 16" ;; esac; { [ "$v" -ge 1 ] && [ "$v" -le 16 ]; } || fail "a number from 1 to 16"; opt="max-connection-per-server"; val="$v" ;;
  limit) v="${v// /}"; [ -n "$v" ] || v=0; case "$v" in 0|[0-9]*[KkMm]|[0-9]*) case "$v" in *[!0-9KkMm]*) fail "0 = no limit, or like 500K / 2M" ;; esac ;; *) fail "0 = no limit, or like 500K / 2M" ;; esac; opt="max-overall-download-limit"; val="${v^^}" ;;
  *) fail "unknown setting" ;;
esac
case "$k" in max|conn) jq --arg k "$k" --argjson v "$v" '.[$k]=$v' "$JSON" > "$JSON.new" ;; *) jq --arg k "$k" --arg v "${k/limit/$val}" '.[$k]=$v' "$JSON" > "$JSON.new" ;; esac
[ "$k" = dir ] && jq --arg v "$v" '.dir=$v' "$JSON" > "$JSON.new"
[ "$k" = limit ] && jq --arg v "$val" '.limit=$v' "$JSON" > "$JSON.new"
[ -s "$JSON.new" ] && mv -f "$JSON.new" "$JSON" || { rm -f "$JSON.new"; fail "could not save the setting"; }
# live: apply to the running engine (if it is not running, dm.sh reads dm.json at the next start)
p=$(jq -nc --arg o "$opt" --arg v "$val" '[{($o):$v}]')
[ "$k" = conn ] && p=$(jq -nc --arg v "$val" '[{"max-connection-per-server":$v,"split":$v}]')
SEC="$(cat "$STATE/dm-secret" 2>/dev/null)"
curl -s -m 3 -H 'Content-Type: application/json' --data-binary "$(jq -nc --arg t "token:$SEC" --argjson p "$p" '{jsonrpc:"2.0",id:"snow",method:"aria2.changeGlobalOption",params:([$t]+$p)}')" "http://127.0.0.1:${DM_PORT:-6899}/jsonrpc" >/dev/null 2>&1
echo '{"ok":true}'
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm-hook.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-hook.sh GID NUM PATH : aria2 calls this the moment a download STARTS (--on-download-start, set by dm.sh).
#   "Ask where to save" on  ->  a brand-new download is paused at once and dm-ask.sh opens the folder chooser for it.
#   Not asked: downloads that already have data (resumed after a restart), the real download that follows a magnet link, downloads already decided.
STATE="$HOME/.config/snow/state"; JSON="$STATE/dm.json"; RPC="$HOME/.config/snow/bin/downloads/dm-rpc.sh"; ASK="$HOME/.config/snow/bin/downloads/dm-ask.sh"
NOTE="$HOME/.config/snow/bin/downloads/dm-notify.sh"
G="${1:-}"; [ -n "$G" ] || exit 0
go() { bash "$NOTE" -g start "$@" >/dev/null 2>&1 & exit 0; }   # the download goes on: "started" notification (only when the switch is on)
case "$G" in 5d0cd3b*) go "$G" "${2:-}" "${3:-}" ;; esac   # the browser extension already asked for the folder (its GIDs start like this)
[ "$(jq -r 'if has("ask") then .ask else true end' "$JSON" 2>/dev/null)" = "true" ] || go "$G" "${2:-}" "${3:-}"
touch "$STATE/dm-decided"; grep -qxF "$G" "$STATE/dm-decided" && go "$G" "${2:-}" "${3:-}"
info=$(bash "$RPC" raw aria2.tellStatus "$(jq -nc --arg g "$G" '[$g,["completedLength","following","status"]]')")
[ "$(jq -r '.result.completedLength // "x"' <<<"$info")" = "0" ] || go "$G" "${2:-}" "${3:-}"
[ -z "$(jq -r '.result.following // empty' <<<"$info")" ] || go "$G" "${2:-}" "${3:-}"
# the browser extension may have chosen the folder already: then there is nothing to ask
od=$(jq -r '.result.dir // ""' <<<"$(bash "$RPC" raw aria2.getOption "$(jq -nc --arg g "$G" '[$g]')")"); gd=$(jq -r '.result.dir // ""' <<<"$(bash "$RPC" raw aria2.getGlobalOption)")
[ -n "$od" ] && [ -n "$gd" ] && [ "$od" != "$gd" ] && go "$G" "${2:-}" "${3:-}"
mkdir -p "$STATE/dm-asking"; : > "$STATE/dm-asking/$G"   # this pause is ours (not the user's): dm-notify.sh does not report it
bash "$RPC" pause "$G" >/dev/null
( flock 9; bash "$ASK" "$G" ) 9>"$STATE/dm-ask.lock" >/dev/null 2>&1 &
exit 0
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm-pick-host.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-pick-host.sh : "native messaging" helper of the Snow DM Bridge browser extension. The browser starts this script for ONE request and waits for ONE answer.
#   {"add":{url,name,size,referer,cookie,ua}}  opens the Snow "Save download" window (name, folder, Download / Queue / Cancel), then adds the
#                                              download to aria2.   Answer: {"ok":true,"action":"download|queue|cancel"} or {"ok":false,"error":"..."}
#   {"status":true}    answer: {"ok":true,"active":N,"waiting":N,"speed":N}      {"theme":true}  answer: the colours of theme.json
#   {"start":"/folder"} (old, v0.7)  opens the Snow file manager in "choose a folder" mode.  Answer: {"ok":true,"dir":"/chosen/folder"}
#   bash dm-pick-host.sh install     tells Brave / Chromium / Chrome that this helper exists (run once; run again if you install another browser; restart the browser after)
#   bash dm-pick-host.sh remove      takes that away again
# Only the extension with the fixed ID below may talk to it.
NAME="snow.dm.picker"; EXTID="dgcieipjigcopchalnknlppkihfllcag"
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
dirs() { local d; for d in "$HOME/.config/BraveSoftware"/*/ "$HOME/.config/chromium/" "$HOME/.config/google-chrome/"; do [ -d "$d" ] && echo "${d%/}/NativeMessagingHosts"; done; }
case "${1:-}" in
  install)
    n=0
    while IFS= read -r d; do
      mkdir -p "$d" && jq -n --arg n "$NAME" --arg p "$SELF" --arg o "chrome-extension://$EXTID/" \
        '{name:$n, description:"Snow download manager: folder chooser", path:$p, type:"stdio", allowed_origins:[$o]}' > "$d/$NAME.json" && { echo "[PASS] $d/$NAME.json"; n=$((n + 1)); }
    done < <(dirs)
    [ "$n" -gt 0 ] && echo "Restart the browser once." || echo "[WARN] no Brave / Chromium / Chrome settings folder found yet: start the browser once, then run this again."
    exit 0 ;;
  remove) while IFS= read -r d; do rm -f -- "$d/$NAME.json"; done < <(dirs); echo "removed"; exit 0 ;;
esac
# ---------------- host mode: one request, one answer (4 bytes length, then JSON)
export LC_ALL=C
len=$(dd bs=1 count=4 2>/dev/null | od -An -tu4 | tr -d ' ')
case "$len" in ''|*[!0-9]*) exit 1 ;; esac
[ "$len" -gt 0 ] && [ "$len" -lt 65536 ] || exit 1   # the extension keeps the cookie text under 8 KB
msg=$(dd bs=1 count="$len" 2>/dev/null)
reply() { local s="$1" n=${#1}; printf "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' $((n & 255)) $(((n >> 8) & 255)) $(((n >> 16) & 255)) $(((n >> 24) & 255)))"; printf '%s' "$s"; }
if [ "$(jq -r '.theme // false' <<<"$msg" 2>/dev/null)" = "true" ]; then   # the colours of the Snow desktop, so the extension pages look like the file manager
  reply "$(jq -c '{ok:true, theme:.}' "$HOME/.config/snow/state/theme.json" 2>/dev/null || jq -nc '{ok:false}')"; exit 0
fi
STATE="$HOME/.config/snow/state"; CONF="$HOME/.config/snow/bin/downloads"
if [ "$(jq -r 'has("status")' <<<"$msg" 2>/dev/null)" = "true" ]; then
  reply "$(bash "$CONF/dm-rpc.sh" status | jq -c 'if .ok then {ok:true,active,waiting,speed} else {ok:false,error:(.error // "engine not running")} end' 2>/dev/null || jq -nc '{ok:false,error:"engine not running"}')"; exit 0
fi
if [ "$(jq -r 'has("add")' <<<"$msg" 2>/dev/null)" = "true" ]; then
  export DMS_URL="$(jq -r '.add.url // ""' <<<"$msg")" DMS_NAME="$(jq -r '.add.name // ""' <<<"$msg")" DMS_SIZE="$(jq -r '.add.size // -1' <<<"$msg")"
  export DMS_REFERER="$(jq -r '.add.referer // ""' <<<"$msg")" DMS_COOKIE="$(jq -r '.add.cookie // ""' <<<"$msg")" DMS_UA="$(jq -r '.add.ua // ""' <<<"$msg")"
  reply "$(bash "$CONF/dm-save.sh" 2>/dev/null </dev/null || jq -nc '{ok:false,error:"dm-save.sh failed"}')"; exit 0   # the window + the hand-over to aria2 live in dm-save.sh
fi
start=$(jq -r '.start // ""' <<<"$msg" 2>/dev/null)
[ -d "$start" ] || start=$(jq -r '.lastdir // .dir // ""' "$HOME/.config/snow/state/dm.json" 2>/dev/null)
[ -d "$start" ] || start="$HOME/Downloads"; [ -d "$start" ] || start="$HOME"
BIN=$(command -v qs || command -v quickshell) || { reply "$(jq -nc '{ok:false,error:"quickshell is not installed"}')"; exit 0; }
out=$(mktemp "${TMPDIR:-/tmp}/snow-dm-pick.XXXXXX")
FM_START="$start" FM_PICK=dir FM_PICK_TITLE="Choose a download folder" FM_PICK_OUT="$out" "$BIN" -p "$HOME/.config/snow/fm" >/dev/null 2>&1 </dev/null
d=$(head -n1 "$out" 2>/dev/null); rm -f -- "$out"
reply "$(jq -nc --arg d "$d" '{ok:true,dir:$d}')"
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm-pickdir.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-pickdir.sh [START_FOLDER] : opens the Snow file manager in "choose a folder" mode and prints the chosen folder (nothing when cancelled).
#   Used by the "Save download" window of the browser extension (folder button).
start="${1:-}"
[ -d "$start" ] || start=$(jq -r '.lastdir // .dir // ""' "$HOME/.config/snow/state/dm.json" 2>/dev/null)
[ -d "$start" ] || start="$HOME/Downloads"; [ -d "$start" ] || start="$HOME"
BIN=$(command -v qs || command -v quickshell) || exit 1
out=$(mktemp "${TMPDIR:-/tmp}/snow-dm-pick.XXXXXX")
FM_START="$start" FM_PICK=dir FM_PICK_TITLE="Choose a download folder" FM_PICK_OUT="$out" "$BIN" -p "$HOME/.config/snow/fm" >/dev/null 2>&1 </dev/null
head -n1 "$out" 2>/dev/null; rm -f -- "$out"
exit 0
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm-rpc.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-rpc.sh : talks to the aria2 engine (JSON-RPC on 127.0.0.1) for the Snow download manager. Prints ONE line of JSON.
#   dm-rpc.sh status                    {"ok":true,"speed":N,"active":N,"waiting":N,"items":[{gid,status,name,total,done,speed,dir,path,uri,err}]}
#   dm-rpc.sh add LINK|FILE.torrent ... add downloads   dm-rpc.sh addx LINK [OPTIONS_JSON] [top]  one link with options (used by the browser helper)
#              dm-rpc.sh pause|resume|remove|retry|up|down|top GID
#   dm-rpc.sh addvideo LINK ...        video links (YouTube ...) -> yt-dlp via dm-video.sh; video rows have a gid like v:ID and show up in status too
#   dm-rpc.sh limit GID KB             speed limit of ONE download in KB/s (0 = none); video rows too. Shown as "limit" in status.
#   dm-rpc.sh pauseall | resumeall | clear (clear = forget finished / failed rows) | shutdown
STATE="$HOME/.config/snow/state"; PORT="${DM_PORT:-6899}"; SEC="$(cat "$STATE/dm-secret" 2>/dev/null)"
URL="http://127.0.0.1:$PORT/jsonrpc"
call() { curl -s -m 4 -H 'Content-Type: application/json' --data-binary "$1" "$URL" 2>/dev/null; }
req() { jq -nc --arg m "$1" --arg t "token:$SEC" --argjson p "${2:-[]}" '{jsonrpc:"2.0",id:"snow",method:$m,params:([$t]+$p)}'; }
rpc() { call "$(req "$@")"; }
res() { jq -c 'if .error then {ok:false,error:.error.message} elif .result == null then {ok:false,error:"engine not running",down:true} else {ok:true} end' 2>/dev/null || echo '{"ok":false,"error":"engine not running","down":true}'; }
down() { echo '{"ok":false,"error":"engine not running","down":true}'; }
VID="$HOME/.config/snow/bin/downloads/dm-video.sh"
LIMF="$STATE/dm-limits.json"      # {gid: KB/s} of the aria2 downloads that have an own limit (aria2 keeps the real limit in its session)
isv() { case "${1:-}" in v:*) return 0 ;; *) return 1 ;; esac; }       # video job gid
KEYS='["gid","status","totalLength","completedLength","downloadSpeed","files","bittorrent","errorMessage","dir"]'
case "${1:-}" in
  status)
    body=$(jq -nc --arg t "token:$SEC" --argjson k "$KEYS" '{jsonrpc:"2.0",id:"snow",method:"system.multicall",params:[[
      {methodName:"aria2.getGlobalStat",params:[$t]},
      {methodName:"aria2.tellActive",params:[$t,$k]},
      {methodName:"aria2.tellWaiting",params:[$t,0,200,$k]},
      {methodName:"aria2.tellStopped",params:[$t,0,100,$k]}]]}')
    out=$(call "$body"); [ -n "$out" ] || { down; exit 0; }
    vj=$(bash "$VID" status 2>/dev/null); [ -n "$vj" ] || vj='[]'
    lj=$(cat "$LIMF" 2>/dev/null); [ -n "$lj" ] || lj='{}'
    printf '%s' "$out" | jq -c --argjson vj "$vj" --argjson lj "$lj" '
      if .error then {ok:false,error:.error.message}
      elif (.result|type) != "array" then {ok:false,error:"bad answer"}
      else (.result[0][0]) as $g | ((.result[1][0] // []) + (.result[2][0] // []) + (.result[3][0] // [])) as $all
        | {ok:true, speed:(($g.downloadSpeed // "0")|tonumber), active:(($g.numActive // "0")|tonumber), waiting:(($g.numWaiting // "0")|tonumber),
           items:[ $all[] | select(.status != "removed") | {gid, status, dir:(.dir // ""),
             total:((.totalLength // "0")|tonumber), done:((.completedLength // "0")|tonumber), speed:((.downloadSpeed // "0")|tonumber),
             name:((.bittorrent.info.name // (((.files[0].path // "") | split("/") | last) // "")) // ""),
             path:(.files[0].path // ""), uri:(.files[0].uris[0].uri // ""), err:(.errorMessage // ""), limit:($lj[.gid] // 0)} ] } end
      | if .ok then .items += $vj | .speed += ([$vj[].speed] | add // 0) | .active += ([$vj[] | select(.status == "active")] | length) else . end' 2>/dev/null || down ;;
  addvideo)
    shift; n=0; er=""
    for u in "$@"; do r=$(bash "$VID" add "$u"); if [ "$(jq -r '.ok' <<<"$r" 2>/dev/null)" = true ]; then n=$((n + 1)); else er=$(jq -r '.error' <<<"$r" 2>/dev/null); fi; done
    if [ "$n" -gt 0 ]; then echo "{\"ok\":true,\"added\":$n,\"skipped\":0}"; else jq -nc --arg e "${er:-could not start the video download}" '{ok:false,error:$e}'; fi ;;
  add)
    shift; n=0; bad=0
    for u in "$@"; do
      case "$u" in
        http://*|https://*|ftp://*|sftp://*|magnet:*) rpc aria2.addUri "$(jq -nc --arg u "$u" '[[ $u ]]')" >/dev/null && n=$((n + 1)) ;;
        *.torrent) if [ -f "$u" ]; then rpc aria2.addTorrent "$(jq -nc --arg b "$(base64 -w0 "$u")" '[$b]')" >/dev/null && n=$((n + 1)); else bad=$((bad + 1)); fi ;;
        *) bad=$((bad + 1)) ;;
      esac
    done
    if [ "$n" -gt 0 ]; then echo "{\"ok\":true,\"added\":$n,\"skipped\":$bad}"; elif [ "$bad" -gt 0 ]; then echo '{"ok":false,"error":"that is not a link (http, https, ftp, magnet or a .torrent file)"}'; else down; fi ;;
  addx)    # addx LINK [OPTIONS_JSON] [top] : ONE link with aria2 options (dir, out, referer, header ...). Prints {"ok":true,"gid":"..."}; "top" = first in the waiting line
    o="${3:-}"; [ -n "$o" ] || o='{}'
    r=$(rpc aria2.addUri "$(jq -nc --arg u "$2" --argjson o "$o" '[[ $u ],$o]')"); [ -n "$r" ] || { down; exit 0; }
    g=$(jq -r '.result // empty' <<<"$r" 2>/dev/null)
    if [ -n "$g" ]; then
      [ "${4:-}" = "top" ] && rpc aria2.changePosition "$(jq -nc --arg g "$g" '[$g,0,"POS_SET"]')" >/dev/null
      jq -nc --arg g "$g" '{ok:true,gid:$g}'
    else jq -c 'if .error then {ok:false,error:.error.message} else {ok:false,error:"engine not running",down:true} end' <<<"$r" 2>/dev/null || down; fi ;;
  limit)
    case "${3:-}" in ''|*[!0-9]*) echo '{"ok":false,"error":"a whole number: KB per second (0 = no limit)"}'; exit 0 ;; esac
    if isv "${2:-}"; then bash "$VID" limit "${2#v:}" "$3"; exit 0; fi
    val=0; [ "$((10#$3))" -gt 0 ] && val="$((10#$3))K"
    r=$(rpc aria2.changeOption "$(jq -nc --arg g "$2" --arg v "$val" '[$g,{"max-download-limit":$v}]')")
    if [ "$(jq -r '.error // empty' <<<"$r" 2>/dev/null)" != "" ]; then jq -c '{ok:false,error:.error.message}' <<<"$r"; exit 0; fi
    [ -n "$r" ] || { down; exit 0; }
    cur=$(cat "$LIMF" 2>/dev/null); [ -n "$cur" ] || cur='{}'
    jq -c --arg g "$2" --argjson k "$((10#$3))" 'if $k > 0 then .[$g] = $k else del(.[$g]) end' <<<"$cur" > "$LIMF.new" && mv -f "$LIMF.new" "$LIMF"
    echo '{"ok":true}' ;;
  pause|resume|remove|retry) if isv "${2:-}"; then g="${2#v:}"; bash "$VID" "$1" "$g"; exit 0; fi; ;;&
  up|down|top|dir) if isv "${2:-}"; then echo '{"ok":true}'; exit 0; fi; ;;&
  pause)   rpc aria2.forcePause "$(jq -nc --arg g "$2" '[$g]')" | res ;;
  resume)  rpc aria2.unpause "$(jq -nc --arg g "$2" '[$g]')" | res ;;
  remove)  rpc aria2.forceRemove "$(jq -nc --arg g "$2" '[$g]')" >/dev/null; rpc aria2.removeDownloadResult "$(jq -nc --arg g "$2" '[$g]')" | res ;;
  retry)
    u=$(rpc aria2.tellStatus "$(jq -nc --arg g "$2" '[$g,["files"]]')" | jq -r '.result.files[0].uris[0].uri // empty' 2>/dev/null)
    [ -n "$u" ] || { echo '{"ok":false,"error":"no link saved for this download"}'; exit 0; }
    rpc aria2.addUri "$(jq -nc --arg u "$u" '[[ $u ]]')" >/dev/null && rpc aria2.removeDownloadResult "$(jq -nc --arg g "$2" '[$g]')" | res ;;
  up)      rpc aria2.changePosition "$(jq -nc --arg g "$2" '[$g,-1,"POS_CUR"]')" | res ;;
  down)    rpc aria2.changePosition "$(jq -nc --arg g "$2" '[$g,1,"POS_CUR"]')" | res ;;
  top)     rpc aria2.changePosition "$(jq -nc --arg g "$2" '[$g,0,"POS_SET"]')" | res ;;
  dir)     rpc aria2.changeOption "$(jq -nc --arg g "$2" --arg d "$3" '[$g,{dir:$d}]')" | res ;;
  raw)     rpc "$2" "${3:-[]}" ;;
  pauseall)  rpc aria2.forcePauseAll | res ;;
  resumeall) rpc aria2.unpauseAll | res ;;
  clear)     bash "$VID" clear >/dev/null 2>&1; rpc aria2.purgeDownloadResult | res ;;
  shutdown)  rpc aria2.shutdown | res ;;
  *) echo "usage: dm-rpc.sh status|add LINK...|addx LINK [JSON] [top]|pause|resume|remove|retry|up|down|top GID|dir GID FOLDER|pauseall|resumeall|clear|shutdown"; exit 2 ;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm-save.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-save.sh URL [NAME] : opens the Snow "Save download" window (file name, folder, Cancel / Queue / Download) and then adds the download to aria2.
#   Prints ONE line of JSON:  {"ok":true,"action":"download|queue|cancel",...}  or  {"ok":false,"error":"..."}
#   Used by the browser helper (dm-pick-host.sh) and by the link box of the download manager window.
#   The browser helper passes more data through environment variables: DMS_URL DMS_NAME DMS_SIZE DMS_REFERER DMS_COOKIE DMS_UA
STATE="$HOME/.config/snow/state"; CONF="$HOME/.config/snow/bin/downloads"
url="${DMS_URL:-${1:-}}"; name="${DMS_NAME:-${2:-}}"; size="${DMS_SIZE:--1}"; referer="${DMS_REFERER:-}"; cookie="${DMS_COOKIE:-}"; ua="${DMS_UA:-}"
fail() { jq -nc --arg e "$1" '{ok:false,error:$e}'; exit 0; }
case "$url" in http://*|https://*|ftp://*) ;; *) fail "not a downloadable link" ;; esac
case "$size" in ''|*[!0-9-]*) size=-1 ;; esac
command -v qs >/dev/null 2>&1 || command -v quickshell >/dev/null 2>&1 || fail "quickshell is not installed"
mkdir -p "$STATE"
bash "$CONF/dm.sh" daemon >/dev/null 2>&1 || fail "the aria2 engine does not start"
# size (and name) unknown: ask the server (a quick HEAD request, at most 4 seconds)
if [ "$size" -le 0 ] 2>/dev/null || [ -z "$name" ]; then
  args=(-sIL -m 4 --connect-timeout 2); [ -n "$referer" ] && args+=(-e "$referer"); [ -n "$cookie" ] && args+=(-H "Cookie: $cookie"); [ -n "$ua" ] && args+=(-A "$ua")
  hdr=$(curl "${args[@]}" -- "$url" 2>/dev/null | tr -d '\r')
  if [ -n "$hdr" ]; then
    len=$(awk -F': *' 'tolower($1)=="content-length" {v=$2} END {print v}' <<<"$hdr"); case "$len" in ''|*[!0-9]*) ;; *) [ "$len" -gt 0 ] && size="$len" ;; esac
    if [ -z "$name" ]; then
      cd=$(grep -i '^content-disposition:' <<<"$hdr" | tail -n1 | sed -n 's/.*filename\*\?=\(UTF-8'"''"'\)\?"\?\([^";]*\).*/\2/p')
      [ -n "$cd" ] && name=$(printf '%b' "${cd//%/\\x}" 2>/dev/null)
    fi
  fi
fi
if [ -z "$name" ]; then name="${url%%[?#]*}"; name="${name##*/}"; name=$(printf '%b' "${name//%/\\x}" 2>/dev/null); fi
exec 9>"$STATE/dm-popup.lock"; flock 9   # one window at a time when several downloads start together
start=$(jq -r '.lastdir // .dir // ""' "$STATE/dm.json" 2>/dev/null)
[ -d "$start" ] || start=$(xdg-user-dir DOWNLOAD 2>/dev/null); [ -d "$start" ] || start="$HOME/Downloads"; [ -d "$start" ] || start="$HOME"
out=$(mktemp "${TMPDIR:-/tmp}/snow-dm-save.XXXXXX")
BIN=$(command -v qs || command -v quickshell)
mkdir -p "$HOME/.cache/snow"
DMA_URL="$url" DMA_NAME="$name" DMA_SIZE="$size" DMA_DIR="$start" DMA_OUT="$out" "$BIN" -p "$HOME/.config/snow/dmask" >"$HOME/.cache/snow/dm-save.log" 2>&1 </dev/null
ans=$(head -c 4096 "$out" 2>/dev/null); rm -f -- "$out"
act=$(jq -r '.action // "cancel"' <<<"$ans" 2>/dev/null); [ -n "$act" ] || act=cancel
if [ "$act" != "download" ] && [ "$act" != "queue" ]; then jq -nc '{ok:true,action:"cancel"}'; exit 0; fi
dir=$(jq -r '.dir // ""' <<<"$ans"); fname=$(jq -r '.name // ""' <<<"$ans"); fname="${fname//\//_}"; [ "$fname" != ".." ] || fname=""
dir="${dir/#\~/$HOME}"; [ -n "$dir" ] || dir="$start"; mkdir -p "$dir" 2>/dev/null
[ -d "$dir" ] && [ -w "$dir" ] || fail "cannot write into $dir"
gid="5d0cd3b$(od -An -tx1 -N5 /dev/urandom | tr -d ' \n' | cut -c1-9)"   # this prefix = "the folder was already chosen": the engine hook does not ask again
q=0; [ "$act" = "queue" ] && q=1   # Queue = added to the list but PAUSED (press Start in the download manager)
opt=$(jq -nc --arg g "$gid" --arg d "$dir" --arg o "$fname" --arg r "$referer" --arg c "$cookie" --arg ua "$ua" --argjson q "$q" \
  '{gid:$g, dir:$d} + (if $q == 1 then {pause:"true"} else {} end) + (if $o != "" then {out:$o} else {} end) + (if $r != "" then {referer:$r} else {} end) + (if $c != "" then {header:["Cookie: " + $c]} else {} end) + (if $ua != "" then {"user-agent":$ua} else {} end)')
if [ "$act" = "download" ]; then res=$(bash "$CONF/dm-rpc.sh" addx "$url" "$opt" top); else res=$(bash "$CONF/dm-rpc.sh" addx "$url" "$opt"); fi   # Download = first in the line, Queue = paused at the end
if [ "$(jq -r '.ok // false' <<<"$res" 2>/dev/null)" = "true" ]; then
  [ -s "$STATE/dm.json" ] && jq --arg d "$dir" '.lastdir=$d' "$STATE/dm.json" > "$STATE/dm.json.new" && mv -f "$STATE/dm.json.new" "$STATE/dm.json"
  jq -nc --arg a "$act" --arg d "$dir" '{ok:true,action:$a,dir:$d}'
else
  fail "$(jq -r '.error // "aria2 did not accept the link"' <<<"$res" 2>/dev/null)"
fi
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm.sh : Snow download manager = the aria2 engine + its own small Quickshell window (config ~/.config/snow/dm).
#   dm.sh              open the window (starts the engine first when it is not running; a second call only brings the window to the front)
#   dm.sh daemon       only start the engine (Hyprland does this at login, so unfinished downloads continue by themselves)
#   dm.sh add LINK...  add downloads from a terminal (links, magnet links, .torrent files)
#   dm.sh handle [LINK|FILE...]   what the browser calls for magnet: links and .torrent files (adds them, then shows the window)
#   dm.sh restart      restart the engine (needed once after an update of this manager)
#   dm.sh stop         stop the engine (unfinished downloads are saved and continue the next time the engine starts)
# Settings (folder, how many at once, connections, speed limit) live in ~/.config/snow/state/dm.json : change them in the window (gear) or with dm-conf.sh.
CONF="$HOME/.config/snow"; DIR="$CONF/dm"; STATE="$CONF/state"; JSON="$STATE/dm.json"; SEC="$STATE/dm-secret"; SES="$STATE/dm-session"
PORT="${DM_PORT:-6899}"; RPC="$CONF/bin/downloads/dm-rpc.sh"
mkdir -p "$STATE"
[ -s "$SEC" ] || { od -An -tx1 -N16 /dev/urandom | tr -d ' \n' > "$SEC"; chmod 600 "$SEC"; }
cfg() { jq -r --arg k "$1" '.[$k] // empty' "$JSON" 2>/dev/null; }
dl_dir() {
  local d; d="$(cfg dir)"
  [ -n "$d" ] || d="$(xdg-user-dir DOWNLOAD 2>/dev/null)"
  [ -n "$d" ] && [ "$d" != "$HOME" ] || d="$HOME/Downloads"
  d="${d/#\~/$HOME}"; mkdir -p "$d" 2>/dev/null; printf '%s' "$d"
}
engine_up() { curl -s -m 2 --data-binary "{\"jsonrpc\":\"2.0\",\"id\":\"x\",\"method\":\"aria2.getVersion\",\"params\":[\"token:$(cat "$SEC")\"]}" "http://127.0.0.1:$PORT/jsonrpc" 2>/dev/null | grep -q '"result"'; }
start_engine() {
  engine_up && return 0
  command -v aria2c >/dev/null 2>&1 || { echo "[PROBLEM] aria2 is not installed: sudo apt install aria2" >&2; return 1; }
  command -v jq >/dev/null 2>&1 || { echo "[PROBLEM] jq is not installed: sudo apt install jq" >&2; return 1; }
  pkill -f "aria2c.*rpc-listen-port=$PORT" 2>/dev/null && sleep 0.7   # an old engine with another secret (after a restore): stop it, it saves its list
  local max conn lim
  max="$(cfg max)"; conn="$(cfg conn)"; lim="$(cfg limit)"
  : "${max:=3}" "${conn:=8}" "${lim:=0}"
  touch "$SES"
  aria2c --daemon=true --enable-rpc --rpc-listen-port="$PORT" --rpc-listen-all=false --rpc-secret="$(cat "$SEC")" \
    --dir="$(dl_dir)" --max-concurrent-downloads="$max" --max-connection-per-server="$conn" --split="$conn" --min-split-size=1M \
    --max-overall-download-limit="$lim" --continue=true --auto-file-renaming=true --allow-overwrite=false \
    --input-file="$SES" --save-session="$SES" --save-session-interval=15 --console-log-level=error --on-download-start="$CONF/bin/downloads/dm-hook.sh" \
    --on-download-complete="$CONF/bin/downloads/dm-on-complete.sh" --on-download-error="$CONF/bin/downloads/dm-on-error.sh" --on-download-pause="$CONF/bin/downloads/dm-on-pause.sh" >/dev/null 2>&1
  local i; for i in 1 2 3 4 5 6 7 8 9 10; do engine_up && return 0; sleep 0.3; done
  echo "[PROBLEM] the aria2 engine did not start" >&2; return 1
}
case "${1:-open}" in
  daemon) start_engine; ( bash "$CONF/bin/downloads/dm-video.sh" autoupdate >/dev/null 2>&1 & ) ;;
  stop) bash "$RPC" shutdown ;;
  restart) bash "$RPC" shutdown >/dev/null; for i in 1 2 3 4 5 6 7 8 9 10; do engine_up || break; sleep 0.4; done; start_engine ;;
  add) shift; start_engine && bash "$RPC" add "$@" ;;
  handle) shift; if [ "$#" -gt 0 ]; then start_engine && bash "$RPC" add "$@" >/dev/null; fi; exec bash "${BASH_SOURCE[0]}" open ;;
  open)
    # a panel that is open (launcher, quick settings, power menu) must not stay on the screen: close them first
    QSH="$CONF/bin/core/qs.sh"
    if [ -x "$QSH" ] || [ -f "$QSH" ]; then for t in launcher quick power; do bash "$QSH" ipc call "$t" hide >/dev/null 2>&1 & done; fi
    start_engine || true
    ( bash "$CONF/bin/downloads/dm-video.sh" autoupdate >/dev/null 2>&1 & )   # yt-dlp: newest version once a week (setting "ytauto")
    BIN=$(command -v qs || command -v quickshell) || { echo "[PROBLEM] quickshell is not installed" >&2; exit 1; }
    if pgrep -f -- "-p $DIR" >/dev/null 2>&1; then
      command -v hyprctl >/dev/null 2>&1 && hyprctl dispatch focuswindow "title:^Snow Downloads$" >/dev/null 2>&1
    else
      mkdir -p "$HOME/.cache/snow"
      nohup "$BIN" -p "$DIR" > "$HOME/.cache/snow/dm.log" 2>&1 </dev/null &
    fi ;;
  *) echo "usage: dm.sh [open|daemon|add LINK...|handle LINK...|restart|stop]"; exit 2 ;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/dm/DmBtn.qml")
cat <<'SNOW_FILE_END_4b7d'
import QtQuick

// Small round icon button of the download manager (icon = Material Symbols code point, tip = text shown on hover).
Rectangle {
    id: b
    property int cp: 0xe5cd
    property string tip: ""
    property bool danger: false
    property bool accent: false
    property bool tipLeft: false
    property bool isClose: false     // the X of a window: red background on hover
    property int size: 32
    signal clicked()
    width: size
    height: size
    radius: size / 2
    antialiasing: true
    color: b.isClose && ma.containsMouse ? (ma.pressed ? Qt.darker(Theme.danger, 1.2) : Theme.danger) : (ma.pressed ? Theme.pressed : (ma.containsMouse ? Theme.hover : (accent ? Theme.accentSoft : "transparent")))
    Behavior on color { ColorAnimation { duration: Theme.hoverMs } }

    Text {
        anchors.centerIn: parent
        text: String.fromCodePoint(b.cp)
        font.family: Theme.iconFont
        renderType: Text.NativeRendering
        font.pixelSize: Math.round(b.size * 0.56)
        color: b.isClose && ma.containsMouse ? "#ffffff" : (b.danger ? Theme.danger : (b.accent ? Theme.accent : Theme.text))
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
    Rectangle {
        id: tipBox
        visible: b.tip !== "" && ma.containsMouse && tipTimer.shown
        z: 100
        height: tipText.implicitHeight + 8
        width: tipText.implicitWidth + 16
        radius: Theme.rChip
        color: Theme.surfaceHi
        border.width: 1
        border.color: Theme.hairline
        x: b.tipLeft ? -width - 6 : (b.width - width) / 2
        y: b.tipLeft ? (b.height - height) / 2 : -height - 6
        Text {
            id: tipText
            anchors.centerIn: parent
            text: b.tip
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsTiny
        }
    }
    Timer {
        id: tipTimer
        property bool shown: false
        interval: 450
        running: ma.containsMouse
        onTriggered: shown = true
        onRunningChanged: if (!running) shown = false
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/dm/DmField.qml")
cat <<'SNOW_FILE_END_4b7d'
import QtQuick

// One-line text box of the download manager. accepted(text) = Enter pressed; edited(text) = the box lost focus.
Rectangle {
    id: f
    property alias text: ti.text
    property alias input: ti
    property alias validator: ti.validator       // e.g. validator: IntValidator { bottom: 0 } = numbers only
    property string hint: ""
    signal accepted(string t)
    signal edited(string t)
    height: 38
    radius: Theme.rTile
    color: Theme.field
    border.width: 1
    border.color: ti.activeFocus ? Theme.accent : Theme.hairline
    Behavior on border.color { ColorAnimation { duration: Theme.hoverMs } }

    TextInput {
        id: ti
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentText
        font.family: Theme.uiFont
        font.pixelSize: Theme.fsBody
        clip: true
        selectByMouse: true
        onAccepted: f.accepted(text)
        onActiveFocusChanged: if (!activeFocus) f.edited(text)
    }
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: ti.text === ""
        text: f.hint
        color: Theme.muted
        font.family: Theme.uiFont
        font.pixelSize: Theme.fsBody
        elide: Text.ElideRight
        width: parent.width - 24
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/dm/Theme.qml")
cat <<'SNOW_FILE_END_4b7d'
pragma Singleton
// ⚠ RULE: 'pragma Singleton' hamesha FILE KI PEHLI LINE rahe. Quickshell pehli '{' wali line (comment me bhi) par header khatam maan leta hai,
//   isliye is line se upar kabhi koi '{' wali comment mat likho — warna ye singleton ban hi nahi paata (Sys.xxx = undefined).
// ============================================================================
//  Theme.qml  —  SAARE RANG, SIZE AUR SPEED YAHAN SE AATE HAIN
// ----------------------------------------------------------------------------
//  KYA HAI   : Ye ek "singleton" hai. Matlab poore Quickshell me ek hi copy,
//              aur har QML file isse "Theme.accent", "Theme.text" jaise naam se padh sakti hai.
//  RANG KAHAN SE : ~/.config/snow/state/theme.json  (is file ko theme.sh banata hai).
//              Rang badalna ho to QML nahi, ye command chalao:
//                  bash ~/.config/snow/bin/theme/theme.sh base   '#000000'   (background)
//                  bash ~/.config/snow/bin/theme/theme.sh accent '#d4af37'   (highlight)
//                  bash ~/.config/snow/bin/theme/theme.sh mode   dark|light|toggle
//  SIZE / SPEED : neeche "DESIGN SETTINGS" me. Sab panels same numbers use karte hain,
//              isliye yahan ek number badlo to poora desktop ek saath badal jata hai.
// ============================================================================

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ---------------------------------------------------------------- RANG
    // ":" ke baad wala rang sirf tab chalta hai jab theme.json abhi nahi bani.
    property color bg:        ja.bg        !== "" ? ja.bg        : "#14161b"   // sabse peeche ka rang
    property color surface:   ja.surface   !== "" ? ja.surface   : "#1b1e25"   // card / dabbe ka rang
    property color surfaceHi: ja.surfaceHi !== "" ? ja.surfaceHi : "#272b35"   // thoda ubhara hua rang
    property color text:      ja.text      !== "" ? ja.text      : "#e6e8ee"   // mukhya likhawat
    property color muted:     ja.muted     !== "" ? ja.muted     : "#8b91a1"   // halki likhawat / band icons
    property color accent:    ja.accent    !== "" ? ja.accent    : "#d4af37"   // highlight rang
    property color warn:      ja.warn      !== "" ? ja.warn      : "#e0a84a"   // chetavni
    property color danger:    ja.danger    !== "" ? ja.danger    : "#e0625f"   // galti / shutdown
    property color success:   ja.success   !== "" ? ja.success   : "#5fba7d"   // sab theek / connected
    property color tint:      ja.tint      !== "" ? ja.tint      : "#ffffff"   // dark me safed, light me kala (halke overlay ke liye)

    // accent ke upar likhi cheez ka rang: halka accent ho to kala text, gehra ho to safed
    readonly property color accentText: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.55 ? "#14161b" : "#ffffff"

    // ---------------------------------------------------------------- TAYAR (derived) RANG
    // Ye upar ke rangon se apne aap bante hain. Inhe direct mat badlo.
    readonly property color cardBg:     Qt.alpha(surface, 0.96)   // floating card ka background
    readonly property color railBg:     Qt.alpha(surface, 0.90)   // right wali vertical bar ka background
    readonly property color hairline:   Qt.alpha(tint, 0.09)      // patli border line
    readonly property color hover:      Qt.alpha(tint, 0.07)      // mouse upar aane par
    readonly property color pressed:    Qt.alpha(tint, 0.12)      // dabate waqt
    readonly property color field:      Qt.alpha(tint, 0.06)      // text box ka background
    readonly property color accentSoft: Qt.alpha(accent, 0.16)    // "ON" wali cheez ka halka background

    // ---------------------------------------------------------------- DESIGN SETTINGS (yahan badlo)
    readonly property string uiFont:   "Inter"                    // likhawat ka font
    readonly property string iconFont: "Material Symbols Rounded" // icon wala font (Icons.qml iske code points use karti hai)

    readonly property int rCard: 20     // bade card ke kone kitne gol
    readonly property int rRail: 24     // right wali bar ke kone
    readonly property int rTile: 14     // button / row ke kone
    readonly property int rChip: 10     // chhote chips ke kone
    readonly property int gap:   12     // cheezon ke beech ki jagah
    readonly property int pad:   16     // card ke andar ki jagah (padding)

    readonly property int fsTitle: 15   // card ka title
    readonly property int fsBody:  13   // normal likhawat
    readonly property int fsSmall: 12   // chhoti likhawat
    readonly property int fsTiny:  11   // sabse chhoti likhawat (subtitle, tooltip)

    readonly property int animMs:  160  // khulne / band hone ki speed (milliseconds). Bada number = dheema.
    readonly property int hoverMs: 110  // hover ke rang badalne ki speed

    // ---------------------------------------------------------------- theme.json PADHNE WALA HISSA
    FileView {
        path: Quickshell.env("HOME") + "/.config/snow/state/theme.json"
        watchChanges: true          // file badle to turant naya rang le lo
        printErrors: false
        onFileChanged: reload()

        adapter: JsonAdapter {
            id: ja
            property string bg: ""
            property string surface: ""
            property string surfaceHi: ""
            property string text: ""
            property string muted: ""
            property string accent: ""
            property string warn: ""
            property string danger: ""
            property string success: ""
            property string tint: ""
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/dm/shell.qml")
cat <<'SNOW_FILE_END_4b7d'
import Quickshell
import Quickshell.Io
import QtQuick

// Snow download manager. Own Quickshell instance: qs -p ~/.config/snow/dm   (started by ~/.config/snow/bin/downloads/dm.sh)
// The engine is aria2 (a background program). This window only SHOWS it and sends it commands:
//   dm-rpc.sh status   is read every second (list, speed)      dm-rpc.sh add / pause / resume / remove / retry / up / down ...   = the buttons
//   dm-conf.sh set ... = the settings (gear): folder, downloads at once, connections, speed limit
// Colours: Theme.qml only (theme.json). Nothing here changes any file except through those helper scripts.
ShellRoot {
    id: app

    readonly property string home: Quickshell.env("HOME")
    readonly property string binDir: home + "/.config/snow/bin/downloads"
    readonly property string rpc: binDir + "/dm-rpc.sh"
    readonly property string confSh: binDir + "/dm-conf.sh"
    readonly property string saveSh: binDir + "/dm-save.sh"
    readonly property string vsaveSh: binDir + "/dm-vsave.sh"
    readonly property string dmSh: binDir + "/dm.sh"

    property bool engineUp: false
    property string engineErr: ""
    property real speed: 0
    property var items: []
    property string filter: "all"          // all | active | queued | done
    property bool settingsOpen: false
    property string toastText: ""
    property double lastStart: 0
    property int nAll: 0
    property int nActive: 0
    property int nQueued: 0
    property int nDone: 0
    // ---- settings card: the values are edited in a DRAFT and only written when Save is pressed
    property int dMax: 3
    property int dConn: 8
    property bool dAsk: true
    property bool dnStart: false      // notifications (draft)
    property bool dnStop: false
    property bool dnDone: true
    property bool dnError: true
    property bool dYtAuto: true       // update yt-dlp by itself, once a week (draft)
    property string ytLine: ""        // what the yt-dlp row says: version / "Updating ..." / result
    property bool ytBusy: false
    property bool savingSettings: false
    // ---- speed limit of ONE download (popup)
    property string limGid: ""
    property string limName: ""

    // ------------------------------------------------------------ helpers
    function fmtSize(b) {
        if (!(b > 0)) return "0 B"
        if (b < 1024) return Math.round(b) + " B"
        var u = ["KB", "MB", "GB", "TB"], i = -1
        do { b = b / 1024; i++ } while (b >= 1024 && i < 3)
        return (b >= 100 ? b.toFixed(0) : b.toFixed(1)) + " " + u[i]
    }
    function fmtEta(it) {
        if (!(it.speed > 0) || !(it.total > it.done)) return ""
        var s = Math.round((it.total - it.done) / it.speed)
        if (s < 60) return s + "s"
        if (s < 3600) return Math.floor(s / 60) + "m " + (s % 60 < 10 ? "0" : "") + (s % 60) + "s"
        return Math.floor(s / 3600) + "h " + (Math.floor(s / 60) % 60 < 10 ? "0" : "") + (Math.floor(s / 60) % 60) + "m"
    }
    function uriName(u) {
        if (!u) return ""
        if (u.indexOf("magnet:") === 0) return "Magnet link"
        var p = u.split("?")[0].split("#")[0].split("/").pop()
        try { p = decodeURIComponent(p) } catch (e) { }
        return p
    }
    function kindOf(st) {
        if (st === "active" || st === "paused") return "active"
        if (st === "waiting") return "queued"
        return "done"
    }
    function norm(it) {
        var nm = it.name
        if (!nm) nm = uriName(it.uri)
        if (!nm) nm = "Getting information ..."
        return { gid: it.gid, st: it.status, nm: nm, total: it.total, done: it.done, spd: it.speed,
                 dir: it.dir, pth: it.path, err: it.err, pct: it.total > 0 ? Math.min(100, Math.floor(it.done * 100 / it.total)) : 0,
                 eta: fmtEta(it), lim: it.limit ? it.limit : 0 }
    }
    // a limit from dm.json ("500K", "2M", "0" or an old plain number = bytes) as KB per second
    function limitKb(s) {
        var m = String(s === undefined || s === null || s === "" ? "0" : s).match(/^(\d+)\s*([KkMm]?)$/)
        if (!m) return 0
        var n = parseInt(m[1])
        if (m[2] === "K" || m[2] === "k") return n
        if (m[2] === "M" || m[2] === "m") return n * 1024
        return Math.ceil(n / 1024)
    }
    function limTxt(l) { return l > 0 ? "   ·   limit " + l + " KB/s" : "" }
    function openSettings() {
        dirField.text = cfg.dir
        limField.text = String(limitKb(cfg.limit))
        dMax = cfg.max; dConn = cfg.conn; dAsk = cfg.ask
        dnStart = cfg.nstart; dnStop = cfg.nstop; dnDone = cfg.ndone; dnError = cfg.nerror; dYtAuto = cfg.ytauto
        if (!ytBusy) { ytLine = "Reading the version ..."; ytVerProc.running = true }
        settingsOpen = true
    }
    function nGet(i) { return i === 0 ? dnStart : (i === 1 ? dnStop : (i === 2 ? dnDone : dnError)) }
    function nFlip(i) { if (i === 0) dnStart = !dnStart; else if (i === 1) dnStop = !dnStop; else if (i === 2) dnDone = !dnDone; else dnError = !dnError }
    function pickFolder() {
        if (pickProc.running) return
        pickProc.command = [binDir + "/dm-pickdir.sh", dirField.text.replace(/^\s+|\s+$/g, "")]
        pickProc.running = true
    }
    function updateYt() {
        if (ytBusy) return
        ytBusy = true
        ytLine = "Updating yt-dlp ... (can take about a minute)"
        ytUpProc.running = true
    }
    function saveSettings() {
        var ch = {}
        var d = dirField.text.replace(/^\s+|\s+$/g, "")
        if (d !== cfg.dir) ch.dir = d
        if (dMax !== cfg.max) ch.max = dMax
        if (dConn !== cfg.conn) ch.conn = dConn
        var lv = limField.text.replace(/\s/g, ""); if (lv === "") lv = "0"
        if (parseInt(lv) !== limitKb(cfg.limit)) ch.limit = parseInt(lv)
        if (dAsk !== cfg.ask) ch.ask = dAsk ? "on" : "off"
        if (dnStart !== cfg.nstart) ch.nstart = dnStart ? "on" : "off"
        if (dnStop !== cfg.nstop) ch.nstop = dnStop ? "on" : "off"
        if (dnDone !== cfg.ndone) ch.ndone = dnDone ? "on" : "off"
        if (dnError !== cfg.nerror) ch.nerror = dnError ? "on" : "off"
        if (dYtAuto !== cfg.ytauto) ch.ytauto = dYtAuto ? "on" : "off"
        if (Object.keys(ch).length === 0) { settingsOpen = false; return }
        savingSettings = true
        confProc.command = [confSh, "batch", JSON.stringify(ch)]
        confProc.running = true
    }
    function openLimit(gid, nm, cur) {
        limField2.text = String(cur > 0 ? cur : 0)
        limName = nm
        limGid = gid
        limField2.input.forceActiveFocus()
        limField2.input.selectAll()
    }
    function setLimit() {
        var v = limField2.text.replace(/\s/g, ""); if (v === "") v = "0"
        Quickshell.execDetached([rpc, "limit", limGid, v])
        toast(parseInt(v) > 0 ? "Speed limit set: " + parseInt(v) + " KB/s" : "Speed limit removed")
        limGid = ""
        quickPoll.restart()
    }
    function toast(t) { toastText = t; toastTimer.restart() }

    // ------------------------------------------------------------ list model (updated in place, so rows do not flicker)
    function sync() {
        var list = []
        for (var i = 0; i < items.length; i++)
            if (filter === "all" || kindOf(items[i].status) === filter) list.push(norm(items[i]))
        var same = dlModel.count === list.length
        if (same) for (var j = 0; j < list.length; j++) if (dlModel.get(j).gid !== list[j].gid) { same = false; break }
        if (!same) {
            dlModel.clear()
            for (var k = 0; k < list.length; k++) dlModel.append(list[k])
        } else {
            for (var m = 0; m < list.length; m++) dlModel.set(m, list[m])
        }
    }
    function onStatus(text) {
        var r = null
        try { r = JSON.parse(text) } catch (e) { r = null }
        if (r === null || !r.ok) {
            engineUp = false
            engineErr = r === null ? "no answer from dm-rpc.sh" : (r.error || "error")
            if (new Date().getTime() - lastStart > 12000) { lastStart = new Date().getTime(); Quickshell.execDetached([dmSh, "daemon"]) }
            return
        }
        engineUp = true
        speed = r.speed
        items = r.items
        var a = 0, q = 0, d = 0
        for (var i = 0; i < r.items.length; i++) {
            var k = kindOf(r.items[i].status)
            if (k === "active") a++; else if (k === "queued") q++; else d++
        }
        nAll = r.items.length; nActive = a; nQueued = q; nDone = d
        sync()
    }
    function act(args) {
        Quickshell.execDetached([rpc].concat(args))
        quickPoll.restart()
    }
    function addLinks(t) {
        var l = t.split(/\s+/).filter(function (x) { return x.length > 0 })
        if (l.length === 0) return
        // web links (http, https, ftp) first open the "Save download" window (name + folder + Download / Queue / Cancel); magnet links and .torrent files go straight in
        // video pages (YouTube ...) go to yt-dlp (dm-video.sh) and are saved in the download folder with the quality chosen in the settings
        var vre = /^https?:\/\/([a-z0-9-]+\.)*(youtube\.com|youtu\.be|vimeo\.com|dailymotion\.com|twitch\.tv|tiktok\.com|instagram\.com|facebook\.com|fb\.watch|twitter\.com|x\.com|reddit\.com|soundcloud\.com|bilibili\.com)(\/|$|\?)/i
        var vid = l.filter(function (x) { return vre.test(x) })
        l = l.filter(function (x) { return !vre.test(x) })
        // each video link opens the "Save video" window (quality / audio only / folder), one after the other
        if (vid.length > 0) { vidProc.command = ["bash", "-c", "for u in \"$@\"; do bash \"$0\" \"$u\"; done", vsaveSh].concat(vid); vidProc.running = true; urlField.text = "" }
        var web = l.filter(function (x) { return /^(https?|ftp):\/\//i.test(x) })
        var rest = l.filter(function (x) { return !/^(https?|ftp):\/\//i.test(x) })
        if (web.length > 0) {
            saveProc.command = ["bash", "-c", "for u in \"$@\"; do bash \"$0\" \"$u\"; done", saveSh].concat(web)
            saveProc.running = true
            urlField.text = ""
        }
        if (rest.length > 0) { addProc.command = [rpc, "add"].concat(rest); addProc.running = true }
    }
    function setConf(k, v) {
        confProc.command = [confSh, "set", k, String(v)]
        confProc.running = true
    }
    onFilterChanged: sync()

    // ------------------------------------------------------------ processes / timers
    Process {
        id: poll
        command: [app.rpc, "status"]
        stdout: StdioCollector { onStreamFinished: app.onStatus(text) }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!poll.running) poll.running = true
    }
    Timer { id: quickPoll; interval: 250; onTriggered: if (!poll.running) poll.running = true }
    Timer { id: toastTimer; interval: 3500; onTriggered: app.toastText = "" }
    Process {
        id: addProc
        stdout: StdioCollector {
            onStreamFinished: {
                var r = null
                try { r = JSON.parse(text) } catch (e) { r = null }
                if (r && r.ok) { urlField.text = ""; app.toast(r.added > 1 ? r.added + " downloads added" : "Download added"); quickPoll.restart() }
                else app.toast(r && r.error ? r.error : "Could not add the link")
            }
        }
    }
    Process {
        id: vidProc
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n"), ok = 0, err = ""
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim() === "") continue
                    try { var r = JSON.parse(lines[i]); if (r.ok && r.action === "download") ok++; else if (!r.ok) err = r.error || "Could not start the video download" } catch (e) { }
                }
                if (err !== "") app.toast(err); else if (ok > 0) { app.toast(ok > 1 ? ok + " video downloads started" : "Video download started"); quickPoll.restart() }
            }
        }
    }
    Process {
        id: saveProc
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n"), ok = 0, paused = 0, err = ""
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim() === "") continue
                    try { var r = JSON.parse(lines[i]); if (r.ok && r.action !== "cancel") { ok++; if (r.action === "queue") paused++ } else if (!r.ok) err = r.error || "Could not add the link" } catch (e) { /* not a result line */ }
                }
                if (err !== "") app.toast(err); else if (ok > 0) { app.toast(paused === ok ? (ok > 1 ? ok + " added to the list (paused): press Start" : "Added to the list (paused): press Start") : (ok > 1 ? ok + " downloads added" : "Download added")); quickPoll.restart() }
            }
        }
    }
    Process {
        id: pickProc
        stdout: StdioCollector {
            onStreamFinished: { var d = text.split("\n")[0].replace(/^\s+|\s+$/g, ""); if (d !== "") dirField.text = d }
        }
    }
    Process {
        id: ytVerProc
        command: [app.binDir + "/dm-video.sh", "version"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (app.ytBusy) return
                var r = null
                try { r = JSON.parse(text) } catch (e) { r = null }
                if (r && r.ok) app.ytLine = "Version " + r.version + (r.own ? "" : "   (old system copy: press Update)")
                else app.ytLine = r && r.error ? r.error : "yt-dlp is not installed: press Update"
            }
        }
    }
    Process {
        id: ytUpProc
        command: [app.binDir + "/dm-video.sh", "selfupdate"]
        stdout: StdioCollector {
            onStreamFinished: {
                app.ytBusy = false
                var r = null
                try { r = JSON.parse(text) } catch (e) { r = null }
                if (r && r.ok) { app.ytLine = r.msg; app.toast(r.msg) }
                else { app.ytLine = "Could not update: " + (r && r.error ? r.error : "no answer"); app.toast("yt-dlp update failed") }
            }
        }
    }
    Process {
        id: confProc
        stdout: StdioCollector {
            onStreamFinished: {
                var r = null
                try { r = JSON.parse(text) } catch (e) { r = null }
                if (app.savingSettings) {
                    app.savingSettings = false
                    if (r && r.ok) { app.settingsOpen = false; app.toast("Settings saved") }
                    else app.toast(r && r.error ? r.error : "Settings not saved")
                    return
                }
                if (r && !r.ok) app.toast(r.error || "Setting not saved")
            }
        }
    }

    // ------------------------------------------------------------ settings file (dm.json), read live
    FileView {
        id: confFile
        path: app.home + "/.config/snow/state/dm.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: cfg
            property string dir: ""
            property int max: 3
            property int conn: 8
            property string limit: "0"
            property bool ask: true
            property bool nstart: false
            property bool nstop: false
            property bool ndone: true
            property bool nerror: true
            property bool ytauto: true
        }
    }

    // on / off switch (settings card)
    component Tog: Rectangle {
        id: tg
        property bool checked: false
        signal flipped()
        width: 46
        height: 26
        radius: 13
        color: tg.checked ? Theme.accent : Theme.field
        border.width: 1
        border.color: tg.checked ? Theme.accent : Theme.hairline
        Behavior on color { ColorAnimation { duration: Theme.hoverMs } }
        Rectangle {
            width: 20
            height: 20
            radius: 10
            y: 3
            x: tg.checked ? parent.width - width - 3 : 3
            color: tg.checked ? Theme.accentText : Theme.muted
            Behavior on x { NumberAnimation { duration: Theme.hoverMs } }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tg.flipped() }
    }

    // ------------------------------------------------------------ window
    FloatingWindow {
        id: win
        visible: true
        title: "Snow Downloads"
        implicitWidth: 960
        implicitHeight: 680                 // only a first size: this is a normal TILED window (no fixed size, no float rule in snow-look.lua), like any other program
        color: Theme.bg
        onVisibleChanged: if (!visible) Qt.quit()

        Item {
            anchors.fill: parent
            focus: true
            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_Escape) { if (app.limGid !== "") app.limGid = ""; else if (app.settingsOpen) app.settingsOpen = false; else Qt.quit(); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && (e.key === Qt.Key_W || e.key === Qt.Key_Q)) { Qt.quit(); e.accepted = true }
            }

            // ---------- top: add a link
            Item {
                id: top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                height: 40
                Image {
                    id: logo
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    source: "file://" + app.home + "/.config/snow/dm/logo.png"
                    sourceSize: Qt.size(144, 144)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }
                DmField {
                    id: urlField
                    anchors.left: logo.right
                    anchors.leftMargin: 10
                    anchors.right: pasteBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    height: 40
                    hint: "Paste a link or magnet link, press Enter"
                    onAccepted: (t) => app.addLinks(t)
                    Component.onCompleted: input.forceActiveFocus()
                }
                DmBtn {
                    id: pasteBtn
                    anchors.right: addBtn.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    cp: 0xe14f
                    tip: "Paste"
                    onClicked: { urlField.input.forceActiveFocus(); urlField.input.paste() }
                }
                DmBtn {
                    id: closeBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    cp: 0xe5cd
                    isClose: true
                    tip: "Close (Esc)"
                    tipLeft: true
                    onClicked: Qt.quit()
                }
                Rectangle {
                    id: addBtn
                    anchors.right: closeBtn.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: addTxt.implicitWidth + 32
                    height: 40
                    radius: 20
                    antialiasing: true
                    color: addMa.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent
                    opacity: addMa.containsMouse ? 0.92 : 1
                    Text {
                        id: addTxt
                        anchors.centerIn: parent
                        text: "Add"
                        color: Theme.accentText
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fsBody
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: addMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: app.addLinks(urlField.text)
                    }
                }
            }

            // ---------- filter chips + actions
            Item {
                id: bar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: top.bottom
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 8
                height: 34
                Row {
                    spacing: 6
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: [{ k: "all", t: "All", n: app.nAll }, { k: "active", t: "Active", n: app.nActive },
                                { k: "queued", t: "Queued", n: app.nQueued }, { k: "done", t: "Done", n: app.nDone }]
                        delegate: Rectangle {
                            required property var modelData
                            height: 30
                            width: chipTxt.implicitWidth + 24
                            radius: 15
                            antialiasing: true
                            color: app.filter === modelData.k ? Theme.accentSoft : (chipMa.containsMouse ? Theme.hover : "transparent")
                            border.width: 1
                            border.color: app.filter === modelData.k ? Theme.accent : Theme.hairline
                            Text {
                                id: chipTxt
                                anchors.centerIn: parent
                                text: modelData.t + (modelData.n > 0 ? "  " + modelData.n : "")
                                color: app.filter === modelData.k ? Theme.accent : Theme.muted
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.fsSmall
                                font.weight: app.filter === modelData.k ? Font.DemiBold : Font.Normal
                            }
                            MouseArea {
                                id: chipMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: app.filter = modelData.k
                            }
                        }
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    DmBtn { cp: 0xe037; tip: "Start all"; onClicked: app.act(["resumeall"]) }
                    DmBtn { cp: 0xe034; tip: "Pause all"; onClicked: app.act(["pauseall"]) }
                    DmBtn { cp: 0xe0b8; tip: "Clear finished"; onClicked: app.act(["clear"]) }
                    DmBtn { cp: 0xe8b8; tip: "Settings"; accent: app.settingsOpen; onClicked: { if (app.settingsOpen) app.settingsOpen = false; else app.openSettings() } }
                }
            }

            // ---------- list
            ListModel { id: dlModel }
            ListView {
                id: list
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: bar.bottom
                anchors.bottom: status.top
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                clip: true
                spacing: 6
                model: dlModel
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    id: row
                    width: list.width
                    height: 66
                    radius: Theme.rTile
                    antialiasing: true
                    color: rowMa.containsMouse ? Theme.surfaceHi : Theme.surface
                    readonly property string st: model.st
                    readonly property string infoText: {
                                if (row.st === "active") return app.fmtSize(model.done) + (model.total > 0 ? " of " + app.fmtSize(model.total) + "  (" + model.pct + "%)" : "") + "   ·   " + app.fmtSize(model.spd) + "/s" + (model.eta !== "" ? "   ·   " + model.eta + " left" : "")
                                if (row.st === "paused") return "Paused   ·   " + model.pct + "%   ·   " + app.fmtSize(model.done) + (model.total > 0 ? " of " + app.fmtSize(model.total) : "")
                                if (row.st === "waiting") return "Queued (waiting for a free place)"
                                if (row.st === "complete") return "Done   ·   " + app.fmtSize(model.total)
                                return "Failed   ·   " + (model.err !== "" ? model.err : "unknown error")
                            }
                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onDoubleClicked: if (row.st === "complete" && model.pth !== "") Quickshell.execDetached(["xdg-open", model.pth])
                    }
                    // state badge
                    Rectangle {
                        id: badge
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 36
                        radius: 18
                        antialiasing: true
                        color: row.st === "complete" ? Qt.alpha(Theme.success, 0.16) : (row.st === "error" ? Qt.alpha(Theme.danger, 0.16) : (row.st === "active" ? Theme.accentSoft : Theme.field))
                        Text {
                            anchors.centerIn: parent
                            text: String.fromCodePoint(row.st === "complete" ? 0xe5ca : (row.st === "error" ? 0xf8b6 : (row.st === "active" ? 0xf001 : (row.st === "paused" ? 0xe034 : 0xefd6))))
                            font.family: Theme.iconFont
                            renderType: Text.NativeRendering
                            font.pixelSize: 20
                            color: row.st === "complete" ? Theme.success : (row.st === "error" ? Theme.danger : (row.st === "active" ? Theme.accent : Theme.muted))
                        }
                    }
                    // buttons (right)
                    Row {
                        id: btns
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0
                        DmBtn { visible: row.st === "waiting"; size: 28; cp: 0xe5d8; tip: "Move up in the queue"; tipLeft: true; onClicked: app.act(["up", model.gid]) }
                        DmBtn { visible: row.st === "waiting"; size: 28; cp: 0xe5db; tip: "Move down in the queue"; tipLeft: true; onClicked: app.act(["down", model.gid]) }
                        DmBtn { visible: row.st === "waiting"; size: 28; cp: 0xe25a; tip: "Move to the top of the queue"; tipLeft: true; accent: true; onClicked: app.act(["top", model.gid]) }
                        DmBtn { visible: row.st === "active" || row.st === "paused" || row.st === "waiting"; size: 28; cp: 0xe9e4; tip: "Speed limit of this download"; tipLeft: true; accent: model.lim > 0; onClicked: app.openLimit(model.gid, model.nm, model.lim) }
                        DmBtn { visible: row.st === "active"; cp: 0xe034; tip: "Pause"; tipLeft: true; onClicked: app.act(["pause", model.gid]) }
                        DmBtn { visible: row.st === "paused"; cp: 0xe037; tip: "Resume"; tipLeft: true; accent: true; onClicked: app.act(["resume", model.gid]) }
                        DmBtn { visible: row.st === "error"; cp: 0xe5d5; tip: "Try again"; tipLeft: true; accent: true; onClicked: app.act(["retry", model.gid]) }
                        DmBtn { visible: row.st === "complete" || row.st === "error" || row.st === "paused" || row.st === "active"; cp: 0xe2c8; tip: "Show in folder"; tipLeft: true; onClicked: Quickshell.execDetached([app.home + "/.config/snow/bin/filemanager/fm.sh", model.dir]) }
                        DmBtn { cp: row.st === "complete" || row.st === "error" ? 0xe5cd : 0xe047; danger: true; tip: row.st === "complete" || row.st === "error" ? "Remove from the list" : "Stop and remove"; tipLeft: true; onClicked: app.act(["remove", model.gid]) }
                    }
                    // name + bar + info
                    Column {
                        anchors.left: badge.right
                        anchors.leftMargin: 12
                        anchors.right: btns.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        Text {
                            width: parent.width
                            text: model.nm
                            elide: Text.ElideMiddle
                            color: Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fsBody
                            font.weight: Font.Medium
                        }
                        Rectangle {
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Theme.field
                            visible: row.st !== "error"
                            Rectangle {
                                height: parent.height
                                radius: 2
                                width: parent.width * (row.st === "complete" ? 1 : model.pct / 100)
                                color: row.st === "complete" ? Theme.success : (row.st === "active" ? Theme.accent : Theme.muted)
                                Behavior on width { NumberAnimation { duration: 400 } }
                            }
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            color: row.st === "error" ? Theme.danger : Theme.muted
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fsTiny
                            text: row.infoText + (row.st === "active" || row.st === "paused" || row.st === "waiting" ? app.limTxt(model.lim) : "")
                        }
                    }
                }
            }
            Text {
                anchors.centerIn: list
                visible: app.engineUp && dlModel.count === 0
                horizontalAlignment: Text.AlignHCenter
                text: app.filter === "all" ? "No downloads yet.\nPaste a link above and press Enter." : "Nothing here."
                color: Theme.muted
                font.family: Theme.uiFont
                font.pixelSize: Theme.fsBody
                lineHeight: 1.3
            }
            // engine not running
            Column {
                anchors.centerIn: list
                visible: !app.engineUp
                spacing: 10
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "The download engine (aria2) is not running."
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fsBody
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: app.engineErr + "   (if aria2 is missing: sudo apt install aria2)"
                    color: Theme.muted
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fsTiny
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 130
                    height: 34
                    radius: 17
                    color: Theme.accentSoft
                    border.width: 1
                    border.color: Theme.accent
                    Text { anchors.centerIn: parent; text: "Start engine"; color: Theme.accent; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { app.lastStart = new Date().getTime(); Quickshell.execDetached([app.dmSh, "daemon"]); quickPoll.restart() } }
                }
            }

            // ---------- status bar: speed, counts
            Item {
                id: status
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                height: 38
                Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 1; color: Theme.hairline }
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: String.fromCodePoint(0xf1e3) + " " + app.fmtSize(app.speed) + "/s"
                    color: app.speed > 0 ? Theme.accent : Theme.muted
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fsBody
                    font.weight: Font.DemiBold
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: app.nActive + " active   ·   " + app.nQueued + " queued   ·   " + app.nDone + " finished" + (cfg.limit !== "0" && cfg.limit !== "" ? "   ·   limit " + cfg.limit + "/s" : "")
                    color: Theme.muted
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fsTiny
                }
            }

            // ---------- toast
            Rectangle {
                visible: app.toastText !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: status.top
                anchors.bottomMargin: 12
                width: toastTxt.implicitWidth + 28
                height: 34
                radius: 17
                color: Theme.surfaceHi
                border.width: 1
                border.color: Theme.hairline
                Text { id: toastTxt; anchors.centerIn: parent; text: app.toastText; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
            }

            // ---------- settings card (gear): the rows scroll when the window is small, Save / Cancel stay at the bottom
            Rectangle {
                anchors.fill: parent
                visible: app.settingsOpen
                color: Qt.alpha("#000000", 0.45)
                MouseArea { anchors.fill: parent; onClicked: app.settingsOpen = false }
                Rectangle {
                    id: setCard
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 40, 500)
                    height: Math.min(parent.height - 40, setCol.implicitHeight + 36 + 64)
                    radius: Theme.rCard
                    color: Theme.cardBg
                    border.width: 1
                    border.color: Theme.hairline
                    MouseArea { anchors.fill: parent }
                    Flickable {
                        id: setFlick
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: setFoot.top
                        clip: true
                        contentWidth: width
                        contentHeight: setCol.implicitHeight + 36
                        boundsBehavior: Flickable.StopAtBounds
                        Column {
                            id: setCol
                            x: 18
                            y: 18
                            width: setFlick.width - 36
                            spacing: 14
                            Text { text: "Download settings"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsTitle; font.weight: Font.DemiBold }
                            Column {
                                width: parent.width
                                spacing: 6
                                Text { text: "Save downloads in"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                                Item {
                                    width: parent.width
                                    height: 40
                                    DmField {
                                        id: dirField
                                        anchors.left: parent.left
                                        anchors.right: pickBtn.left
                                        anchors.rightMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 40
                                        hint: "Your Downloads folder (default)"
                                        text: ""
                                        onAccepted: (t) => app.saveSettings()
                                    }
                                    DmBtn {
                                        id: pickBtn
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        size: 40
                                        cp: 0xe2c8
                                        tip: "Choose a folder"
                                        tipLeft: true
                                        onClicked: app.pickFolder()
                                    }
                                }
                            }
                            Item {
                                width: parent.width
                                height: 34
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Downloads at the same time"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    DmBtn { cp: 0xe15b; tip: "Less"; onClicked: if (app.dMax > 1) app.dMax = app.dMax - 1 }
                                    Text { width: 30; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter; text: app.dMax; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold }
                                    DmBtn { cp: 0xe145; tip: "More"; onClicked: if (app.dMax < 10) app.dMax = app.dMax + 1 }
                                }
                            }
                            Item {
                                width: parent.width
                                height: 34
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Connections per download"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    DmBtn { cp: 0xe15b; tip: "Less"; onClicked: if (app.dConn > 1) app.dConn = app.dConn - 1 }
                                    Text { width: 30; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter; text: app.dConn; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold }
                                    DmBtn { cp: 0xe145; tip: "More"; onClicked: if (app.dConn < 16) app.dConn = app.dConn + 1 }
                                }
                            }
                            Item {
                                width: parent.width
                                height: 38
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Speed limit for all downloads (0 = none)"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6
                                    DmField {
                                        id: limField
                                        width: 84
                                        height: 34
                                        hint: "0"
                                        text: ""
                                        validator: IntValidator { bottom: 0; top: 10000000 }
                                        onAccepted: (t) => app.saveSettings()
                                    }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "KB/s"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                                }
                            }
                            Item {
                                width: parent.width
                                height: 34
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Ask where to save every download"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody }
                                Tog { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; checked: app.dAsk; onFlipped: app.dAsk = !app.dAsk }
                            }
                            Column {
                                width: parent.width
                                spacing: 8
                                Text { text: "Show a notification when a download ..."; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                                Row {
                                    spacing: 6
                                    Repeater {
                                        model: ["starts", "stops", "finishes", "fails"]
                                        delegate: Rectangle {
                                            id: nChip
                                            required property int index
                                            required property string modelData
                                            property bool chipOn: app.nGet(index)
                                            height: 30
                                            width: nTxt.implicitWidth + 24
                                            radius: 15
                                            antialiasing: true
                                            color: nChip.chipOn ? Theme.accentSoft : (nMa.containsMouse ? Theme.hover : "transparent")
                                            border.width: 1
                                            border.color: nChip.chipOn ? Theme.accent : Theme.hairline
                                            Text {
                                                id: nTxt
                                                anchors.centerIn: parent
                                                text: (nChip.chipOn ? "✓  " : "") + nChip.modelData
                                                color: nChip.chipOn ? Theme.accent : Theme.muted
                                                font.family: Theme.uiFont
                                                font.pixelSize: Theme.fsSmall
                                                font.weight: nChip.chipOn ? Font.DemiBold : Font.Normal
                                            }
                                            MouseArea { id: nMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.nFlip(nChip.index) }
                                        }
                                    }
                                }
                            }
                            Item {
                                width: parent.width
                                height: 48
                                Column {
                                    anchors.left: parent.left
                                    anchors.right: ytBtn.left
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text { text: "yt-dlp (video downloads)"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody }
                                    Text { width: parent.width; text: app.ytLine; elide: Text.ElideRight; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                                }
                                Rectangle {
                                    id: ytBtn
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: ytTxt.implicitWidth + 24
                                    height: 30
                                    radius: 15
                                    opacity: app.ytBusy ? 0.5 : 1
                                    color: ytMa.containsMouse && !app.ytBusy ? Theme.hover : Theme.accentSoft
                                    border.width: 1
                                    border.color: Theme.accent
                                    Text { id: ytTxt; anchors.centerIn: parent; text: app.ytBusy ? "Updating ..." : "Update now"; color: Theme.accent; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall; font.weight: Font.DemiBold }
                                    MouseArea { id: ytMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.updateYt() }
                                }
                            }
                            Item {
                                width: parent.width
                                height: 34
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Update yt-dlp by itself (once a week)"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody }
                                Tog { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; checked: app.dYtAuto; onFlipped: app.dYtAuto = !app.dYtAuto }
                            }
                            Item {
                                width: parent.width
                                height: 34
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Browser: Aria2 Explorer  ·  127.0.0.1:6899"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody }
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: secTxt.implicitWidth + 24
                                    height: 30
                                    radius: 15
                                    color: secMa.containsMouse ? Theme.hover : Theme.accentSoft
                                    border.width: 1
                                    border.color: Theme.accent
                                    Text { id: secTxt; anchors.centerIn: parent; text: "Copy secret"; color: Theme.accent; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall; font.weight: Font.DemiBold }
                                    MouseArea {
                                        id: secMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { Quickshell.execDetached(["bash", "-c", "wl-copy < \"$1\"", "x", app.home + "/.config/snow/state/dm-secret"]); app.toast("Secret copied: paste it in the browser extension") }
                                    }
                                }
                            }
                        }
                    }
                    Item {
                        id: setFoot
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 64
                        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 1; color: Theme.hairline }
                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            Rectangle {
                                width: 96; height: 40; radius: 20; antialiasing: true
                                color: scMa.pressed ? Theme.pressed : (scMa.containsMouse ? Theme.hover : "transparent")
                                border.width: 1; border.color: Theme.hairline
                                Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.danger; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold }
                                MouseArea { id: scMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.settingsOpen = false }
                            }
                            Rectangle {
                                width: 96; height: 40; radius: 20; antialiasing: true
                                color: ssMa.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent
                                opacity: ssMa.containsMouse ? 0.92 : 1
                                Text { anchors.centerIn: parent; text: "Save"; color: Theme.accentText; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold }
                                MouseArea { id: ssMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.saveSettings() }
                            }
                        }
                    }
                }
            }

            // ---------- speed limit of ONE download (the speed button of a row)
            Rectangle {
                anchors.fill: parent
                visible: app.limGid !== ""
                color: Qt.alpha("#000000", 0.45)
                MouseArea { anchors.fill: parent; onClicked: app.limGid = "" }
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 40, 400)
                    height: limCol.implicitHeight + 36
                    radius: Theme.rCard
                    color: Theme.cardBg
                    border.width: 1
                    border.color: Theme.hairline
                    MouseArea { anchors.fill: parent }
                    Column {
                        id: limCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 18
                        spacing: 12
                        Text { text: "Speed limit of this download"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsTitle; font.weight: Font.DemiBold }
                        Text { width: parent.width; text: app.limName; elide: Text.ElideMiddle; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                        Row {
                            spacing: 8
                            DmField {
                                id: limField2
                                width: 140
                                height: 40
                                hint: "0"
                                text: "0"
                                validator: IntValidator { bottom: 0; top: 10000000 }
                                onAccepted: (t) => app.setLimit()
                            }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "KB/s   (0 = no limit)"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                        }
                        Item {
                            width: parent.width
                            height: 44
                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8
                                Rectangle {
                                    width: 96; height: 40; radius: 20; antialiasing: true
                                    color: lcMa.pressed ? Theme.pressed : (lcMa.containsMouse ? Theme.hover : "transparent")
                                    border.width: 1; border.color: Theme.hairline
                                    Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.danger; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold }
                                    MouseArea { id: lcMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.limGid = "" }
                                }
                                Rectangle {
                                    width: 96; height: 40; radius: 20; antialiasing: true
                                    color: lsMa.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent
                                    opacity: lsMa.containsMouse ? 0.92 : 1
                                    Text { anchors.centerIn: parent; text: "Set"; color: Theme.accentText; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold }
                                    MouseArea { id: lsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.setLimit() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/dmask/DmBtn.qml")
cat <<'SNOW_FILE_END_4b7d'
import QtQuick

// Small round icon button of the download manager (icon = Material Symbols code point, tip = text shown on hover).
Rectangle {
    id: b
    property int cp: 0xe5cd
    property string tip: ""
    property bool danger: false
    property bool accent: false
    property bool tipLeft: false
    property bool isClose: false     // the X of a window: red background on hover
    property int size: 32
    signal clicked()
    width: size
    height: size
    radius: size / 2
    antialiasing: true
    color: b.isClose && ma.containsMouse ? (ma.pressed ? Qt.darker(Theme.danger, 1.2) : Theme.danger) : (ma.pressed ? Theme.pressed : (ma.containsMouse ? Theme.hover : (accent ? Theme.accentSoft : "transparent")))
    Behavior on color { ColorAnimation { duration: Theme.hoverMs } }

    Text {
        anchors.centerIn: parent
        text: String.fromCodePoint(b.cp)
        font.family: Theme.iconFont
        renderType: Text.NativeRendering
        font.pixelSize: Math.round(b.size * 0.56)
        color: b.isClose && ma.containsMouse ? "#ffffff" : (b.danger ? Theme.danger : (b.accent ? Theme.accent : Theme.text))
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
    Rectangle {
        id: tipBox
        visible: b.tip !== "" && ma.containsMouse && tipTimer.shown
        z: 100
        height: tipText.implicitHeight + 8
        width: tipText.implicitWidth + 16
        radius: Theme.rChip
        color: Theme.surfaceHi
        border.width: 1
        border.color: Theme.hairline
        x: b.tipLeft ? -width - 6 : (b.width - width) / 2
        y: b.tipLeft ? (b.height - height) / 2 : -height - 6
        Text {
            id: tipText
            anchors.centerIn: parent
            text: b.tip
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsTiny
        }
    }
    Timer {
        id: tipTimer
        property bool shown: false
        interval: 450
        running: ma.containsMouse
        onTriggered: shown = true
        onRunningChanged: if (!running) shown = false
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/dmask/DmField.qml")
cat <<'SNOW_FILE_END_4b7d'
import QtQuick

// One-line text box of the download manager. accepted(text) = Enter pressed; edited(text) = the box lost focus.
Rectangle {
    id: f
    property alias text: ti.text
    property alias input: ti
    property alias validator: ti.validator       // e.g. validator: IntValidator { bottom: 0 } = numbers only
    property string hint: ""
    signal accepted(string t)
    signal edited(string t)
    height: 38
    radius: Theme.rTile
    color: Theme.field
    border.width: 1
    border.color: ti.activeFocus ? Theme.accent : Theme.hairline
    Behavior on border.color { ColorAnimation { duration: Theme.hoverMs } }

    TextInput {
        id: ti
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentText
        font.family: Theme.uiFont
        font.pixelSize: Theme.fsBody
        clip: true
        selectByMouse: true
        onAccepted: f.accepted(text)
        onActiveFocusChanged: if (!activeFocus) f.edited(text)
    }
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: ti.text === ""
        text: f.hint
        color: Theme.muted
        font.family: Theme.uiFont
        font.pixelSize: Theme.fsBody
        elide: Text.ElideRight
        width: parent.width - 24
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/dmask/Theme.qml")
cat <<'SNOW_FILE_END_4b7d'
pragma Singleton
// ⚠ RULE: 'pragma Singleton' hamesha FILE KI PEHLI LINE rahe. Quickshell pehli '{' wali line (comment me bhi) par header khatam maan leta hai,
//   isliye is line se upar kabhi koi '{' wali comment mat likho — warna ye singleton ban hi nahi paata (Sys.xxx = undefined).
// ============================================================================
//  Theme.qml  —  SAARE RANG, SIZE AUR SPEED YAHAN SE AATE HAIN
// ----------------------------------------------------------------------------
//  KYA HAI   : Ye ek "singleton" hai. Matlab poore Quickshell me ek hi copy,
//              aur har QML file isse "Theme.accent", "Theme.text" jaise naam se padh sakti hai.
//  RANG KAHAN SE : ~/.config/snow/state/theme.json  (is file ko theme.sh banata hai).
//              Rang badalna ho to QML nahi, ye command chalao:
//                  bash ~/.config/snow/bin/theme/theme.sh base   '#000000'   (background)
//                  bash ~/.config/snow/bin/theme/theme.sh accent '#d4af37'   (highlight)
//                  bash ~/.config/snow/bin/theme/theme.sh mode   dark|light|toggle
//  SIZE / SPEED : neeche "DESIGN SETTINGS" me. Sab panels same numbers use karte hain,
//              isliye yahan ek number badlo to poora desktop ek saath badal jata hai.
// ============================================================================

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ---------------------------------------------------------------- RANG
    // ":" ke baad wala rang sirf tab chalta hai jab theme.json abhi nahi bani.
    property color bg:        ja.bg        !== "" ? ja.bg        : "#14161b"   // sabse peeche ka rang
    property color surface:   ja.surface   !== "" ? ja.surface   : "#1b1e25"   // card / dabbe ka rang
    property color surfaceHi: ja.surfaceHi !== "" ? ja.surfaceHi : "#272b35"   // thoda ubhara hua rang
    property color text:      ja.text      !== "" ? ja.text      : "#e6e8ee"   // mukhya likhawat
    property color muted:     ja.muted     !== "" ? ja.muted     : "#8b91a1"   // halki likhawat / band icons
    property color accent:    ja.accent    !== "" ? ja.accent    : "#d4af37"   // highlight rang
    property color warn:      ja.warn      !== "" ? ja.warn      : "#e0a84a"   // chetavni
    property color danger:    ja.danger    !== "" ? ja.danger    : "#e0625f"   // galti / shutdown
    property color success:   ja.success   !== "" ? ja.success   : "#5fba7d"   // sab theek / connected
    property color tint:      ja.tint      !== "" ? ja.tint      : "#ffffff"   // dark me safed, light me kala (halke overlay ke liye)

    // accent ke upar likhi cheez ka rang: halka accent ho to kala text, gehra ho to safed
    readonly property color accentText: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.55 ? "#14161b" : "#ffffff"

    // ---------------------------------------------------------------- TAYAR (derived) RANG
    // Ye upar ke rangon se apne aap bante hain. Inhe direct mat badlo.
    readonly property color cardBg:     Qt.alpha(surface, 0.96)   // floating card ka background
    readonly property color railBg:     Qt.alpha(surface, 0.90)   // right wali vertical bar ka background
    readonly property color hairline:   Qt.alpha(tint, 0.09)      // patli border line
    readonly property color hover:      Qt.alpha(tint, 0.07)      // mouse upar aane par
    readonly property color pressed:    Qt.alpha(tint, 0.12)      // dabate waqt
    readonly property color field:      Qt.alpha(tint, 0.06)      // text box ka background
    readonly property color accentSoft: Qt.alpha(accent, 0.16)    // "ON" wali cheez ka halka background

    // ---------------------------------------------------------------- DESIGN SETTINGS (yahan badlo)
    readonly property string uiFont:   "Inter"                    // likhawat ka font
    readonly property string iconFont: "Material Symbols Rounded" // icon wala font (Icons.qml iske code points use karti hai)

    readonly property int rCard: 20     // bade card ke kone kitne gol
    readonly property int rRail: 24     // right wali bar ke kone
    readonly property int rTile: 14     // button / row ke kone
    readonly property int rChip: 10     // chhote chips ke kone
    readonly property int gap:   12     // cheezon ke beech ki jagah
    readonly property int pad:   16     // card ke andar ki jagah (padding)

    readonly property int fsTitle: 15   // card ka title
    readonly property int fsBody:  13   // normal likhawat
    readonly property int fsSmall: 12   // chhoti likhawat
    readonly property int fsTiny:  11   // sabse chhoti likhawat (subtitle, tooltip)

    readonly property int animMs:  160  // khulne / band hone ki speed (milliseconds). Bada number = dheema.
    readonly property int hoverMs: 110  // hover ke rang badalne ki speed

    // ---------------------------------------------------------------- theme.json PADHNE WALA HISSA
    FileView {
        path: Quickshell.env("HOME") + "/.config/snow/state/theme.json"
        watchChanges: true          // file badle to turant naya rang le lo
        printErrors: false
        onFileChanged: reload()

        adapter: JsonAdapter {
            id: ja
            property string bg: ""
            property string surface: ""
            property string surfaceHi: ""
            property string text: ""
            property string muted: ""
            property string accent: ""
            property string warn: ""
            property string danger: ""
            property string success: ""
            property string tint: ""
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/dmask/shell.qml")
cat <<'SNOW_FILE_END_4b7d'
import Quickshell
import Quickshell.Io
import QtQuick

// "Save this download?" window of the browser extension (Snow DM Bridge). Own Quickshell instance: qs -p ~/.config/snow/dmask
// Started by dm-pick-host.sh with: DMA_URL, DMA_NAME, DMA_SIZE (bytes, -1 = unknown), DMA_DIR (start folder), DMA_OUT (file for the answer).
// The answer is ONE line of JSON in DMA_OUT:  {"action":"download|queue|cancel","name":"...","dir":"..."}
ShellRoot {
    id: app
    readonly property string home: Quickshell.env("HOME")
    readonly property string url: Quickshell.env("DMA_URL") ? Quickshell.env("DMA_URL") : ""
    readonly property string startName: Quickshell.env("DMA_NAME") ? Quickshell.env("DMA_NAME") : ""
    readonly property real size: Quickshell.env("DMA_SIZE") ? Number(Quickshell.env("DMA_SIZE")) : -1
    readonly property string startDir: Quickshell.env("DMA_DIR") ? Quickshell.env("DMA_DIR") : ""
    readonly property string outFile: Quickshell.env("DMA_OUT") ? Quickshell.env("DMA_OUT") : ""
    property bool done: false

    function fmtSize(n) {
        if (!(n > 0)) return "size unknown"
        if (n < 1024) return n + " B"
        var u = ["KB", "MB", "GB", "TB"], v = n / 1024, i = 0
        while (v >= 1024 && i < 3) { v /= 1024; i++ }
        return v.toFixed(v >= 100 ? 0 : 1) + " " + u[i]
    }
    function cleanName(s) { return s.replace(/[\/\\]/g, "_").replace(/^\s+|\s+$/g, "") }
    // act = "download" | "queue" | "cancel"
    function finish(act) {
        if (done) return
        done = true
        var j = JSON.stringify({ action: act, name: cleanName(nameField.text), dir: dirField.text.replace(/^\s+|\s+$/g, "") })
        wr.command = ["bash", "-c", "printf '%s' \"$1\" > \"$2\"", "x", j, app.outFile]
        wr.running = true
    }

    Process { id: wr; onExited: Qt.quit() }
    Process {
        id: pick
        stdout: StdioCollector {
            onStreamFinished: { var d = text.trim(); if (d !== "") dirField.text = d }
        }
    }

    FloatingWindow {
        id: win
        visible: true
        title: "Snow DM Save"
        implicitWidth: 560
        implicitHeight: 300
        minimumSize: Qt.size(560, 300)      // same min and max size = Hyprland makes it a FLOATING window
        maximumSize: Qt.size(560, 300)
        color: Theme.bg
        onVisibleChanged: if (!visible) app.finish("cancel")

        Item {
            anchors.fill: parent
            focus: true
            MouseArea { anchors.fill: parent; z: -1; onPressed: win.startSystemMove() }   // empty places drag the window
            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_Escape) { app.finish("cancel"); e.accepted = true }
            }

            // thin strip at the very top: drag it to move the window
            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 12
                DragHandler { target: null; onActiveChanged: if (active) win.startSystemMove() }   // press and drag here = move the window (no Super key needed)
            }
            // ---------- header
            Item {
                id: head
                DragHandler { target: null; onActiveChanged: if (active) win.startSystemMove() }   // press and drag here = move the window (no Super key needed)
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                height: 36
                Text {
                    id: ttl
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Save download"
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fsTitle
                    font.weight: Font.DemiBold
                }
                DmBtn {
                    id: closeBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    cp: 0xe5cd
                    isClose: true
                    tip: "Cancel (Esc)"
                    tipLeft: true
                    onClicked: app.finish("cancel")
                }
                Rectangle {
                    anchors.right: closeBtn.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    height: 24
                    width: sizeTxt.implicitWidth + 20
                    radius: Theme.rChip
                    color: Theme.accentSoft
                    Text {
                        id: sizeTxt
                        anchors.centerIn: parent
                        text: app.fmtSize(app.size)
                        color: Theme.accent
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fsSmall
                        font.weight: Font.DemiBold
                    }
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: head.bottom
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 6
                spacing: 6

                Text {
                    width: parent.width
                    text: app.url
                    elide: Text.ElideMiddle
                    color: Theme.muted
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fsTiny
                }
                Item { width: 1; height: 6 }
                Text { text: "File name"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                DmField {
                    id: nameField
                    width: parent.width
                    height: 40
                    hint: "File name"
                    text: app.startName
                    onAccepted: (t) => app.finish("download")
                    Component.onCompleted: {
                        input.forceActiveFocus()
                        // select the name without the ending, so a small change is quick (the ending stays)
                        var dot = text.lastIndexOf(".")
                        if (dot > 0) input.select(0, dot); else input.selectAll()
                    }
                }
                Item { width: 1; height: 2 }
                Text { text: "Save in"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                Item {
                    width: parent.width
                    height: 40
                    DmField {
                        id: dirField
                        anchors.left: parent.left
                        anchors.right: folderBtn.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        height: 40
                        hint: "/home/you/Downloads"
                        text: app.startDir
                        onAccepted: (t) => app.finish("download")
                    }
                    DmBtn {
                        id: folderBtn
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        size: 40
                        cp: 0xe2c8
                        accent: true
                        tip: "Choose a folder"
                        tipLeft: true
                        onClicked: {
                            pick.command = ["bash", app.home + "/.config/snow/bin/downloads/dm-pickdir.sh", dirField.text]
                            pick.running = true
                        }
                    }
                }
            }

            // ---------- buttons: Cancel | Queue | Download  (one row, fixed widths: nothing can wrap)
            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                spacing: 8
                Rectangle {
                    width: 96; height: 40; radius: 20; antialiasing: true
                    color: cMa.pressed ? Theme.pressed : (cMa.containsMouse ? Theme.hover : "transparent")
                    border.width: 1; border.color: Theme.hairline
                    Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.danger; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold }
                    MouseArea { id: cMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.finish("cancel") }
                }
                Rectangle {
                    width: 96; height: 40; radius: 20; antialiasing: true
                    color: qMa.pressed ? Theme.pressed : (qMa.containsMouse ? Theme.hover : Theme.field)
                    border.width: 1; border.color: Theme.hairline
                    Text { anchors.centerIn: parent; text: "Queue"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold }
                    MouseArea { id: qMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.finish("queue") }
                }
                Rectangle {
                    width: 120; height: 40; radius: 20; antialiasing: true
                    color: dMa.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent
                    opacity: dMa.containsMouse ? 0.92 : 1
                    Text { anchors.centerIn: parent; text: "Download"; color: Theme.accentText; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold }
                    MouseArea { id: dMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.finish("download") }
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/state/dm.json")
cat <<'SNOW_FILE_END_4b7d'
{
  "dir": "",
  "max": 3,
  "conn": 8,
  "limit": "0",
  "ask": true,
  "vq": "best"
}
SNOW_FILE_END_4b7d
;;
"u/.local/share/applications/snow-downloads.desktop")
cat <<'SNOW_FILE_END_4b7d'
[Desktop Entry]
Type=Application
Name=Snow Downloads
GenericName=Download manager
Comment=Download manager (aria2 engine), Super+D
Exec=@HOME@/.config/snow/bin/downloads/dm.sh handle %U
Icon=snow-downloads
Terminal=false
Categories=Network;FileTransfer;
MimeType=x-scheme-handler/magnet;application/x-bittorrent;
# snow-downloads
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm-notify.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-notify.sh : desktop notifications of the Snow download manager (shown by the Snow notification popups).
#   dm-notify.sh EVENT NAME [DETAIL]      EVENT = start | stop | done | error      (used by the video downloads)
#   dm-notify.sh -g EVENT GID NUM PATH    the same for an aria2 download (aria2 calls this through dm-on-*.sh / dm-hook.sh; the name is looked up)
# Every event has its own switch in the settings (gear > "Show a notification when a download ..."), stored in dm.json:
#   nstart (default off)  nstop (default off)  ndone (default on)  nerror (default on)
# Nothing is shown when the switch is off or notify-send is missing. Always exits 0 (a notification must never disturb a download).
STATE="$HOME/.config/snow/state"; JSON="$STATE/dm.json"; RPC="$HOME/.config/snow/bin/downloads/dm-rpc.sh"
name=""; detail=""
if [ "${1:-}" = "-g" ]; then
  ev="${2:-}"; gid="${3:-}"; path="${5:-}"
  [ -n "$gid" ] || exit 0
  info=$(bash "$RPC" raw aria2.tellStatus "$(jq -nc --arg g "$gid" '[$g,["bittorrent","files","errorMessage","followedBy"]]')" 2>/dev/null)
  # the small download of a magnet link (it only fetches the torrent data) and the pause that dm-hook.sh makes while it asks for the folder are not reported
  [ "$ev" = done ] && [ -n "$(jq -r '.result.followedBy[0] // empty' <<<"$info" 2>/dev/null)" ] && exit 0
  if [ "$ev" = stop ]; then
    m="$STATE/dm-asking/$gid"
    if [ -e "$m" ]; then fresh=$(find "$m" -mmin -1 2>/dev/null); rm -f "$m"; [ -n "$fresh" ] && exit 0; fi
  fi
  name=$(jq -r '.result.bittorrent.info.name // empty' <<<"$info" 2>/dev/null)
  [ -n "$name" ] || { [ -n "$path" ] && name=$(basename "$path"); }
  [ -n "$name" ] || name=$(jq -r '.result.files[0].path // empty' <<<"$info" 2>/dev/null | sed 's#.*/##')
  [ -n "$name" ] || name="$gid"
  detail=$(jq -r '.result.errorMessage // empty' <<<"$info" 2>/dev/null | cut -c1-160)
else
  ev="${1:-}"; name="${2:-}"; detail="${3:-}"
fi
case "$ev" in
  start) key=nstart; def=false; title="Download started" ;;
  stop)  key=nstop;  def=false; title="Download stopped" ;;
  done)  key=ndone;  def=true;  title="Download finished" ;;
  error) key=nerror; def=true;  title="Download failed" ;;
  *) exit 0 ;;
esac
on=$(jq -r --arg k "$key" --argjson d "$def" 'if has($k) then .[$k] else $d end' "$JSON" 2>/dev/null)
[ -n "$on" ] || on="$def"
[ "$on" = true ] || exit 0
command -v notify-send >/dev/null 2>&1 || exit 0
body="$name"; [ -n "$detail" ] && body="$name"$'\n'"$detail"
notify-send -a "Snow Downloads" -i snow-downloads "$title" "$body" >/dev/null 2>&1
exit 0
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm-on-complete.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-on-complete.sh GID NUM PATH : aria2 runs this when a download is complete (--on-download-complete, set by dm.sh); it only shows the "done" notification (see dm-notify.sh).
exec bash "$HOME/.config/snow/bin/downloads/dm-notify.sh" -g done "$@"
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm-on-error.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-on-error.sh GID NUM PATH : aria2 runs this when a download error (--on-download-error, set by dm.sh); it only shows the "error" notification (see dm-notify.sh).
exec bash "$HOME/.config/snow/bin/downloads/dm-notify.sh" -g error "$@"
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm-on-pause.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-on-pause.sh GID NUM PATH : aria2 runs this when a download pause (--on-download-pause, set by dm.sh); it only shows the "stop" notification (see dm-notify.sh).
exec bash "$HOME/.config/snow/bin/downloads/dm-notify.sh" -g stop "$@"
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm-video.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-video.sh : video + audio downloads (YouTube and many other sites) for the Snow download manager, done by yt-dlp.
#   dm-video.sh info LINK                         JSON about the video: title, uploader, duration, available heights (and size guesses). Used by the "Save video" window.
#   dm-video.sh add LINK [OPTIONS]                start a download. Options (all optional):
#                  --q best|2160|1440|1080|720|480|360|audio   quality (a number = at most that height; audio = audio only)
#                  --afmt mp3|m4a|opus|flac|wav               audio format (audio only)
#                  --aq best|320|256|192|128|96               audio quality in kbit/s (mp3, m4a, opus; flac and wav are lossless)
#                  --dir FOLDER   --name FILENAME-WITHOUT-ENDING
#                (without options the settings of dm.json are used: vq, afmt, aq)
#   dm-video.sh status                            JSON array of all video jobs, same fields as dm-rpc.sh status items (gid "v:ID")
#   dm-video.sh pause|resume|retry|remove ID      one job (ID = the gid without "v:")
#   dm-video.sh limit ID KB                       speed limit of ONE job in KB/s (0 = the general limit of dm.json); a running job is restarted (it continues)
#   dm-video.sh clear                             forget finished / failed jobs
#   dm-video.sh install | update | selfupdate        put the newest yt-dlp into ~/.local/bin (checked with the official checksum) | update it (yt-dlp -U)
#   dm-video.sh version | selfupdate | autoupdate   version as JSON | "Update now" button (json answer) | the quiet weekly update (setting ytauto)
#   dm-video.sh check                             prints what is missing (yt-dlp, ffmpeg, javascript runtime)
# Jobs live in ~/.config/snow/state/dm-video/ (ID.json, ID.log, ID.rc = exit code, ID.pid, ID.path = final file).
# yt-dlp does its own downloading and joins video + audio with ffmpeg; pause = stop it, resume = start again (it continues the .part files).
CONF="$HOME/.config/snow"; STATE="$CONF/state"; JD="$STATE/dm-video"; DMJ="$STATE/dm.json"; NOTE="$CONF/bin/downloads/dm-notify.sh"
# our own (newest) yt-dlp in ~/.local/bin comes first; the Debian package is old and fails on YouTube
if [ -x "$HOME/.local/bin/yt-dlp" ]; then YT="$HOME/.local/bin/yt-dlp"; else YT="$(command -v yt-dlp 2>/dev/null || true)"; fi
mkdir -p "$JD"
fail() { jq -nc --arg e "$1" '{ok:false,error:$e}'; exit 0; }
cfg() { jq -r --arg k "$1" '.[$k] // empty' "$DMJ" 2>/dev/null; }
dl_dir() {
  local d; d="$(cfg dir)"; [ -n "$d" ] || d="$(xdg-user-dir DOWNLOAD 2>/dev/null)"
  [ -n "$d" ] && [ "$d" != "$HOME" ] || d="$HOME/Downloads"
  d="${d/#\~/$HOME}"; mkdir -p "$d" 2>/dev/null; printf '%s' "$d"
}
is_id() { [[ "${1:-}" =~ ^[0-9]{13}[0-9a-f]{4}$ ]]; }
alive() { local p; p=$(cat "$JD/$1.pid" 2>/dev/null); [ -n "$p" ] && kill -0 "$p" 2>/dev/null; }
stopjob() { local p; p=$(cat "$JD/$1.pid" 2>/dev/null); [ -n "$p" ] && { kill -TERM -- "-$p" 2>/dev/null || kill -TERM "$p" 2>/dev/null; sleep 0.3; kill -KILL -- "-$p" 2>/dev/null; }; rm -f "$JD/$1.pid"; }

# YouTube needs a javascript runtime: deno is used by yt-dlp itself, node has to be switched on (only when this yt-dlp knows the option:
# an old one stops with "no such option", code 2). Prints the option or nothing.
js_opts() { if ! command -v deno >/dev/null 2>&1 && command -v node >/dev/null 2>&1 && "$YT" --help 2>/dev/null | grep -q -- '--js-runtimes'; then printf '%s\n' --js-runtimes node; fi; }

# the yt-dlp format arguments of one job -> prints one argument per line
fmt_args() {   # quality audio-format audio-quality
  local q=$1 af=$2 aq=$3
  case "$q" in
    audio)
      printf '%s\n' -f 'ba/b' -x --audio-format "$af"
      case "$af" in mp3|m4a|opus) if [ "$aq" = best ] || [ -z "$aq" ]; then printf '%s\n' --audio-quality 0; else printf '%s\n' --audio-quality "${aq}K"; fi ;; esac ;;
    best|"") printf '%s\n' -f 'bv*+ba/b' --merge-output-format 'mp4/mkv' ;;
    *) printf '%s\n' -f "bv*[height<=$q]+ba/b[height<=$q]/bv*+ba/b" --merge-output-format 'mp4/mkv' ;;
  esac
}

# a limit from dm.json ("500K", "2M", "0", an old plain number = bytes) in KB/s
to_kb() { case "$1" in *[Kk]) echo "${1%[Kk]}" ;; *[Mm]) echo $(( ${1%[Mm]} * 1024 )) ;; ''|0|*[!0-9]*) echo 0 ;; *) echo $(( ($1 + 1023) / 1024 )) ;; esac; }

start_job() {   # ID
  local id=$1 url q af aq nm dnm dir lim js=() args=() oname
  url=$(jq -r '.url' "$JD/$id.json"); q=$(jq -r '.q' "$JD/$id.json"); dir=$(jq -r '.dir' "$JD/$id.json")
  af=$(jq -r '.afmt // "mp3"' "$JD/$id.json"); aq=$(jq -r '.aq // "best"' "$JD/$id.json"); nm=$(jq -r '.name // ""' "$JD/$id.json")
  mapfile -t args < <(fmt_args "$q" "$af" "$aq")
  mapfile -t js < <(js_opts)
  # speed limit: the one of this job, else the general one (aria2 does not know about these downloads)
  lim=$(jq -r '.limit // 0' "$JD/$id.json"); case "$lim" in ''|*[!0-9]*) lim=0 ;; esac
  [ "$lim" -gt 0 ] || lim=$(to_kb "$(cfg limit)")
  [ "$lim" -gt 0 ] 2>/dev/null && js+=(--limit-rate "${lim}K")
  # own file name (without the ending): "/" is not allowed, "%" has a meaning for yt-dlp
  dnm="$nm"   # the name as the user typed it (for the notification)
  if [ -n "$nm" ]; then nm="${nm//\//_}"; nm="${nm//%/%%}"; oname="$nm.%(ext)s"; else oname="%(title).150B [%(id)s].%(ext)s"; fi
  rm -f "$JD/$id.rc" "$JD/$id.pid"
  jq '.state="running"' "$JD/$id.json" > "$JD/$id.json.new" && mv -f "$JD/$id.json.new" "$JD/$id.json"
  [ -f "$NOTE" ] && bash "$NOTE" start "${dnm:-$url}" >/dev/null 2>&1 &
  setsid nohup bash -c '
    yt="$1"; id="$2"; jd="$3"; dir="$4"; url="$5"; oname="$6"; nf="$7"; shift 7
    "$yt" --newline --no-playlist --no-colors --ignore-config "$@" \
      --progress-template "download:SNOWP|%(progress.downloaded_bytes)s|%(progress.total_bytes)s|%(progress.total_bytes_estimate)s|%(progress.speed)s|%(progress.eta)s|%(info.title)s|%(progress.filename)s" \
      --print-to-file "after_move:%(filepath)s" "$jd/$id.path" \
      -P "$dir" -o "$oname" -- "$url" >> "$jd/$id.log" 2>&1
    rc=$?; echo "$rc" > "$jd/$id.rc"
    # notification (only reached when yt-dlp ended by itself: pause / remove kill this whole group before)
    fn=$(basename "$(head -n 1 "$jd/$id.path" 2>/dev/null)" 2>/dev/null); { [ -n "$fn" ] && [ "$fn" != . ]; } || fn="$url"
    if [ -f "$nf" ]; then
      if [ "$rc" = 0 ]; then bash "$nf" done "$fn" >/dev/null 2>&1
      else e=$(grep -a "^ERROR\|: error: " "$jd/$id.log" 2>/dev/null | tail -n 1 | cut -c1-160); bash "$nf" error "$fn" "${e:-yt-dlp stopped (code $rc)}" >/dev/null 2>&1; fi
    fi
  ' dm-video "$YT" "$id" "$JD" "$dir" "$url" "$oname" "$NOTE" "${js[@]}" "${args[@]}" >/dev/null 2>&1 < /dev/null &
  echo $! > "$JD/$id.pid"
}

case "${1:-}" in
  info)
    url="${2:-}"; case "$url" in http://*|https://*) ;; *) fail "that is not a web link" ;; esac
    [ -n "$YT" ] || fail "yt-dlp is not installed: run  bash ~/.config/snow/bin/downloads/dm-video.sh install"
    mapfile -t js < <(js_opts)
    raw=$(timeout 90 "$YT" -J --no-playlist --no-warnings --ignore-config "${js[@]}" -- "$url" 2>"$JD/info.err") || {
      e=$(grep -a '^ERROR\|: error: ' "$JD/info.err" | tail -n 1 | cut -c1-220); fail "${e:-could not read the video information}"; }
    jq -c '
      (.formats // []) as $f
      | ([$f[] | select(.vcodec != null and .vcodec != "none" and .height != null)] ) as $v
      | ([$f[] | select(.acodec != null and .acodec != "none" and (.vcodec == null or .vcodec == "none"))] | map(.filesize // .filesize_approx // 0) | max // 0) as $asz
      | {ok:true, title:(.title // ""), uploader:(.uploader // .channel // ""), duration:(.duration // 0), live:(.is_live // false),
         heights:([$v[].height] | unique | reverse),
         sizes:([$v | group_by(.height)[] | {key:(.[0].height | tostring), value:((map(.filesize // .filesize_approx // 0) | max) + $asz)}] | map(select(.value > 0)) | from_entries),
         hasVideo:(($v | length) > 0)}' <<<"$raw" 2>/dev/null || fail "could not read the video information" ;;
  add)
    url="${2:-}"; shift 2 2>/dev/null; q=""; af=""; aq=""; dir=""; nm=""
    if [ "$#" -gt 0 ] && [[ "$1" != --* ]]; then q="$1"; shift; fi      # old form: add LINK QUALITY
    while [ "$#" -gt 0 ]; do case "$1" in --q) q="${2:-}"; shift 2 ;; --afmt) af="${2:-}"; shift 2 ;; --aq) aq="${2:-}"; shift 2 ;; --dir) dir="${2:-}"; shift 2 ;; --name) nm="${2:-}"; shift 2 ;; *) shift ;; esac; done
    case "$url" in http://*|https://*) ;; *) fail "that is not a web link" ;; esac
    [ -n "$YT" ] || fail "yt-dlp is not installed: run  bash ~/.config/snow/bin/downloads/dm-video.sh install"
    [ -n "$q" ] || q=$(cfg vq); case "$q" in best|audio|[0-9][0-9][0-9]|[0-9][0-9][0-9][0-9]) ;; *) q=best ;; esac
    [ -n "$af" ] || af=$(cfg afmt); case "$af" in mp3|m4a|opus|flac|wav) ;; *) af=mp3 ;; esac
    [ -n "$aq" ] || aq=$(cfg aq); case "$aq" in best|320|256|192|128|96) ;; *) aq=best ;; esac
    if [ -n "$dir" ]; then dir="${dir/#\~/$HOME}"; mkdir -p "$dir" 2>/dev/null; [ -d "$dir" ] && [ -w "$dir" ] || fail "cannot write into $dir"; else dir=$(dl_dir); fi
    id="$(date +%s%3N)$(od -An -tx1 -N2 /dev/urandom | tr -d ' \n')"
    jq -nc --arg u "$url" --arg q "$q" --arg d "$dir" --arg af "$af" --arg aq "$aq" --arg n "$nm" '{url:$u,q:$q,dir:$d,afmt:$af,aq:$aq,name:$n,state:"running"}' > "$JD/$id.json"
    : > "$JD/$id.log"
    start_job "$id"
    jq -nc --arg g "v:$id" '{ok:true,gid:$g}' ;;
  status)
    out="[]"
    for f in "$JD"/*.json; do
      [ -e "$f" ] || continue
      id=$(basename "$f" .json); is_id "$id" || continue
      rc=$(cat "$JD/$id.rc" 2>/dev/null)
      if [ -n "$rc" ]; then [ "$rc" = 0 ] && s=complete || s=error
      elif alive "$id"; then s=active
      else s=paused; fi     # stopped by the user, or the computer was switched off in between
      line=$(tail -n 60 "$JD/$id.log" 2>/dev/null | grep -a '^SNOWP|' | tail -n 1)
      err=""; [ "$s" = error ] && err=$(grep -a '^ERROR\|: error: ' "$JD/$id.log" 2>/dev/null | tail -n 1 | cut -c1-200)
      [ "$s" = error ] && [ -z "$err" ] && err="yt-dlp stopped (code $rc)"
      path=$(head -n 1 "$JD/$id.path" 2>/dev/null)
      item=$(jq -nc --arg g "v:$id" --arg s "$s" --arg p "$line" --arg err "$err" --arg path "$path" --slurpfile j "$f" '
        ($p | split("|")) as $a
        | def n($i): (($a[$i] // "NA") | tonumber? // 0);
        {gid:$g, status:$s, dir:$j[0].dir, uri:$j[0].url, err:$err,
         total:(if n(2) > 0 then n(2) else n(3) end), done:n(1), speed:(if $s == "active" then n(4) else 0 end),
         name:(if $path != "" then ($path | split("/") | last) elif ($a[6] // "") != "" and $a[6] != "NA" then $a[6] else "" end),
         path:(if $path != "" then $path else "" end), limit:($j[0].limit // 0)}
        | if .total > 0 and .done > .total then .total = .done else . end
        | if .status == "complete" then (if .total == 0 then (.total = 1 | .done = 1) else (.done = .total) end) else . end')
      out=$(jq -c --argjson i "$item" '. + [$i]' <<<"$out")
    done
    printf '%s\n' "$out" ;;
  pause)   is_id "${2:-}" || fail "bad id"; stopjob "$2"; [ -f "$NOTE" ] && bash "$NOTE" stop "$(jq -r 'if (.name // "") != "" then .name else .url end' "$JD/$2.json" 2>/dev/null)" >/dev/null 2>&1 &
            jq '.state="paused"' "$JD/$2.json" > "$JD/$2.json.new" && mv -f "$JD/$2.json.new" "$JD/$2.json"; echo '{"ok":true}' ;;
  resume|retry)
    is_id "${2:-}" || fail "bad id"; [ -f "$JD/$2.json" ] || fail "unknown video job"
    [ -n "$YT" ] || fail "yt-dlp is not installed"
    alive "$2" || start_job "$2"; echo '{"ok":true}' ;;
  limit)
    is_id "${2:-}" || fail "bad id"; [ -f "$JD/$2.json" ] || fail "unknown video job"
    case "${3:-}" in ''|*[!0-9]*) fail "a whole number: KB per second (0 = general limit)" ;; esac
    jq --argjson l "$((10#$3))" '.limit=$l' "$JD/$2.json" > "$JD/$2.json.new" && mv -f "$JD/$2.json.new" "$JD/$2.json"
    if alive "$2"; then stopjob "$2"; start_job "$2"; fi      # yt-dlp continues the .part files with the new limit
    echo '{"ok":true}' ;;
  remove)  is_id "${2:-}" || fail "bad id"; stopjob "$2"; rm -f "$JD/$2".{json,log,rc,pid,path,json.new}; echo '{"ok":true}' ;;
  clear)
    for f in "$JD"/*.rc; do [ -e "$f" ] || continue; id=$(basename "$f" .rc); rm -f "$JD/$id".{json,log,rc,pid,path}; done
    echo '{"ok":true}' ;;
  install)
    # the self-contained build (yt-dlp_linux: no python needed), checked with the official SHA2-256SUMS; an older file is kept as yt-dlp.bak
    BASE="https://github.com/yt-dlp/yt-dlp/releases/latest/download"; DEST="$HOME/.local/bin"; TMP=$(mktemp -d) || exit 1
    echo "downloading yt-dlp (about 35 MB) ..."
    curl -fL --retry 6 --retry-delay 5 --retry-all-errors -o "$TMP/yt-dlp_linux" "$BASE/yt-dlp_linux" || { rm -rf "$TMP"; echo "[PROBLEM] download failed (internet / GitHub?). Nothing was changed."; exit 1; }
    if curl -fL --retry 2 --retry-delay 3 --retry-all-errors -o "$TMP/SHA2-256SUMS" "$BASE/SHA2-256SUMS" 2>/dev/null && [ -s "$TMP/SHA2-256SUMS" ]; then
      want=$(grep -E '[[:space:]]\*?yt-dlp_linux$' "$TMP/SHA2-256SUMS" | awk '{print $1}' | head -n1); have=$(sha256sum "$TMP/yt-dlp_linux" | awk '{print $1}')
      { [ -n "$want" ] && [ "$want" = "$have" ]; } || { rm -rf "$TMP"; echo "[PROBLEM] the checksum does NOT match (file damaged). Not installed."; exit 1; }
      echo "checksum OK"
    else echo "checksum list not available right now: continuing (the file came from the official GitHub release over HTTPS)"; fi
    chmod +x "$TMP/yt-dlp_linux"
    v=$("$TMP/yt-dlp_linux" --version 2>&1) || { rm -rf "$TMP"; echo "[PROBLEM] the downloaded yt-dlp does not run: $v"; exit 1; }
    mkdir -p "$DEST"; [ -f "$DEST/yt-dlp" ] && mv -f "$DEST/yt-dlp" "$DEST/yt-dlp.bak"
    cp "$TMP/yt-dlp_linux" "$DEST/yt-dlp" && chmod +x "$DEST/yt-dlp" || { rm -rf "$TMP"; echo "[PROBLEM] could not copy into $DEST"; exit 1; }
    rm -rf "$TMP"; echo "yt-dlp $v installed in ~/.local/bin" ;;
  update)
    [ -n "$YT" ] || { echo "[PROBLEM] yt-dlp is not installed"; exit 1; }
    "$YT" -U ;;
  version)
    [ -n "$YT" ] || fail "yt-dlp is not installed: press Update"
    own=false; [ "$YT" = "$HOME/.local/bin/yt-dlp" ] && own=true
    jq -nc --arg v "$("$YT" --version 2>/dev/null)" --arg p "$YT" --argjson o "$own" '{ok:true,version:$v,path:$p,own:$o}' ;;
  selfupdate)
    # the button "Update now" of the settings: prints ONE json line {ok, msg, version, changed}
    OWN="$HOME/.local/bin/yt-dlp"; old=""; [ -x "$OWN" ] && old=$("$OWN" --version 2>/dev/null)
    ok=false; log=""
    if [ -x "$OWN" ]; then
      cp -f "$OWN" "$OWN.bak" 2>/dev/null
      log=$(timeout 240 "$OWN" -U 2>&1) && ok=true
    fi
    if [ "$ok" != true ]; then   # no own copy yet, or the self-update did not work (old build, no write permission ...): the checksum way
      log=$(timeout 300 bash "${BASH_SOURCE[0]}" install 2>&1) && ok=true || ok=false
    fi
    new=""; [ -x "$OWN" ] && new=$("$OWN" --version 2>/dev/null)
    if [ "$ok" != true ] || [ -z "$new" ]; then
      e=$(printf '%s\n' "$log" | grep -a "PROBLEM\|ERROR\|error" | tail -n 1 | cut -c1-160); fail "${e:-no internet, or GitHub is not reachable. Nothing was changed.}"
    fi
    if [ "$new" != "$old" ]; then jq -nc --arg v "$new" --arg o "$old" '{ok:true,changed:true,version:$v,msg:(if $o=="" then "yt-dlp "+$v+" installed" else "Updated yt-dlp: "+$o+" -> "+$v end)}'
    else jq -nc --arg v "$new" '{ok:true,changed:false,version:$v,msg:("yt-dlp is already the newest ("+$v+")")}'; fi ;;
  autoupdate)
    # called quietly when the engine / the window starts: once a week, only when we have our own copy and the setting "ytauto" is on (default on)
    [ "$(jq -r 'if has("ytauto") then .ytauto else true end' "$DMJ" 2>/dev/null)" = true ] || exit 0
    [ -x "$HOME/.local/bin/yt-dlp" ] || exit 0
    ok="$STATE/yt-update-ok"; try="$STATE/yt-update-try"
    [ -f "$ok" ] && [ -n "$(find "$ok" -mtime -7 2>/dev/null)" ] && exit 0
    [ -f "$try" ] && [ -n "$(find "$try" -mmin -360 2>/dev/null)" ] && exit 0
    : > "$try"; mkdir -p "$HOME/.cache/snow"
    r=$(bash "${BASH_SOURCE[0]}" selfupdate 2>>"$HOME/.cache/snow/yt-update.log"); echo "$(date '+%F %T') $r" >> "$HOME/.cache/snow/yt-update.log"
    [ "$(jq -r '.ok // false' <<<"$r" 2>/dev/null)" = true ] && : > "$ok"; exit 0 ;;
  check)
    [ -n "$YT" ] && echo "yt-dlp: ok ($("$YT" --version 2>/dev/null)) at $YT" || echo "yt-dlp: MISSING  (bash $0 install)"
    [ -n "$YT" ] && [ "$YT" != "$HOME/.local/bin/yt-dlp" ] && echo "  note: this is the Debian package (old). Run: bash $0 install   (puts the newest one in ~/.local/bin, which is used first)"
    command -v ffmpeg >/dev/null 2>&1 && echo "ffmpeg: ok" || echo "ffmpeg: MISSING  (sudo apt install ffmpeg)"
    if command -v deno >/dev/null 2>&1; then echo "javascript runtime: deno"; elif command -v node >/dev/null 2>&1; then echo "javascript runtime: node"; else echo "javascript runtime: MISSING  (sudo apt install nodejs)"; fi ;;
  *) echo "usage: dm-video.sh info LINK | add LINK [--q Q --afmt F --aq K --dir D --name N] | status | pause|resume|retry|remove ID | clear | install | update | version | selfupdate | autoupdate | check"; exit 2 ;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/downloads/dm-vsave.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# dm-vsave.sh URL : opens the Snow "Save video" window (quality / audio format / audio quality / name / folder) for ONE video link,
#   then starts the download with dm-video.sh. Prints ONE line of JSON: {"ok":true,"action":"download|cancel",...} or {"ok":false,"error":"..."}
#   Used by the link box of the download manager window. The last choices are remembered in dm.json (vmode, vq, afmt, aq, lastdir).
STATE="$HOME/.config/snow/state"; CONF="$HOME/.config/snow/bin/downloads"; DMJ="$STATE/dm.json"
url="${1:-}"
fail() { jq -nc --arg e "$1" '{ok:false,error:$e}'; exit 0; }
case "$url" in http://*|https://*) ;; *) fail "not a web link" ;; esac
command -v qs >/dev/null 2>&1 || command -v quickshell >/dev/null 2>&1 || fail "quickshell is not installed"
{ [ -x "$HOME/.local/bin/yt-dlp" ] || command -v yt-dlp >/dev/null 2>&1; } || fail "yt-dlp is not installed: run  bash ~/.config/snow/bin/downloads/dm-video.sh install"
mkdir -p "$STATE"; [ -s "$DMJ" ] || echo '{}' > "$DMJ"
exec 9>"$STATE/dm-popup.lock"; flock 9      # one window at a time
cfg() { jq -r --arg k "$1" '.[$k] // empty' "$DMJ" 2>/dev/null; }
start=$(cfg lastdir); [ -d "$start" ] || start=$(cfg dir); [ -d "$start" ] || start=$(xdg-user-dir DOWNLOAD 2>/dev/null); [ -d "$start" ] || start="$HOME/Downloads"; [ -d "$start" ] || start="$HOME"
out=$(mktemp "${TMPDIR:-/tmp}/snow-dm-vsave.XXXXXX")
BIN=$(command -v qs || command -v quickshell); mkdir -p "$HOME/.cache/snow"
DMV_URL="$url" DMV_DIR="$start" DMV_OUT="$out" DMV_MODE="$(cfg vmode)" DMV_Q="$(cfg vq)" DMV_AFMT="$(cfg afmt)" DMV_AQ="$(cfg aq)" \
  "$BIN" -p "$HOME/.config/snow/dmvid" >"$HOME/.cache/snow/dm-vsave.log" 2>&1 </dev/null
ans=$(head -c 4096 "$out" 2>/dev/null); rm -f -- "$out"
[ "$(jq -r '.action // "cancel"' <<<"$ans" 2>/dev/null)" = download ] || { jq -nc '{ok:true,action:"cancel"}'; exit 0; }
mode=$(jq -r '.mode // "video"' <<<"$ans"); q=$(jq -r '.q // "best"' <<<"$ans"); af=$(jq -r '.afmt // "mp3"' <<<"$ans"); aq=$(jq -r '.aq // "best"' <<<"$ans")
nm=$(jq -r '.name // ""' <<<"$ans"); dir=$(jq -r '.dir // ""' <<<"$ans"); dir="${dir/#\~/$HOME}"; [ -n "$dir" ] || dir="$start"
res=$(bash "$CONF/dm-video.sh" add "$url" --q "$q" --afmt "$af" --aq "$aq" --dir "$dir" --name "$nm")
if [ "$(jq -r '.ok // false' <<<"$res" 2>/dev/null)" = true ]; then
  # remember the choices for the next time (audio choices are kept apart from the video quality)
  jq --arg m "$mode" --arg q "$q" --arg af "$af" --arg aq "$aq" --arg d "$dir" \
     '.vmode=$m | (if $q != "audio" then .vq=$q else . end) | .afmt=$af | .aq=$aq | .lastdir=$d' "$DMJ" > "$DMJ.new" && mv -f "$DMJ.new" "$DMJ"
  jq -nc --arg a download --arg d "$dir" --arg m "$mode" '{ok:true,action:$a,dir:$d,mode:$m}'
else
  fail "$(jq -r '.error // "could not start the video download"' <<<"$res" 2>/dev/null)"
fi
SNOW_FILE_END_4b7d
;;
"u/.config/snow/dmvid/DmBtn.qml")
cat <<'SNOW_FILE_END_4b7d'
import QtQuick

// Small round icon button of the download manager (icon = Material Symbols code point, tip = text shown on hover).
Rectangle {
    id: b
    property int cp: 0xe5cd
    property string tip: ""
    property bool danger: false
    property bool accent: false
    property bool tipLeft: false
    property bool isClose: false     // the X of a window: red background on hover
    property int size: 32
    signal clicked()
    width: size
    height: size
    radius: size / 2
    antialiasing: true
    color: b.isClose && ma.containsMouse ? (ma.pressed ? Qt.darker(Theme.danger, 1.2) : Theme.danger) : (ma.pressed ? Theme.pressed : (ma.containsMouse ? Theme.hover : (accent ? Theme.accentSoft : "transparent")))
    Behavior on color { ColorAnimation { duration: Theme.hoverMs } }

    Text {
        anchors.centerIn: parent
        text: String.fromCodePoint(b.cp)
        font.family: Theme.iconFont
        renderType: Text.NativeRendering
        font.pixelSize: Math.round(b.size * 0.56)
        color: b.isClose && ma.containsMouse ? "#ffffff" : (b.danger ? Theme.danger : (b.accent ? Theme.accent : Theme.text))
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
    Rectangle {
        id: tipBox
        visible: b.tip !== "" && ma.containsMouse && tipTimer.shown
        z: 100
        height: tipText.implicitHeight + 8
        width: tipText.implicitWidth + 16
        radius: Theme.rChip
        color: Theme.surfaceHi
        border.width: 1
        border.color: Theme.hairline
        x: b.tipLeft ? -width - 6 : (b.width - width) / 2
        y: b.tipLeft ? (b.height - height) / 2 : -height - 6
        Text {
            id: tipText
            anchors.centerIn: parent
            text: b.tip
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fsTiny
        }
    }
    Timer {
        id: tipTimer
        property bool shown: false
        interval: 450
        running: ma.containsMouse
        onTriggered: shown = true
        onRunningChanged: if (!running) shown = false
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/dmvid/DmField.qml")
cat <<'SNOW_FILE_END_4b7d'
import QtQuick

// One-line text box of the download manager. accepted(text) = Enter pressed; edited(text) = the box lost focus.
Rectangle {
    id: f
    property alias text: ti.text
    property alias input: ti
    property alias validator: ti.validator       // e.g. validator: IntValidator { bottom: 0 } = numbers only
    property string hint: ""
    signal accepted(string t)
    signal edited(string t)
    height: 38
    radius: Theme.rTile
    color: Theme.field
    border.width: 1
    border.color: ti.activeFocus ? Theme.accent : Theme.hairline
    Behavior on border.color { ColorAnimation { duration: Theme.hoverMs } }

    TextInput {
        id: ti
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentText
        font.family: Theme.uiFont
        font.pixelSize: Theme.fsBody
        clip: true
        selectByMouse: true
        onAccepted: f.accepted(text)
        onActiveFocusChanged: if (!activeFocus) f.edited(text)
    }
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: ti.text === ""
        text: f.hint
        color: Theme.muted
        font.family: Theme.uiFont
        font.pixelSize: Theme.fsBody
        elide: Text.ElideRight
        width: parent.width - 24
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/dmvid/Theme.qml")
cat <<'SNOW_FILE_END_4b7d'
pragma Singleton
// ⚠ RULE: 'pragma Singleton' hamesha FILE KI PEHLI LINE rahe. Quickshell pehli '{' wali line (comment me bhi) par header khatam maan leta hai,
//   isliye is line se upar kabhi koi '{' wali comment mat likho — warna ye singleton ban hi nahi paata (Sys.xxx = undefined).
// ============================================================================
//  Theme.qml  —  SAARE RANG, SIZE AUR SPEED YAHAN SE AATE HAIN
// ----------------------------------------------------------------------------
//  KYA HAI   : Ye ek "singleton" hai. Matlab poore Quickshell me ek hi copy,
//              aur har QML file isse "Theme.accent", "Theme.text" jaise naam se padh sakti hai.
//  RANG KAHAN SE : ~/.config/snow/state/theme.json  (is file ko theme.sh banata hai).
//              Rang badalna ho to QML nahi, ye command chalao:
//                  bash ~/.config/snow/bin/theme/theme.sh base   '#000000'   (background)
//                  bash ~/.config/snow/bin/theme/theme.sh accent '#d4af37'   (highlight)
//                  bash ~/.config/snow/bin/theme/theme.sh mode   dark|light|toggle
//  SIZE / SPEED : neeche "DESIGN SETTINGS" me. Sab panels same numbers use karte hain,
//              isliye yahan ek number badlo to poora desktop ek saath badal jata hai.
// ============================================================================

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ---------------------------------------------------------------- RANG
    // ":" ke baad wala rang sirf tab chalta hai jab theme.json abhi nahi bani.
    property color bg:        ja.bg        !== "" ? ja.bg        : "#14161b"   // sabse peeche ka rang
    property color surface:   ja.surface   !== "" ? ja.surface   : "#1b1e25"   // card / dabbe ka rang
    property color surfaceHi: ja.surfaceHi !== "" ? ja.surfaceHi : "#272b35"   // thoda ubhara hua rang
    property color text:      ja.text      !== "" ? ja.text      : "#e6e8ee"   // mukhya likhawat
    property color muted:     ja.muted     !== "" ? ja.muted     : "#8b91a1"   // halki likhawat / band icons
    property color accent:    ja.accent    !== "" ? ja.accent    : "#d4af37"   // highlight rang
    property color warn:      ja.warn      !== "" ? ja.warn      : "#e0a84a"   // chetavni
    property color danger:    ja.danger    !== "" ? ja.danger    : "#e0625f"   // galti / shutdown
    property color success:   ja.success   !== "" ? ja.success   : "#5fba7d"   // sab theek / connected
    property color tint:      ja.tint      !== "" ? ja.tint      : "#ffffff"   // dark me safed, light me kala (halke overlay ke liye)

    // accent ke upar likhi cheez ka rang: halka accent ho to kala text, gehra ho to safed
    readonly property color accentText: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.55 ? "#14161b" : "#ffffff"

    // ---------------------------------------------------------------- TAYAR (derived) RANG
    // Ye upar ke rangon se apne aap bante hain. Inhe direct mat badlo.
    readonly property color cardBg:     Qt.alpha(surface, 0.96)   // floating card ka background
    readonly property color railBg:     Qt.alpha(surface, 0.90)   // right wali vertical bar ka background
    readonly property color hairline:   Qt.alpha(tint, 0.09)      // patli border line
    readonly property color hover:      Qt.alpha(tint, 0.07)      // mouse upar aane par
    readonly property color pressed:    Qt.alpha(tint, 0.12)      // dabate waqt
    readonly property color field:      Qt.alpha(tint, 0.06)      // text box ka background
    readonly property color accentSoft: Qt.alpha(accent, 0.16)    // "ON" wali cheez ka halka background

    // ---------------------------------------------------------------- DESIGN SETTINGS (yahan badlo)
    readonly property string uiFont:   "Inter"                    // likhawat ka font
    readonly property string iconFont: "Material Symbols Rounded" // icon wala font (Icons.qml iske code points use karti hai)

    readonly property int rCard: 20     // bade card ke kone kitne gol
    readonly property int rRail: 24     // right wali bar ke kone
    readonly property int rTile: 14     // button / row ke kone
    readonly property int rChip: 10     // chhote chips ke kone
    readonly property int gap:   12     // cheezon ke beech ki jagah
    readonly property int pad:   16     // card ke andar ki jagah (padding)

    readonly property int fsTitle: 15   // card ka title
    readonly property int fsBody:  13   // normal likhawat
    readonly property int fsSmall: 12   // chhoti likhawat
    readonly property int fsTiny:  11   // sabse chhoti likhawat (subtitle, tooltip)

    readonly property int animMs:  160  // khulne / band hone ki speed (milliseconds). Bada number = dheema.
    readonly property int hoverMs: 110  // hover ke rang badalne ki speed

    // ---------------------------------------------------------------- theme.json PADHNE WALA HISSA
    FileView {
        path: Quickshell.env("HOME") + "/.config/snow/state/theme.json"
        watchChanges: true          // file badle to turant naya rang le lo
        printErrors: false
        onFileChanged: reload()

        adapter: JsonAdapter {
            id: ja
            property string bg: ""
            property string surface: ""
            property string surfaceHi: ""
            property string text: ""
            property string muted: ""
            property string accent: ""
            property string warn: ""
            property string danger: ""
            property string success: ""
            property string tint: ""
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/dmvid/shell.qml")
cat <<'SNOW_FILE_END_4b7d'
import Quickshell
import Quickshell.Io
import QtQuick

// "Save video" window of the Snow download manager (video links: YouTube ...). Own Quickshell instance: qs -p ~/.config/snow/dmvid
// Started by dm-vsave.sh with: DMV_URL, DMV_DIR (start folder), DMV_OUT (file for the answer), DMV_MODE (video|audio), DMV_Q, DMV_AFMT, DMV_AQ (last choices).
// The video information (title, available qualities) is read by dm-video.sh info while the window is already open.
// The answer is ONE line of JSON in DMV_OUT:  {"action":"download|cancel","mode":"video|audio","q":"best|1080|...","afmt":"mp3","aq":"best|192","name":"","dir":"..."}
ShellRoot {
    id: app
    readonly property string home: Quickshell.env("HOME")
    readonly property string url: Quickshell.env("DMV_URL") ? Quickshell.env("DMV_URL") : ""
    readonly property string startDir: Quickshell.env("DMV_DIR") ? Quickshell.env("DMV_DIR") : ""
    readonly property string outFile: Quickshell.env("DMV_OUT") ? Quickshell.env("DMV_OUT") : ""
    readonly property string videoSh: home + "/.config/snow/bin/downloads/dm-video.sh"

    property bool done: false
    property string mode: Quickshell.env("DMV_MODE") === "audio" ? "audio" : "video"
    property string vq: Quickshell.env("DMV_Q") ? Quickshell.env("DMV_Q") : "best"
    property string afmt: Quickshell.env("DMV_AFMT") ? Quickshell.env("DMV_AFMT") : "mp3"
    property string aq: Quickshell.env("DMV_AQ") ? Quickshell.env("DMV_AQ") : "best"
    property string phase: "loading"          // loading | ready | failed
    property string errText: ""
    property string vTitle: ""
    property string vInfo: ""
    property var heights: []
    property var sizes: ({})
    property string openDrop: ""              // id of the dropdown that is open ("" = none)
    readonly property bool lossless: afmt === "flac" || afmt === "wav"

    function fmtSize(n) {
        if (!(n > 0)) return ""
        var u = ["KB", "MB", "GB", "TB"], v = n / 1024, i = 0
        while (v >= 1024 && i < 3) { v /= 1024; i++ }
        return " · ~" + v.toFixed(v >= 100 ? 0 : 1) + " " + u[i]
    }
    function fmtDur(s) {
        s = Math.round(s)
        if (!(s > 0)) return ""
        var h = Math.floor(s / 3600), m = Math.floor(s / 60) % 60, x = s % 60
        return (h > 0 ? h + ":" + (m < 10 ? "0" : "") : "") + m + ":" + (x < 10 ? "0" : "") + x
    }
    function heightLabel(h) {
        return h + "p" + (h >= 4320 ? " (8K)" : h >= 2160 ? " (4K)" : h >= 1440 ? " (2K)" : h >= 1080 ? " (Full HD)" : h >= 720 ? " (HD)" : "")
    }
    // options of the quality dropdown, built from what the video really has
    function videoOptions() {
        var o = [{ v: "best", t: "Best available" + (heights.length > 0 ? " (" + heights[0] + "p)" : "") + (heights.length > 0 ? fmtSize(sizes[String(heights[0])]) : "") }]
        for (var i = 0; i < heights.length; i++) o.push({ v: String(heights[i]), t: heightLabel(heights[i]) + fmtSize(sizes[String(heights[i])]) })
        return o
    }
    function cleanName(s) { return s.replace(/[\/\\]/g, "_").replace(/^\s+|\s+$/g, "") }
    function finish(act) {
        if (done) return
        done = true
        var nm = cleanName(nameField.text)
        if (nm === cleanName(vTitle)) nm = ""           // the title was not changed: yt-dlp makes the name itself
        var q = mode === "audio" ? "audio" : vq
        var j = JSON.stringify({ action: act, mode: mode, q: q, afmt: afmt, aq: aq, name: nm, dir: dirField.text.replace(/^\s+|\s+$/g, "") })
        wr.command = ["bash", "-c", "printf '%s' \"$1\" > \"$2\"", "x", j, app.outFile]
        wr.running = true
    }

    Process { id: wr; onExited: Qt.quit() }
    Process {
        id: pick
        stdout: StdioCollector {
            onStreamFinished: { var d = text.trim(); if (d !== "") dirField.text = d }
        }
    }
    Process {
        id: info
        command: ["bash", app.videoSh, "info", app.url]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var r = null
                try { r = JSON.parse(text) } catch (e) { r = null }
                if (r && r.ok) {
                    app.vTitle = r.title
                    app.heights = r.heights
                    app.sizes = r.sizes
                    var d = app.fmtDur(r.duration)
                    app.vInfo = (r.uploader !== "" ? r.uploader : "") + (r.uploader !== "" && d !== "" ? "  ·  " : "") + d + (r.live ? "  ·  LIVE" : "")
                    if (!r.hasVideo) app.mode = "audio"
                    // the last choice is kept when this video has it, else Best
                    if (app.vq !== "best" && r.heights.indexOf(Number(app.vq)) < 0) app.vq = "best"
                    nameField.text = r.title
                    app.phase = "ready"
                } else {
                    app.errText = r && r.error ? r.error : "Could not read the video information"
                    app.phase = "failed"
                }
            }
        }
    }

    // ------------------------------------------------------------ a dropdown (list opens below the box, inside this window)
    component Drop: Item {
        id: d
        property string dropId: ""
        property var options: []              // [{ v: "value", t: "text" }]
        property string value: ""
        property bool enabled: true
        property string note: ""              // text shown instead of the value when the dropdown is disabled
        property string openId: ""            // id of the dropdown that is open now (set from outside: openId: app.openDrop)
        signal picked(string v)
        signal toggled(string id)             // the box was clicked: the owner opens / closes the list
        signal closed()                       // an entry was chosen
        readonly property bool opened: d.openId === d.dropId
        height: 40
        z: opened ? 100 : 0
        readonly property string curText: {
            if (!d.enabled) return d.note
            for (var i = 0; i < d.options.length; i++) if (d.options[i].v === d.value) return d.options[i].t
            return d.options.length > 0 ? d.options[0].t : ""
        }
        Rectangle {
            anchors.fill: parent
            radius: Theme.rTile
            antialiasing: true
            color: !d.enabled ? "transparent" : (dMa.containsMouse ? Theme.hover : Theme.field)
            border.width: 1
            border.color: d.opened ? Theme.accent : Theme.hairline
            opacity: d.enabled ? 1 : 0.6
            Text {
                anchors.left: parent.left; anchors.right: arrow.left; anchors.leftMargin: 12; anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: d.curText; elide: Text.ElideRight
                color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody
            }
            Text {
                id: arrow
                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                text: d.opened ? "▴" : "▾"; visible: d.enabled
                color: Theme.muted; font.pixelSize: Theme.fsBody
            }
            MouseArea {
                id: dMa
                anchors.fill: parent
                enabled: d.enabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: d.toggled(d.dropId)
            }
        }
        Rectangle {
            visible: d.opened
            y: d.height + 4
            width: d.width
            height: Math.min(d.options.length, 6) * 34 + 8
            radius: Theme.rTile
            color: Theme.surface
            border.width: 1
            border.color: Theme.hairline
            ListView {
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                model: d.options
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 34
                    radius: 8
                    color: modelData.v === d.value ? Theme.accentSoft : (oMa.containsMouse ? Theme.hover : "transparent")
                    Text {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 10; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.t; elide: Text.ElideRight
                        color: modelData.v === d.value ? Theme.accent : Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody
                    }
                    MouseArea {
                        id: oMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { d.picked(modelData.v); d.closed() }
                    }
                }
            }
        }
    }

    FloatingWindow {
        id: win
        visible: true
        title: "Snow DM Save Video"
        implicitWidth: 560
        implicitHeight: 470
        minimumSize: Qt.size(560, 470)      // same min and max size = Hyprland makes it a FLOATING window
        maximumSize: Qt.size(560, 470)
        color: Theme.bg
        onVisibleChanged: if (!visible) app.finish("cancel")

        Item {
            anchors.fill: parent
            focus: true
            MouseArea { anchors.fill: parent; z: -1; onPressed: { app.openDrop = ""; win.startSystemMove() } }   // empty places drag the window
            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_Escape) { if (app.openDrop !== "") app.openDrop = ""; else app.finish("cancel"); e.accepted = true }
            }

            Item {                                   // thin strip at the very top: drag it to move the window
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                height: 12
                DragHandler { target: null; onActiveChanged: if (active) win.startSystemMove() }
            }
            // ---------- header
            Item {
                id: head
                DragHandler { target: null; onActiveChanged: if (active) win.startSystemMove() }
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 16
                height: 36
                Text {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    text: "Save video"
                    color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsTitle; font.weight: Font.DemiBold
                }
                DmBtn {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    cp: 0xe5cd; isClose: true; tip: "Cancel (Esc)"; tipLeft: true
                    onClicked: app.finish("cancel")
                }
            }

            Column {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: head.bottom
                anchors.leftMargin: 16; anchors.rightMargin: 16; anchors.topMargin: 6
                spacing: 6

                // ---------- what video is this
                Text {
                    width: parent.width
                    text: app.phase === "loading" ? "Reading the video information ..." : (app.phase === "failed" ? "Could not read the video" : app.vTitle)
                    elide: Text.ElideRight
                    color: Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    text: app.phase === "failed" ? app.errText + "  (You can still download with \"Best available\".)" : (app.phase === "loading" ? app.url : app.vInfo)
                    color: app.phase === "failed" ? Theme.danger : Theme.muted
                    font.family: Theme.uiFont; font.pixelSize: Theme.fsTiny
                }
                Item { width: 1; height: 4 }

                // ---------- Video | Audio only
                Row {
                    spacing: 8
                    Repeater {
                        model: [ { id: "video", lb: "Video" }, { id: "audio", lb: "Audio only" } ]
                        delegate: Rectangle {
                            id: mb
                            required property var modelData
                            readonly property bool on: app.mode === mb.modelData.id
                            width: 130; height: 34; radius: 17; antialiasing: true
                            color: mb.on ? Theme.accent : (mbMa.containsMouse ? Theme.hover : Theme.field)
                            border.width: 1; border.color: mb.on ? Theme.accent : Theme.hairline
                            Text { anchors.centerIn: parent; text: mb.modelData.lb; color: mb.on ? Theme.accentText : Theme.text; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold }
                            MouseArea { id: mbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { app.openDrop = ""; app.mode = mb.modelData.id } }
                        }
                    }
                }
                Item { width: 1; height: 2 }

                // ---------- quality (video) or format + quality (audio): same place
                Item {
                    width: parent.width
                    height: 66
                    z: 50
                    Column {
                        visible: app.mode === "video"
                        width: parent.width
                        spacing: 4
                        Text { text: "Video quality"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                        Drop {
                            dropId: "vq"
                            openId: app.openDrop
                            onToggled: (id) => app.openDrop = (app.openDrop === id ? "" : id)
                            onClosed: app.openDrop = ""
                            width: parent.width
                            options: app.videoOptions()
                            value: app.vq
                            onPicked: (v) => app.vq = v
                        }
                    }
                    Row {
                        visible: app.mode === "audio"
                        width: parent.width
                        spacing: 10
                        Column {
                            width: (parent.width - 10) / 2
                            spacing: 4
                            Text { text: "Audio format"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                            Drop {
                                dropId: "afmt"
                                openId: app.openDrop
                                onToggled: (id) => app.openDrop = (app.openDrop === id ? "" : id)
                                onClosed: app.openDrop = ""
                                width: parent.width
                                options: [ { v: "mp3", t: "MP3" }, { v: "m4a", t: "M4A (AAC)" }, { v: "opus", t: "Opus" }, { v: "flac", t: "FLAC (lossless)" }, { v: "wav", t: "WAV (lossless)" } ]
                                value: app.afmt
                                onPicked: (v) => app.afmt = v
                            }
                        }
                        Column {
                            width: (parent.width - 10) / 2
                            spacing: 4
                            Text { text: "Audio quality"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                            Drop {
                                dropId: "aq"
                                openId: app.openDrop
                                onToggled: (id) => app.openDrop = (app.openDrop === id ? "" : id)
                                onClosed: app.openDrop = ""
                                width: parent.width
                                enabled: !app.lossless
                                note: "Lossless"
                                options: [ { v: "best", t: "Best" }, { v: "320", t: "320 kbit/s" }, { v: "256", t: "256 kbit/s" }, { v: "192", t: "192 kbit/s" }, { v: "128", t: "128 kbit/s" }, { v: "96", t: "96 kbit/s" } ]
                                value: app.aq
                                onPicked: (v) => app.aq = v
                            }
                        }
                    }
                }

                Text { text: "File name"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                DmField {
                    id: nameField
                    width: parent.width
                    height: 40
                    hint: "File name (without the ending)"
                    text: ""
                    onAccepted: (t) => app.finish("download")
                }
                Item { width: 1; height: 2 }
                Text { text: "Save in"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall }
                Item {
                    width: parent.width
                    height: 40
                    DmField {
                        id: dirField
                        anchors.left: parent.left; anchors.right: folderBtn.left; anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        height: 40
                        hint: "/home/you/Downloads"
                        text: app.startDir
                        onAccepted: (t) => app.finish("download")
                    }
                    DmBtn {
                        id: folderBtn
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        size: 40; cp: 0xe2c8; accent: true; tip: "Choose a folder"; tipLeft: true
                        onClicked: {
                            pick.command = ["bash", app.home + "/.config/snow/bin/downloads/dm-pickdir.sh", dirField.text]
                            pick.running = true
                        }
                    }
                }
            }

            // ---------- buttons: Cancel | Download
            Row {
                anchors.right: parent.right; anchors.bottom: parent.bottom
                anchors.margins: 16
                spacing: 8
                Rectangle {
                    width: 96; height: 40; radius: 20; antialiasing: true
                    color: cMa.pressed ? Theme.pressed : (cMa.containsMouse ? Theme.hover : "transparent")
                    border.width: 1; border.color: Theme.hairline
                    Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.danger; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold }
                    MouseArea { id: cMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.finish("cancel") }
                }
                Rectangle {
                    width: 120; height: 40; radius: 20; antialiasing: true
                    color: dMa2.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent
                    opacity: app.phase === "loading" ? 0.5 : (dMa2.containsMouse ? 0.92 : 1)
                    Text { anchors.centerIn: parent; text: "Download"; color: Theme.accentText; font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold }
                    MouseArea { id: dMa2; anchors.fill: parent; hoverEnabled: true; enabled: app.phase !== "loading"; cursorShape: Qt.PointingHandCursor; onClicked: app.finish("download") }
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
pre() {
apt_install aria2 jq curl wl-clipboard xdg-utils ffmpeg nodejs   # ffmpeg joins video + audio, nodejs = the javascript runtime yt-dlp needs for YouTube
}
post() {
mkdir -p "$HOME/.local/share/icons/hicolor/256x256/apps"
base64 -d > "$HOME/.local/share/icons/hicolor/256x256/apps/snow-downloads.png" <<'SNOWICON'
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
SNOWICON
mkdir -p "$HOME/.local/share/icons/hicolor/64x64/apps"
base64 -d > "$HOME/.local/share/icons/hicolor/64x64/apps/snow-downloads.png" <<'SNOWICON'
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
SNOWICON
rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/snow-downloads.svg"
gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
pass "gold+black icon installed (snow-downloads)"
command -v xdg-mime >/dev/null 2>&1 && { xdg-mime default snow-downloads.desktop x-scheme-handler/magnet application/x-bittorrent 2>/dev/null; pass "magnet links and .torrent files open in the Snow download manager"; }
update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
bash "$HOME/.config/snow/bin/downloads/dm-pick-host.sh" install >/dev/null 2>&1 && pass "browser folder button: native helper registered (restart the browser once)"
base64 -d > "$HOME/.config/snow/dm/logo.png" <<'SNOWLOGO'
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
SNOWLOGO
pass "download manager logo installed"
if [ -x "$HOME/.local/bin/yt-dlp" ]; then pass "yt-dlp found in ~/.local/bin (video downloads)"
else timeout 300 bash "$HOME/.config/snow/bin/downloads/dm-video.sh" install >/dev/null 2>&1 && pass "yt-dlp installed in ~/.local/bin (video downloads, checked with the official checksum)" || warn "yt-dlp could not be downloaded (internet?): video downloads need it" "bash ~/.config/snow/bin/downloads/dm-video.sh install"; fi
if pgrep -f "aria2c.*rpc-listen-port=6899" >/dev/null 2>&1; then bash "$HOME/.config/snow/bin/downloads/dm.sh" restart >/dev/null 2>&1 && pass "download engine restarted (new version)" || warn "engine restart failed" "bash ~/.config/snow/bin/downloads/dm.sh restart"; fi
}
extra_check() {
have aria2c && pass "aria2 installed" || fail "aria2 is not installed" "sudo apt-get install aria2"
have jq && pass "jq installed" || fail "jq is missing" "sudo apt-get install jq"
for f in shell DmBtn DmField Theme; do [ -f "$HOME/.config/snow/dm/$f.qml" ] && pass "dm/$f.qml present" || fail "dm/$f.qml missing" "bash ~/Snow/Script/28-download-manager.sh"; done
for f in shell DmBtn DmField Theme; do [ -f "$HOME/.config/snow/dmask/$f.qml" ] && pass "dmask/$f.qml present" || fail "dmask/$f.qml missing" "bash ~/Snow/Script/28-download-manager.sh"; done
for f in shell DmBtn DmField Theme; do [ -f "$HOME/.config/snow/dmvid/$f.qml" ] && pass "dmvid/$f.qml present" || fail "dmvid/$f.qml missing" "bash ~/Snow/Script/28-download-manager.sh"; done
for f in DmBtn DmField; do   # dmvid ("Save video" window) keeps its own copy too: it must stay identical to dm
  [ -f "$HOME/.config/snow/dm/$f.qml" ] && [ -f "$HOME/.config/snow/dmvid/$f.qml" ] || continue
  cmp -s "$HOME/.config/snow/dm/$f.qml" "$HOME/.config/snow/dmvid/$f.qml" && pass "dm/$f.qml is identical to dmvid/$f.qml" || warn "dm/$f.qml differs from dmvid/$f.qml" "keep all three (dm, dmask, dmvid) the same: copy the newest one over the others, then Files/backup.sh"
done
[ -f "$HOME/.config/snow/dm/logo.png" ] && pass "dm/logo.png present" || warn "dm/logo.png missing (the window shows no logo)" "bash ~/Snow/Script/28-download-manager.sh"
{ [ -x "$HOME/.local/bin/yt-dlp" ] || have yt-dlp; } && pass "yt-dlp found (video downloads)" || warn "yt-dlp is not installed: video downloads will not work" "bash ~/.config/snow/bin/downloads/dm-video.sh install"
have ffmpeg && pass "ffmpeg installed (joins video and audio)" || warn "ffmpeg is not installed: video downloads cannot be joined" "sudo apt-get install ffmpeg"
{ have node || have deno; } && pass "javascript runtime found (node or deno: YouTube)" || warn "no javascript runtime (node or deno): YouTube links can fail" "sudo apt-get install nodejs"
for f in DmBtn DmField; do   # dm and dmask keep their own copy of these two: they must stay identical
  [ -f "$HOME/.config/snow/dm/$f.qml" ] && [ -f "$HOME/.config/snow/dmask/$f.qml" ] || continue
  cmp -s "$HOME/.config/snow/dm/$f.qml" "$HOME/.config/snow/dmask/$f.qml" && pass "dm/$f.qml is identical to dmask/$f.qml" || warn "dm/$f.qml differs from dmask/$f.qml" "keep both the same: copy the newest one over the other, then Files/backup.sh"
done
for s in downloads/dm.sh downloads/dm-rpc.sh downloads/dm-conf.sh downloads/dm-ask.sh downloads/dm-hook.sh downloads/dm-pick-host.sh downloads/dm-pickdir.sh downloads/dm-save.sh downloads/dm-notify.sh downloads/dm-on-complete.sh downloads/dm-on-error.sh downloads/dm-on-pause.sh downloads/dm-video.sh downloads/dm-vsave.sh; do [ -f "$BIN/$s" ] || continue; bash -n "$BIN/$s" && pass "$s: syntax ok" || fail "$s: syntax error" "bash ~/Snow/Script/${MOD}.sh"; done
}
component_main "$@"
