#!/usr/bin/env bash
# 19-file-manager.sh : Snow file manager (Super+E)
# Own file manager: its own Quickshell window (config ~/.config/snow/fm) + the fm-*.sh helpers. Your pins / state files are kept when they exist.
#   bash Script/19-file-manager.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/19-file-manager.sh check    read-only check
MOD="19-file-manager"; TITLE="Snow file manager (Super+E)"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/snow/bin/filemanager/fm-default.sh|755|0"
  "u|.config/snow/bin/filemanager/fm-dev.sh|755|0"
  "u|.config/snow/bin/filemanager/fm-find.sh|755|0"
  "u|.config/snow/bin/filemanager/fm-icon.sh|755|0"
  "u|.config/snow/bin/filemanager/fm-info.sh|755|0"
  "u|.config/snow/bin/filemanager/fm-ls.sh|755|0"
  "u|.config/snow/bin/filemanager/fm-op.sh|755|0"
  "u|.config/snow/bin/filemanager/fm-open.sh|755|0"
  "u|.config/snow/bin/filemanager/fm-side.sh|755|0"
  "u|.config/snow/bin/filemanager/fm-trash.sh|755|0"
  "u|.config/snow/bin/filemanager/fm.sh|755|0"
  "u|.config/snow/fm/FileIcon.qml|644|0"
  "u|.config/snow/fm/FolderIcon.qml|644|0"
  "u|.config/snow/fm/Theme.qml|644|0"
  "u|.config/snow/fm/shell.qml|644|0"
  "u|.config/snow/state/fm-pins|644|1"
  "u|.config/snow/state/fm-state.json|644|1"
  "u|.local/share/applications/snow-files.desktop|644|0"
)
emit() {
case "$1" in
"u/.config/snow/bin/filemanager/fm-default.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# fm-default.sh : default programs by kind of file (text, images, videos, music, PDF) for the Snow file manager.
#   fm-default.sh list              JSON {"cats":[{"id":"text","label":"Text files","current":"x.desktop","apps":[{"id":"x.desktop","name":"..."}]}, ...]}
#   fm-default.sh set CATEGORY APPID  make APPID the default for all file types of that category (xdg-mime default ...). Result {"ok":..,"msg":..}
#   The choice is stored by xdg in ~/.config/mimeapps.list (a copy of the old file is kept once as mimeapps.list.snowfm-bak). It is used by every program.
DIRS=("$HOME/.local/share/applications" /usr/local/share/applications /usr/share/applications /var/lib/flatpak/exports/share/applications "$HOME/.local/share/flatpak/exports/share/applications")
find_desktop() { local d; for d in "${DIRS[@]}"; do [ -f "$d/$1" ] && { printf '%s' "$d/$1"; return 0; }; done; return 1; }
cat_info() {   # $1 = category -> sets LABEL and MIMES (first one = the one asked)
  case "$1" in
    text)   LABEL="Text files"; MIMES="text/plain text/markdown application/x-shellscript text/x-shellscript application/json text/x-python";;
    image)  LABEL="Images";     MIMES="image/png image/jpeg image/gif image/webp image/bmp image/svg+xml image/avif image/tiff";;
    video)  LABEL="Videos";     MIMES="video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo video/mpeg video/ogg video/x-flv";;
    audio)  LABEL="Music";      MIMES="audio/mpeg audio/flac audio/ogg audio/x-wav audio/wav audio/mp4 audio/aac audio/opus audio/x-flac";;
    pdf)    LABEL="PDF files";  MIMES="application/pdf";;
    *) return 1;;
  esac
}
CATS="text image video audio pdf"
ML="${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"
cur_of() {   # current default program of one mime type: our own list first (it wins), else what xdg-mime says
  local v=""
  [ -f "$ML" ] && v=$(sed -n '/^\[Default Applications\]/,/^\[/{s/^'"$(printf '%s' "$1" | sed 's|[][\\.*^$/]|\\&|g')"'=//p}' "$ML" | head -n1 | cut -d';' -f1)
  [ -n "$v" ] || v=$(xdg-mime query default "$1" 2>/dev/null | head -n1)
  printf '%s' "$v"
}
case "${1:-}" in
  list)
    command -v jq >/dev/null 2>&1 || { echo '{"cats":[]}'; exit 0; }
    for c in $CATS; do
      cat_info "$c"; rep="${MIMES%% *}"
      cur=$(cur_of "$rep")
      ids=$(gio mime "$rep" 2>/dev/null | sed -n 's/^[[:space:]]\+\([^[:space:]]\+\.desktop\)[[:space:]]*$/\1/p')
      more=$(find "${DIRS[@]}" -maxdepth 1 -name '*.desktop' 2>/dev/null | xargs -r grep -l "^MimeType=.*${rep}" 2>/dev/null | sed 's|.*/||')
      all=$(printf '%s\n%s\n%s\n' "$cur" "$ids" "$more" | awk 'NF && !s[$0]++')
      apps=$(while IFS= read -r id; do
        [ -n "$id" ] || continue
        df=$(find_desktop "$id") || continue
        grep -qi '^NoDisplay=true' "$df" && continue
        nm=$(grep -m1 '^Name=' "$df" | cut -d= -f2-); [ -n "$nm" ] && printf '%s\t%s\n' "$id" "$nm"
      done <<< "$all" | head -12 | jq -R -s -c '[split("\n")[] | select(length > 0) | split("\t") | {id: .[0], name: .[1]}]')
      jq -n -c --arg id "$c" --arg l "$LABEL" --arg cur "$cur" --argjson apps "${apps:-[]}" '{id:$id,label:$l,current:$cur,apps:$apps}'
    done | jq -s -c '{cats: .}';;
  set)
    c="${2:-}"; id="${3:-}"
    cat_info "$c" || { echo '{"ok":false,"msg":"unknown kind of file"}'; exit 0; }
    find_desktop "$id" >/dev/null || { echo '{"ok":false,"msg":"program not found"}'; exit 0; }
    ml="$ML"
    [ -f "$ml" ] && [ ! -e "$ml.snowfm-bak" ] && cp -f -- "$ml" "$ml.snowfm-bak"
    for m in $MIMES; do xdg-mime default "$id" "$m" 2>/dev/null; done
    now=$(cur_of "${MIMES%% *}")
    if [ "$now" = "$id" ]; then jq -n -c --arg m "$LABEL now open with $(grep -m1 '^Name=' "$(find_desktop "$id")" | cut -d= -f2-)" '{ok:true,msg:$m}'
    else echo '{"ok":false,"msg":"could not save the choice"}'; fi;;
  *) echo "usage: fm-default.sh list | set CATEGORY APPID"; exit 2;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/filemanager/fm-dev.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# fm-dev.sh : drives for the Snow file manager side pane. Uses lsblk (list) and udisksctl (mount / unmount / eject).
#   fm-dev.sh list              {"devs":[{"dev":"/dev/sdb1","name":"USB","size":"29.8G","fstype":"exfat","mount":"/run/media/x/USB","removable":true,"disk":"/dev/sdb"}]}
#   fm-dev.sh mount DEV         {"ok":true,"path":"/run/media/..","msg":".."}
#   fm-dev.sh unmount DEV       fm-dev.sh eject DEV   (unmount, then power the stick off if it is removable)
# Left out of the list: the system (/, /boot, /boot/efi, /home, /var, /usr), swap, LUKS / LVM containers, loop and optical devices,
# and helper partitions by their partition type: EFI system, BIOS boot, Microsoft reserved, Windows recovery (also on other disks).
# Nothing is formatted or written. Mount / eject ask for the password through the Snow polkit window when the system wants it.
J() { jq -n -c --argjson ok "$1" --arg path "${2:-}" --arg msg "${3:-}" '{ok:$ok,path:$path,msg:$msg}'; }
# adds "total" and "avail" (bytes) to every mounted drive in the list (df, 3 second limit)
add_space() {
  local sp l av r sz tg
  sp=$(timeout 3 df -B1 --output=target,size,avail 2>/dev/null | tail -n +2 | while IFS= read -r l; do
    av=${l##* }; r=${l% *}; r=${r%"${r##*[![:space:]]}"}; sz=${r##* }; tg=${r% *}; tg=${tg%"${tg##*[![:space:]]}"}
    printf '%s\t%s\t%s\n' "$tg" "$sz" "$av"
  done | jq -R -s -c '[split("\n")[] | select(length > 0) | split("\t") | {key: .[0], value: {total: (.[1] | tonumber? // 0), avail: (.[2] | tonumber? // 0)}}] | from_entries' 2>/dev/null)
  [ -n "$sp" ] || sp='{}'
  jq -c --argjson sp "$sp" '.devs |= map(. + ($sp[.mount] // {total: 0, avail: 0}))'
}
valid() { [[ "${1:-}" =~ ^/dev/[A-Za-z0-9_/-]+$ ]] && [ -b "$1" ] || [ -n "${SNOW_FM_TEST:-}" ]; }
case "${1:-list}" in
  list)
    command -v jq >/dev/null 2>&1 || { echo '{"devs":[]}'; exit 0; }
    if [ -n "${SNOW_FM_LSBLK:-}" ]; then RAW=$(cat "$SNOW_FM_LSBLK"); else RAW=$(lsblk -J -o NAME,PATH,LABEL,SIZE,FSTYPE,MOUNTPOINTS,RM,HOTPLUG,TYPE,TRAN,PKNAME,PARTTYPE,PARTLABEL 2>/dev/null); fi
    [ -n "$RAW" ] || { echo '{"devs":[]}'; exit 0; }
    printf '%s' "$RAW" | jq -c '
      def sysmount: . as $m | ($m == "/" or $m == "/home" or $m == "/var" or $m == "/usr" or ($m | startswith("/boot")) or $m == "[SWAP]");
      def helper: ((.parttype // "") | ascii_downcase) as $t | ((.label // "") | ascii_downcase) as $l | ((.partlabel // "") | ascii_downcase) as $pl
        | ($t | IN("c12a7328-f81f-11d2-ba4b-00a0c93ec93b","21686148-6449-6e6f-744e-656564454649","e3c9e316-0b5c-4db8-817d-f92df00215ae","de94bba4-06d1-4d40-a16a-bfd50179d6ac","0xef","0x27","0x82"))
          or ($pl | test("^(efi system|efi|esp|microsoft reserved|basic data partition recovery|windows re|recovery)"))
          or (.fstype == "vfat" and ($l | test("^(efi|esp|efi system)")));
      def truthy: . == true or . == "1" or . == 1;
      { devs: [ .blockdevices[]? | recurse(.children[]?)
        | select(.fstype != null and (.fstype | IN("swap","crypto_LUKS","LVM2_member","linux_raid_member","iso9660") | not))
        | select((.type // "") | IN("loop","rom","crypt","lvm") | not)
        | select(helper | not)
        | . as $d | ([ .mountpoints[]? | select(. != null) ] | first // "") as $mp
        | select(($mp == "") or ($mp | sysmount | not))
        | { dev: .path, name: (if (.label // "") != "" then .label else ((.size // "") + " " + .fstype) end),
            size: (.size // ""), fstype: .fstype, mount: $mp,
            removable: ((.rm | truthy) or (.hotplug | truthy) or (.tran == "usb")),
            disk: (if .pkname then "/dev/" + .pkname else "" end) } ] }' | add_space
    ;;
  mount)
    dev="${2:-}"; valid "$dev" || { J false "" "bad device"; exit 1; }
    out=$(udisksctl mount -b "$dev" 2>&1); rc=$?
    path=$(printf '%s' "$out" | sed -n "s/^Mounted .* at \(.*\)\$/\1/p" | head -1)
    [ -n "$path" ] || path=$(printf '%s' "$out" | sed -n "s/.*already mounted at \`\([^']*\)'.*/\1/p" | head -1)
    # the answer can end with "." and/or be quoted (`/path'.) depending on the udisks version: clean it, keep only a folder that exists
    if [ -n "$path" ]; then
      for c in "$path" "${path%.}" "${path#\`}" "$(c=${path%.}; c=${c%\'}; printf '%s' "${c#\`}")"; do [ -d "$c" ] && { path="$c"; break; }; done
      [ -d "$path" ] || [ -n "${SNOW_FM_TEST:-}" ] || path=""
    fi
    if [ -n "$path" ]; then J true "$path" "mounted"; else J false "" "${out:0:200}"; fi;;
  unmount|eject)
    dev="${2:-}"; valid "$dev" || { J false "" "bad device"; exit 1; }
    out=$(udisksctl unmount -b "$dev" 2>&1); rc=$?
    if [ $rc -ne 0 ] && ! printf '%s' "$out" | grep -qi 'not mounted'; then J false "" "${out:0:200}"; exit 1; fi
    if [ "$1" = eject ]; then
      disk=$(lsblk -no PKNAME "$dev" 2>/dev/null | head -1); [ -n "$disk" ] || disk="${dev##*/}"
      rm_=$(lsblk -dno RM "/dev/$disk" 2>/dev/null | tr -d ' ')
      if [ "$rm_" = 1 ]; then
        out=$(udisksctl power-off -b "/dev/$disk" 2>&1) && { J true "" "ejected - you can remove it"; exit 0; }
        J true "" "unmounted (power-off not done: ${out:0:120})"; exit 0
      fi
    fi
    J true "" "unmounted";;
  *) echo "usage: fm-dev.sh list|mount DEV|unmount DEV|eject DEV"; exit 2;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/filemanager/fm-find.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# fm-find.sh DIR QUERY [hidden] : search a folder AND all its sub folders by name, for the Snow file manager. Read-only.
#   Every word of QUERY must be in the file name (not case sensitive). Same JSON as fm-ls.sh, but "name" is the path inside DIR
#   (like "sub/deeper/a.txt") and there is "truncated":true when more than 1000 matches were found (only the first 1000 are given).
#   Stays on the same disk (no other drives), does not follow links, 20 second limit. Without "hidden" dot-files/folders are skipped.
D="${1:-$HOME}"; Q="${2:-}"; SH="${3:-}"
command -v jq >/dev/null 2>&1 || { echo '{"ok":false,"error":"jq is not installed","items":[]}'; exit 0; }
D="${D%/}"; [ -n "$D" ] || D="/"
if [ ! -d "$D" ]; then jq -n --arg p "$D" '{path:$p,ok:false,error:"not a folder",items:[]}'; exit 0; fi
if [ ! -r "$D" ] || [ ! -x "$D" ]; then jq -n --arg p "$D" '{path:$p,ok:false,error:"no permission",items:[]}'; exit 0; fi
MAX=1000
args=()
for w in $Q; do
  w="${w//\\/\\\\}"; w="${w//\*/\\*}"; w="${w//\?/\\?}"; w="${w//\[/\\[}"
  args+=(-iname "*${w}*")
done
[ ${#args[@]} -gt 0 ] || { jq -n --arg p "$D" '{path:$p,ok:true,items:[],truncated:false}'; exit 0; }
pr=()
[ "$SH" = "hidden" ] || pr=( \( -name '.*' -prune \) -o )
timeout 20 find "$D" -xdev -mindepth 1 "${pr[@]}" \( "${args[@]}" \) -printf '%y\037%Y\037%s\037%T@\037%P\0' 2>/dev/null |
  head -z -n $((MAX + 1)) | tr '\0' '\036' |
  jq -R -s --arg p "$D" --arg q "$Q" --argjson max "$MAX" '
    ( split("\u001e") | map(select(length > 0) | split("\u001f") | select(length == 5)) ) as $all
    | { path: $p, ok: true, query: $q, truncated: (($all | length) > $max),
        items: ( $all[0:$max] | map(
          { name: .[4], dir: (.[0] == "d" or (.[0] == "l" and .[1] == "d")), link: (.[0] == "l"),
            size: (.[2] | tonumber? // 0), mtime: (.[3] | tonumber? // 0 | floor),
            hidden: (.[4] | (startswith(".") or contains("/."))) })
          | sort_by([(.dir | not), (.name | ascii_downcase)]) ) }'
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/filemanager/fm-icon.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# fm-icon.sh : optional own folder icon (an .svg file) for the Snow file manager. Result = one JSON line {"ok":true|false,"msg":"..."}
#   fm-icon.sh set FILE.svg   check the file (.svg, text with <svg, max 2 MB), copy it to ~/.config/snow/fm/folder.svg (old one -> folder.svg.bak)
#   fm-icon.sh reset          remove folder.svg (kept as folder.svg.bak) -> the file manager draws its own folder again
#   fm-icon.sh choose         open a small file manager window in "choose an .svg" mode, then do "set" with the chosen file
DEST="$HOME/.config/snow/fm/folder.svg"
J() { jq -n -c --argjson ok "$1" --arg m "$2" '{ok:$ok,msg:$m}' 2>/dev/null || printf '{"ok":%s,"msg":"%s"}\n' "$1" "$2"; }
do_set() {
  local src="$1"
  [ -f "$src" ] || { J false "file not found"; return 1; }
  case "${src,,}" in *.svg) ;; *) J false "this is not an .svg file"; return 1;; esac
  [ "$(stat -c %s -- "$src" 2>/dev/null || echo 99999999)" -le 2097152 ] || { J false "file is bigger than 2 MB"; return 1; }
  head -c 65536 -- "$src" | grep -qi '<svg' || { J false "this does not look like an SVG image"; return 1; }
  mkdir -p "$(dirname "$DEST")"
  [ -f "$DEST" ] && cp -f -- "$DEST" "$DEST.bak"
  cp -f -- "$src" "$DEST.new.$$" && mv -f -- "$DEST.new.$$" "$DEST" || { rm -f -- "$DEST.new.$$"; J false "copy failed"; return 1; }
  J true "Folder icon changed"
}
case "${1:-}" in
  set) do_set "${2:-}";;
  reset)
    if [ -f "$DEST" ]; then mv -f -- "$DEST" "$DEST.bak" && J true "Folder icon reset (old file kept as folder.svg.bak)" || J false "could not reset"
    else J true "Already using the built-in folder icon"; fi;;
  choose)
    BIN=$(command -v qs || command -v quickshell) || { J false "quickshell not found"; exit 0; }
    out=$(mktemp "${TMPDIR:-/tmp}/snow-fm-pick.XXXXXX"); start="$HOME/Pictures"; [ -d "$start" ] || start="$HOME"
    mkdir -p "$HOME/.cache/snow"
    FM_START="$start" FM_PICK=svg FM_PICK_OUT="$out" "$BIN" -p "$HOME/.config/snow/fm" >"$HOME/.cache/snow/fm-pick.log" 2>&1 </dev/null
    f=$(head -n1 "$out" 2>/dev/null); rm -f -- "$out"
    if [ -n "$f" ]; then do_set "$f"; else echo ""; fi;;
  *) echo "usage: fm-icon.sh set FILE.svg | reset | choose"; exit 2;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/filemanager/fm-info.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# fm-info.sh PATH... : details for the Properties window of the Snow file manager. Read-only.
#   one path   -> {"rows":[["Name","x"],["Type","..."],["Location","/.."],["Size","1.2 MB (1234567 bytes)"],["Contains","12 items"],["Modified","28 Oct 2026, 14:03"],["Permissions","rw-r--r--  snow:snow"]]}
#   many paths -> name count, total size, location
# A folder is measured with du / find (stops after 20 s on huge folders and says so).
command -v jq >/dev/null 2>&1 || { echo '{"rows":[["Error","jq is not installed"]]}'; exit 0; }
human() { if command -v numfmt >/dev/null 2>&1; then numfmt --to=iec --suffix=B --format=%.1f "$1" 2>/dev/null | sed 's/\.0B$/B/;s/\.0\([KMGT]\)B$/\1B/' ; else echo "$1 B"; fi; }
size_of() {  # size_of PATH -> bytes (or empty when too slow)
  if [ -d "$1" ] && [ ! -L "$1" ]; then timeout 20 du -sb -- "$1" 2>/dev/null | cut -f1; else stat -c %s -- "$1" 2>/dev/null; fi
}
ROWS=()
add() { ROWS+=("$1"$'\x1f'"$2"); }
if [ "$#" -eq 0 ]; then echo '{"rows":[]}'; exit 0; fi
if [ "$#" -gt 1 ]; then
  total=0; nd=0; nf=0; slow=""
  for p in "$@"; do
    [ -d "$p" ] && [ ! -L "$p" ] && nd=$((nd + 1)) || nf=$((nf + 1))
    s=$(size_of "$p"); if [ -n "$s" ]; then total=$((total + s)); else slow=" (a folder was too large to measure)"; fi
  done
  add "Selected" "$# items ($nf files, $nd folders)"; add "Total size" "$(human $total) ($total bytes)$slow"; add "Location" "$(dirname -- "$1")"
else
  p="$1"
  if [ ! -e "$p" ] && [ ! -L "$p" ]; then add "Error" "not found"; else
    add "Name" "${p##*/}"
    if [ -L "$p" ]; then add "Type" "Link"; add "Link target" "$(readlink -- "$p")"
    elif [ -d "$p" ]; then add "Type" "Folder"
    else
      t=""; command -v file >/dev/null 2>&1 && t=$(file -b --mime-type -- "$p" 2>/dev/null)
      [ -n "$t" ] || t=$(xdg-mime query filetype "$p" 2>/dev/null)
      add "Type" "${t:-File}"
    fi
    add "Location" "$(dirname -- "$p")"
    s=$(size_of "$p")
    if [ -n "$s" ]; then add "Size" "$(human "$s") ($s bytes)"; else add "Size" "too large to measure quickly"; fi
    if [ -d "$p" ] && [ ! -L "$p" ]; then n=$(timeout 20 find "$p" -mindepth 1 2>/dev/null | wc -l); add "Contains" "$n items (all levels)"; fi
    m=$(stat -c %Y -- "$p" 2>/dev/null); [ -n "$m" ] && add "Modified" "$(date -d "@$m" '+%d %b %Y, %H:%M')"
    a=$(stat -c %X -- "$p" 2>/dev/null); [ -n "$a" ] && add "Accessed" "$(date -d "@$a" '+%d %b %Y, %H:%M')"
    add "Permissions" "$(stat -c '%A  %U:%G' -- "$p" 2>/dev/null)"
  fi
fi
printf '%s\n' "${ROWS[@]}" | jq -R -s -c '{rows: [split("\n")[] | select(length > 0) | split("\u001f")]}'
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/filemanager/fm-ls.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# fm-ls.sh DIR [hidden] : list one folder as JSON for the Snow file manager (fm.qml). Read-only, changes nothing.
#   {"path":"/home/x","ok":true,"items":[{"name":"a","dir":true,"link":false,"size":4096,"mtime":1761750000,"hidden":false}, ...]}
#   folders first, then A-Z (not case sensitive). Without "hidden" the names starting with a dot are left out.
#   On an error: {"path":"...","ok":false,"error":"..."}
D="${1:-$HOME}"; SH="${2:-}"
command -v jq >/dev/null 2>&1 || { echo '{"ok":false,"error":"jq is not installed","items":[]}'; exit 0; }
D="${D%/}"; [ -n "$D" ] || D="/"
if [ ! -d "$D" ]; then jq -n --arg p "$D" '{path:$p,ok:false,error:"not a folder",items:[]}'; exit 0; fi
if [ ! -r "$D" ] || [ ! -x "$D" ]; then jq -n --arg p "$D" '{path:$p,ok:false,error:"no permission",items:[]}'; exit 0; fi
find "$D" -mindepth 1 -maxdepth 1 -printf '%y\037%Y\037%s\037%T@\037%f\036' 2>/dev/null |
  jq -R -s --arg p "$D" --arg sh "$SH" '
    { path: $p, ok: true,
      items: ( split("\u001e") | map(select(length > 0) | split("\u001f")
        | select(length == 5)
        | { name: .[4], dir: (.[0] == "d" or (.[0] == "l" and .[1] == "d")), link: (.[0] == "l"),
            size: (.[2] | tonumber? // 0), mtime: (.[3] | tonumber? // 0 | floor), hidden: (.[4] | startswith(".")) }
        | select($sh == "hidden" or (.hidden | not)))
        | sort_by([(.dir | not), (.name | ascii_downcase)]) ) }'
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/filemanager/fm-op.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# fm-op.sh : file work for the Snow file manager (fm). Never overwrites: a name that exists gets "name (copy)", "name (copy 2)" ...
#   fm-op.sh clip-set copy|cut PATH...     remember files (shared by all fm windows: ~/.cache/snow-fm-clip)
#   fm-op.sh paste DEST_DIR                copy or move the remembered files into DEST_DIR (cut = move, clipboard is cleared afterwards)
#   fm-op.sh copy DEST_DIR PATH...         fm-op.sh move DEST_DIR PATH...
#   fm-op.sh trash PATH...                 to the Trash (gio trash), NOT deleted for good
#   fm-op.sh batchrename PATTERN PATH...   rename many: 'Holiday ##' -> Holiday 01.jpg, Holiday 02.jpg ... (extensions kept)
#   fm-op.sh undo                          undo the last move / rename / trash / copy / new item (journal ~/.cache/snow-fm-undo)
#   fm-op.sh conflicts DEST PATH...        print 'C<TAB>name' for every item that already exists in DEST   (paste-conflicts DEST: same for the clipboard)
#   env SNOW_FM_CONFLICT=replace|skip|both  what copy / move / paste do when the name exists (default both = 'name (copy)'; replace = the old one goes to the Trash)
#   fm-op.sh zip DEST_DIR PATH...          Compress to zip (same folder, temp name until finished)
#   fm-op.sh copypath PATH                 put the path text into the system clipboard (needs wl-clipboard)
#   fm-op.sh rmrf PATH...                  delete for good (Shift+Delete), protected folders refused
#   fm-op.sh rename PATH NEWNAME           fm-op.sh mkdir DIR NAME          fm-op.sh mkfile DIR NAME (new empty file)
#   fm-op.sh extract DEST_DIR ARCHIVE...   unpack into a new folder (or the single top item) next to DEST_DIR rules: never overwrites
# Output, one line each (TAB separated):  P pct done total index/count name   |   E message   |   D ok_count error_count
# Copy goes to a hidden temporary name (.fmpart-PID-N) inside the destination and is renamed at the very end, so a half-copied
# file never looks like a finished one. Move on the same disk = rename. Move to another disk = copy, then (only if the copy
# reported success) sync and remove the original, item by item. TERM (Cancel button) stops, removes the temporary copy, keeps the originals.
CLIP="${SNOW_FM_CLIP:-$HOME/.cache/snow-fm-clip}"
OK=0; ERR=0; CHILD=""; PART=""
say() { printf '%s\n' "$*"; }
err() { ERR=$((ERR + 1)); printf 'E\t%s\n' "$*"; }
on_term() { [ -n "$CHILD" ] && kill "$CHILD" 2>/dev/null; wait 2>/dev/null; [ -n "$PART" ] && rm -rf -- "$PART"; printf 'E\tcancelled\nD\t%s\t%s\n' "$OK" "$((ERR + 1))"; exit 130; }
trap on_term TERM INT
# the five main folders (Documents Downloads Pictures Music Videos in home) can not be trashed, deleted, renamed or moved
is_prot() { local rp n; rp=$(realpath -m -- "$1" 2>/dev/null); for n in Documents Downloads Pictures Music Videos; do [ "$rp" = "$(realpath -m -- "$HOME/$n")" ] && return 0; done; return 1; }

# ---- undo journal: every finished action is written to ~/.cache/snow-fm-undo as a block  "@@<TAB>kind"  + lines "A<TAB>B"
#   kind move/rename: A = old path, B = new path (undo = put it back)   create: B = the new item (undo = it goes to the Trash)   trash: A = original path   perm: not undoable
JRN="${SNOW_FM_UNDO:-$HOME/.cache/snow-fm-undo}"; JR=(); JK=""
jrec() { JR+=("$1"$'\t'"$2"); }
jflush() {
  [ -n "$JK" ] && [ "${#JR[@]}" -gt 0 ] || return 0
  mkdir -p "$(dirname "$JRN")"
  { printf '@@\t%s\n' "$JK"; printf '%s\n' "${JR[@]}"; } >> "$JRN"
  if [ "$(wc -l < "$JRN")" -gt 3000 ]; then tail -n 1500 "$JRN" | awk 'f || /^@@/ {f=1; print}' > "$JRN.tmp" && mv -f "$JRN.tmp" "$JRN"; fi
}
undo_last() {
  local ln kind e a b dst tid n=0 self; self="$(dirname "$0")"
  [ -s "$JRN" ] || { err "nothing to undo"; return; }
  ln=$(grep -n '^@@' "$JRN" | tail -1 | cut -d: -f1); [ -n "$ln" ] || { err "nothing to undo"; return; }
  kind=$(sed -n "${ln}p" "$JRN" | cut -f2)
  local ents=(); mapfile -t ents < <(tail -n +$((ln + 1)) "$JRN")
  head -n $((ln - 1)) "$JRN" > "$JRN.tmp" && mv -f "$JRN.tmp" "$JRN"
  case "$kind" in
    perm) err "the last action was a permanent delete: it can not be undone";;
    move|rename)
      for ((n = ${#ents[@]} - 1; n >= 0; n--)); do
        e="${ents[$n]}"; a="${e%%$'\t'*}"; b="${e#*$'\t'}"
        if [ ! -e "$b" ] && [ ! -L "$b" ]; then err "not found any more: ${b##*/}"; continue; fi
        dst="$a"; if [ -e "$a" ] || [ -L "$a" ]; then dst=$(unique "$(dirname "$a")" "${a##*/}"); fi
        mkdir -p -- "$(dirname "$dst")"
        if mv -T -- "$b" "$dst"; then OK=$((OK + 1)); else err "could not put back: ${b##*/}"; fi
      done; say "U	$([ "$kind" = move ] && echo "moved back" || echo "old name restored"): $OK";;
    create)
      for e in "${ents[@]}"; do
        b="${e#*$'\t'}"
        if [ ! -e "$b" ] && [ ! -L "$b" ]; then continue; fi
        if gio trash -- "$b" 2>/dev/null; then OK=$((OK + 1)); else err "could not remove: ${b##*/}"; fi
      done; say "U	new items moved to Trash: $OK";;
    trash)
      for e in "${ents[@]}"; do
        a="${e%%$'\t'*}"
        tid=$(bash "$self/fm-trash.sh" list 2>/dev/null | jq -r --arg o "$a" '[.items[] | select(.orig == $o)] | sort_by(.mtime) | last | .tid // empty' 2>/dev/null)
        if [ -z "$tid" ]; then err "not found in the Trash: ${a##*/}"; continue; fi
        bash "$self/fm-trash.sh" restore "$tid" >/dev/null 2>&1
        if [ -e "$a" ] || [ -L "$a" ] || [ -e "${a%/*}/${a##*/} (copy)" ]; then OK=$((OK + 1)); else err "could not restore: ${a##*/}"; fi
      done; say "U	restored from Trash: $OK";;
    *) err "unknown undo entry";;
  esac
}
paste_resolve() {  # sets mode (copy|cut|"") and files[] : the system clipboard files if they differ from FM2's own note, else FM2's note
  mode=""; files=()
  local sysl=(); mapfile -t sysl < <(sys_files)
  if [ "${#sysl[@]}" -gt 1 ]; then
    if [ -s "$CLIP" ] && [ "$(printf '%s\n' "${sysl[@]:1}" | sort)" = "$(tail -n +2 "$CLIP" | sort)" ]; then :
    else mode="${sysl[0]}"; files=("${sysl[@]:1}"); fi
  fi
  if [ -z "$mode" ] && [ -s "$CLIP" ]; then mode=$(head -1 "$CLIP"); mapfile -t files < <(tail -n +2 "$CLIP"); fi
}
list_conflicts() {  # list_conflicts DEST SRC...
  local dest="${1%/}" s n dd; shift; dd=$(cd "$dest" 2>/dev/null && pwd -P)
  for s in "$@"; do
    s="${s%/}"; n="${s##*/}"
    [ "$(cd "$(dirname "$s")" 2>/dev/null && pwd -P)" = "$dd" ] && continue
    if [ -e "$dest/$n" ] || [ -L "$dest/$n" ]; then printf 'C\t%s\n' "$n"; fi
  done
}
batchrename() {  # batchrename PATTERN PATH...
  local pat="${1:-}" p name ext dir num pre rest lead width i=0 n idx; shift
  local olds=() news=() tmps=()
  [ -n "$pat" ] && [[ "$pat" != */* ]] && [ "$pat" != . ] && [ "$pat" != .. ] || { err "bad name"; return; }
  pre="${pat%%#*}"
  if [ "$pre" = "$pat" ]; then rest=""; width=1; pre="$pat "; else rest="${pat#"$pre"}"; lead="${rest%%[!#]*}"; width=${#lead}; rest="${rest#"$lead"}"; fi
  dir=$(dirname "$1")
  for p in "$@"; do
    p="${p%/}"; i=$((i + 1)); name="${p##*/}"; ext=""
    [ "$(dirname "$p")" = "$dir" ] || { err "all items must be in the same folder"; return; }
    is_prot "$p" && { err "protected folder, cannot be renamed: $name"; return; }
    { [ -e "$p" ] || [ -L "$p" ]; } || { err "not found: $name"; return; }
    if [ ! -d "$p" ] && [[ "$name" == *.* && "${name%.*}" != "" ]]; then ext=".${name##*.}"; fi
    num=$(printf '%0*d' "$width" "$i")
    olds+=("$p"); news+=("$pre$num$rest$ext")
  done
  for n in "${!news[@]}"; do
    p="$dir/${news[$n]}"
    if { [ -e "$p" ] || [ -L "$p" ]; } && [ "$p" != "${olds[$n]}" ]; then
      local own=0; for idx in "${olds[@]}"; do [ "$idx" = "$p" ] && own=1; done
      [ "$own" = 1 ] || { err "'${news[$n]}' already exists, nothing was renamed"; return; }
    fi
  done
  for n in "${!olds[@]}"; do
    tmps+=("$dir/.fmren-$$-$n")
    mv -T -- "${olds[$n]}" "${tmps[$n]}" || { err "rename failed: ${olds[$n]##*/}"; for ((idx = 0; idx < n; idx++)); do mv -T -- "${tmps[$idx]}" "${olds[$idx]}"; done; return; }
  done
  for n in "${!olds[@]}"; do
    if mv -T -- "${tmps[$n]}" "$dir/${news[$n]}"; then OK=$((OK + 1)); [ "${olds[$n]}" = "$dir/${news[$n]}" ] || jrec "${olds[$n]}" "$dir/${news[$n]}"; else err "rename failed: ${news[$n]}"; mv -T -- "${tmps[$n]}" "${olds[$n]}" 2>/dev/null; fi
  done
  JK=rename
}

bytes() { du -sb -- "$1" 2>/dev/null | cut -f1; }
unique() {  # unique DIR NAME -> a free full path in DIR
  local d="${1%/}" n="$2" base ext p i=1
  [ "$d" = "" ] && d=""
  p="$d/$n"; [ -e "$p" ] || [ -L "$p" ] || { printf '%s' "$p"; return; }
  if [[ "$n" == *.* && "${n%.*}" != "" ]]; then base="${n%.*}"; ext=".${n##*.}"; else base="$n"; ext=""; fi
  while :; do
    if [ "$i" = 1 ]; then p="$d/$base (copy)$ext"; else p="$d/$base (copy $i)$ext"; fi
    [ -e "$p" ] || [ -L "$p" ] || { printf '%s' "$p"; return; }
    i=$((i + 1))
  done
}
inside() { case "$2/" in "$1"/*) return 0;; esac; return 1; }   # inside A B : is B inside A (or A itself)

transfer() {  # transfer copy|move DEST SRC...
  local mode="$1" dest="${2%/}" src name final tmp total=0 base=0 n=0 cnt idx=0 sz pid cur CM="${SNOW_FM_CONFLICT:-both}"
  shift 2
  [ "$mode" = move ] && JK=move || JK=create
  [ -d "$dest" ] && [ -w "$dest" ] || { err "destination is not a writable folder: $dest"; return; }
  dest=$(cd "$dest" && pwd -P)
  cnt=$#
  for src in "$@"; do sz=$(bytes "$src"); total=$((total + ${sz:-0})); done
  for src in "$@"; do
    idx=$((idx + 1)); src="${src%/}"; name="${src##*/}"
    if [ ! -e "$src" ] && [ ! -L "$src" ]; then err "not found: $name"; continue; fi
    if [ "$mode" = move ] && is_prot "$src"; then err "protected folder, cannot be moved: $name"; continue; fi
    if [ -d "$src" ] && [ ! -L "$src" ] && inside "$(cd "$src" && pwd -P)" "$dest"; then err "cannot put a folder into itself: $name"; continue; fi
    local sdir; sdir=$(cd "$(dirname "$src")" && pwd -P)
    if [ "$mode" = move ] && [ "$sdir" = "$dest" ]; then say "P	100	0	0	$idx/$cnt	$name (already here)"; continue; fi
    local cand="$dest/$name" repl=0
    if [ -e "$cand" ] || [ -L "$cand" ]; then
      if [ "$sdir" = "$dest" ] || [ "$CM" = both ]; then :
      elif [ "$CM" = skip ]; then say "P	100	0	0	$idx/$cnt	$name (skipped)"; continue
      else
        if inside "$cand" "$src"; then err "cannot replace a folder with something inside it: $name"; continue; fi
        repl=1
      fi
    fi
    final=$(unique "$dest" "$name")
    if [ "$mode" = move ] && [ "$(stat -c %d -- "$src" 2>/dev/null)" = "$(stat -c %d -- "$dest" 2>/dev/null)" ]; then
      if [ "$repl" = 1 ]; then gio trash -- "$cand" 2>/dev/null && final="$cand" || { err "could not move the old '$name' to the Trash"; continue; }; fi
      if mv -T -- "$src" "$final"; then OK=$((OK + 1)); jrec "$src" "$final"; else err "could not move: $name"; fi
      say "P	$((100 * idx / cnt))	0	0	$idx/$cnt	$name"; continue
    fi
    tmp="$dest/.fmpart-$$-$idx"; PART="$tmp"; rm -rf -- "$tmp"
    cp -r -P --preserve=mode,timestamps --reflink=auto -- "$src" "$tmp" 2>${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-cp.$$ &
    CHILD=$!
    while kill -0 "$CHILD" 2>/dev/null; do
      cur=$(bytes "$tmp"); cur=${cur:-0}
      local all=$((base + cur)) pct=0; [ "$total" -gt 0 ] && pct=$((100 * all / total)); [ "$pct" -gt 100 ] && pct=100
      say "P	$pct	$all	$total	$idx/$cnt	$name"
      sleep 0.3
    done
    wait "$CHILD"; local rc=$?; CHILD=""
    if [ "$rc" -ne 0 ]; then err "copy failed: $name ($(head -c 200 ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-cp.$$ | tr '\n' ' '))"; rm -rf -- "$tmp"; PART=""; continue; fi
    final=$(unique "$dest" "$name")
    if [ "$repl" = 1 ]; then
      if gio trash -- "$cand" 2>/dev/null; then final="$cand"; else err "could not move the old '$name' to the Trash"; rm -rf -- "$tmp"; PART=""; continue; fi
    fi
    if ! mv -T -- "$tmp" "$final"; then err "could not finish: $name"; rm -rf -- "$tmp"; PART=""; continue; fi
    PART=""
    if [ "$mode" = move ]; then
      sync -f -- "$final" 2>/dev/null || sync
      if [ -e "$final" ] || [ -L "$final" ]; then rm -rf -- "$src" || err "copied, but the original could not be removed: $name"; fi
    fi
    OK=$((OK + 1)); jrec "$([ "$mode" = move ] && echo "$src" || echo -)" "$final"; sz=$(bytes "$final"); base=$((base + ${sz:-0}))
    say "P	$([ "$total" -gt 0 ] && echo $((100 * base / total)) || echo 100)	$base	$total	$idx/$cnt	$name"
  done
  rm -f ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-cp.$$
}

sevenz() { command -v 7zz || command -v 7z || command -v 7za; }
extract_into() {  # extract_into ARCHIVE TMPDIR : 0 = ok
  local a="$1" t="$2" z; local l="${a,,}"
  case "$l" in
    *.zip) if command -v unzip >/dev/null 2>&1; then unzip -q -- "$a" -d "$t"; else z=$(sevenz) && "$z" x -y -o"$t" -- "$a" >/dev/null; fi;;
    *.7z|*.rar) z=$(sevenz) && "$z" x -y -o"$t" -- "$a" >/dev/null;;
    *.tar|*.tar.*|*.tgz|*.txz|*.tbz2|*.tbz|*.tzst) tar -xf "$a" -C "$t";;
    *.gz) gzip -dc -- "$a" > "$t/$(basename "${a%.*}")";;
    *.xz) xz -dc -- "$a" > "$t/$(basename "${a%.*}")";;
    *.bz2) bzip2 -dc -- "$a" > "$t/$(basename "${a%.*}")";;
    *.zst) zstd -dc -- "$a" > "$t/$(basename "${a%.*}")";;
    *) echo "unknown archive type" >&2; return 1;;
  esac
}
extract() {  # extract DEST ARCHIVE...
  local dest="${1%/}" a name base idx=0 cnt tmp final entries rc
  shift; cnt=$#
  [ -d "$dest" ] && [ -w "$dest" ] || { err "destination is not a writable folder: $dest"; return; }
  dest=$(cd "$dest" && pwd -P)
  for a in "$@"; do
    idx=$((idx + 1)); name="${a##*/}"
    [ -f "$a" ] || { err "not a file: $name"; continue; }
    base="$name"; for e in .tar.gz .tar.xz .tar.bz2 .tar.zst .tgz .txz .tbz2 .zip .7z .rar .tar .gz .xz .bz2 .zst; do case "${name,,}" in *"$e") base="${name:0:${#name}-${#e}}"; break;; esac; done
    [ -n "$base" ] || base="$name.out"
    tmp="$dest/.fmpart-$$-$idx"; PART="$tmp"; rm -rf -- "$tmp"; mkdir -- "$tmp" || { err "cannot write here"; PART=""; continue; }
    extract_into "$a" "$tmp" 2>${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-ex.$$ &
    CHILD=$!
    while kill -0 "$CHILD" 2>/dev/null; do say "P	0	0	0	$idx/$cnt	Extracting $name"; sleep 0.5; done
    wait "$CHILD"; rc=$?; CHILD=""
    if [ "$rc" -ne 0 ]; then err "extract failed: $name ($(head -c 200 ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-ex.$$ | tr '\n' ' '))"; rm -rf -- "$tmp"; PART=""; continue; fi
    mapfile -t entries < <(find "$tmp" -mindepth 1 -maxdepth 1)
    if [ "${#entries[@]}" -eq 1 ]; then final=$(unique "$dest" "${entries[0]##*/}"); mv -T -- "${entries[0]}" "$final" && rmdir "$tmp"
    else final=$(unique "$dest" "$base"); mv -T -- "$tmp" "$final"; fi
    if [ $? -eq 0 ]; then OK=$((OK + 1)); jrec - "$final"; JK=create; else err "could not finish: $name"; rm -rf -- "$tmp"; fi
    PART=""
    say "P	100	0	0	$idx/$cnt	$name"
  done
  rm -f ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-ex.$$
}

cmd="${1:-}"; shift || true
# ---- system clipboard (wl-clipboard). Copy / Cut also put the files on the system clipboard as text/uri-list, Paste also understands files copied in other programs.
has_wl() { command -v wl-copy >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; }
uri_of() { printf 'file://%s' "$(printf '%s' "$1" | jq -sRr '@uri' | sed 's|%2F|/|g')"; }
sys_set() { has_wl || return 0; local f; { for f in "$@"; do printf '%s\r\n' "$(uri_of "$f")"; done; } | wl-copy --type text/uri-list 2>/dev/null; return 0; }
sys_files() {  # prints MODE (copy|cut) and then one path per line, when the system clipboard holds files
  has_wl || return 1
  local types raw mode=copy u
  types=$(timeout 2 wl-paste --list-types 2>/dev/null) || return 1
  if grep -qx 'x-special/gnome-copied-files' <<<"$types"; then
    raw=$(timeout 2 wl-paste -t x-special/gnome-copied-files 2>/dev/null); mode=$(head -1 <<<"$raw"); raw=$(tail -n +2 <<<"$raw")
  elif grep -qx 'text/uri-list' <<<"$types"; then raw=$(timeout 2 wl-paste -t text/uri-list 2>/dev/null)
  else return 1; fi
  [ "$mode" = cut ] || mode=copy
  printf '%s\n' "$mode"
  while IFS= read -r u; do u=${u%$'\r'}; case "$u" in file://*) u=${u#file://}; u=${u#localhost}; printf '%b\n' "${u//%/\\x}";; esac; done <<<"$raw"
}
zipit() {  # zipit DEST SRC...   all SRC in the same folder; result DEST/NAME.zip
  local dest="${1%/}" src first parent base final tmp rc s names=()
  shift
  [ -d "$dest" ] && [ -w "$dest" ] || { err "destination is not a writable folder: $dest"; return; }
  first="${1%/}"; parent=$(dirname "$first")
  for s in "$@"; do
    s="${s%/}"; [ "$(dirname "$s")" = "$parent" ] || { err "all items must be in the same folder"; return; }
    [ -e "$s" ] || [ -L "$s" ] || { err "not found: ${s##*/}"; return; }
    names+=("${s##*/}")
  done
  if [ "$#" -eq 1 ]; then base="${first##*/}"; [ -d "$first" ] || base="${base%.*}"; else base="${parent##*/}"; fi
  [ -n "$base" ] || base=archive
  final=$(unique "$dest" "$base.zip")
  tmp="$dest/.fmpart-$$-zip.zip"; PART="$tmp"; rm -f -- "$tmp"
  say "P	0	0	0	1/1	${final##*/}"
  if command -v zip >/dev/null 2>&1; then ( cd "$parent" && exec zip -r -q -y "$tmp" -- "${names[@]}" ) 2>${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-zip.$$ &
  elif command -v 7zz >/dev/null 2>&1; then ( cd "$parent" && exec 7zz a -tzip -bso0 -bsp0 "$tmp" "${names[@]}" ) 2>${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-zip.$$ &
  elif command -v 7z >/dev/null 2>&1; then ( cd "$parent" && exec 7z a -tzip -bso0 -bsp0 "$tmp" "${names[@]}" ) 2>${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-zip.$$ &
  else err "no zip program (sudo apt install zip)"; PART=""; return; fi
  CHILD=$!; wait "$CHILD"; rc=$?; CHILD=""
  if [ "$rc" -ne 0 ] || [ ! -s "$tmp" ]; then err "zip failed ($(head -c 200 ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-zip.$$ 2>/dev/null | tr '\n' ' '))"; rm -f -- "$tmp"; PART=""; rm -f ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-zip.$$; return; fi
  rm -f ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-zip.$$
  final=$(unique "$dest" "$base.zip")
  if mv -T -- "$tmp" "$final"; then OK=$((OK + 1)); jrec - "$final"; JK=create; else err "could not finish the zip"; rm -f -- "$tmp"; fi
  PART=""
}
case "$cmd" in
  clip-set)
    mode="${1:-}"; shift || true
    [ "$mode" = copy ] || [ "$mode" = cut ] || { err "clip-set: copy or cut"; say "D	0	$ERR"; exit 1; }
    mkdir -p "$(dirname "$CLIP")"; { echo "$mode"; printf '%s\n' "$@"; } > "$CLIP"; OK=$#; sys_set "$@";;
  paste)
    dest="${1:-}"; paste_resolve
    if [ -z "$mode" ] || [ "${#files[@]}" -eq 0 ]; then err "nothing to paste"
    elif [ "$mode" = cut ]; then transfer move "$dest" "${files[@]}"; [ "$ERR" -eq 0 ] && rm -f "$CLIP"
    else transfer copy "$dest" "${files[@]}"; fi;;
  paste-conflicts) dest="${1:-}"; paste_resolve; [ "${#files[@]}" -gt 0 ] && list_conflicts "$dest" "${files[@]}"; exit 0;;
  conflicts) list_conflicts "$@"; exit 0;;
  undo) undo_last;;
  batchrename) batchrename "$@";;
  zip) zipit "$@";;
  copypath)
    if has_wl; then printf '%s' "${1:-}" | wl-copy 2>/dev/null && OK=1 || err "could not copy"; else err "wl-clipboard is not installed (sudo apt install wl-clipboard)"; fi;;
  extract) extract "$@";;
  copy|move) transfer "$cmd" "$@";;
  trash)
    for f in "$@"; do
      if is_prot "$f"; then err "protected folder, cannot be deleted: ${f##*/}"; continue; fi
      if gio trash -- "$f" 2>${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-tr.$$; then OK=$((OK + 1)); jrec "$f" -; JK=trash; else err "could not trash: ${f##*/} ($(head -c 150 ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-tr.$$ | tr '\n' ' '))"; fi
    done; rm -f ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-tr.$$;;
  rename)
    src="${1:-}"; new="${2:-}"
    if [ -z "$new" ] || [[ "$new" == */* ]] || [ "$new" = . ] || [ "$new" = .. ]; then err "bad name"
    elif [ ! -e "$src" ] && [ ! -L "$src" ]; then err "not found"
    elif is_prot "$src"; then err "protected folder, cannot be renamed"
    elif [ "$new" = "${src##*/}" ]; then OK=1
    elif [ -e "$(dirname "$src")/$new" ] || [ -L "$(dirname "$src")/$new" ]; then err "'$new' already exists"
    elif mv -T -- "$src" "$(dirname "$src")/$new"; then OK=1; jrec "$src" "$(dirname "$src")/$new"; JK=rename; else err "rename failed"; fi;;
  mkdir)
    d="${1:-}"; new="${2:-}"
    if [ -z "$new" ] || [[ "$new" == */* ]] || [ "$new" = . ] || [ "$new" = .. ]; then err "bad name"
    elif [ -e "$d/$new" ] || [ -L "$d/$new" ]; then err "'$new' already exists"
    elif mkdir -- "$d/$new"; then OK=1; jrec - "$d/$new"; JK=create; else err "could not create the folder"; fi;;
  mkfile)
    d="${1:-}"; new="${2:-}"
    if [ -z "$new" ] || [[ "$new" == */* ]] || [ "$new" = . ] || [ "$new" = .. ]; then err "bad name"
    elif [ -e "$d/$new" ] || [ -L "$d/$new" ]; then err "'$new' already exists"
    elif ( set -o noclobber; : > "$d/$new" ) 2>/dev/null; then OK=1; jrec - "$d/$new"; JK=create; else err "could not create the file"; fi;;
  rmrf)
    # permanent delete (Shift+Delete). Refuses system / home-level folders. No Trash, cannot be undone.
    for f in "$@"; do
      rp=$(realpath -m -- "$f" 2>/dev/null)
      case "$rp" in
        ""|/|"$HOME"|"$(dirname "$HOME")"|/home|/usr|/etc|/var|/bin|/boot|/lib|/lib32|/lib64|/sbin|/opt|/root|/run|/sys|/proc|/dev|/mnt|/media|/srv|/tmp)
          err "refused (protected folder): ${f##*/}"; continue;;
      esac
      if is_prot "$f"; then err "protected folder, cannot be deleted: ${f##*/}"; continue; fi
      if [ ! -e "$f" ] && [ ! -L "$f" ]; then err "not found: ${f##*/}"; continue; fi
      if rm -rf -- "$f" 2>/dev/null && [ ! -e "$f" ] && [ ! -L "$f" ]; then OK=$((OK + 1)); jrec "$f" -; JK=perm; else err "could not delete: ${f##*/}"; fi
    done;;
  *) err "unknown command: $cmd";;
esac
jflush
say "D	$OK	$ERR"
[ "$ERR" -eq 0 ]
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/filemanager/fm-open.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# fm-open.sh : "Open with ..." for the Snow file manager.
#   fm-open.sh list FILE            JSON {"apps":[{"id":"x.desktop","name":"..."}]}  programs that can open FILE (best matches first)
#   fm-open.sh all                  JSON {"apps":[...]}  EVERY installed program that has a menu entry (A-Z)
#   fm-open.sh default FILE         JSON {"id":"x.desktop","name":"Mousepad","mime":"text/plain"}  the program that opens this kind of file now
#   fm-open.sh setdefault APPID FILE  make APPID the default for the kind (mime type) of FILE. Stored by xdg in ~/.config/mimeapps.list
#                                   (a copy of the old file is kept once as mimeapps.list.snowfm-bak). Result {"ok":..,"msg":..}
#   fm-open.sh run APPID FILE...    start that program with the file(s)
DIRS=("$HOME/.local/share/applications" /usr/local/share/applications /usr/share/applications /var/lib/flatpak/exports/share/applications "$HOME/.local/share/flatpak/exports/share/applications")
ML="${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"
find_desktop() { local d; for d in "${DIRS[@]}"; do [ -f "$d/$1" ] && { printf '%s' "$d/$1"; return 0; }; done; return 1; }
mime_of() {
  local m
  m=$(gio info -a standard::content-type -- "$1" 2>/dev/null | sed -n 's/^ *standard::content-type: *//p')
  [ -n "$m" ] || m=$(xdg-mime query filetype "$1" 2>/dev/null)
  printf '%s' "$m"
}
cur_of() {   # current default program of a mime type: our own list first (it wins), else what xdg-mime says
  local v=""
  [ -f "$ML" ] && v=$(sed -n '/^\[Default Applications\]/,/^\[/{s/^'"$(printf '%s' "$1" | sed 's|[][\\.*^$/]|\\&|g')"'=//p}' "$ML" | head -n1 | cut -d';' -f1)
  [ -n "$v" ] || v=$(xdg-mime query default "$1" 2>/dev/null | head -n1)
  printf '%s' "$v"
}
app_name() { local df; df=$(find_desktop "$1") && grep -m1 '^Name=' "$df" | cut -d= -f2-; }
case "${1:-}" in
  list)
    f="${2:-}"
    command -v jq >/dev/null 2>&1 || { echo '{"apps":[]}'; exit 0; }
    mime=$(mime_of "$f")
    ids=$(gio mime "$mime" 2>/dev/null | sed -n 's/^[[:space:]]\+\([^[:space:]]\+\.desktop\)[[:space:]]*$/\1/p' | awk '!s[$0]++')
    if [ -z "$ids" ] && [ -n "$mime" ]; then   # nothing registered: every program that handles this kind of file (text/*, image/* ...)
      ids=$(find "${DIRS[@]}" -maxdepth 1 -name '*.desktop' 2>/dev/null | xargs -r grep -l "^MimeType=.*${mime%%/*}/" 2>/dev/null | sed 's|.*/||' | awk '!s[$0]++' | head -14)
    fi
    {
      while IFS= read -r id; do
        [ -n "$id" ] || continue
        df=$(find_desktop "$id") || continue
        grep -qi '^NoDisplay=true' "$df" && continue
        nm=$(grep -m1 '^Name=' "$df" | cut -d= -f2-)
        [ -n "$nm" ] && printf '%s\t%s\n' "$id" "$nm"
      done <<< "$ids"
    } | head -14 | jq -R -s -c '{apps: [split("\n")[] | select(length > 0) | split("\t") | {id: .[0], name: .[1]}]}';;
  all)
    command -v jq >/dev/null 2>&1 || { echo '{"apps":[]}'; exit 0; }
    ex=(); for d in "${DIRS[@]}"; do [ -d "$d" ] && ex+=("$d"); done
    [ ${#ex[@]} -gt 0 ] || { echo '{"apps":[]}'; exit 0; }
    find -L "${ex[@]}" -maxdepth 1 -name '*.desktop' -print0 2>/dev/null | xargs -0 -r awk '
      function emit() { if (id != "" && !nod && !hid && ex && name != "" && type == "Application") print id "\t" name }
      FNR == 1 { emit(); id = FILENAME; sub(".*/", "", id); name = ""; nod = 0; hid = 0; ex = 0; type = ""; inm = 0 }
      /^\[/ { inm = ($0 == "[Desktop Entry]"); next }
      inm && /^Name=/ && name == "" { name = substr($0, 6) }
      inm && /^NoDisplay=/ { if (tolower(substr($0, 11)) == "true") nod = 1 }
      inm && /^Hidden=/ { if (tolower(substr($0, 8)) == "true") hid = 1 }
      inm && /^Exec=/ { ex = 1 }
      inm && /^Type=/ { type = substr($0, 6) }
      END { emit() }' |
      awk -F'\t' '!s[$1]++' | sort -f -t$'\t' -k2,2 |
      jq -R -s -c '{apps: [split("\n")[] | select(length > 0) | split("\t") | {id: .[0], name: .[1]}]}';;
  default)
    f="${2:-}"; mime=$(mime_of "$f"); id=$(cur_of "$mime"); nm=""; [ -n "$id" ] && nm=$(app_name "$id")
    jq -n -c --arg id "$id" --arg n "$nm" --arg m "$mime" '{id:$id,name:$n,mime:$m}';;
  setdefault)
    id="${2:-}"; f="${3:-}"; mime=$(mime_of "$f")
    [ -n "$mime" ] || { echo '{"ok":false,"msg":"could not find out the kind of this file"}'; exit 0; }
    find_desktop "$id" >/dev/null || { echo '{"ok":false,"msg":"program not found"}'; exit 0; }
    [ -f "$ML" ] && [ ! -e "$ML.snowfm-bak" ] && cp -f -- "$ML" "$ML.snowfm-bak"
    xdg-mime default "$id" "$mime" 2>/dev/null
    if [ "$(cur_of "$mime")" = "$id" ]; then jq -n -c --arg m "Always opens with $(app_name "$id")" '{ok:true,msg:$m}'
    else echo '{"ok":false,"msg":"could not save the choice"}'; fi;;
  run)
    id="${2:-}"; shift 2 || exit 2
    df=$(find_desktop "$id") || { echo "unknown program: $id" >&2; exit 1; }
    setsid nohup gio launch "$df" "$@" >/dev/null 2>&1 </dev/null &;;
  *) echo "usage: fm-open.sh list FILE | all | default FILE | setdefault APPID FILE | run APPID FILE..."; exit 2;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/filemanager/fm-side.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# fm-side.sh : side pane data of the Snow file manager.
#   fm-side.sh list            JSON: {"places":[{"name","path","icon"}],"pins":[{"name","path"}]}  (only folders that exist)
#   fm-side.sh pin PATH        add a pinned folder          fm-side.sh unpin PATH     remove it
# Pins are kept in ~/.config/snow/state/fm-pins (one path per line). Nothing else is touched.
PINS="${SNOW_FM_PINS:-$HOME/.config/snow/state/fm-pins}"
case "${1:-list}" in
  pin)
    p="${2:-}"; [ -d "$p" ] || { echo "not a folder"; exit 1; }
    p=$(cd "$p" && pwd -P); mkdir -p "$(dirname "$PINS")"; touch "$PINS"
    grep -qxF -- "$p" "$PINS" || printf '%s\n' "$p" >> "$PINS";;
  unpin)
    p="${2:-}"; [ -f "$PINS" ] || exit 0
    t=$(mktemp) && grep -vxF -- "$p" "$PINS" > "$t"; cat "$t" > "$PINS"; rm -f "$t";;
  list)
    command -v jq >/dev/null 2>&1 || { echo '{"places":[],"pins":[]}'; exit 0; }
    # free space of the system drive (shown under "Root"): total and available bytes
    read -r RT RA < <(timeout 3 df -B1 --output=size,avail / 2>/dev/null | tail -n 1)
    case "$RT" in ''|*[!0-9]*) RT=0 ;; esac; case "$RA" in ''|*[!0-9]*) RA=0 ;; esac
    {
      printf 'Home\t%s\thome\n' "$HOME"
      d=$(xdg-user-dir DESKTOP 2>/dev/null); [ -n "$d" ] || d="$HOME/Desktop"
      [ -d "$d" ] && [ "$d" != "$HOME" ] && printf 'Desktop\t%s\tdesktop\n' "$d"
      for spec in "Documents docs" "Downloads download" "Pictures pictures" "Music music" "Videos videos"; do
        set -- $spec; d="$HOME/$1"; mkdir -p -- "$d" 2>/dev/null; [ -d "$d" ] && printf '%s\t%s\t%s\n' "$1" "$d" "$2"
      done
      printf 'Trash\ttrash:///\ttrash\n'
      printf 'Root\t/\troot\n'
    } | jq -R -s --argjson t "${RT:-0}" --argjson a "${RA:-0}" '[split("\n")[] | select(length>0) | split("\t") | {name:.[0], path:.[1], icon:.[2]}] | map(if .icon == "root" then . + {total:$t, avail:$a} else . end)' > ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-pl.$$
    if [ -f "$PINS" ]; then
      while IFS= read -r l; do [ -d "$l" ] && printf '%s\t%s\n' "${l##*/}" "$l"; done < "$PINS" |
        jq -R -s '[split("\n")[] | select(length>0) | split("\t") | {name:.[0], path:.[1]}]' > ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-pn.$$
    else echo '[]' > ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-pn.$$; fi
    jq -n --slurpfile a ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-pl.$$ --slurpfile b ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-pn.$$ '{places:$a[0], pins:$b[0]}'
    rm -f ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-pl.$$ ${XDG_RUNTIME_DIR:-/tmp}/.snow-fm-pn.$$;;
  *) echo "usage: fm-side.sh list|pin PATH|unpin PATH"; exit 2;;
esac
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/filemanager/fm-trash.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# fm-trash.sh : the Trash of the Snow file manager. Reads the FreeDesktop trash of your home AND of every mounted drive
# (~/.local/share/Trash, <drive>/.Trash-UID, <drive>/.Trash/UID), so files deleted from another drive show up too.
#   fm-trash.sh list            JSON like fm-ls.sh: {"path":"trash:///","ok":true,"items":[{"name","dir","size","mtime","tid","orig"}]}  (mtime = deletion time)
#   fm-trash.sh restore ID...   put back to the original place (a free name "x (copy)" if it is taken; missing folders are created)
#   fm-trash.sh purge ID...     delete these items for good          fm-trash.sh empty     delete everything in every trash
# ID = the full path of the item inside its trash "files" folder (the "tid" of the list). Only paths inside a real trash folder are accepted.
# Output of restore / purge / empty:  E<TAB>message  and  D<TAB>ok<TAB>errors   (same as fm-op.sh)
UIDN=$(id -u)
HOMETRASH="${SNOW_FM_TRASH_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/Trash}"
MOUNTS="${SNOW_FM_MOUNTS:-/proc/self/mounts}"
OK=0; ERR=0
err() { ERR=$((ERR + 1)); printf 'E\t%s\n' "$*"; }
dirs() {  # "TRASHDIR<TAB>TOPDIR" per line (TOPDIR empty = home trash)
  [ -d "$HOMETRASH/files" ] && printf '%s\t\n' "$HOMETRASH"
  while read -r _ mp fs _; do
    case "$fs" in proc|sysfs|tmpfs|devtmpfs|devpts|cgroup*|securityfs|debugfs|tracefs|configfs|fusectl|mqueue|hugetlbfs|pstore|bpf|autofs|overlay|squashfs|efivarfs|binfmt_misc|ramfs|nsfs) continue;; esac
    mp=$(printf '%b' "${mp//\\040/ }")
    for t in "$mp/.Trash/$UIDN" "$mp/.Trash-$UIDN"; do [ -d "$t/files" ] && [ ! -L "$t" ] && printf '%s\t%s\n' "$t" "$mp"; done
  done < "$MOUNTS" | sort -u
}
urldec() { printf '%b' "${1//%/\\x}"; }
info_of() { local id="$1"; printf '%s' "${id%/files/*}/info/${id##*/}.trashinfo"; }
orig_of() {  # orig_of ID TOP
  local info p; info=$(info_of "$1"); [ -f "$info" ] || { printf '%s' "${1##*/}"; return; }
  p=$(sed -n 's/^Path=//p' "$info" | head -1); p=$(urldec "$p")
  case "$p" in /*) printf '%s' "$p";; *) printf '%s/%s' "${2%/}" "$p";; esac
}
valid_id() {  # valid_id ID : echoes TOP of its trash if the id is inside a real trash
  local id="$1" t top
  case "$id" in *"/../"*|*"/..") return 1;; esac
  while IFS=$'\t' read -r t top; do
    case "$id" in "$t"/files/?*) [ -e "$id" ] || [ -L "$id" ] || return 1; printf '%s' "$top"; return 0;; esac
  done < <(dirs)
  return 1
}
unique() {
  local d="${1%/}" n="$2" base ext p i=1
  p="$d/$n"; [ -e "$p" ] || [ -L "$p" ] || { printf '%s' "$p"; return; }
  if [[ "$n" == *.* && "${n%.*}" != "" ]]; then base="${n%.*}"; ext=".${n##*.}"; else base="$n"; ext=""; fi
  while :; do
    if [ "$i" = 1 ]; then p="$d/$base (copy)$ext"; else p="$d/$base (copy $i)$ext"; fi
    [ -e "$p" ] || [ -L "$p" ] || { printf '%s' "$p"; return; }
    i=$((i + 1))
  done
}
cmd="${1:-list}"; shift || true
case "$cmd" in
  list)
    command -v jq >/dev/null 2>&1 || { echo '{"path":"trash:///","ok":false,"error":"jq is not installed","items":[]}'; exit 0; }
    while IFS=$'\t' read -r t top; do
      for f in "$t/files"/* "$t/files"/.[!.]* "$t/files"/..?*; do
        [ -e "$f" ] || [ -L "$f" ] || continue
        o=$(orig_of "$f" "$top"); nm="${o##*/}"; [ -n "$nm" ] || nm="${f##*/}"
        dd=$(sed -n 's/^DeletionDate=//p' "$(info_of "$f")" 2>/dev/null | head -1); ts=0; [ -n "$dd" ] && ts=$(date -d "$dd" +%s 2>/dev/null || echo 0)
        isd=0; [ -d "$f" ] && [ ! -L "$f" ] && isd=1
        sz=$(stat -c %s -- "$f" 2>/dev/null || echo 0)
        printf '%s\037%s\037%s\037%s\037%s\037%s\036' "${nm//[$'\037\036']/ }" "$isd" "$sz" "$ts" "$f" "${o//[$'\037\036']/ }"
      done
    done < <(dirs) | jq -R -s '{ path: "trash:///", ok: true, items: ( split("\u001e") | map(select(length > 0) | split("\u001f") | select(length == 6)
        | { name: .[0], dir: (.[1] == "1"), link: false, hidden: false, size: (.[2] | tonumber? // 0), mtime: (.[3] | tonumber? // 0), tid: .[4], orig: .[5] })
        | sort_by(-.mtime) ) }'
    exit 0;;
  restore)
    for id in "$@"; do
      top=$(valid_id "$id") || { err "not in a trash folder: ${id##*/}"; continue; }
      o=$(orig_of "$id" "$top"); dir=$(dirname "$o"); nm="${o##*/}"
      mkdir -p -- "$dir" 2>/dev/null || { err "cannot create $dir"; continue; }
      final=$(unique "$dir" "$nm")
      if mv -T -- "$id" "$final"; then rm -f -- "$(info_of "$id")"; OK=$((OK + 1)); else err "could not restore: $nm"; fi
    done;;
  purge)
    for id in "$@"; do
      valid_id "$id" >/dev/null || { err "not in a trash folder: ${id##*/}"; continue; }
      if rm -rf -- "$id"; then rm -f -- "$(info_of "$id")"; OK=$((OK + 1)); else err "could not delete: ${id##*/}"; fi
    done;;
  empty)
    while IFS=$'\t' read -r t top; do
      for f in "$t/files"/* "$t/files"/.[!.]* "$t/files"/..?*; do
        [ -e "$f" ] || [ -L "$f" ] || continue
        if rm -rf -- "$f"; then OK=$((OK + 1)); else err "could not delete: ${f##*/}"; fi
      done
      find "$t/info" -mindepth 1 -maxdepth 1 -name '*.trashinfo' -delete 2>/dev/null; rm -f "$t/directorysizes"
    done < <(dirs);;
  *) err "unknown command: $cmd";;
esac
printf 'D\t%s\t%s\n' "$OK" "$ERR"
[ "$ERR" -eq 0 ]
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/filemanager/fm.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/usr/bin/env bash
# fm.sh [FOLDER] : open a NEW Snow file manager window (own Quickshell instance, config ~/.config/snow/fm). Every call opens another window.
# FOLDER (optional) = start folder (used by "Open in new window").
DIR="$HOME/.config/snow/fm"
BIN=$(command -v qs || command -v quickshell) || { echo "[PROBLEM] quickshell is not installed" >&2; exit 1; }
START="${1:-}"; [ -d "$START" ] || START=""
mkdir -p "$HOME/.cache/snow"
FM_START="$START" nohup "$BIN" -p "$DIR" > "$HOME/.cache/snow/fm.log" 2>&1 </dev/null &
SNOW_FILE_END_4b7d
;;
"u/.config/snow/fm/FileIcon.qml")
cat <<'SNOW_FILE_END_4b7d'
import QtQuick

// Snow file manager: file icon = a round badge (soft gradient, thin light rim, gloss, shadow) with the file-type symbol of our icon font in it.
// Same style as FolderIcon.qml. Sharp at every size. No image files.
Item {
    id: root
    property real sz: 48
    property color tone: "#64748b"
    property string glyph: ""
    property string iconFont: ""
    property string label: ""        // not shown (kept so the file list can pass it)
    property bool dark: false        // dark badge with a green symbol (scripts)
    property bool zip: false         // archives: draw a zipper instead of a font symbol
    property string svgSrc: ""      // ~/.config/snow/icons/file-<kind>.svg (universal icon folder); if it is missing the drawn badge below is used
    readonly property bool useSvg: svg.status === Image.Ready
    width: sz
    height: sz

    Image {
        id: svg
        anchors.fill: parent
        source: root.svgSrc
        sourceSize.width: Math.ceil(root.sz * 2)
        sourceSize.height: Math.ceil(root.sz * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: false      // small files, cached: shows at once (no flash while scrolling / refreshing)
        cache: true
        visible: status === Image.Ready
    }
    Item {
        visible: !root.useSvg && svg.status !== Image.Loading
        anchors.fill: parent

    Rectangle { x: root.sz * 0.04; y: root.sz * 0.10; width: root.sz * 0.92; height: width; radius: width / 2; color: "#000000"; opacity: 0.25 }
    Rectangle {
        x: root.sz * 0.04; y: root.sz * 0.04; width: root.sz * 0.92; height: width; radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.dark ? "#3d4354" : Qt.lighter(root.tone, 1.22) }
            GradientStop { position: 1.0; color: root.dark ? "#242836" : Qt.darker(root.tone, 1.12) }
        }
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.28)
    }
    // gloss on the upper half
    Rectangle { x: root.sz * 0.20; y: root.sz * 0.09; width: root.sz * 0.60; height: root.sz * 0.30; radius: height / 2; color: "#ffffff"; opacity: 0.14 }
    // zipper: rail + interlocking teeth, slider and pull tab (all plain rectangles)
    Item {
        visible: root.zip
        anchors.fill: parent
        readonly property color hole: Qt.darker(root.tone, 1.18)
        Rectangle { x: root.sz * 0.487; y: root.sz * 0.12; width: root.sz * 0.026; height: root.sz * 0.50; radius: width / 2; color: "#ffffff"; opacity: 0.6 }
        Repeater {
            model: 8
            delegate: Rectangle {
                x: root.sz * (index % 2 === 0 ? 0.365 : 0.505)
                y: root.sz * (0.12 + index * 0.058)
                width: root.sz * 0.13; height: root.sz * 0.044; radius: root.sz * 0.014
                color: "#ffffff"
            }
        }
        Rectangle { x: root.sz * 0.38; y: root.sz * 0.55; width: root.sz * 0.24; height: root.sz * 0.17; radius: root.sz * 0.045; color: "#ffffff" }
        Rectangle { x: root.sz * 0.47; y: root.sz * 0.595; width: root.sz * 0.06; height: root.sz * 0.075; radius: root.sz * 0.016; color: parent.hole }
        Rectangle { x: root.sz * 0.42; y: root.sz * 0.70; width: root.sz * 0.16; height: root.sz * 0.19; radius: root.sz * 0.045; color: "#ffffff" }
        Rectangle { x: root.sz * 0.465; y: root.sz * 0.745; width: root.sz * 0.07; height: root.sz * 0.10; radius: root.sz * 0.02; color: parent.hole }
    }
    Text {
        visible: !root.zip
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.sz * 0.005
        text: root.glyph
        font.family: root.iconFont
        renderType: Text.NativeRendering
        font.pixelSize: root.sz * 0.70
        font.variableAxes: ({ "FILL": 1 })
        color: root.dark ? "#22c55e" : "#ffffff"
    }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/fm/FolderIcon.qml")
cat <<'SNOW_FILE_END_4b7d'
import QtQuick

// Snow file manager: folder icon in the flat, soft style of the Colloid icon theme - a tab on the back panel, a pale sheet of paper peeking out,
// a lighter front panel (top-to-bottom shading, thin highlight line on its top edge) and a small soft shadow. Drawn only with plain rectangles:
// sharp at every size, follows the accent colour, needs no image files.
Item {
    id: root
    property real sz: 48
    property color tone: "#7aa2f7"
    property bool dim: false
    property string iconFont: ""     // not used any more (kept so old code keeps working)
    property string glyph: ""           // optional symbol (icon font) drawn in the middle of the front panel (Documents, Downloads, ...)
    property string svgSrc: ""       // optional: if this file exists (~/.config/snow/fm/folder.svg) it is used instead of the drawn folder
    readonly property bool useSvg: svg.status === Image.Ready
    readonly property color back: Qt.darker(tone, 1.22)
    width: sz
    height: sz
    opacity: dim ? 0.55 : 1

    Image {
        id: svg
        anchors.fill: parent
        source: root.svgSrc
        sourceSize.width: root.sz * 2
        sourceSize.height: root.sz * 2
        fillMode: Image.PreserveAspectFit
        asynchronous: false
        cache: true
        visible: status === Image.Ready
    }

    Item {
        anchors.fill: parent
        Item {
            visible: !root.useSvg && svg.status !== Image.Loading
            anchors.fill: parent
        // soft shadow
        Rectangle { x: root.sz * 0.12; y: root.sz * 0.82; width: root.sz * 0.76; height: root.sz * 0.06; radius: root.sz * 0.03; color: "#000000"; opacity: 0.20 }
        Rectangle { x: root.sz * 0.08; y: root.sz * 0.84; width: root.sz * 0.84; height: root.sz * 0.04; radius: root.sz * 0.02; color: "#000000"; opacity: 0.12 }
        // back panel with the tab
        Rectangle { x: root.sz * 0.06; y: root.sz * 0.20; width: root.sz * 0.88; height: root.sz * 0.62; radius: root.sz * 0.08; color: root.back }
        Rectangle { x: root.sz * 0.06; y: root.sz * 0.12; width: root.sz * 0.42; height: root.sz * 0.20; radius: root.sz * 0.06; color: root.back }
        // sheet of paper
        Rectangle { x: root.sz * 0.13; y: root.sz * 0.26; width: root.sz * 0.74; height: root.sz * 0.16; radius: root.sz * 0.03; color: "#ffffff"; opacity: 0.55 }
        // front panel
        Rectangle {
            x: root.sz * 0.06; y: root.sz * 0.34; width: root.sz * 0.88; height: root.sz * 0.50; radius: root.sz * 0.08
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(root.tone, 1.22) }
                GradientStop { position: 1.0; color: root.tone }
            }
        }
        // thin highlight on the top edge of the front panel
        Rectangle { x: root.sz * 0.09; y: root.sz * 0.35; width: root.sz * 0.82; height: Math.max(1, root.sz * 0.02); radius: root.sz * 0.01; color: "#ffffff"; opacity: 0.45 }
        }
        // symbol in the middle of the front panel (a little dark under it = embossed look)
        Text {
            visible: !root.useSvg && svg.status !== Image.Loading && root.glyph !== "" && root.iconFont !== ""
            x: (root.sz - width) / 2 + root.sz * 0.012
            y: root.sz * 0.59 - height / 2 + root.sz * 0.014
            text: root.glyph
            font.family: root.iconFont
            renderType: Text.NativeRendering
            font.pixelSize: root.sz * 0.34
            font.variableAxes: ({ "FILL": 1 })
            color: "#000000"
            opacity: 0.18
        }
        Text {
            visible: !root.useSvg && svg.status !== Image.Loading && root.glyph !== "" && root.iconFont !== ""
            x: (root.sz - width) / 2
            y: root.sz * (root.useSvg ? 0.655 : 0.59) - height / 2
            text: root.glyph
            font.family: root.iconFont
            renderType: Text.NativeRendering
            font.pixelSize: root.sz * (root.useSvg ? 0.30 : 0.34)
            font.variableAxes: ({ "FILL": 1 })
            color: root.useSvg ? Qt.darker(root.tone, 1.05) : "#ffffff"
            opacity: root.useSvg ? 1.0 : 0.92
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/fm/Theme.qml")
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
"u/.config/snow/fm/shell.qml")
cat <<'SNOW_FILE_END_4b7d'
//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick

// Snow file manager (FM2). Own Quickshell instance: qs -p ~/.config/snow/fm   (started by ~/.config/snow/bin/filemanager/fm.sh)
// STEP 1: window, folder list (fm-ls.sh), back / forward / up / home, editable path bar, hidden files toggle, open on double-click.
// STEP 2: views (icon / list / details: Ctrl+1 / Ctrl+2 / Ctrl+3), multi-select (Ctrl-click, Shift-click, Ctrl+A, Shift+arrows), file-type icons.
// STEP 3: copy / cut / paste (Ctrl+C / X / V, shared by all windows), delete = Trash (Delete), rename (F2), new folder (Ctrl+Shift+N), progress bar + Cancel.
//         All file work is done by ~/.config/snow/bin/filemanager/fm-op.sh in a separate process; this window only shows it.
// STEP 4: right-click menu (rows and empty space): Open, Open in terminal, Extract here, Copy/Cut/Paste, Rename, Trash, New folder, Terminal here.
// STEP 5: side pane (Places, Pinned folders; pin / unpin from the right-click menu). Right-click is now decided by ONE overlay (rows + empty space), files also get "Open terminal here".
// STEP 6: drives in the side pane ("Devices": click = mount + open, eject button, right-click Mount / Unmount / Eject), refreshed every 4 s by fm-dev.sh.
// STEP 7a: "Move to Trash?" confirm dialog for every delete, small toast notification at the bottom (copied / cut / pasted / trashed / errors).
// STEP 7b: ONE view button (Grid / List / Details + icon size), no action bar (everything is in the right-click menu), New file, Trash view
//          (trash:/// = home trash + every drive, Restore / Delete permanently / Empty Trash), pinned folders show a folder icon.
// STEP 34: Enter that closes a pop-up (rename, new folder, confirm, path/search box, Open with) no longer opens the file under it (0.4 s guard dlgT); key is Super+E (installer moves our Super+Shift+E bind).
// STEP 37: other pane: a click on its empty space makes it the active pane; X button in both pane titles (closes that pane); empty-space click clears the selection but the file keeps a thin focus border, Space selects it (Ctrl+Space = add / remove).
// STEP 36: each pane keeps its OWN view mode, icon size, sorting and hidden-files setting (swapped with the pane).
// STEP 35: width dragging (side pane, Details columns) removed; TWO PANES (Ctrl+D or the button in the top bar): each pane has a path title, the side pane and the top bar work on the active pane; Ctrl+Left / Ctrl+Right or a click choose the pane, Ctrl+Shift+C / Ctrl+Shift+X copy / move to the other pane.
// STEP 33: Tab / Shift+Tab move the keyboard focus between the list, the side pane and the top bar (arrows + Enter work in the side pane and top bar, Esc goes back to the list); permissions grid removed from Properties;
// STEP 32: tabs (Ctrl+T new tab, Ctrl+W close, Ctrl+Tab next, right-click a folder -> Open in new tab; the tab strip shows when there is more than one tab);
// STEP 31: files dragged from other programs (browser, other file manager) can be dropped into this window: on a folder, on a side pane entry, or on the empty list = into the open folder (copy);
// STEP 30: free space (status bar + bar under every mounted drive), Properties shows a Read / Write / Run tick grid for owner / group / everyone else;
// STEP 29: Ctrl + mouse wheel zoom is caught by the overlay above the list (the Flickable swallowed it before);
// STEP 28: Ctrl + mouse wheel (and Ctrl + / Ctrl -) change the icon size in the grid view;
// STEP 27: two more icon sizes in the grid view: Extra large (112 px) and Huge (160 px);
// STEP 26: archive files (zip, rar, tar, gz, xz, 7z ...) get a drawn zipper in a green badge;
// STEP 25: folder icon redrawn in the flat Colloid style (back panel + tab, paper, shaded front panel, highlight, shadow); zip / rar / tar / 7z ... files use the zip-with-zipper symbol;
// STEP 24: drag files out of the window into other programs (browser upload, other file manager): when the mouse leaves the window while dragging, a real drag-and-drop with text/uri-list (copy) starts;
// STEP 23: the choose-a-file window has a slim side pane (Home, Downloads, Pictures + external drives; no Pinned, no resize handle);
// STEP 22: choose-a-file window (pick mode) is small, floating (fixed size), no side pane / right-click / file operations, with Cancel and Select buttons; details view hides the Modified, then Size, then Type column when the list gets narrow (Name stays);
// STEP 21: "Open with" menu has "Other programs ..." (window with ALL installed programs, search, and a tick "Always use this program for these files"); the by-file-kind default menu of step 20 is gone;
// STEP 20: right-click the Home button = menu: own folder icon (.svg, picked in a small file manager window), reset, default programs by file kind (text / images / videos / music / PDF); folder.svg is optional (no warnings without it);
// STEP 19: side pane width can be dragged (double click the handle = back to normal), details columns (Type / Size / Modified) can be dragged wider/narrower, both remembered; below 620 px window width the side pane hides itself;
// STEP 18: search can include sub folders (magnifier icon in the search box, results show the path inside the folder; right-click "Open containing folder");
// STEP 17: click on empty list space closes the path box; right-click menu has 'Sort by' sub menu (Name / Time / File type / Size, Ascending / Descending), no 'Delete permanently' in the menu (Shift+Delete stays);
//          Details view has a Type column; type-to-jump cycles with the same letter.
// STEP 16: bigger symbols in the file badges, optional folder.svg (~/.config/snow/fm/folder.svg replaces the drawn folder), scroll bars in the three side-pane boxes.
// STEP 15: icons restyled: folder = our icon font's filled folder with outline + bevel + shadow (embossed), files = round badges with the type symbol (no extension text).
// STEP 14: file icons drawn like the folder icon (FileIcon.qml: page + symbol + extension badge; video, audio, picture, PDF, documents, sheets, slides, text, code, scripts (.sh dark), archives, packages, disk images, fonts).
// STEP 13: folders are drawn as embossed folder icons (FolderIcon.qml: back plate, paper, lighter front, highlight, shadow) in Grid / List / Details.
// STEP 12: scroll bar for the file list (drag it, or click the track).
// STEP 11: Split view removed (Ctrl+N / Super+Shift+E open a new window); the toolbar refresh button is now a close (X) button (refresh = right-click > Refresh).
// STEP 10: name conflict dialog (Replace / Skip / Keep both), Ctrl+Z undo, Paste into folder, batch rename (select several, F2), type a letter to jump to a name, Split view (Ctrl+Shift+D).
// STEP 9: image thumbnails (Grid / List / Details), drag and drop (rows -> folder rows / side pane / Trash; Ctrl = copy), Open with ..., Compress to zip, Copy path,
//         system clipboard (wl-clipboard) for Copy / Cut / Paste with other programs.
// STEP 8b: side pane = three separate boxes (Places / Devices / Pinned), own icon for every place, Trash = recycling icon, drives = storage icon,
//          Documents / Downloads / Pictures / Music / Videos can not be deleted, renamed or moved.
// STEP 8a: view button (click = Grid > List > Details, right-click = menu), last view / icon size / sort remembered (~/.config/snow/state/fm-state.json), sorting (Details header or view menu), search (Ctrl+F),
//          Shift+Delete = permanent delete, Open in new window (Ctrl+N), softer look.
// STEP 7c: path bar = clickable folder buttons (click on the empty part = editable path, Ctrl+L too), Properties window (Alt+Enter), the folder refreshes by itself
//          when files appear / disappear, status line shows name / size / type / date of the selection.
// STEP 8a: view button (click = rotate Grid > List > Details, right-click = menu), last view / icon size / sort remembered (~/.config/snow/state/fm-state.json),
//          sorting (Name / Size / Date / Type, click the Details header), search box (Ctrl+F), Shift+Delete = delete permanently,
//          Open in new window (Ctrl+N), nicer rows (accent bar, zebra, borders).
// Colours: Theme.qml only (theme.json). Nothing here changes any file.
ShellRoot {
    id: app

    property string cwd: ""
    property var items: []
    property int cur: -1
    property int anchor: -1
    property var selMap: ({})
    property int selCount: 0
    property string view: "details"   // icon | list | details
    readonly property int cols: Math.max(1, Math.floor(grid.width / cellW))
    property bool showHidden: false
    property string err: ""
    property var hist: []
    property var tabs: [{ p: "", h: [], i: -1 }]
    property int tabIdx: 0
    property string zone: "list"
    property double dlgT: 0
    // ---- two panes: the ACTIVE pane is the normal state above (cwd, items, hist ...); the other pane lives in pas
    property bool dual: false
    property int act2: 0
    property double swapT: 0
    property string pasPending: ""
    property string pasSig: ""
    property var pas: ({ cwd: "", allItems: [], items: [], hist: [], hidx: -1, err: "", view: "details", isz: "m", hidden: false, sortKey: "name", sortDesc: false })
    readonly property bool dualOn: dual && pickMode === "" && win.width >= 760
    readonly property real paneW: dualOn ? Math.floor((win.width - contentX - 12 - 8) / 2) : win.width - contentX - 12
    readonly property real paneTop: dualOn ? 36 : 0
    onDualOnChanged: { if (dualOn && pas.cwd !== "") pasLoad() }
    property bool zoneShow: false
    property int barIdx: 4
    property string sideSel: ""
    readonly property real contentTop: 12 + 48 + 8 + (tabs.length > 1 && pickMode === "" ? 40 : 0)
    property int hidx: -1
    property string pending: ""
    property bool opBusy: false
    property int opPct: 0
    property string opText: ""
    property string opMsg: ""
    property string opErr: ""
    property int opOk: 0
    property string dlgMode: ""      // "" | rename | mkdir
    property bool opIndet: false
    property bool pathEdit: false
    property var allItems: []
    property string filterText: ""
    property bool searchDeep: false
    readonly property string pickMode: Quickshell.env("FM_PICK") ? Quickshell.env("FM_PICK") : ""
    readonly property string pickOut: Quickshell.env("FM_PICK_OUT") ? Quickshell.env("FM_PICK_OUT") : ""
    readonly property string pickTitle: Quickshell.env("FM_PICK_TITLE") ? Quickshell.env("FM_PICK_TITLE") : ""   // FM_PICK=dir : "choose a folder" window (used by the download manager)
    property bool svgOn: false
    property var iconThemes: []                       // names from icon-theme.sh list ("snow" = our own icons)
    property string iconThemeCur: "snow"
    property int iconRev: 0                           // +1 after every icon change: makes the svg images load again
    readonly property string revSuffix: iconRev > 0 ? "#" + iconRev : ""
    readonly property string themeScript: home + "/.config/snow/bin/theme/icon-theme.sh"
    readonly property string iconsDir: "file://" + home + "/.config/snow/icons"     // universal icon folder (icons-gen.sh)
    readonly property string folderSvg: svgOn ? "file://" + home + "/.config/snow/fm/folder.svg" + revSuffix : iconsDir + "/folder.svg" + revSuffix
    readonly property string iconScript: home + "/.config/snow/bin/filemanager/fm-icon.sh"
    property bool apOpen: false
    property bool apAlways: false
    property string apFile: ""
    property string apName: ""
    property string apExtLabel: ""
    property string apCurrent: ""
    property string apFilter: ""
    property var apAll: []
    property var apShown: []
    property real homeMX: 0
    property real homeMY: 0
    property bool deepActive: false
    property bool deepBusy: false
    property bool deepTrunc: false
    property string sortKey: "name"      // name | size | date | type
    property bool sortDesc: false
    readonly property string statePath: home + "/.config/snow/state/fm-state.json"
    readonly property string binDir: home + "/.config/snow/bin"
    property var propRows: []
    property string freeText: ""
    property string dirSig: ""
    property var keepNames: []
    property string keepCur: ""
    property real keepY: 0
    readonly property string openScript: home + "/.config/snow/bin/filemanager/fm-open.sh"
    readonly property string infoScript: home + "/.config/snow/bin/filemanager/fm-info.sh"
    readonly property var crumbs: crumbList()
    property string isz: "m"          // grid icon size: s | m | l | xl | xxl
    property string confirmKind: "trash"   // trash | purge | empty
    readonly property bool inTrash: cwd === "trash:///"
    readonly property string trashScript: home + "/.config/snow/bin/filemanager/fm-trash.sh"
    readonly property int cellW: isz === "s" ? 96 : isz === "l" ? 152 : isz === "xl" ? 196 : isz === "xxl" ? 248 : 116
    readonly property int iconPx: isz === "s" ? 36 : isz === "l" ? 80 : isz === "xl" ? 112 : isz === "xxl" ? 160 : 48
    readonly property int cellH: iconPx + 62
    property string opKind: ""
    property var confirmPaths: []
    property string toast: ""
    property bool toastBad: false
    property bool toastShow: false
    property var places: []
    property var pins: []
    property var sideModel: []
    property var sidePlaces: []
    // drag and drop (inside this window): rows -> folder row / side pane entry
    property bool dragPressed: false
    property bool dragging: false
    property bool dragExt: false
    property string dragUriText: ""
    property real dragX: 0
    property real dragY: 0
    property real dragSX: 0
    property real dragSY: 0
    property int dragIdx: -1
    property var dragPaths: []
    property bool dragCtrl: false
    property bool justDragged: false
    property string dropHint: ""
    property var owPaths: []
    property var subModel: []
    property real subY: 0
    onMenuOpenChanged: subModel = []
    // name conflicts (Replace / Skip / Keep both), undo message, type-to-jump
    property string conflictMode: ""
    property var pendingArgs: []
    property string pendingLabel: ""
    property var conflictNames: []
    property string opU: ""
    property string typeBuf: ""
    property var sideDevs: []
    property var sidePins: []
    property var devs: []
    property string devText: ""
    property string devWork: ""
    property bool devGo: false
    property string devMount: ""
    readonly property string devScript: home + "/.config/snow/bin/filemanager/fm-dev.sh"
    readonly property string sideScript: home + "/.config/snow/bin/filemanager/fm-side.sh"
    property int sideW: 214
    property int wType: 72      // widest word "Folder" + a little air on both sides
    property int wSize: 76      // widest text "999 MB" + air
    property int wDate: 130     // "04/10/2026 19:24" + air
    readonly property bool sideShown: pickMode !== "" || win.width >= 620
    readonly property int contentX: sideShown ? sideW + 22 : 12
    readonly property real detW: card.width - 16
    readonly property int colMode: (detW - 172 >= wType + wSize + wDate + 40) ? 3 : (detW - 172 >= wType + wSize + 30) ? 2 : (detW - 172 >= wType + 20) ? 1 : 0
    readonly property int colsW: colMode === 3 ? wType + wSize + wDate + 40 : colMode === 2 ? wType + wSize + 30 : colMode === 1 ? wType + 20 : 12
    function colShown(k) { return k === "type" ? colMode >= 1 : k === "size" ? colMode >= 2 : colMode >= 3 }
    function colW(k) { return k === "type" ? wType : k === "size" ? wSize : wDate }
    function colX(k) {
        if (k === "date") return -(10 + wDate)
        if (k === "size") return colMode >= 3 ? -(20 + wDate + wSize) : -(10 + wSize)
        return colMode >= 3 ? -(30 + wDate + wSize + wType) : colMode === 2 ? -(20 + wSize + wType) : -(10 + wType)
    }
    property bool menuOpen: false
    property var menuModel: []
    property real menuX: 0
    property real menuY: 0
    readonly property string opScript: home + "/.config/snow/bin/filemanager/fm-op.sh"
    readonly property string home: Quickshell.env("HOME")
    readonly property string lsScript: home + "/.config/snow/bin/filemanager/fm-ls.sh"
    readonly property string findScript: home + "/.config/snow/bin/filemanager/fm-find.sh"

    // icon code points (Material Symbols Rounded, checked in the font's codepoints list)
    readonly property string icFolder: String.fromCodePoint(0xe2c7)
    readonly property string icFile: String.fromCodePoint(0xe873)
    readonly property string icBack: String.fromCodePoint(0xe5c4)
    readonly property string icFwd: String.fromCodePoint(0xe5c8)
    readonly property string icUp: String.fromCodePoint(0xe5d8)
    readonly property string icHome: String.fromCodePoint(0xe9b2)
    readonly property string icRefresh: String.fromCodePoint(0xe5d5)
    readonly property string icEye: String.fromCodePoint(0xe8f4)
    readonly property string icEyeOff: String.fromCodePoint(0xe8f5)
    readonly property string icImage: String.fromCodePoint(0xe3f4)
    readonly property string icVideo: String.fromCodePoint(0xeb87)
    readonly property string icAudio: String.fromCodePoint(0xeb82)
    readonly property string icSort: String.fromCodePoint(0xe164)
    readonly property string icChevron: String.fromCodePoint(0xe5cc)
    readonly property string icApps: String.fromCodePoint(0xe5c3)
    readonly property string icLink: String.fromCodePoint(0xe250)
    readonly property string icArchive: String.fromCodePoint(0xeb2c)
    readonly property string icPdf: String.fromCodePoint(0xe415)
    readonly property string icCode: String.fromCodePoint(0xe86f)
    readonly property string icGrid: String.fromCodePoint(0xe9b0)
    readonly property string icList: String.fromCodePoint(0xe8ee)
    readonly property string icTable: String.fromCodePoint(0xf101)
    readonly property string icCopy: String.fromCodePoint(0xe14d)
    readonly property string icCut: String.fromCodePoint(0xe14e)
    readonly property string icPaste: String.fromCodePoint(0xe14f)
    readonly property string icDelete: String.fromCodePoint(0xe92e)
    readonly property string icRename: String.fromCodePoint(0xf097)
    readonly property string icNewDir: String.fromCodePoint(0xe2cc)
    readonly property string icTerm: String.fromCodePoint(0xeb8e)
    readonly property string icUsb: String.fromCodePoint(0xe1e0)
    readonly property string icCheck: String.fromCodePoint(0xe668)
    readonly property string icRestore: String.fromCodePoint(0xe938)
    readonly property string icDelForever: String.fromCodePoint(0xe92b)
    readonly property string icNewFile: String.fromCodePoint(0xe89c)
    readonly property string icInfo: String.fromCodePoint(0xe88e)
    readonly property string icSearch: String.fromCodePoint(0xef7a)
    readonly property string icArrowUp: String.fromCodePoint(0xe5d8)
    readonly property string icArrowDown: String.fromCodePoint(0xe5db)
    readonly property string icNewWin: String.fromCodePoint(0xe89e)
    readonly property string icDeep: String.fromCodePoint(0xe97a)
    readonly property string icOpenDir: String.fromCodePoint(0xe2c8)
    readonly property string icAdd: String.fromCodePoint(0xe145)
    readonly property string icClose: String.fromCodePoint(0xe5cd)
    readonly property string icDual: String.fromCodePoint(0xe949)
    readonly property string icEject: String.fromCodePoint(0xe8fb)
    readonly property string icPin: String.fromCodePoint(0xf10d)
    readonly property string icTrash: String.fromCodePoint(0xe760)
    readonly property string icDrive: String.fromCodePoint(0xe1db)
    readonly property string icDisk: String.fromCodePoint(0xf80e)
    readonly property string icDesk: String.fromCodePoint(0xe30c)
    readonly property string icPics: String.fromCodePoint(0xe412)
    readonly property string icMusic2: String.fromCodePoint(0xf01f)
    readonly property string icVideos: String.fromCodePoint(0xe1c4)
    readonly property string icDocs: String.fromCodePoint(0xe873)
    readonly property string icDown: String.fromCodePoint(0xf090)
    readonly property string icMusic: String.fromCodePoint(0xe405)
    readonly property string icVideoP: String.fromCodePoint(0xe404)

    function norm(p) {
        p = (p || "").trim()
        if (p.indexOf("trash:") === 0) return "trash:///"
        if (p === "" || p === "~") return home
        if (p.indexOf("~/") === 0) p = home + p.substring(1)
        if (p.charAt(0) !== "/") p = cwd + "/" + p
        p = p.replace(/\/+/g, "/")
        if (p.length > 1 && p.charAt(p.length - 1) === "/") p = p.substring(0, p.length - 1)
        return p
    }
    function baseName(n) { var i = n.lastIndexOf("/"); return i >= 0 ? n.substring(i + 1) : n }
    function parent(p) { if (p === "trash:///") return home; var q = p.replace(/\/[^\/]*$/, ""); return q === "" ? "/" : q }
    function runDeep() {
        var q = filterText.trim()
        if (!searchDeep || q === "" || inTrash || cwd === "") return
        deepBusy = true
        if (deepProc.running) deepProc.running = false
        deepProc.cwdAt = cwd; deepProc.q = q
        deepProc.command = ["bash", findScript, cwd, q, showHidden ? "hidden" : ""]
        deepProc.running = true
    }
    function leaveDeep() { if (deepActive || deepBusy) { deepActive = false; deepBusy = false; deepTrunc = false; if (deepProc.running) deepProc.running = false; go(cwd, false) } }
    function searchChanged() {
        if (searchDeep && filterText.trim() !== "" && !inTrash) { deepTimer.restart(); return }
        deepTimer.stop()
        if (deepActive || deepBusy) leaveDeep(); else rebuild(true)
    }
    function tabLabel(i) {
        var p = i === tabIdx ? cwd : tabs[i].p
        if (p === "trash:///") return "Trash"
        if (p === "/") return "/"
        if (p === home) return "Home"
        var n = p.replace(/^.*\//, "")
        return n === "" ? "..." : n
    }
    // ---- Tab / Shift+Tab: keyboard focus zones (list -> side pane -> top bar)
    function sideEntries() {
        var arrs = [sidePlaces, sideDevs, sidePins], r = []
        for (var b = 0; b < 3; b++) for (var i = 0; i < arrs[b].length; i++) {
            var e = arrs[b][i]
            if (e.head === true || e.path === undefined) continue
            r.push({ key: b + ":" + i, e: e })
        }
        return r
    }
    function zoneSet(z, show) {
        zone = z; zoneShow = show === true
        if (pathEdit) pathEdit = false
        if (z === "side") {
            var l = sideEntries(), pick = ""
            for (var i = 0; i < l.length; i++) if (l[i].e.path === cwd) { pick = l[i].key; break }
            if (pick === "" && l.length > 0) pick = l[0].key
            sideSel = pick
        }
        else if (z === "bar") { if (barIdx < 0 || barIdx > barMax()) barIdx = 4 }
        keys.forceActiveFocus()
    }
    function barMax() { return pickMode === "" ? 8 : 5 }
    function zoneStep(dir) {
        var order = ["list"]
        if (sideShown && sideEntries().length > 0) order.push("side")
        order.push("bar")
        var i = order.indexOf(zone)
        zoneSet(order[(i + dir + order.length) % order.length], true)
    }
    function sideMove(d) {
        var l = sideEntries()
        if (l.length === 0) return
        var p = 0
        for (var i = 0; i < l.length; i++) if (l[i].key === sideSel) { p = i; break }
        sideSel = l[Math.max(0, Math.min(l.length - 1, p + d))].key
    }
    function sideOpenSel() {
        var l = sideEntries()
        for (var i = 0; i < l.length; i++) if (l[i].key === sideSel) {
            var e = l[i].e
            if (e.dev !== undefined && e.mounted !== true) devAct("mount", e.dev, true, "")
            else if (e.path !== "") go(e.path, true)
            break
        }
        zoneSet("list", false)
    }
    function barActivate(i) {
        if (i === 0) back()
        else if (i === 1) forward()
        else if (i === 2) up()
        else if (i === 3) go(home, true)
        else if (i === 4) { zoneSet("list", false); startPathEdit() }
        else if (i === 5) { zoneSet("list", false); searchInput.forceActiveFocus(); searchInput.selectAll() }
        else if (i === 6) cycleView()
        else if (i === 7) dualToggle()
        else if (i === 8) { showHidden = !showHidden; go(cwd, false) }
    }
    function zoneKeys(e) {
        if (e.modifiers & Qt.ControlModifier) return false
        if (e.key === Qt.Key_Tab) { zoneStep(1); return true }
        if (e.key === Qt.Key_Backtab) { zoneStep(-1); return true }
        if (zone === "list" || dlgMode !== "" || menuOpen || apOpen) return false
        if (e.modifiers & Qt.AltModifier) return false
        if (e.key === Qt.Key_Escape) { zoneSet("list", false); return true }
        var act = e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space
        if (zone === "side") {
            if (e.key === Qt.Key_Up) { sideMove(-1); return true }
            if (e.key === Qt.Key_Down) { sideMove(1); return true }
            if (e.key === Qt.Key_Home) { sideMove(-999); return true }
            if (e.key === Qt.Key_End) { sideMove(999); return true }
            if (act) { sideOpenSel(); return true }
        } else if (zone === "bar") {
            if (e.key === Qt.Key_Left) { barIdx = Math.max(0, barIdx - 1); return true }
            if (e.key === Qt.Key_Right) { barIdx = Math.min(barMax(), barIdx + 1); return true }
            if (act) { barActivate(barIdx); return true }
        }
        zoneSet("list", false)
        return false
    }
    // ---- two panes
    function szCell(z) { return z === "s" ? 96 : z === "l" ? 152 : z === "xl" ? 196 : z === "xxl" ? 248 : 116 }
    function szPx(z) { return z === "s" ? 36 : z === "l" ? 80 : z === "xl" ? 112 : z === "xxl" ? 160 : 48 }
    function pasSort(arr, key, desc) {
        var k0 = sortKey, d0 = sortDesc
        sortKey = key; sortDesc = desc
        arr.sort(cmpItems)
        sortKey = k0; sortDesc = d0
    }
    function pasClick(ix, btn, mods, px, py) {
        keys.forceActiveFocus()
        paneSwap()
        if (ix >= 0 && ix < items.length) {
            pick(ix, btn === Qt.LeftButton ? mods : 0)
            if (btn === Qt.RightButton) openMenu(ix, px, py)
        }
    }
    function paneClose(side) {
        if (!dualOn) return
        if (side === act2) paneSwap()
        dual = false
        saveState()
        keys.forceActiveFocus()
    }
    function spaceSel(mods) {
        if (cur < 0 || cur >= items.length) return
        if (mods & Qt.ControlModifier) { pick(cur, Qt.ControlModifier); return }
        if (selMap[cur] === true && selCount === 1) setSel({})
        else { var m = {}; m[cur] = true; anchor = cur; setSel(m) }
    }
    function paneTitle(p) { return p === "trash:///" ? "Trash" : p }
    function pasLoad(p) {
        if (p === undefined || p === "") p = pas.cwd
        if (p === "") return
        if (pasLister.running) { pasPending = p; return }
        pasPending = ""
        pasLister.target = p
        pasLister.command = p === "trash:///" ? ["bash", trashScript, "list"] : ["bash", lsScript, p, pas.hidden ? "hidden" : ""]
        pasLister.running = true
    }
    function dualToggle() {
        if (pickMode !== "") return
        dual = !dual
        if (dual) {
            var deep = deepActive || deepBusy
            var a = deep ? [] : items.slice()
            act2 = 0
            pas = { cwd: cwd, allItems: deep ? [] : allItems.slice(), items: a, hist: [cwd], hidx: 0, err: "", view: view, isz: isz, hidden: showHidden, sortKey: sortKey, sortDesc: sortDesc }
            pasLoad(cwd)
            notify("Two panes: Ctrl+Left / Ctrl+Right or a click choose the pane", false)
        }
        saveState()
    }
    function paneSwap() {
        if (!dualOn || pas.cwd === "") return
        var wasDeep = deepActive || deepBusy
        if (wasDeep) { deepActive = false; deepBusy = false; deepTrunc = false; deepTimer.stop(); if (deepProc.running) deepProc.running = false }
        swapT = Date.now()
        var lv = wasDeep ? [] : allItems.slice()
        var lit = lv.slice(); lit.sort(cmpItems)
        var live = { cwd: cwd, allItems: lv, items: lit, hist: hist, hidx: hidx, err: err, view: view, isz: isz, hidden: showHidden, sortKey: sortKey, sortDesc: sortDesc }
        var p = pas
        pas = live
        cwd = p.cwd; allItems = p.allItems; err = p.err; hist = p.hist; hidx = p.hidx; filterText = ""
        view = p.view; isz = p.isz; showHidden = p.hidden; sortKey = p.sortKey; sortDesc = p.sortDesc
        rebuild(false)
        saveState()
        act2 = 1 - act2
        if (wasDeep) pasLoad(live.cwd)
        load(cwd)
    }
    function toOther(kind) {
        if (!dualOn || pickMode !== "") return
        var p = selPaths()
        if (p.length === 0) { notify("Select something first", true); return }
        if (inTrash || pas.cwd === "trash:///") { notify("Not possible with the Trash", true); return }
        if (pas.cwd === cwd) { notify("Both panes show the same folder", true); return }
        if (kind === "move" && anyProt(p)) { notify("Protected folder: can not be moved (copy it instead)", true); return }
        startTransfer(kind, pas.cwd, p)
    }
    function saveTab() { var t = tabs.slice(); t[tabIdx] = { p: cwd, h: hist, i: hidx }; tabs = t }
    function applyTab(i) {
        var t = tabs[i]
        tabIdx = i; hist = t.h; hidx = t.i; filterText = ""
        load(t.p)
    }
    function newTab(path) {
        if (pickMode !== "") return
        saveTab()
        var t = tabs.slice()
        t.splice(tabIdx + 1, 0, { p: path, h: [], i: -1 })
        tabs = t; tabIdx = tabIdx + 1
        hist = []; hidx = -1
        go(path, true)
    }
    function switchTab(i) { if (i < 0 || i >= tabs.length || i === tabIdx) return; saveTab(); applyTab(i) }
    function closeTab(i) {
        if (i < 0 || i >= tabs.length) return
        if (tabs.length === 1) { Qt.quit(); return }
        saveTab()
        var t = tabs.slice(); t.splice(i, 1)
        var wasActive = (i === tabIdx)
        tabs = t
        if (wasActive) applyTab(Math.min(i, t.length - 1))
        else if (i < tabIdx) tabIdx--
    }
    function load(p) {
        if (deepActive && p === cwd && searchDeep && filterText.trim() !== "") { runDeep(); return }
        if (deepActive || deepBusy) { deepActive = false; deepBusy = false; deepTrunc = false; deepTimer.stop(); if (deepProc.running) deepProc.running = false }
        if (lister.running) { pending = p; return }
        pending = ""
        lister.target = p
        lister.command = p === "trash:///" ? ["bash", trashScript, "list"] : ["bash", lsScript, p, showHidden ? "hidden" : ""]
        lister.running = true
    }
    // record = true: new place (cut the forward history); false: back / forward / refresh
    function go(p, record) {
        p = norm(p)
        if (record) {
            filterText = ""
            var h = hist.slice(0, hidx + 1)
            if (h.length === 0 || h[h.length - 1] !== p) h.push(p)
            hist = h; hidx = h.length - 1
        }
        load(p)
    }
    function back() { if (hidx > 0) { hidx--; load(hist[hidx]) } }
    function forward() { if (hidx < hist.length - 1) { hidx++; load(hist[hidx]) } }
    function up() { if (cwd !== "/") go(parent(cwd), true) }
    function openItem(i) {
        if (i < 0 || i >= items.length) return
        var it = items[i]
        if (inTrash) { notify("Restore it first (right-click)", false); return }
        var full = (cwd === "/" ? "" : cwd) + "/" + it.name
        if (it.dir) go(full, true)
        else if (pickMode === "dir") return
        else if (pickMode !== "") {
            if (ext(it.name) !== pickMode) { notify("Please choose a ." + pickMode + " file", true); return }
            pickDone()
        }
        else Quickshell.execDetached(["xdg-open", full])
    }
    function ext(n) { var i = n.lastIndexOf("."); return i > 0 ? n.substring(i + 1).toLowerCase() : "" }
    function iconFor(it) {
        if (it.dir) return icFolder
        var e = ext(it.name)
        if (["png","jpg","jpeg","gif","webp","bmp","svg","avif","tif","tiff"].indexOf(e) >= 0) return icImage
        if (["mp4","mkv","webm","avi","mov","flv","m4v"].indexOf(e) >= 0) return icVideo
        if (["mp3","flac","ogg","opus","wav","m4a","aac"].indexOf(e) >= 0) return icAudio
        if (["zip","tar","gz","xz","bz2","zst","7z","rar","tgz","deb"].indexOf(e) >= 0) return icArchive
        if (e === "pdf") return icPdf
        if (["sh","py","js","qml","lua","c","h","cpp","rs","go","json","conf","css","html","xml","yml","yaml","toml"].indexOf(e) >= 0) return icCode
        return icFile
    }
    // colours / symbols of the file-type icons (FileIcon.qml). Fixed type colours on purpose (video violet, audio pink, ...); folders follow the accent.
    function fileStyle(name) {
        var e = ext(name), L = e.toUpperCase().substring(0, 4)
        function mk(t, g, l, d, k) { return { tone: t, glyph: String.fromCodePoint(g), label: l, dark: d === true, zip: false, kind: k || "file" } }
        if (["mp4","mkv","webm","avi","mov","flv","m4v","wmv","mpg","mpeg"].indexOf(e) >= 0) return mk("#8b5cf6", 0xe037, L, false, "video")
        if (["mp3","flac","ogg","opus","wav","m4a","aac","wma"].indexOf(e) >= 0) return mk("#ec4899", 0xe405, L, false, "audio")
        if (["png","jpg","jpeg","gif","webp","bmp","svg","avif","tif","tiff","ico","heic"].indexOf(e) >= 0) return mk("#14b8a6", 0xe3f4, L, false, "image")
        if (e === "pdf") return mk("#ef4444", 0xe415, "PDF", false, "pdf")
        if (["doc","docx","odt","rtf"].indexOf(e) >= 0) return mk("#3b82f6", 0xe873, "DOC", false, "doc")
        if (["xls","xlsx","ods","csv"].indexOf(e) >= 0) return mk("#22a06b", 0xe265, "XLS", false, "sheet")
        if (["ppt","pptx","odp"].indexOf(e) >= 0) return mk("#f97316", 0xe41b, "PPT", false, "slides")
        if (["txt","md","log","nfo"].indexOf(e) >= 0) return mk("#64748b", 0xe26c, L, false, "text")
        if (["sh","bash","zsh","fish"].indexOf(e) >= 0) return mk("#22c55e", 0xeb8e, L, true, "script")
        if (["py","js","ts","jsx","tsx","c","h","cpp","hpp","java","rs","go","json","yml","yaml","toml","ini","conf","cfg","lua","qml","html","css","xml","php","rb","sql"].indexOf(e) >= 0) return mk("#0ea5e9", 0xe86f, L, false, "code")
        if (["zip","tar","gz","xz","bz2","zst","7z","rar","tgz","txz"].indexOf(e) >= 0) { var zs = mk("#ca8a04", 0xeb2c, L, false, "archive"); zs.zip = true; return zs }
        if (["deb","rpm","appimage","flatpak","exe","msi","apk"].indexOf(e) >= 0) return mk("#6366f1", 0xf720, L, false, "package")
        if (["iso","img"].indexOf(e) >= 0) return mk("#78716c", 0xe019, L, false, "disk")
        if (["ttf","otf","woff","woff2"].indexOf(e) >= 0) return mk("#a855f7", 0xe262, L, false, "font")
        return mk("#64748b", 0xe873, e !== "" && e.length <= 4 ? L : "")
    }
    function crumbList() {
        if (cwd === "trash:///") return [{ n: "Trash", p: "trash:///" }]
        var parts = cwd.split("/"), r = [{ n: "/", p: "/" }], acc = ""
        for (var i = 1; i < parts.length; i++) { if (parts[i] === "") continue; acc += "/" + parts[i]; r.push({ n: parts[i], p: acc }) }
        return r
    }
    function startPathEdit() { pathEdit = true; pathInput.text = cwd; pathInput.forceActiveFocus(); pathInput.selectAll() }
    function kindOf(it) {
        if (it.dir) return "Folder"
        var e = ext(it.name)
        return e === "" ? "File" : e.toUpperCase()
    }
    function statusText() {
        var hid = showHidden ? "  -  hidden files shown" : ""
        if (pickMode === "dir") return "Save into:  " + cwd + "     (open the folder you want, then press Select)"
        if (pickMode !== "" && !pickOk()) return "Choose a ." + pickMode.toUpperCase() + " file (double-click it, or select it and press Select)"
        if (deepBusy) return "Searching in sub folders ..."
        if (deepActive && selCount === 0) return items.length + (items.length === 1 ? " result" : " results") + " for \"" + filterText.trim() + "\" in " + cwd + " and its sub folders" + (deepTrunc ? "  -  only the first 1000 are shown, type more letters" : "")
        if (selCount === 0) return items.length + " items" + (freeText !== "" && !inTrash ? "  -  " + freeText + " free" : "") + hid
        if (selCount === 1 && cur >= 0 && items[cur]) {
            var it = items[cur]
            if (inTrash) return it.name + "  -  " + (it.dir ? "Folder" : fmtSize(it.size)) + "  -  deleted " + fmtDate(it.mtime) + "  -  from " + it.orig
            return it.name + "  -  " + (it.dir ? "Folder" : fmtSize(it.size) + "  -  " + kindOf(it)) + (it.mtime > 0 ? "  -  modified " + fmtDate(it.mtime) : "") + (it.link ? "  -  link" : "")
        }
        var f = 0, d = 0, b = 0
        for (var k in selMap) { var x = items[parseInt(k)]; if (!x) continue; if (x.dir) d++; else { f++; b += x.size } }
        return selCount + " selected  (" + f + (f === 1 ? " file" : " files") + ", " + d + (d === 1 ? " folder" : " folders") + ")" + (f > 0 ? "  -  " + fmtSize(b) : "")
    }
    function setSel(m) { opMsg = ""; selMap = m; var n = 0; for (var k in m) n++; selCount = n }
    function pick(i, mods) {
        if (i < 0 || i >= items.length) return
        var m = {}
        if ((mods & Qt.ShiftModifier) && anchor >= 0) {
            if (mods & Qt.ControlModifier) m = Object.assign({}, selMap)
            for (var j = Math.min(anchor, i); j <= Math.max(anchor, i); j++) m[j] = true
            cur = i
        } else if (mods & Qt.ControlModifier) {
            m = Object.assign({}, selMap)
            if (m[i]) delete m[i]; else m[i] = true
            cur = i; anchor = i
        } else { m[i] = true; cur = i; anchor = i }
        setSel(m)
        if (view === "icon") grid.positionViewAtIndex(i, GridView.Contain)
        else list.positionViewAtIndex(i, ListView.Contain)
    }
    function move(d, mods) {
        if (items.length === 0) return
        var n = cur < 0 ? 0 : Math.max(0, Math.min(items.length - 1, cur + d))
        pick(n, mods & Qt.ShiftModifier)
    }
    function selectAll() { var m = {}; for (var j = 0; j < items.length; j++) m[j] = true; setSel(m) }
    function cmpItems(a, b) {
        if (inTrash) return b.mtime - a.mtime
        if (a.dir !== b.dir) return a.dir ? -1 : 1
        var k = sortKey, r = 0
        if (k === "size" && !a.dir) r = a.size - b.size
        else if (k === "date") r = a.mtime - b.mtime
        else if (k === "type") { var ea = ext(a.name), eb = ext(b.name); r = ea < eb ? -1 : ea > eb ? 1 : 0 }
        if (r === 0) { var na = a.name.toLowerCase(), nb = b.name.toLowerCase(); r = na < nb ? -1 : na > nb ? 1 : 0 }
        return sortDesc ? -r : r
    }
    // rebuild the shown list from allItems (filter + sort). keep = true: same folder, keep selection by name and the scroll position
    function isImg(n) { return ["png","jpg","jpeg","gif","webp","bmp","svg"].indexOf(ext(n)) >= 0 }
    function thumbSrc(it) {
        if (inTrash || it.dir || !isImg(it.name)) return ""
        return "file://" + encodeURI(fullPath(it)).replace(/#/g, "%23").replace(/\?/g, "%3F")
    }
    function dragPress(idx, x, y) { if (inTrash || pickMode !== "") return; dragPressed = true; dragIdx = idx; dragSX = x; dragSY = y; justDragged = false }
    function dragMove(x, y) {
        if (!dragPressed) return
        if (!dragging) {
            if (Math.abs(x - dragSX) + Math.abs(y - dragSY) < 12) return
            if (dragIdx < 0 || dragIdx >= items.length) { dragPressed = false; return }
            if (!selMap[dragIdx]) pick(dragIdx, 0)
            dragPaths = selPaths()
            if (dragPaths.length === 0) { dragPressed = false; return }
            dragging = true
        }
        dragX = x; dragY = y
        if (!dragExt && (x < 0 || y < 0 || x > win.width || y > win.height)) {
            var u = []
            for (var i = 0; i < dragPaths.length; i++) u.push("file://" + encodeURI(dragPaths[i]).replace(/#/g, "%23").replace(/\?/g, "%3F"))
            dragUriText = u.join("\r\n") + "\r\n"
            dragExt = true
        }
    }
    function extDragDone() { dragExt = false; dragging = false; dragPressed = false; dropHint = ""; justDragged = true }
    function dragCancel() { if (dragExt) return; dragging = false; dragPressed = false; dropHint = "" }
    function dragEnd(mods) {
        var was = dragging
        dragPressed = false
        if (!was) return
        dragCtrl = (mods & Qt.ControlModifier) !== 0
        justDragged = true
        dragProxy.Drag.drop()
        dragging = false; dropHint = ""
    }
    function hintFor(dest) {
        var nm = dest === "trash:///" ? "Trash" : dest.replace(/^.*\//, "")
        return (dragCtrl ? "Copy " : "Move ") + plural(dragPaths.length) + " to " + (nm === "" ? "/" : nm)
    }
    function sortSub() {
        return [
            { ic: sortKey === "name" ? icCheck : "", lb: "Name", a: "sort", arg: "name", on: true },
            { ic: sortKey === "date" ? icCheck : "", lb: "Time", a: "sort", arg: "date", on: true },
            { ic: sortKey === "type" ? icCheck : "", lb: "File type", a: "sort", arg: "type", on: true },
            { ic: sortKey === "size" ? icCheck : "", lb: "Size", a: "sort", arg: "size", on: true },
            { sep: true },
            { ic: !sortDesc ? icCheck : "", lb: "Ascending", a: "sortdir", arg: "asc", on: true },
            { ic: sortDesc ? icCheck : "", lb: "Descending", a: "sortdir", arg: "desc", on: true }
        ]
    }
    // paste / copy / move: first ask the helper which names already exist in the destination; if some do, show Replace / Skip / Keep both
    function startTransfer(kind, dest, srcs) {
        if (pickMode !== "") return
        if (opBusy) { opMsg = "Wait: another job is running"; return }
        if (kind === "paste") { pendingArgs = ["paste", dest]; pendingLabel = "Pasting"; conflProc.command = ["bash", opScript, "paste-conflicts", dest] }
        else { pendingArgs = [kind, dest].concat(srcs); pendingLabel = kind === "copy" ? "Copying" : "Moving"; conflProc.command = ["bash", opScript, "conflicts", dest].concat(srcs) }
        conflictMode = ""
        conflProc.running = true
    }
    function conflictResult(text) {
        var names = []
        var ls = text.split("\n")
        for (var q = 0; q < ls.length; q++) if (ls[q].indexOf("C\t") === 0) names.push(ls[q].substring(2))
        if (names.length === 0) { runOp(pendingArgs, pendingLabel); return }
        conflictNames = names; dlgMode = "conflict"; dlgKeys.forceActiveFocus()
    }
    function conflictChoose(mode) {
        dlgMode = ""; keys.forceActiveFocus()
        if (mode === "") return
        conflictMode = mode
        runOp(pendingArgs, pendingLabel)
    }
    // type to jump: letters typed within a split second make a prefix ("sno" -> snow); the same letter again (s, s) goes to the NEXT name with that letter
    function jumpTo(ch) {
        var c = ch.toLowerCase()
        var buf = typeBuf + c
        typeBuf = buf; typeTimer.restart()
        var n = items.length
        if (n === 0) return
        var same = true
        for (var k = 1; k < buf.length; k++) if (buf.charAt(k) !== buf.charAt(0)) same = false
        var q, i
        if (same) {
            var start = (cur >= 0 && items[cur] && items[cur].name.toLowerCase().indexOf(c) === 0) ? cur + 1 : 0
            for (q = 0; q < n; q++) { i = (start + q) % n; if (items[i].name.toLowerCase().indexOf(c) === 0) { pick(i, 0); return } }
            return
        }
        var from = cur >= 0 ? cur : 0
        for (q = 0; q < n; q++) { i = (from + q) % n; if (items[i].name.toLowerCase().indexOf(buf) === 0) { pick(i, 0); return } }
    }
    function dropExternal(dest, ev) {
        if (!ev || !ev.hasUrls || dest === "" || dest === "trash:///" || inTrash || pickMode !== "") return
        var ps = [], skipped = 0, bad = 0
        for (var i = 0; i < ev.urls.length; i++) {
            var u = ev.urls[i].toString()
            if (u.indexOf("file://") !== 0) { bad++; continue }
            var fp = ""
            try { fp = decodeURIComponent(u.substring(7)) } catch (e) { bad++; continue }
            if (fp === "") { bad++; continue }
            if (parent(fp) === dest) { skipped++; continue }
            ps.push(fp)
        }
        if (ps.length === 0) {
            notify(skipped > 0 ? "Already in this folder" : "Only files from this computer can be dropped here", skipped === 0)
            return
        }
        ev.accept(Qt.CopyAction)
        keys.forceActiveFocus()
        startTransfer("copy", dest, ps)
    }
    function dropOn(dest, ev) {
        if (!dragging) { dropExternal(dest, ev); return }
        var p = dragPaths
        if (!dragging || p.length === 0 || dest === "") return
        if (dest === "trash:///") {
            if (anyProt(p)) { notify("Protected folder: can not be deleted", true); return }
            confirmKind = "trash"; confirmPaths = p; dlgMode = "confirm"; dlgKeys.forceActiveFocus(); return
        }
        if (!dragCtrl && anyProt(p)) { notify("Protected folder: can not be moved (hold Ctrl to copy it)", true); return }
        startTransfer(dragCtrl ? "copy" : "move", dest, p)
    }
    function rebuild(keep) {
        dragCancel()
        var keepN = [], keepC = "", ky = 0
        if (keep) {
            for (var kk in selMap) { var o = items[parseInt(kk)]; if (o) keepN.push(o.name) }
            if (cur >= 0 && items[cur]) keepC = items[cur].name
            ky = view === "icon" ? grid.contentY : list.contentY
        }
        var f = filterText.trim().toLowerCase(), a = []
        for (var i = 0; i < allItems.length; i++) if (deepActive || f === "" || allItems[i].name.toLowerCase().indexOf(f) >= 0) a.push(allItems[i])
        a.sort(cmpItems)
        items = a
        cur = -1; anchor = -1; setSel({})
        var m2 = {}, any = false
        for (var q = 0; q < a.length; q++) {
            if (keepN.indexOf(a[q].name) >= 0) { m2[q] = true; any = true }
            if (a[q].name === keepC) { cur = q; anchor = q }
        }
        if (keep && any) { setSel(m2); if (cur < 0) cur = parseInt(Object.keys(m2)[0]) }
        else if (a.length > 0) pick(0, 0)
        if (keep) { if (view === "icon") grid.contentY = ky; else list.contentY = ky }
        else { list.positionViewAtBeginning(); grid.positionViewAtBeginning() }
    }
    function saveState() {
        if (pickMode !== "") return
        Quickshell.execDetached(["bash", "-c", "mkdir -p \"$(dirname \"$2\")\"; printf '%s' \"$1\" > \"$2\"", "x",
            JSON.stringify({ view: view, isz: isz, sortKey: sortKey, sortDesc: sortDesc, dual: dual }), statePath])
    }
    property real wheelAcc: 0
    function sizeStep(dir) {
        var order = ["s", "m", "l", "xl", "xxl"], i = order.indexOf(isz)
        var n = Math.max(0, Math.min(order.length - 1, i + dir))
        if (n === i) return
        isz = order[n]; saveState()
        if (view !== "icon") setView("icon")
        else if (cur >= 0) grid.positionViewAtIndex(cur, GridView.Contain)
    }
    function sizeWheel(dy) {
        wheelAcc += dy
        if (Math.abs(wheelAcc) < 100) return
        sizeStep(wheelAcc > 0 ? 1 : -1)
        wheelAcc = 0
    }
    function cycleView() { setView(view === "icon" ? "list" : view === "list" ? "details" : "icon") }
    function setSort(k) { if (sortKey === k) sortDesc = !sortDesc; else { sortKey = k; sortDesc = false }; rebuild(true); saveState() }
    function setView(v) { view = v; saveState(); if (cur >= 0) { if (v === "icon") grid.positionViewAtIndex(cur, GridView.Contain); else list.positionViewAtIndex(cur, ListView.Contain) } }
    function isArchive(n) {
        var l = n.toLowerCase()
        var e = [".zip",".7z",".rar",".tar",".tar.gz",".tgz",".tar.xz",".txz",".tar.bz2",".tbz2",".tar.zst",".gz",".xz",".bz2",".zst"]
        for (var i = 0; i < e.length; i++) if (l.length > e[i].length && l.lastIndexOf(e[i]) === l.length - e[i].length) return true
        return false
    }
    function openMenu(i, x, y) {
        if (pickMode !== "") return
        var m = []
        if (inTrash) {
            if (i >= 0) {
                if (!selMap[i]) pick(i, 0)
                m.push({ ic: icRestore, lb: "Restore", a: "restore", on: true })
                m.push({ sep: true })
                m.push({ ic: icDelForever, lb: "Delete permanently", a: "delete", on: true, danger: true })
            } else {
                m.push({ ic: icDelForever, lb: "Empty Trash", a: "empty", on: items.length > 0, danger: true })
                m.push({ ic: icRefresh, lb: "Refresh", a: "refresh", on: true })
            }
            var ht = 12
            for (var q = 0; q < m.length; q++) ht += m[q].sep ? 9 : 34
            menuModel = m
            menuX = Math.max(8, Math.min(x, win.width - 248))
            menuY = Math.max(8, Math.min(y, win.height - ht - 8))
            menuOpen = true
            return
        }
        if (i >= 0) {
            if (!selMap[i]) pick(i, 0)
            var it = items[i], one = selCount === 1
            m.push({ ic: icFolder, lb: "Open", a: "open", on: one })
            if (deepActive && one) m.push({ ic: icOpenDir, lb: "Open containing folder", a: "openparent", on: true })
            if (!it.dir && one) m.push({ ic: icApps, lb: "Open with ...", a: "openwith", on: true })
            if (it.dir && one) m.push({ ic: icTerm, lb: "Open in terminal", a: "terminal", on: true })
            else m.push({ ic: icTerm, lb: "Open terminal here", a: "terminalHere", on: true })
            if (it.dir && one) m.push({ ic: icPin, lb: "Pin to side pane", a: "pin", arg: fullPath(it), on: true })
            if (it.dir && one) m.push({ ic: icNewWin, lb: "Open in new tab", a: "newtab", arg: fullPath(it), on: true })
            if (it.dir && one) m.push({ ic: icNewWin, lb: "Open in new window", a: "newwin", arg: fullPath(it), on: true })
            if (!it.dir && one && isArchive(it.name)) m.push({ ic: icArchive, lb: "Extract here", a: "extract", on: true })
            m.push({ ic: icArchive, lb: "Compress to zip", a: "zip", on: true })
            if (one) m.push({ ic: icLink, lb: "Copy path", a: "copypath", on: true })
            m.push({ sep: true })
            m.push({ ic: icCopy, lb: "Copy", a: "copy", on: true })
            m.push({ ic: icCut, lb: "Cut", a: "cut", on: !anyProt(selPaths()) })
            m.push({ ic: icPaste, lb: "Paste", a: "paste", on: true })
            if (it.dir && one) m.push({ ic: icPaste, lb: "Paste into folder", a: "pasteinto", arg: fullPath(it), on: true })
            if (dualOn && pas.cwd !== "" && pas.cwd !== "trash:///") {
                m.push({ ic: icCopy, lb: "Copy to other pane", a: "toother", arg: "copy", on: true })
                m.push({ ic: icCut, lb: "Move to other pane", a: "toother", arg: "move", on: !anyProt(selPaths()) })
            }
            m.push({ sep: true })
            m.push({ ic: icRename, lb: "Rename", a: "rename", on: !anyProt(selPaths()) })
            m.push({ ic: icSort, lb: "Sort by", sub: sortSub(), on: true })
            m.push({ ic: icInfo, lb: "Properties", a: "props", on: true })
            m.push({ ic: icDelete, lb: "Move to Trash", a: "delete", on: !anyProt(selPaths()), danger: true })
        } else {
            m.push({ ic: icNewDir, lb: "New folder", a: "mkdir", on: true })
            m.push({ ic: icNewFile, lb: "New file", a: "mkfile", on: true })
            m.push({ ic: icPaste, lb: "Paste", a: "paste", on: true })
            m.push({ ic: icRestore, lb: "Undo last action", a: "undo", on: true })
            m.push({ ic: icSort, lb: "Sort by", sub: sortSub(), on: true })
            m.push({ sep: true })
            m.push({ ic: icTerm, lb: "Open terminal here", a: "terminalHere", on: true })
            m.push({ ic: icPin, lb: "Pin this folder", a: "pin", arg: cwd, on: cwd !== "/" })
            m.push({ ic: icNewWin, lb: "New tab", a: "newtab", arg: cwd, on: true })
            m.push({ ic: icNewWin, lb: "Open in new window", a: "newwin", arg: cwd, on: true })
            m.push({ ic: icInfo, lb: "Properties", a: "props", on: true })
            m.push({ ic: icRefresh, lb: "Refresh", a: "refresh", on: true })
        }
        var h = 12
        for (var j = 0; j < m.length; j++) h += m[j].sep ? 9 : 34
        menuModel = m
        menuX = Math.max(8, Math.min(x, win.width - 248))
        menuY = Math.max(8, Math.min(y, win.height - h - 8))
        menuOpen = true
    }
    function viewMenu(x, y) {
        var m = [
            { ic: view === "icon" ? icCheck : "", lb: "Grid", a: "view", arg: "icon", on: true },
            { ic: view === "list" ? icCheck : "", lb: "List", a: "view", arg: "list", on: true },
            { ic: view === "details" ? icCheck : "", lb: "Details", a: "view", arg: "details", on: true },
            { sep: true },
            { ic: isz === "s" ? icCheck : "", lb: "Small icons", a: "isize", arg: "s", on: true },
            { ic: isz === "m" ? icCheck : "", lb: "Medium icons", a: "isize", arg: "m", on: true },
            { ic: isz === "l" ? icCheck : "", lb: "Large icons", a: "isize", arg: "l", on: true },
            { ic: isz === "xl" ? icCheck : "", lb: "Extra large icons", a: "isize", arg: "xl", on: true },
            { ic: isz === "xxl" ? icCheck : "", lb: "Huge icons", a: "isize", arg: "xxl", on: true },
            { sep: true },
            { ic: sortKey === "name" ? icCheck : "", lb: "Sort by name", a: "sort", arg: "name", on: true },
            { ic: sortKey === "size" ? icCheck : "", lb: "Sort by size", a: "sort", arg: "size", on: true },
            { ic: sortKey === "date" ? icCheck : "", lb: "Sort by date", a: "sort", arg: "date", on: true },
            { ic: sortKey === "type" ? icCheck : "", lb: "Sort by type", a: "sort", arg: "type", on: true },
            { sep: true },
            { ic: !sortDesc ? icCheck : "", lb: "Ascending (A-Z, small first)", a: "sortdir", arg: "asc", on: true },
            { ic: sortDesc ? icCheck : "", lb: "Descending (Z-A, big first)", a: "sortdir", arg: "desc", on: true },
            { sep: true },
            { ic: dual ? icCheck : "", lb: "Two panes (Ctrl+D)", a: "dual", on: pickMode === "" }
        ]
        var h = 12
        for (var j = 0; j < m.length; j++) h += m[j].sep ? 9 : 34
        menuModel = m
        menuX = Math.max(8, Math.min(x, win.width - 248))
        menuY = Math.max(8, Math.min(y, win.height - h - 8))
        menuOpen = true
    }
    function showMenu(m, x, y) {
        var h = 12
        for (var q = 0; q < m.length; q++) h += m[q].sep ? 9 : 34
        menuModel = m; subModel = []
        menuX = Math.max(8, Math.min(x, win.width - 248))
        menuY = Math.max(8, Math.min(y, win.height - h - 8))
        menuOpen = true
    }
    function homeMenu(x, y) {
        var m = [
            { ic: icImage, lb: "Folder icon ...", a: "pickicon", on: pickMode === "" },
            { ic: icRestore, lb: "Reset folder icon", a: "reseticon", on: svgOn }
        ]
        if (iconThemes.length > 1) {
            m.push({ sep: true })
            for (var q = 0; q < iconThemes.length; q++)
                m.push({ ic: iconThemes[q] === iconThemeCur ? icCheck : "", lb: "Icons: " + (iconThemes[q] === "snow" ? "Snow (own)" : iconThemes[q] === "snow-simple" ? "Snow Simple" : iconThemes[q]), a: "icontheme", arg: iconThemes[q], on: pickMode === "" })
        }
        showMenu(m, x, y)
    }
    function pickOk() { if (pickMode === "dir") return cwd !== "" && !inTrash; return pickMode !== "" && cur >= 0 && items[cur] && !items[cur].dir && ext(items[cur].name) === pickMode }
    function pickDone() {
        if (!pickOk()) { notify(pickMode === "dir" ? "Open a real folder first" : "Please choose a ." + pickMode + " file", true); return }
        var full = pickMode === "dir" ? cwd : (cwd === "/" ? "" : cwd) + "/" + items[cur].name
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" > \"$2\"", "x", full, pickOut])
        pickQuit.start()
    }
    function apRefilter() {
        var f = apFilter.trim().toLowerCase(), r = []
        for (var i = 0; i < apAll.length; i++) if (f === "" || apAll[i].name.toLowerCase().indexOf(f) >= 0) r.push(apAll[i])
        apShown = r
    }
    function apClose() { apOpen = false; keys.forceActiveFocus() }
    function apRun(id) { Quickshell.execDetached(["bash", openScript, "run", id, apFile]); notify("Opening ...", false); apClose() }
    function apChoose(id) {
        if (apAlways) { apPending = id; apSetProc.command = ["bash", openScript, "setdefault", id, apFile]; apSetProc.running = true }
        else apRun(id)
    }
    property string apPending: ""
    function menuClick(a, arg, mp) { menuOpen = false; if (a === "owmore") { act(a, arg); return }; if (a === "devmount") devAct("mount", arg, true, ""); else if (a === "devunmount") devAct("unmount", arg, false, mp); else if (a === "deveject") devAct("eject", arg, false, mp); else act(a, arg); if (dlgMode === "") keys.forceActiveFocus() }
    function placeIcon(k) {
        return k === "home" ? icHome : k === "docs" ? icDocs : k === "download" ? icDown : k === "music" ? icMusic2
             : k === "pictures" ? icPics : k === "videos" ? icVideos : k === "desktop" ? icDesk : k === "trash" ? icTrash : k === "root" ? icDisk : icFolder
    }
    function buildSide() {
        var p = [{ head: true, text: "Places" }]
        for (var i = 0; i < places.length; i++) { if (pickMode !== "" && ["home", "download", "pictures"].indexOf(places[i].icon) < 0) continue; var q = { name: places[i].name, path: places[i].path, ic: placeIcon(places[i].icon), pin: false }
            if (places[i].total > 0) { q.total = places[i].total; q.avail = places[i].avail || 0; q.sub = fmtSize(q.avail) + " free of " + fmtSize(q.total) }
            p.push(q) }
        var dv = []
        if (devs.length > 0) {
            dv.push({ head: true, text: "Devices" })
            for (var d = 0; d < devs.length; d++) {
                var v = devs[d]
                dv.push({ name: v.name, path: v.mount, ic: v.removable ? icUsb : icDrive, pin: false, dev: v.dev, mounted: v.mount !== "",
                         removable: v.removable, total: v.mount !== "" ? (v.total || 0) : 0, avail: v.avail || 0,
                         sub: (v.mount !== "" && v.total > 0) ? fmtSize(v.avail) + " free of " + fmtSize(v.total) : v.size + "  " + v.fstype + (v.mount === "" ? "  (not mounted)" : "") })
            }
        }
        var pn = []
        if (pins.length > 0 && pickMode === "") {
            pn.push({ head: true, text: "Pinned" })
            for (var j = 0; j < pins.length; j++) pn.push({ name: pins[j].name, path: pins[j].path, ic: icFolder, pin: true })
        }
        sidePlaces = p; sideDevs = dv; sidePins = pn
    }
    function boxNat(a) {
        if (a.length === 0) return 0
        var h = 16
        for (var k = 0; k < a.length; k++) h += a[k].head === true ? 30 : (a[k].sub !== undefined ? (a[k].total > 0 ? 54 : 46) : 36)
        return h
    }
    function boxLayout(avail) {
        var arrs = [sidePlaces, sideDevs, sidePins], n = [], hs = [], cnt = 0, tot = 0
        for (var i = 0; i < 3; i++) { n.push(boxNat(arrs[i])); hs.push(n[i]); if (n[i] > 0) { cnt++; tot += n[i] } }
        var over = tot + 8 * Math.max(cnt - 1, 0) - avail
        for (var q = 2; q >= 0 && over > 0; q--) { var can = Math.max(0, hs[q] - 110); var t = Math.min(can, over); hs[q] -= t; over -= t }
        var y = 0, res = []
        for (var r = 0; r < 3; r++) { res.push({ y: y, h: hs[r] }); if (hs[r] > 0) y += hs[r] + 8 }
        return res
    }
    // the five main folders can not be deleted / renamed / moved (their content can)
    // symbol drawn in the middle of the folder icon for the five main folders (only inside the home folder)
    function folderKind(dir, name) {      // which of the 5 home folders (own svg with the symbol inside)
        if (dir !== home) return ""
        return name === "Documents" ? "documents" : name === "Downloads" ? "downloads" : name === "Pictures" ? "pictures" : name === "Music" ? "music" : name === "Videos" ? "videos" : ""
    }
    function folderSvgFor(dir, name) {
        var k = folderKind(dir, name)
        return (k !== "" && !svgOn) ? iconsDir + "/folder-" + k + ".svg" + revSuffix : folderSvg
    }
    function folderGlyph(dir, name) {
        if (dir !== home) return ""
        return name === "Documents" ? icDocs : name === "Downloads" ? icDown : name === "Pictures" ? icPics : name === "Music" ? icMusic2 : name === "Videos" ? icVideos : ""
    }
    function isProt(p) {
        var n = ["Documents", "Downloads", "Pictures", "Music", "Videos"]
        for (var i = 0; i < n.length; i++) if (p === home + "/" + n[i]) return true
        return false
    }
    function anyProt(ps) { for (var i = 0; i < ps.length; i++) if (isProt(ps[i])) return true; return false }
    function devAct(kind, dev, go, mp) {
        if (devWork !== "") { opMsg = "Wait: " + devWork; return }
        devWork = kind === "mount" ? "mounting" : kind === "eject" ? "ejecting" : "unmounting"
        devGo = go === true; devMount = mp || ""
        opMsg = devWork.charAt(0).toUpperCase() + devWork.slice(1) + " " + dev + " ..."
        devRunner.command = ["bash", devScript, kind, dev]
        devRunner.running = true
    }
    function devDone(text) {
        var r = null
        try { r = JSON.parse(text) } catch (e) { r = null }
        var kind = devWork; devWork = ""
        if (r === null) { opMsg = "Problem: no answer from fm-dev.sh"; return }
        if (!r.ok) { opMsg = "Problem: " + r.msg; notify("Problem: " + r.msg, true); devLoad(); return }
        opMsg = r.msg; notify(r.msg, false)
        if (kind === "mounting" && devGo && r.path !== "") go(r.path, true)
        if (kind !== "mounting" && devMount !== "" && cwd.indexOf(devMount) === 0) go(home, true)
        devLoad()
    }
    function devLoad() { devList.running = true }
    function devClick(e) {
        if (e.mounted) go(e.path, true)
        else devAct("mount", e.dev, true, "")
    }
    function sideMenu(e, x, y) {
        var m = []
        if (e.dev !== undefined) {
            if (e.mounted) {
                m.push({ ic: icFolder, lb: "Open", a: "goto", arg: e.path, on: true })
                m.push({ ic: icEject, lb: "Unmount", a: "devunmount", arg: e.dev, mp: e.path, on: true })
                if (e.removable) m.push({ ic: icUsb, lb: "Eject (safe to remove)", a: "deveject", arg: e.dev, mp: e.path, on: true })
            } else m.push({ ic: icUsb, lb: "Mount", a: "devmount", arg: e.dev, on: true })
            menuModel = m
            menuX = Math.max(8, Math.min(x, win.width - 248))
            menuY = Math.max(8, Math.min(y, win.height - 140))
            menuOpen = true
            return
        }
        m.push({ ic: icFolder, lb: "Open", a: "goto", arg: e.path, on: true })
        if (e.path === "trash:///") m.push({ ic: icDelForever, lb: "Empty Trash", a: "empty", on: true, danger: true })
        else if (e.pin) m.push({ ic: icPin, lb: "Unpin", a: "unpin", arg: e.path, on: true })
        else m.push({ ic: icPin, lb: "Pin to side pane", a: "pin", arg: e.path, on: e.path !== "/" })
        menuModel = m
        menuX = Math.max(8, Math.min(x, win.width - 248))
        menuY = Math.max(8, Math.min(y, win.height - 100))
        menuOpen = true
    }
    function sideLoad() { sideList.running = true }
    function sideRun(args) { sideRunner.command = ["bash", sideScript].concat(args); sideRunner.running = true }
    function fullPath(it) { if (it.tid !== undefined) return it.tid; return (cwd === "/" ? "" : cwd) + "/" + it.name }
    function selPaths() {
        var idx = []
        for (var k in selMap) idx.push(parseInt(k))
        idx.sort(function (a, b) { return a - b })
        var r = []
        for (var j = 0; j < idx.length; j++) if (items[idx[j]]) r.push(fullPath(items[idx[j]]))
        return r
    }
    function notify(t, bad) {
        toast = t; toastBad = bad === true; toastShow = true
        toastTimer.interval = bad === true ? 6000 : 2800
        toastTimer.restart()
    }
    function plural(n) { return n + (n === 1 ? " item" : " items") }
    function runOp(args, label, indet, script) {
        if (opBusy) { opMsg = "Wait: another job is running"; return }
        opKind = args[0]; opBusy = true; opIndet = indet === true; opPct = 0; opText = label; opMsg = ""; opErr = ""; opOk = 0; opU = ""
        op.command = (conflictMode !== "" ? ["env", "SNOW_FM_CONFLICT=" + conflictMode] : []).concat(["bash", script !== undefined ? script : opScript], args)
        conflictMode = ""
        op.running = true
    }
    function opLine(line) {
        var f = line.split("\t")
        if (f[0] === "P") { opPct = parseInt(f[1]) || 0; opText = f[5] + "  (" + f[4] + ")" }
        else if (f[0] === "E") opErr = opErr === "" ? f[1] : opErr + "  |  " + f[1]
        else if (f[0] === "D") opOk = parseInt(f[1]) || 0
        else if (f[0] === "U") opU = f[1]
    }
    function opDone() {
        opBusy = false
        var k = opKind
        if (opErr !== "") { opMsg = "Problem: " + opErr; notify("Problem: " + opErr, true) }
        else {
            var t = k === "undo" ? "Undone: " + opU : k === "batchrename" ? "Renamed " + plural(opOk) : k === "paste" ? "Pasted " + plural(opOk) : k === "move" ? "Moved " + plural(opOk) : k === "copy" ? "Copied " + plural(opOk) : k === "zip" ? "Zip created" : k === "copypath" ? "Path copied" : k === "trash" ? "Moved " + plural(opOk) + " to Trash"
                  : k === "rename" ? "Renamed" : k === "mkdir" ? "Folder created" : k === "mkfile" ? "File created" : k === "extract" ? "Extracted"
                  : k === "restore" ? "Restored " + plural(opOk) : k === "purge" || k === "rmrf" ? "Deleted permanently: " + plural(opOk) : k === "empty" ? "Trash emptied" : "Done"
            opMsg = t; notify(t, false)
        }
        go(cwd, false)
        if (dualOn) pasLoad()
    }
    function act(name, arg) {
        if (pickMode !== "" && ["open", "goto", "view", "sort", "sortdir", "refresh", "isize", "none", "props"].indexOf(name) < 0) return
        var p = selPaths()
        if (inTrash && ["copy", "cut", "paste", "rename", "mkdir", "mkfile", "extract", "terminal", "terminalHere", "pin", "zip", "openwith", "copypath"].indexOf(name) >= 0) { notify("Not possible inside the Trash", true); return }
        if (!inTrash && ["delete", "deleteperm", "cut", "rename"].indexOf(name) >= 0 && anyProt(p)) { notify("Protected folder: Documents / Downloads / Pictures / Music / Videos can not be deleted, renamed or moved", true); return }
        if (name === "none") return
        if (name === "pickicon") { if (!iconProc.running) { notify("A small window opens - double-click an .svg file there", false); iconProc.command = ["bash", iconScript, "choose"]; iconProc.running = true } return }
        if (name === "icontheme") { if (!itSetProc.running) { itSetProc.command = ["bash", themeScript, "set", arg]; itSetProc.running = true } return }
        if (name === "reseticon") { if (!iconProc.running) { iconProc.command = ["bash", iconScript, "reset"]; iconProc.running = true } return }
        if (name === "owmore") {
            if (owPaths.length !== 1) return
            apFile = owPaths[0]; apName = apFile.replace(/^.*\//, ""); var xe = ext(apName)
            apExtLabel = xe !== "" ? "." + xe + " files" : "files of this kind"
            apAlways = false; apFilter = ""; apSearch.text = ""; apCurrent = ""; apOpen = true
            if (apAll.length === 0) apAllProc.running = true; else apRefilter()
            apCurProc.command = ["bash", openScript, "default", apFile]; apCurProc.running = true
            apSearch.forceActiveFocus()
            return
        }
        if (name === "dual") { dualToggle(); return }
        if (name === "toother") { toOther(arg); return }
        if (name === "view") { setView(arg); return }
        if (name === "sort") { setSort(arg); return }
        if (name === "sortdir") { sortDesc = arg === "desc"; rebuild(true); saveState(); return }
        if (name === "newtab") { newTab(arg ? arg : cwd); return }
        if (name === "newwin") { Quickshell.execDetached(["bash", binDir + "/filemanager/fm.sh", arg ? arg : cwd]); return }
        if (name === "deleteperm") { if (p.length > 0) { confirmKind = "delperm"; confirmPaths = p; dlgMode = "confirm"; dlgKeys.forceActiveFocus() } return }
        if (name === "props") {
            var pp = inTrash ? [] : (p.length > 0 ? p : [cwd])
            if (pp.length === 0) return
            propRows = [["", "Calculating ..."]]
            infoProc.command = ["bash", infoScript].concat(pp)
            infoProc.running = true
            dlgMode = "props"; dlgKeys.forceActiveFocus()
            return
        }
        if (name === "isize") { isz = arg; saveState(); if (view !== "icon") setView("icon"); return }
        if (name === "restore") { if (p.length > 0) runOp(["restore"].concat(p), "Restoring", false, trashScript); return }
        if (name === "empty") { confirmKind = "empty"; confirmPaths = []; dlgMode = "confirm"; dlgKeys.forceActiveFocus(); return }
        if (name === "copy" || name === "cut") {
            if (p.length === 0) return
            Quickshell.execDetached(["bash", opScript, "clip-set", name].concat(p))
            opMsg = plural(p.length) + (name === "copy" ? " copied" : " cut") + " - paste with Ctrl+V (also in another window)"
            notify((name === "copy" ? "Copied " : "Cut ") + plural(p.length) + "  -  paste with Ctrl+V", false)
        }
        else if (name === "open") openItem(cur)
        else if (name === "openparent") { if (cur >= 0 && items[cur]) { var fp = fullPath(items[cur]); go(parent(fp), true) } }
        else if (name === "goto") go(arg, true)
        else if (name === "pin") { sideRun(["pin", arg]); opMsg = "Pinned: " + arg; notify("Pinned to side pane", false) }
        else if (name === "unpin") { sideRun(["unpin", arg]); opMsg = "Unpinned"; notify("Unpinned", false) }
        else if (name === "terminal") { if (cur >= 0 && items[cur] && items[cur].dir) Quickshell.execDetached(["kitty", "--directory", fullPath(items[cur])]) }
        else if (name === "terminalHere") Quickshell.execDetached(["kitty", "--directory", cwd])
        else if (name === "refresh") go(cwd, false)
        else if (name === "extract") { if (p.length === 1) runOp(["extract", cwd, p[0]], "Extracting", true) }
        else if (name === "paste") startTransfer("paste", cwd, [])
        else if (name === "pasteinto") { if (arg) startTransfer("paste", arg, []) }
        else if (name === "undo") runOp(["undo"], "Undoing", true)
        else if (name === "zip") { if (p.length > 0) runOp(["zip", cwd].concat(p), "Compressing", true) }
        else if (name === "copypath") { if (p.length === 1) runOp(["copypath", p[0]], "Copying path", true) }
        else if (name === "openwith") { if (p.length === 1) { owPaths = p; openProc.command = ["bash", openScript, "list", p[0]]; openProc.running = true } }
        else if (name === "owrun") { if (owPaths.length > 0) { Quickshell.execDetached(["bash", openScript, "run", arg].concat(owPaths)); notify("Opening ...", false) } }
        else if (name === "delete") { if (p.length > 0) { confirmKind = inTrash ? "purge" : "trash"; confirmPaths = p; dlgMode = "confirm"; dlgKeys.forceActiveFocus() } }
        else if (name === "rename") {
            if (selCount > 1) { dlgMode = "brename"; dlgInput.text = "Item ##"; dlgInput.forceActiveFocus(); dlgInput.select(0, 4); return }
            if (cur < 0 || !items[cur]) return
            dlgMode = "rename"; dlgInput.text = baseName(items[cur].name)
            dlgInput.forceActiveFocus()
            var bn = baseName(items[cur].name), d = bn.lastIndexOf(".")
            dlgInput.select(0, d > 0 && !items[cur].dir ? d : bn.length)
        }
        else if (name === "mkdir") { dlgMode = "mkdir"; dlgInput.text = "New folder"; dlgInput.forceActiveFocus(); dlgInput.selectAll() }
        else if (name === "mkfile") { dlgMode = "mkfile"; dlgInput.text = "New file.txt"; dlgInput.forceActiveFocus(); dlgInput.select(0, 8) }
    }
    function dlgAccept() {
        dlgT = Date.now()
        var m = dlgMode
        if (m === "props") { dlgMode = ""; keys.forceActiveFocus(); return }
        if (m === "confirm") {
            dlgMode = ""; keys.forceActiveFocus()
            if (confirmKind === "empty") runOp(["empty"], "Emptying Trash", true, trashScript)
            else if (confirmPaths.length > 0 && confirmKind === "delperm") runOp(["rmrf"].concat(confirmPaths), "Deleting", true)
            else if (confirmPaths.length > 0 && confirmKind === "purge") runOp(["purge"].concat(confirmPaths), "Deleting", true, trashScript)
            else if (confirmPaths.length > 0) runOp(["trash"].concat(confirmPaths), "Moving to Trash")
            return
        }
        var t = dlgInput.text.trim()
        dlgMode = ""; keys.forceActiveFocus()
        if (t === "") return
        if (m === "brename") runOp(["batchrename", t].concat(selPaths()), "Renaming")
        else if (m === "rename" && cur >= 0) runOp(["rename", fullPath(items[cur]), t], "Renaming")
        else if (m === "mkdir") runOp(["mkdir", cwd, t], "Creating folder")
        else if (m === "mkfile") runOp(["mkfile", cwd, t], "Creating file")
    }
    function dlgCancel() { dlgT = Date.now(); dlgMode = ""; keys.forceActiveFocus() }
    function fmtSize(b) {
        if (b < 1024) return b + " B"
        var u = ["KB", "MB", "GB", "TB"], v = b / 1024, i = 0
        while (v >= 1024 && i < 3) { v /= 1024; i++ }
        return (v < 10 ? v.toFixed(1) : Math.round(v)) + " " + u[i]
    }
    function fmtDate(t) { return t > 0 ? Qt.formatDateTime(new Date(t * 1000), "dd/MM/yyyy HH:mm") : "" }

    Process {
        id: lister
        property string target: ""
        stdout: StdioCollector {
            onStreamFinished: {
                var r = null
                try { r = JSON.parse(text) } catch (e) { r = null }
                if (r === null) { app.err = "Could not read the folder (no answer from fm-ls.sh)" }
                else if (!r.ok) { app.err = r.error || "Error" }
                else {
                    app.err = ""
                    var same = (r.path === app.cwd)
                    app.cwd = r.path
                    app.allItems = r.items
                    app.rebuild(same)
                    app.dirSig = ""; if (r.path !== "trash:///") statProc.running = true
                    if (r.path !== "trash:///" && !dfProc.running) { dfProc.forDir = r.path; dfProc.command = ["bash", "-c", "timeout 3 df -B1 --output=avail -- \"$1\" 2>/dev/null | tail -n1", "x", r.path]; dfProc.running = true }
                }
                if (app.pending !== "") app.load(app.pending)
            }
        }
    }

    Process {
        id: deepProc
        property string cwdAt: ""
        property string q: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (deepProc.cwdAt !== app.cwd || deepProc.q !== app.filterText.trim() || !app.searchDeep) return
                var r = null
                try { r = JSON.parse(text) } catch (e) { r = null }
                app.deepBusy = false
                if (r === null || !r.ok) { app.err = (r && r.error) ? r.error : "Search failed (no answer from fm-find.sh)"; return }
                app.err = ""
                app.deepActive = true
                app.deepTrunc = r.truncated === true
                app.allItems = r.items
                app.rebuild(false)
            }
        }
    }
    Timer { id: deepTimer; interval: 450; onTriggered: app.runDeep() }

    Process {
        id: svgChk
        command: ["test", "-f", app.home + "/.config/snow/fm/folder.svg"]
        onExited: (code, status) => { app.svgOn = (code === 0) }
    }
    Timer { id: svgTimer; interval: 150; onTriggered: svgChk.running = true }
    Timer { id: pickQuit; interval: 250; onTriggered: Qt.quit() }
    Process {
        id: itListProc
        command: ["bash", app.themeScript, "list"]
        stdout: StdioCollector {
            onStreamFinished: { try { var r = JSON.parse(text); app.iconThemes = r.themes; app.iconThemeCur = r.current } catch (e) { app.iconThemes = [] } }
        }
    }
    Process {
        id: itSetProc
        stdout: StdioCollector {
            onStreamFinished: {
                try { var r = JSON.parse(text); app.notify(r.msg, !r.ok); if (r.ok) { app.iconRev = app.iconRev + 1; itListProc.running = true } }
                catch (e) { app.notify("Icon theme: no answer from icon-theme.sh", true) }
            }
        }
    }
    Process {
        id: iconProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "") return
                try {
                    var r = JSON.parse(text)
                    app.notify(r.msg, !r.ok)
                    if (r.ok) { app.iconRev = app.iconRev + 1; app.svgOn = false; svgTimer.start() }
                } catch (e) { app.notify("Folder icon: no answer from fm-icon.sh", true) }
            }
        }
    }
    Process {
        id: apAllProc
        command: ["bash", app.openScript, "all"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { app.apAll = JSON.parse(text).apps } catch (e) { app.apAll = [] }
                app.apRefilter()
            }
        }
    }
    Process {
        id: apCurProc
        stdout: StdioCollector {
            onStreamFinished: { try { app.apCurrent = JSON.parse(text).name } catch (e) { app.apCurrent = "" } }
        }
    }
    Process {
        id: apSetProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var r = JSON.parse(text)
                    app.notify(r.msg, !r.ok)
                    if (r.ok) app.apRun(app.apPending)
                } catch (e) { app.notify("Default program: no answer from fm-open.sh", true) }
            }
        }
    }
    Process {
        id: op
        stdout: SplitParser { onRead: (line) => app.opLine(line) }
        onExited: (code, status) => app.opDone()
    }

    Process {
        id: sideList
        command: ["bash", app.sideScript, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { var r = JSON.parse(text); app.places = r.places; app.pins = r.pins; app.buildSide() } catch (e) { }
            }
        }
    }
    Process {
        id: sideRunner
        onExited: app.sideLoad()
    }

    Process {
        id: devList
        command: ["bash", app.devScript, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text === app.devText) return
                try { var r = JSON.parse(text); app.devText = text; app.devs = r.devs; app.buildSide() } catch (e) { }
            }
        }
    }
    Process {
        id: dfProc
        property string forDir: ""
        stdout: StdioCollector {
            onStreamFinished: {
                var b = parseInt(text.trim())
                if (dfProc.forDir === app.cwd) app.freeText = isNaN(b) ? "" : app.fmtSize(b)
            }
        }
    }
    Process {
        id: pasLister
        property string target: ""
        stdout: StdioCollector {
            onStreamFinished: {
                var r = null
                try { r = JSON.parse(text) } catch (e) { r = null }
                var o = app.pas
                if (r === null || !r.ok) {
                    app.pas = { cwd: o.cwd, allItems: [], items: [], hist: o.hist, hidx: o.hidx, err: r === null ? "Could not read the folder" : (r.error || "Error"), view: o.view, isz: o.isz, hidden: o.hidden, sortKey: o.sortKey, sortDesc: o.sortDesc }
                } else {
                    var a = r.items.slice(); app.pasSort(a, o.sortKey, o.sortDesc)
                    app.pas = { cwd: r.path, allItems: r.items, items: a, hist: o.hist.length > 0 ? o.hist : [r.path], hidx: o.hist.length > 0 ? o.hidx : 0, err: "", view: o.view, isz: o.isz, hidden: o.hidden, sortKey: o.sortKey, sortDesc: o.sortDesc }
                }
                app.pasSig = ""
                if (app.pasPending !== "") app.pasLoad(app.pasPending)
            }
        }
    }
    Process {
        id: pasStat
        command: ["stat", "-c", "%.9Y", "--", app.pas.cwd]
        stdout: StdioCollector {
            onStreamFinished: {
                var sg = text.trim()
                if (sg === "") return
                if (app.pasSig === "") app.pasSig = sg
                else if (sg !== app.pasSig) { app.pasSig = sg; app.pasLoad() }
            }
        }
    }
    Timer {
        interval: 2500
        running: app.dualOn
        repeat: true
        onTriggered: if (!pasLister.running && !pasStat.running && !app.opBusy && app.pas.cwd !== "" && app.pas.cwd !== "trash:///") pasStat.running = true
    }
    Process {
        id: statProc
        command: ["stat", "-c", "%.9Y", "--", app.cwd]
        stdout: StdioCollector {
            onStreamFinished: {
                var sg = text.trim()
                if (sg === "") return
                if (app.dirSig === "") app.dirSig = sg
                else if (sg !== app.dirSig) { app.dirSig = sg; app.go(app.cwd, false) }
            }
        }
    }
    Timer { id: typeTimer; interval: 800; onTriggered: app.typeBuf = "" }
    Process {
        id: conflProc
        stdout: StdioCollector { onStreamFinished: app.conflictResult(text) }
    }
    Process {
        id: openProc
        stdout: StdioCollector {
            onStreamFinished: {
                var m = []
                try {
                    var a = JSON.parse(text).apps
                    for (var q = 0; q < a.length; q++) m.push({ ic: app.icApps, lb: a[q].name, a: "owrun", arg: a[q].id, on: true })
                } catch (e) { }
                if (m.length === 0) m.push({ ic: app.icApps, lb: "No program found", a: "none", on: false })
                m.push({ sep: true })
                m.push({ ic: app.icApps, lb: "Other programs ...", a: "owmore", on: true })
                var h = 12 + (m.length - 1) * 34 + 9
                app.menuModel = m
                app.menuY = Math.max(8, Math.min(app.menuY, win.height - h - 8))
                app.menuOpen = true
            }
        }
    }
    Process {
        id: infoProc
        stdout: StdioCollector {
            onStreamFinished: {
                try { app.propRows = JSON.parse(text).rows } catch (e) { app.propRows = [["Error", "no answer from fm-info.sh"]] }
            }
        }
    }
    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: if (!lister.running && !statProc.running && !app.deepActive && !app.deepBusy && !app.opBusy && app.cwd !== "" && app.cwd !== "trash:///") statProc.running = true
    }
    Timer { id: toastTimer; interval: 2800; onTriggered: app.toastShow = false }
    Process {
        id: devRunner
        stdout: StdioCollector { onStreamFinished: app.devDone(text) }
    }
    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: if (!devList.running) app.devLoad()
    }

    Process {
        id: stateProc
        command: ["cat", app.statePath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var r = JSON.parse(text)
                    if (["icon", "list", "details"].indexOf(r.view) >= 0) app.view = app.pickMode !== "" ? "list" : r.view
                    if (["s", "m", "l", "xl", "xxl"].indexOf(r.isz) >= 0) app.isz = r.isz
                    if (["name", "size", "date", "type"].indexOf(r.sortKey) >= 0) { app.sortKey = r.sortKey; app.sortDesc = r.sortDesc === true }
                    if (typeof r.dual === "boolean" && app.pickMode === "" && r.dual && !app.dual) { app.dual = true; app.pas = { cwd: "", allItems: [], items: [], hist: [], hidx: -1, err: "", view: app.view, isz: app.isz, hidden: app.showHidden, sortKey: app.sortKey, sortDesc: app.sortDesc }; app.pasLoad(app.cwd !== "" ? app.cwd : app.home) }
                    if (app.allItems.length > 0) app.rebuild(true)
                } catch (e) { }
            }
        }
    }
    Component.onCompleted: {
        var st = Quickshell.env("FM_START")
        if (pickMode !== "") { view = "list"; sideW = 170 }
        go(st ? st : home, true); sideLoad(); devLoad(); stateProc.running = true; svgChk.running = true; itListProc.running = true
    }

    FloatingWindow {
        id: win
        visible: true
        title: app.pickMode !== "" ? (app.pickTitle !== "" ? app.pickTitle : (app.pickMode === "dir" ? "Choose a folder" : "Choose a ." + app.pickMode + " file")) : "Snow Files"
        implicitWidth: app.pickMode !== "" ? 780 : 980
        implicitHeight: app.pickMode !== "" ? 540 : 660
        minimumSize: app.pickMode !== "" ? Qt.size(780, 540) : Qt.size(0, 0)
        maximumSize: app.pickMode !== "" ? Qt.size(780, 540) : Qt.size(0, 0)
        color: Theme.bg
        onVisibleChanged: if (!visible) Qt.quit()

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: (e) => {
                if (app.zoneKeys(e)) { e.accepted = true }
                else if (e.modifiers & Qt.AltModifier && e.key === Qt.Key_Left) { app.back(); e.accepted = true }
                else if (e.modifiers & Qt.AltModifier && e.key === Qt.Key_Right) { app.forward(); e.accepted = true }
                else if (e.modifiers & Qt.AltModifier && e.key === Qt.Key_Up) { app.up(); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_H) { app.showHidden = !app.showHidden; app.go(app.cwd, false); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_L) { app.startPathEdit(); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && !(e.modifiers & Qt.ShiftModifier) && e.key === Qt.Key_T) { app.newTab(app.inTrash ? app.home : app.cwd); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_W) { app.closeTab(app.tabIdx); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && (e.key === Qt.Key_Tab || e.key === Qt.Key_PageDown)) { app.switchTab((app.tabIdx + 1) % app.tabs.length); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && (e.key === Qt.Key_Backtab || e.key === Qt.Key_PageUp)) { app.switchTab((app.tabIdx + app.tabs.length - 1) % app.tabs.length); e.accepted = true }
                else if (e.modifiers & Qt.AltModifier && (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)) { app.act("props"); e.accepted = true }
                else if (e.key === Qt.Key_F5) { app.go(app.cwd, false); e.accepted = true }
                else if (e.key === Qt.Key_Backspace) { app.up(); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_1) { app.setView("icon"); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_2) { app.setView("list"); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_3) { app.setView("details"); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && !(e.modifiers & Qt.ShiftModifier) && e.key === Qt.Key_D) { app.dualToggle(); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && !(e.modifiers & Qt.ShiftModifier) && (e.key === Qt.Key_Left || e.key === Qt.Key_Right)) { if (app.dualOn && app.act2 !== (e.key === Qt.Key_Left ? 0 : 1)) app.paneSwap(); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.modifiers & Qt.ShiftModifier && e.key === Qt.Key_C) { app.toOther("copy"); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.modifiers & Qt.ShiftModifier && e.key === Qt.Key_X) { app.toOther("move"); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_A) { app.selectAll(); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_C) { app.act("copy"); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_X) { app.act("cut"); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_V) { app.act("paste"); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && (e.key === Qt.Key_Plus || e.key === Qt.Key_Equal)) { app.sizeStep(1); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_Minus) { app.sizeStep(-1); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.modifiers & Qt.ShiftModifier && e.key === Qt.Key_N) { app.act("mkdir"); e.accepted = true }
                else if (e.key === Qt.Key_Delete) { app.act((e.modifiers & Qt.ShiftModifier) ? "deleteperm" : "delete"); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_F) { searchInput.forceActiveFocus(); searchInput.selectAll(); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && !(e.modifiers & Qt.ShiftModifier) && e.key === Qt.Key_N) { app.act("newwin", app.inTrash ? app.home : app.cwd); e.accepted = true }
                else if (e.modifiers & Qt.ControlModifier && !(e.modifiers & Qt.ShiftModifier) && e.key === Qt.Key_Z) { app.act("undo"); e.accepted = true }
                else if (e.key === Qt.Key_F2) { app.act("rename"); e.accepted = true }
                else if (e.key === Qt.Key_Escape) { if (app.dragging) app.dragCancel(); else if (app.menuOpen) app.menuOpen = false; else app.setSel({}); e.accepted = true }
                else if (e.key === Qt.Key_Down) { app.move(app.view === "icon" ? app.cols : 1, e.modifiers); e.accepted = true }
                else if (e.key === Qt.Key_Up) { app.move(app.view === "icon" ? -app.cols : -1, e.modifiers); e.accepted = true }
                else if (e.key === Qt.Key_Right && app.view === "icon") { app.move(1, e.modifiers); e.accepted = true }
                else if (e.key === Qt.Key_Left && app.view === "icon") { app.move(-1, e.modifiers); e.accepted = true }
                else if (e.key === Qt.Key_Home) { app.pick(0, e.modifiers); e.accepted = true }
                else if (e.key === Qt.Key_End) { app.pick(app.items.length - 1, e.modifiers); e.accepted = true }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (Date.now() - app.dlgT > 400) app.openItem(app.cur); e.accepted = true }
                else if (e.text.length === 1 && e.text > " " && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) { app.jumpTo(e.text); e.accepted = true }
                else if (e.key === Qt.Key_Space && app.typeBuf !== "") { app.jumpTo(" "); e.accepted = true }
                else if (e.key === Qt.Key_Space && app.cur >= 0) { app.spaceSel(e.modifiers); e.accepted = true }
            }

            // ---------- toolbar
            Rectangle {
                id: bar
                x: 12; y: 12
                width: parent.width - 24
                height: 48
                radius: 24
                color: Theme.surface

                Row {
                    id: btns
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Repeater {
                        model: [
                            { ic: app.icBack, on: app.hidx > 0, act: 0 },
                            { ic: app.icFwd, on: app.hidx < app.hist.length - 1, act: 1 },
                            { ic: app.icUp, on: app.cwd !== "/", act: 2 },
                            { ic: app.icHome, on: true, act: 3 }
                        ]
                        delegate: Rectangle {
                            width: 36; height: 36; radius: 18
                            color: ma.containsMouse && modelData.on ? Theme.surfaceHi : "transparent"
                            border.width: (app.zone === "bar" && app.barIdx === modelData.act) ? 2 : 0
                            border.color: Theme.accent
                            opacity: modelData.on ? 1 : 0.35
                            Text {
                                anchors.centerIn: parent
                                text: modelData.ic
                                font.family: Theme.iconFont
                                renderType: Text.NativeRendering
                                font.pixelSize: 22
                                color: Theme.text
                            }
                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (m) => {
                                    if (m.button === Qt.RightButton) {
                                        if (modelData.act === 3) { var hp = ma.mapToItem(keys, 0, 40); app.homeMenu(hp.x, hp.y) }
                                        return
                                    }
                                    if (!modelData.on) return
                                    if (modelData.act === 0) app.back()
                                    else if (modelData.act === 1) app.forward()
                                    else if (modelData.act === 2) app.up()
                                    else app.go(app.home, true)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: pathBox
                    x: btns.x + btns.width + 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - (app.pickMode !== "" ? 20 : 188) - 190
                    height: 34
                    radius: 17
                    color: Theme.bg
                    border.width: (app.pathEdit || (app.zone === "bar" && app.barIdx === 4)) ? 2 : 0
                    border.color: Theme.accent
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                        visible: !app.pathEdit
                        onClicked: app.startPathEdit()
                    }
                    Item {
                        id: crumbBox
                        visible: !app.pathEdit
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        clip: true
                        Row {
                            id: crumbRow
                            height: parent.height
                            x: Math.min(0, crumbBox.width - width)
                            Repeater {
                                model: app.crumbs
                                delegate: Row {
                                    height: crumbRow.height
                                    Text {
                                        visible: index > 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "\u203A"
                                        color: Theme.muted
                                        font.family: Theme.uiFont
                                        font.pixelSize: 16
                                        leftPadding: 2
                                        rightPadding: 2
                                    }
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: cTxt.implicitWidth + 18
                                        height: 26
                                        radius: 13
                                        color: cMa2.containsMouse ? Theme.surfaceHi : (index === app.crumbs.length - 1 ? Qt.alpha(Theme.accent, 0.22) : "transparent")
                                        Text {
                                            id: cTxt
                                            anchors.centerIn: parent
                                            text: modelData.n
                                            color: index === app.crumbs.length - 1 ? Theme.text : Theme.muted
                                            font.family: Theme.uiFont
                                            font.pixelSize: 14
                                            font.weight: index === app.crumbs.length - 1 ? Font.DemiBold : Font.Normal
                                        }
                                        MouseArea {
                                            id: cMa2
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: { keys.forceActiveFocus(); if (modelData.p !== app.cwd) app.go(modelData.p, true) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    TextInput {
                        id: pathInput
                        visible: app.pathEdit
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.uiFont
                        font.pixelSize: 15
                        color: Theme.text
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.accentText
                        clip: true
                        onActiveFocusChanged: if (!activeFocus) app.pathEdit = false
                        onAccepted: { app.dlgT = Date.now(); app.pathEdit = false; app.go(text, true); keys.forceActiveFocus() }
                        Keys.onEscapePressed: { app.pathEdit = false; keys.forceActiveFocus() }
                        Keys.onTabPressed: { app.barIdx = 4; app.zoneSet("side", true); if (!app.sideShown) app.zoneSet("bar", true) }
                        Keys.onBacktabPressed: { app.barIdx = 4; app.zoneSet("list", true) }
                    }
                }

                Rectangle {
                    id: searchBox
                    x: pathBox.x + pathBox.width + 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 190
                    height: 34
                    radius: 17
                    color: Theme.bg
                    border.width: (searchInput.activeFocus || (app.zone === "bar" && app.barIdx === 5)) ? 2 : 0
                    border.color: Theme.accent
                    Text {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: app.icSearch
                        font.family: Theme.iconFont
                        renderType: Text.NativeRendering
                        font.pixelSize: 18
                        color: app.searchDeep ? Theme.accent : Theme.muted
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -5
                            onClicked: {
                                app.searchDeep = !app.searchDeep
                                if (app.searchDeep && app.filterText.trim() !== "") app.runDeep()
                                else if (!app.searchDeep) { deepTimer.stop(); if (app.deepActive || app.deepBusy) app.leaveDeep(); else app.rebuild(true) }
                                keys.forceActiveFocus()
                            }
                        }
                    }
                    Text {
                        x: 34
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchInput.text === "" && !searchInput.activeFocus
                        text: app.searchDeep ? "Search + sub folders" : "Search  (Ctrl+F)"
                        font.family: Theme.uiFont
                        font.pixelSize: 13
                        color: Theme.muted
                    }
                    TextInput {
                        id: searchInput
                        x: 34
                        width: parent.width - 34 - 30
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.uiFont
                        font.pixelSize: 14
                        color: Theme.text
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.accentText
                        clip: true
                        onTextChanged: if (text !== app.filterText) { app.filterText = text; app.searchChanged() }
                        onAccepted: { app.dlgT = Date.now(); if (app.searchDeep && text.trim() !== "") { deepTimer.stop(); app.runDeep() } keys.forceActiveFocus() }
                        Keys.onEscapePressed: { text = ""; keys.forceActiveFocus() }
                        Keys.onTabPressed: { app.barIdx = 5; app.zoneSet("list", true) }
                        Keys.onBacktabPressed: { app.barIdx = 5; app.zoneSet("bar", true) }
                    }
                    Text {
                        visible: searchInput.text !== ""
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: app.icClose
                        font.family: Theme.iconFont
                        renderType: Text.NativeRendering
                        font.pixelSize: 18
                        color: Theme.muted
                        MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: { searchInput.text = ""; keys.forceActiveFocus() } }
                    }
                    Connections {
                        target: app
                        function onFilterTextChanged() { if (searchInput.text !== app.filterText) searchInput.text = app.filterText }
                    }
                }

                Row {
                    visible: app.pickMode === ""
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Repeater {
                        model: [ { act: 2 }, { act: 3 }, { act: 0 }, { act: 1 } ]
                        delegate: Rectangle {
                            width: 36; height: 36; radius: 18
                            color: ma2.containsMouse ? Theme.surfaceHi : "transparent"
                            border.width: (app.zone === "bar" && app.barIdx === (modelData.act === 2 ? 6 : modelData.act === 3 ? 7 : modelData.act === 0 ? 8 : -1)) ? 2 : 0
                            border.color: Theme.accent
                            Text {
                                anchors.centerIn: parent
                                text: modelData.act === 3 ? app.icDual : modelData.act === 0 ? (app.showHidden ? app.icEye : app.icEyeOff)
                                    : modelData.act === 1 ? app.icClose
                                    : app.view === "icon" ? app.icGrid : app.view === "list" ? app.icList : app.icTable
                                font.family: Theme.iconFont
                                renderType: Text.NativeRendering
                                font.pixelSize: 22
                                color: (modelData.act === 0 && app.showHidden) || modelData.act === 2 || (modelData.act === 3 && app.dual) ? Theme.accent : Theme.text
                            }
                            MouseArea {
                                id: ma2
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (m) => {
                                    if (modelData.act === 2) {
                                        if (m.button === Qt.RightButton) { var vp = ma2.mapToItem(keys, 0, ma2.height + 8); app.viewMenu(vp.x - 190, vp.y) }
                                        else app.cycleView()
                                    }
                                    else if (modelData.act === 3) app.dualToggle()
                                    else if (modelData.act === 1) Qt.quit()
                                    else { app.showHidden = !app.showHidden; app.go(app.cwd, false) }
                                }
                            }
                        }
                    }
                }
            }

            // ---------- tab strip (only when there is more than one tab)
            Item {
                id: tabBar
                visible: app.tabs.length > 1 && app.pickMode === ""
                x: 12; y: 12 + 48 + 6
                width: parent.width - 24
                height: 32
                Row {
                    spacing: 6
                    Repeater {
                        model: app.tabs.length
                        delegate: Rectangle {
                            readonly property bool isAct: index === app.tabIdx
                            width: Math.max(110, Math.min(210, (tabBar.width - 44) / app.tabs.length - 6)); height: 32; radius: 16
                            color: isAct ? Qt.alpha(Theme.accent, 0.28) : (tMa.containsMouse ? Theme.surfaceHi : Theme.surface)
                            border.width: isAct ? 1 : 0
                            border.color: Qt.alpha(Theme.accent, 0.6)
                            Text {
                                x: 14; width: parent.width - 46
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: app.tabLabel(index)
                                color: isAct ? Theme.text : Theme.muted
                                font.family: Theme.uiFont
                                font.pixelSize: 14
                            }
                            MouseArea {
                                id: tMa
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                onClicked: (m) => { if (m.button === Qt.MiddleButton) app.closeTab(index); else app.switchTab(index) }
                            }
                            Rectangle {
                                x: parent.width - 30; y: 5
                                width: 22; height: 22; radius: 11
                                color: tcMa.containsMouse ? Theme.danger : "transparent"
                                visible: tMa.containsMouse || tcMa.containsMouse || isAct
                                Text { anchors.centerIn: parent; text: app.icClose; font.family: Theme.iconFont; renderType: Text.NativeRendering; font.pixelSize: 15; color: tcMa.containsMouse ? "#ffffff" : Theme.muted }
                                MouseArea { id: tcMa; anchors.fill: parent; hoverEnabled: true; onClicked: app.closeTab(index) }
                            }
                        }
                    }
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: tpMa.containsMouse ? Theme.surfaceHi : Theme.surface
                        Text { anchors.centerIn: parent; text: app.icAdd; font.family: Theme.iconFont; renderType: Text.NativeRendering; font.pixelSize: 20; color: Theme.muted }
                        MouseArea { id: tpMa; anchors.fill: parent; hoverEnabled: true; onClicked: app.newTab(app.inTrash ? app.home : app.cwd) }
                    }
                }
            }

            // ---------- two panes: path title above each pane
            Repeater {
                model: app.dualOn ? 2 : 0
                delegate: Rectangle {
                    readonly property bool isAct: index === app.act2
                    x: app.contentX + index * (app.paneW + 8)
                    y: app.contentTop
                    width: app.paneW; height: 30; radius: 15
                    color: isAct ? Qt.alpha(Theme.accent, 0.22) : (tiMa.containsMouse ? Theme.surfaceHi : Theme.surface)
                    border.width: isAct ? 1 : 0
                    border.color: Qt.alpha(Theme.accent, 0.6)
                    Text {
                        x: 14; width: parent.width - 54
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideLeft
                        text: app.paneTitle(isAct ? app.cwd : app.pas.cwd)
                        textFormat: Text.PlainText
                        color: isAct ? Theme.text : Theme.muted
                        font.family: Theme.uiFont
                        font.pixelSize: 13
                    }
                    MouseArea { id: tiMa; anchors.fill: parent; hoverEnabled: true; onClicked: { keys.forceActiveFocus(); if (!isAct) app.paneSwap() } }
                    Rectangle {
                        x: parent.width - 30; y: 4
                        width: 22; height: 22; radius: 11
                        color: xMa.containsMouse ? Theme.danger : "transparent"
                        Text { anchors.centerIn: parent; text: app.icClose; font.family: Theme.iconFont; renderType: Text.NativeRendering; font.pixelSize: 15; color: xMa.containsMouse ? "#ffffff" : Theme.muted }
                        MouseArea { id: xMa; anchors.fill: parent; hoverEnabled: true; onClicked: app.paneClose(index) }
                    }
                }
            }

            // ---------- two panes: the other (not active) pane. A click on it makes it the active pane.
            Rectangle {
                id: pcard
                visible: app.dualOn
                x: app.contentX + (app.act2 === 0 ? app.paneW + 8 : 0)
                y: app.contentTop + app.paneTop
                width: app.paneW
                height: parent.height - y - 44
                radius: 18
                color: Theme.surface
                border.width: 1
                border.color: Qt.alpha(Theme.tint, 0.08)
                clip: true
                DropArea {
                    anchors.fill: parent
                    enabled: app.dualOn && app.pas.cwd !== ""
                    onDropped: (drop) => app.dropOn(app.pas.cwd, drop)
                }
                Text {
                    visible: app.pas.err !== ""
                    anchors.centerIn: parent
                    text: app.pas.err
                    color: Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: 15
                }
                Text {
                    visible: app.pas.err === "" && app.pas.items.length === 0 && app.pas.cwd !== ""
                    anchors.centerIn: parent
                    text: "This folder is empty"
                    color: Theme.muted
                    font.family: Theme.uiFont
                    font.pixelSize: 15
                }
                Item {
                    visible: app.pas.view === "details"
                    x: 8; y: 6
                    width: parent.width - 16
                    height: 28
                    readonly property bool sh: pasList.width >= 330
                    readonly property bool dt: pasList.width >= 480
                    Text { x: 52; anchors.verticalCenter: parent.verticalCenter; text: "Name"; font.family: Theme.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.muted }
                    Text { visible: parent.sh; x: parent.dt ? parent.width - app.wDate - 20 - app.wSize : parent.width - app.wSize - 10; width: app.wSize; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter; text: "Size"; font.family: Theme.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.muted }
                    Text { visible: parent.dt; x: parent.width - app.wDate - 10; width: app.wDate; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter; text: "Modified"; font.family: Theme.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.muted }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.alpha(Theme.tint, 0.08) }
                }
                ListView {
                    id: pasList
                    visible: app.pas.view !== "icon"
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.topMargin: app.pas.view === "details" ? 38 : 8
                    model: app.pas.items
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle {
                        readonly property bool det: app.pas.view === "details"
                        readonly property bool sh: det && pasList.width >= 330
                        readonly property bool dt: det && pasList.width >= 480
                        width: pasList.width
                        height: app.pas.view === "list" ? 30 : 38
                        radius: 10
                        color: pnMa.hov === index ? Qt.alpha(Theme.tint, 0.09) : (det && index % 2 === 1) ? Qt.alpha(Theme.tint, 0.03) : "transparent"
                        border.width: pDrop.containsDrag ? 2 : 0
                        border.color: Theme.accent
                        FolderIcon {
                            visible: modelData.dir === true
                            x: 10
                            sz: 28
                            anchors.verticalCenter: parent.verticalCenter
                            tone: Theme.accent
                            iconFont: Theme.iconFont
                            svgSrc: app.folderSvgFor(app.pas.cwd, modelData.name)
                            glyph: app.folderGlyph(app.pas.cwd, modelData.name)
                            dim: modelData.hidden === true
                        }
                        FileIcon {
                            visible: modelData.dir !== true
                            x: 10
                            sz: 28
                            anchors.verticalCenter: parent.verticalCenter
                            property var st: app.fileStyle(modelData.name)
                            tone: st.tone; glyph: st.glyph; label: st.label; dark: st.dark; zip: st.zip; svgSrc: app.iconsDir + "/file-" + st.kind + ".svg" + app.revSuffix
                            iconFont: Theme.iconFont
                        }
                        Text {
                            x: 52
                            width: parent.width - 52 - (dt ? app.wDate + app.wSize + 40 : sh ? app.wSize + 26 : 12)
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            textFormat: Text.PlainText
                            elide: Text.ElideMiddle
                            font.family: Theme.uiFont
                            font.pixelSize: 15
                            color: modelData.hidden ? Theme.muted : Theme.text
                        }
                        Text {
                            visible: sh
                            x: dt ? parent.width - app.wDate - 20 - app.wSize : parent.width - app.wSize - 10
                            width: app.wSize
                            horizontalAlignment: Text.AlignHCenter
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.dir ? "" : app.fmtSize(modelData.size)
                            font.family: Theme.uiFont
                            font.pixelSize: 13
                            color: Theme.muted
                        }
                        Text {
                            visible: dt
                            x: parent.width - app.wDate - 10
                            width: app.wDate
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                            text: app.fmtDate(modelData.mtime)
                            font.family: Theme.uiFont
                            font.pixelSize: 13
                            color: Theme.muted
                        }
                        DropArea {
                            id: pDrop
                            anchors.fill: parent
                            enabled: modelData.dir === true && app.pas.cwd !== "trash:///"
                            onDropped: (drop) => app.dropOn((app.pas.cwd === "/" ? "" : app.pas.cwd) + "/" + modelData.name, drop)
                        }
                    }
                }
                GridView {
                    id: pasGrid
                    visible: app.pas.view === "icon"
                    anchors.fill: parent
                    anchors.margins: 8
                    cellWidth: app.szCell(app.pas.isz)
                    cellHeight: app.szPx(app.pas.isz) + 62
                    model: app.pas.items
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Item {
                        readonly property int px: app.szPx(app.pas.isz)
                        width: pasGrid.cellWidth
                        height: pasGrid.cellHeight
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: 12
                            color: pnMa.hov === index ? Qt.alpha(Theme.tint, 0.09) : "transparent"
                            border.width: gpDrop.containsDrag ? 2 : 0
                            border.color: Theme.accent
                            FolderIcon {
                                visible: modelData.dir === true
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 8
                                sz: px
                                tone: Theme.accent
                                iconFont: Theme.iconFont
                                svgSrc: app.folderSvgFor(app.pas.cwd, modelData.name)
                                glyph: app.folderGlyph(app.pas.cwd, modelData.name)
                                dim: modelData.hidden === true
                            }
                            FileIcon {
                                visible: modelData.dir !== true
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 8
                                sz: px
                                property var st: app.fileStyle(modelData.name)
                                tone: st.tone; glyph: st.glyph; label: st.label; dark: st.dark; zip: st.zip; svgSrc: app.iconsDir + "/file-" + st.kind + ".svg" + app.revSuffix
                                iconFont: Theme.iconFont
                            }
                            Text {
                                x: 6; y: px + 16
                                width: parent.width - 12
                                height: 36
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.name
                                textFormat: Text.PlainText
                                wrapMode: Text.WrapAnywhere
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                font.family: Theme.uiFont
                                font.pixelSize: 13
                                color: modelData.hidden ? Theme.muted : Theme.text
                            }
                            DropArea {
                                id: gpDrop
                                anchors.fill: parent
                                enabled: modelData.dir === true && app.pas.cwd !== "trash:///"
                                onDropped: (drop) => app.dropOn((app.pas.cwd === "/" ? "" : app.pas.cwd) + "/" + modelData.name, drop)
                            }
                        }
                    }
                }
                MouseArea {
                    id: pnMa
                    anchors.fill: parent
                    z: 3
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    property int hov: -1
                    function idxAt(x, y) {
                        var v = app.pas.view === "icon" ? pasGrid : pasList
                        var q = mapToItem(v, x, y)
                        if (q.x < 0 || q.y < 0 || q.x > v.width || q.y > v.height) return -1
                        return v.indexAt(q.x + v.contentX, q.y + v.contentY)
                    }
                    onPositionChanged: (m) => { hov = idxAt(m.x, m.y) }
                    onExited: hov = -1
                    onWheel: (w) => { w.accepted = false }
                    onClicked: (m) => {
                        var i = idxAt(m.x, m.y)
                        var pp = mapToItem(keys, m.x, m.y)
                        if (i >= 0) app.pasClick(i, m.button, m.modifiers, pp.x, pp.y)
                        else { keys.forceActiveFocus(); app.paneSwap() }
                    }
                }
            }

            // ---------- list card
            Rectangle {
                id: card
                border.width: (app.zoneShow && app.zone === "list") ? 2 : 1
                border.color: (app.zoneShow && app.zone === "list") ? Theme.accent : Qt.alpha(Theme.tint, 0.08)
                x: app.contentX + (app.dualOn && app.act2 === 1 ? app.paneW + 8 : 0)
                y: app.contentTop + app.paneTop
                width: app.paneW
                height: parent.height - y - 44
                radius: 18
                color: Theme.surface
                clip: true

                // files dragged in from other programs: dropped on the empty list = copied into the open folder
                DropArea {
                    id: cardDrop
                    anchors.fill: parent
                    enabled: !app.dragging && !app.inTrash && app.cwd !== "" && app.pickMode === ""
                    onDropped: (drop) => app.dropOn(app.cwd, drop)
                }
                Rectangle { z: 8; anchors.fill: parent; radius: 18; color: "transparent"; border.width: cardDrop.containsDrag ? 2 : 0; border.color: Theme.accent }

                Text {
                    visible: app.err !== ""
                    anchors.centerIn: parent
                    text: app.err
                    color: Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: 16
                }
                Text {
                    visible: app.err === "" && app.items.length === 0 && app.cwd !== ""
                    anchors.centerIn: parent
                    text: "This folder is empty"
                    color: Theme.muted
                    font.family: Theme.uiFont
                    font.pixelSize: 16
                }

                Item {
                    id: hdr
                    visible: app.view === "details"
                    x: 8; y: 6
                    width: parent.width - 16
                    height: 28
                    Repeater {
                        model: [ { k: "name", t: "Name" }, { k: "type", t: "Type" }, { k: "size", t: "Size" }, { k: "date", t: "Modified" } ]
                        delegate: Rectangle {
                            id: hc
                            readonly property bool isName: modelData.k === "name"
                            visible: isName || app.colShown(modelData.k)
                            x: isName ? 46 : hdr.width + app.colX(modelData.k)
                            width: isName ? Math.max(60, hdr.width - 52 - app.colsW) + 6 : app.colW(modelData.k)
                            height: 26; radius: 13
                            antialiasing: true
                            anchors.verticalCenter: parent.verticalCenter
                            color: hMa.containsMouse ? Qt.alpha(Theme.tint, 0.07) : "transparent"
                            // title + sort arrow as one group: left for Name, centred for the other columns (same centre as the row texts)
                            Row {
                                spacing: 3
                                x: hc.isName ? 6 : (hc.width - width) / 2
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.t
                                    textFormat: Text.PlainText
                                    font.family: Theme.uiFont
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: app.sortKey === modelData.k ? Theme.accent : Theme.muted
                                }
                                Text {
                                    visible: app.sortKey === modelData.k
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: app.sortDesc ? app.icArrowDown : app.icArrowUp
                                    font.family: Theme.iconFont
                                    renderType: Text.NativeRendering
                                    font.pixelSize: 14
                                    color: Theme.accent
                                }
                            }
                            MouseArea { id: hMa; anchors.fill: parent; hoverEnabled: true; onClicked: app.setSort(modelData.k) }
                        }
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.alpha(Theme.tint, 0.08) }
                }

                ListView {
                    id: list
                    visible: app.view !== "icon"
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.topMargin: app.view === "details" ? 38 : 8
                    model: app.items
                    currentIndex: app.cur
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle {
                        width: list.width
                        height: app.view === "list" ? 30 : 38
                        radius: 10
                        color: app.selMap[index] === true ? Qt.alpha(Theme.accent, 0.28)
                             : rowMa.containsMouse ? Qt.alpha(Theme.tint, 0.09)
                             : (app.view === "details" && index % 2 === 1) ? Qt.alpha(Theme.tint, 0.03) : "transparent"
                        Behavior on color { ColorAnimation { duration: 110 } }
                        Rectangle {
                            visible: app.selMap[index] === true
                            x: 2; width: 3; height: parent.height - 12; radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.accent
                        }
                        border.width: rowDrop.containsDrag ? 2 : (app.cur === index && app.selMap[index] !== true) ? 1 : 0
                        border.color: Theme.accent
                        FolderIcon {
                            visible: modelData.dir === true
                            x: 10
                            sz: 28
                            anchors.verticalCenter: parent.verticalCenter
                            tone: Theme.accent
                            iconFont: Theme.iconFont
                            svgSrc: app.folderSvgFor(app.cwd, modelData.name)
                            glyph: app.folderGlyph(app.cwd, modelData.name)
                            dim: modelData.hidden === true
                        }
                        FileIcon {
                            visible: modelData.dir !== true && !rthumb.visible
                            x: 10
                            sz: 28
                            anchors.verticalCenter: parent.verticalCenter
                            property var st: app.fileStyle(modelData.name)
                            tone: st.tone; glyph: st.glyph; label: st.label; dark: st.dark; zip: st.zip; svgSrc: app.iconsDir + "/file-" + st.kind + ".svg" + app.revSuffix
                            iconFont: Theme.iconFont
                        }
                        Image {
                            id: rthumb
                            visible: status === Image.Ready
                            x: 13; width: 24; height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            source: app.thumbSrc(modelData)
                            asynchronous: true
                            sourceSize.width: 48; sourceSize.height: 48
                            fillMode: Image.PreserveAspectCrop
                        }
                        Text {
                            x: 52
                            width: parent.width - 52 - (app.view === "details" ? app.colsW : 12)
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            elide: Text.ElideMiddle
                            font.family: Theme.uiFont
                            font.pixelSize: 15
                            color: modelData.hidden ? Theme.muted : Theme.text
                        }
                        Text {
                            visible: app.view === "details" && app.colShown("type")
                            x: parent.width + app.colX("type")
                            width: app.wType
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                            text: app.kindOf(modelData)
                            font.family: Theme.uiFont
                            font.pixelSize: 13
                            color: Theme.muted
                        }
                        Text {
                            visible: app.view === "details" && app.colShown("size")
                            x: parent.width + app.colX("size")
                            width: app.wSize
                            horizontalAlignment: Text.AlignHCenter
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.dir ? "" : app.fmtSize(modelData.size)
                            font.family: Theme.uiFont
                            font.pixelSize: 13
                            color: Theme.muted
                        }
                        Text {
                            visible: app.view === "details" && app.colShown("date")
                            x: parent.width + app.colX("date")
                            width: app.wDate
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                            text: app.fmtDate(modelData.mtime)
                            font.family: Theme.uiFont
                            font.pixelSize: 13
                            color: Theme.muted
                        }
                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            preventStealing: app.dragPressed
                            onCanceled: app.dragCancel()
                            onPressed: (m) => { if (m.button === Qt.LeftButton) { var p = rowMa.mapToItem(keys, m.x, m.y); app.dragPress(index, p.x, p.y) } }
                            onPositionChanged: (m) => { if (app.dragPressed) { var p = rowMa.mapToItem(keys, m.x, m.y); app.dragMove(p.x, p.y) } }
                            onReleased: (m) => { app.dragEnd(m.modifiers) }
                            onClicked: (m) => {
                                keys.forceActiveFocus()
                                if (app.justDragged) { app.justDragged = false; return }
                                if (m.button === Qt.RightButton) { var p = rowMa.mapToItem(keys, m.x, m.y); app.openMenu(index, p.x, p.y) }
                                else app.pick(index, m.modifiers)
                            }
                            onDoubleClicked: { if (Date.now() - app.swapT > 450) app.openItem(index) }
                        }
                        DropArea {
                            id: rowDrop
                            anchors.fill: parent
                            enabled: modelData.dir === true && (!app.dragging || app.selMap[index] !== true) && !app.inTrash && app.pickMode === ""
                            onEntered: app.dropHint = app.dragging ? app.hintFor(app.fullPath(modelData)) : ""
                            onExited: app.dropHint = ""
                            onDropped: (drop) => app.dropOn(app.fullPath(modelData), drop)
                        }
                    }
                }

                GridView {
                    id: grid
                    visible: app.view === "icon"
                    anchors.fill: parent
                    anchors.margins: 8
                    cellWidth: app.cellW
                    cellHeight: app.cellH
                    model: app.items
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Item {
                        width: grid.cellWidth
                        height: grid.cellHeight
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: 12
                            color: app.selMap[index] === true ? Qt.alpha(Theme.accent, 0.28)
                                 : gMa.containsMouse ? Qt.alpha(Theme.tint, 0.09) : "transparent"
                            border.width: gDrop.containsDrag ? 2 : ((app.selMap[index] === true || app.cur === index) ? 1 : 0)
                            border.color: gDrop.containsDrag ? Theme.accent : Qt.alpha(Theme.accent, 0.6)
                            Behavior on color { ColorAnimation { duration: 110 } }
                            FolderIcon {
                                visible: modelData.dir === true
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 8
                                sz: app.iconPx
                                tone: Theme.accent
                                iconFont: Theme.iconFont
                                svgSrc: app.folderSvgFor(app.cwd, modelData.name)
                                glyph: app.folderGlyph(app.cwd, modelData.name)
                                dim: modelData.hidden === true
                            }
                            FileIcon {
                                visible: modelData.dir !== true && !gthumb.visible
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 8
                                sz: app.iconPx
                                property var st: app.fileStyle(modelData.name)
                                tone: st.tone; glyph: st.glyph; label: st.label; dark: st.dark; zip: st.zip; svgSrc: app.iconsDir + "/file-" + st.kind + ".svg" + app.revSuffix
                                iconFont: Theme.iconFont
                            }
                            Image {
                                id: gthumb
                                visible: status === Image.Ready
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 8
                                width: app.iconPx; height: app.iconPx
                                source: app.thumbSrc(modelData)
                                asynchronous: true
                                sourceSize.width: app.iconPx * 2; sourceSize.height: app.iconPx * 2
                                fillMode: Image.PreserveAspectCrop
                            }
                            Text {
                                x: 6; y: app.iconPx + 16
                                width: parent.width - 12
                                height: 36
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.name
                                wrapMode: Text.WrapAnywhere
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                font.family: Theme.uiFont
                                font.pixelSize: 13
                                color: modelData.hidden ? Theme.muted : Theme.text
                            }
                            MouseArea {
                                id: gMa
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                preventStealing: app.dragPressed
                                onCanceled: app.dragCancel()
                                onPressed: (m) => { if (m.button === Qt.LeftButton) { var p = gMa.mapToItem(keys, m.x, m.y); app.dragPress(index, p.x, p.y) } }
                                onPositionChanged: (m) => { if (app.dragPressed) { var p = gMa.mapToItem(keys, m.x, m.y); app.dragMove(p.x, p.y) } }
                                onReleased: (m) => { app.dragEnd(m.modifiers) }
                                onClicked: (m) => {
                                    keys.forceActiveFocus()
                                    if (app.justDragged) { app.justDragged = false; return }
                                    if (m.button === Qt.RightButton) { var p = gMa.mapToItem(keys, m.x, m.y); app.openMenu(index, p.x, p.y) }
                                    else app.pick(index, m.modifiers)
                                }
                                onDoubleClicked: { if (Date.now() - app.swapT > 450) app.openItem(index) }
                            }
                            DropArea {
                                id: gDrop
                                anchors.fill: parent
                                enabled: modelData.dir === true && (!app.dragging || app.selMap[index] !== true) && !app.inTrash && app.pickMode === ""
                                onEntered: app.dropHint = app.dragging ? app.hintFor(app.fullPath(modelData)) : ""
                                onExited: app.dropHint = ""
                                onDropped: (drop) => app.dropOn(app.fullPath(modelData), drop)
                            }
                        }
                    }
                }
            }

            // ---------- scroll bar for the file list (shown only when the list is longer than the window; drag it or click the track)
            Item {
                id: vbar
                readonly property var v: app.view === "icon" ? grid : list
                readonly property real maxY: Math.max(1, v.contentHeight - v.height)
                visible: v.contentHeight > v.height + 1 && app.dlgMode === ""
                x: card.x + card.width - 15
                y: card.y + (app.view === "details" ? 46 : 12)
                width: 12
                height: card.height - (app.view === "details" ? 58 : 24)
                z: 6
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 4; height: parent.height; radius: 2; color: Qt.alpha(Theme.tint, 0.08) }
                Rectangle {
                    id: vhandle
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: vma.pressed || vma.containsMouse ? 8 : 5
                    radius: width / 2
                    color: vma.pressed ? Theme.accent : Qt.alpha(Theme.accent, 0.65)
                    height: Math.max(34, vbar.height * vbar.v.height / Math.max(1, vbar.v.contentHeight))
                    y: Math.max(0, Math.min(vbar.height - height, (vbar.height - height) * vbar.v.contentY / vbar.maxY))
                }
                MouseArea {
                    id: vma
                    anchors.fill: parent
                    hoverEnabled: true
                    preventStealing: true
                    function setFrom(my) {
                        var f = (my - vhandle.height / 2) / Math.max(1, vbar.height - vhandle.height)
                        vbar.v.contentY = Math.max(0, Math.min(vbar.maxY, f * vbar.maxY))
                    }
                    onPressed: (m) => setFrom(m.y)
                    onPositionChanged: (m) => { if (pressed) setFrom(m.y) }
                }
            }

            // ---------- a click anywhere on the list card (also on empty space of an empty folder) gives the focus back to the list, so an open path box turns into buttons again
            MouseArea {
                x: card.x; y: card.y; width: card.width; height: card.height
                z: 4
                acceptedButtons: Qt.LeftButton
                onPressed: (m) => {
                    app.zone = "list"; app.zoneShow = false; keys.forceActiveFocus()
                    var v = app.view === "icon" ? grid : list
                    var q = mapToItem(v, m.x, m.y)
                    if (q.x >= 0 && q.y >= 0 && q.x <= v.width && q.y <= v.height && v.indexAt(q.x + v.contentX, q.y + v.contentY) < 0 && !(m.modifiers & (Qt.ControlModifier | Qt.ShiftModifier))) app.setSel({})
                    m.accepted = false
                }
            }

            // ---------- right-click overlay on the list card: decides which row is under the mouse (left clicks pass through)
            MouseArea {
                x: card.x; y: card.y; width: card.width; height: card.height
                z: 5
                acceptedButtons: Qt.RightButton
                onWheel: (w) => {
                    if ((w.modifiers & Qt.ControlModifier) && app.view === "icon") { app.sizeWheel(w.angleDelta.y); w.accepted = true }
                    else w.accepted = false
                }
                onClicked: (m) => {
                    var v = app.view === "icon" ? grid : list
                    var q = mapToItem(v, m.x, m.y)
                    var i = v.indexAt(q.x + v.contentX, q.y + v.contentY)
                    var p = mapToItem(keys, m.x, m.y)
                    keys.forceActiveFocus()
                    app.openMenu(i, p.x, p.y)
                }
            }

            // ---------- side pane: three separate boxes (Places / Devices / Pinned)
            Item {
                id: side
                visible: app.sideShown
                x: 12
                y: app.contentTop
                width: app.sideW
                height: parent.height - y - 44
                property var lay: app.boxLayout(height, app.sidePlaces, app.sideDevs, app.sidePins)
                Repeater {
                    model: [app.sidePlaces, app.sideDevs, app.sidePins]
                    delegate: Rectangle {
                        id: sbox
                        readonly property int bi: index
                        x: 0
                        y: side.lay[index].y
                        width: side.width
                        height: side.lay[index].h
                        visible: height > 0
                        radius: 18
                        color: Theme.surface
                        border.width: (app.zoneShow && app.zone === "side") ? 2 : 1
                        border.color: (app.zoneShow && app.zone === "side") ? Theme.accent : Qt.alpha(Theme.tint, 0.08)
                        clip: true
                        ListView {
                            id: sideView
                            anchors.fill: parent
                            anchors.margins: 8
                            anchors.rightMargin: contentHeight > height + 1 ? 14 : 8
                            model: modelData
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            delegate: Item {
                                width: sideView.width
                                height: modelData.head === true ? 30 : (modelData.sub !== undefined ? (modelData.total > 0 ? 54 : 46) : 36)
                                Text {
                                    visible: modelData.head === true
                                    x: 10
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 4
                                    text: modelData.text !== undefined ? modelData.text : ""
                                    color: Theme.muted
                                    font.family: Theme.uiFont
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Rectangle {
                                    visible: modelData.head !== true
                                    anchors.fill: parent
                                    anchors.topMargin: 1
                                    anchors.bottomMargin: 1
                                    radius: 12
                                    color: modelData.path === app.cwd ? Qt.alpha(Theme.accent, 0.28)
                                         : (app.zone === "side" && app.sideSel === sbox.bi + ":" + index) ? Qt.alpha(Theme.tint, 0.16)
                                         : sMa.containsMouse ? Qt.alpha(Theme.tint, 0.09) : "transparent"
                                    border.width: (app.zone === "side" && app.sideSel === sbox.bi + ":" + index) ? 2 : 0
                                    border.color: Theme.accent
                                    Behavior on color { ColorAnimation { duration: 110 } }
                                    Rectangle {
                                        visible: modelData.path === app.cwd
                                        x: 1; width: 3; height: parent.height - 14; radius: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Theme.accent
                                    }
                                    Text {
                                        x: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.ic !== undefined ? modelData.ic : ""
                                        font.family: Theme.iconFont
                                        renderType: Text.NativeRendering
                                        font.pixelSize: 22
                                        color: modelData.path === app.cwd ? Theme.accent : Theme.muted
                                    }
                                    Text {
                                        x: 42
                                        width: parent.width - 52 - (modelData.dev !== undefined && modelData.mounted && modelData.removable ? 30 : 0)
                                        y: modelData.sub !== undefined ? 5 : (parent.height - height) / 2
                                        elide: Text.ElideRight
                                        text: modelData.name !== undefined ? modelData.name : ""
                                        color: Theme.text
                                        font.family: Theme.uiFont
                                        font.pixelSize: 16
                                    }
                                    Text {
                                        visible: modelData.sub !== undefined
                                        x: 42
                                        y: 25
                                        width: parent.width - 52
                                        elide: Text.ElideRight
                                        text: modelData.sub !== undefined ? modelData.sub : ""
                                        color: Theme.muted
                                        font.family: Theme.uiFont
                                        font.pixelSize: 13
                                    }
                                    Rectangle {
                                        visible: modelData.total > 0
                                        x: 42; y: parent.height - 9
                                        width: parent.width - 52; height: 4; radius: 2
                                        color: Qt.alpha(Theme.tint, 0.12)
                                        Rectangle {
                                            readonly property real used: Math.min(1, Math.max(0, 1 - modelData.avail / Math.max(1, modelData.total)))
                                            width: parent.width * used; height: parent.height; radius: 2
                                            color: used > 0.9 ? Theme.danger : Theme.accent
                                        }
                                    }
                                    Rectangle {
                                        visible: modelData.dev !== undefined && modelData.mounted === true && modelData.removable === true
                                        z: 3
                                        x: parent.width - 32; y: (parent.height - 26) / 2
                                        width: 26; height: 26; radius: 13
                                        color: ejMa.containsMouse ? Theme.surfaceHi : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: app.icEject
                                            font.family: Theme.iconFont
                                            renderType: Text.NativeRendering
                                            font.pixelSize: 18
                                            color: Theme.text
                                        }
                                        MouseArea {
                                            id: ejMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: { keys.forceActiveFocus(); app.devAct("eject", modelData.dev, false, modelData.path) }
                                        }
                                    }
                                    DropArea {
                                        id: sDrop
                                        anchors.fill: parent
                                        enabled: modelData.head !== true && modelData.path !== undefined && modelData.path !== "" && (modelData.path !== app.cwd || !app.dragging) && app.pickMode === ""
                                        onEntered: app.dropHint = app.dragging ? app.hintFor(modelData.path) : ""
                                        onExited: app.dropHint = ""
                                        onDropped: (drop) => app.dropOn(modelData.path, drop)
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 12
                                        color: "transparent"
                                        border.width: sDrop.containsDrag ? 2 : 0
                                        border.color: Theme.accent
                                    }
                                    MouseArea {
                                        id: sMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: (m) => {
                                            keys.forceActiveFocus()
                                            if (m.button === Qt.RightButton) { var p = sMa.mapToItem(keys, m.x, m.y); app.sideMenu(modelData, p.x, p.y) }
                                            else if (modelData.dev !== undefined) app.devClick(modelData)
                                            else app.go(modelData.path, true)
                                        }
                                    }
                                }
                            }

                        }
                        // scroll bar of this box (shown only when the box is shorter than its list)
                        Item {
                            id: sbar
                            readonly property real maxY: Math.max(1, sideView.contentHeight - sideView.height)
                            visible: sideView.contentHeight > sideView.height + 1
                            x: sbox.width - 12
                            y: 12
                            width: 10
                            height: sbox.height - 24
                            z: 6
                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 4; height: parent.height; radius: 2; color: Qt.alpha(Theme.tint, 0.08) }
                            Rectangle {
                                id: shandle
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: sma.pressed || sma.containsMouse ? 8 : 5
                                radius: width / 2
                                color: sma.pressed ? Theme.accent : Qt.alpha(Theme.accent, 0.65)
                                height: Math.max(30, sbar.height * sideView.height / Math.max(1, sideView.contentHeight))
                                y: Math.max(0, Math.min(sbar.height - height, (sbar.height - height) * sideView.contentY / sbar.maxY))
                            }
                            MouseArea {
                                id: sma
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true
                                function setFrom(my) {
                                    var f = (my - shandle.height / 2) / Math.max(1, sbar.height - shandle.height)
                                    sideView.contentY = Math.max(0, Math.min(sbar.maxY, f * sbar.maxY))
                                }
                                onPressed: (m) => setFrom(m.y)
                                onPositionChanged: (m) => { if (pressed) setFrom(m.y) }
                            }
                        }
                    }
                }
            }

            // ---------- status line / progress
            Rectangle {
                visible: app.pickMode !== ""
                x: parent.width - 12 - 196
                y: parent.height - 38
                width: 196; height: 34
                color: "transparent"
                z: 5
                Rectangle {
                    width: 90; height: 34; radius: 17
                    color: pcMa.containsMouse ? Theme.surfaceHi : "transparent"
                    border.width: 1; border.color: Qt.alpha(Theme.tint, 0.18)
                    Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: 14 }
                    MouseArea { id: pcMa; anchors.fill: parent; hoverEnabled: true; onClicked: Qt.quit() }
                }
                Rectangle {
                    x: 100
                    width: 96; height: 34; radius: 17
                    color: Theme.accent
                    opacity: app.pickOk() ? 1 : 0.35
                    Text { anchors.centerIn: parent; text: "Select"; color: Theme.accentText; font.family: Theme.uiFont; font.pixelSize: 14; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; onClicked: app.pickDone() }
                }
            }
            Item {
                x: app.contentX + 12
                y: parent.height - 34
                width: parent.width - x - 24 - (app.pickMode !== "" ? 204 : 0)
                height: 28

                Text {
                    visible: !app.opBusy
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    elide: Text.ElideRight
                    text: app.opMsg.indexOf("Problem") === 0 ? app.opMsg : app.statusText()
                    color: app.opMsg.indexOf("Problem") === 0 ? Theme.danger : Theme.muted
                    font.family: Theme.uiFont
                    font.pixelSize: 13
                }
                Row {
                    visible: app.opBusy
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    Text {
                        width: 190
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideMiddle
                        text: app.opText
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: 13
                    }
                    Rectangle {
                        width: 300; height: 8; radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.surfaceHi
                        Rectangle { width: app.opIndet ? parent.width : parent.width * app.opPct / 100; height: parent.height; radius: 4; color: Theme.accent; opacity: app.opIndet ? 0.45 : 1 }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: app.opIndet ? "..." : app.opPct + " %"
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: 13
                    }
                    Rectangle {
                        width: 70; height: 24; radius: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: cMa.containsMouse ? Theme.danger : Theme.surfaceHi
                        Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: 13 }
                        MouseArea { id: cMa; anchors.fill: parent; hoverEnabled: true; onClicked: op.running = false }
                    }
                }
            }

            // ---------- drag and drop: invisible 1px proxy that carries the drag, and a small label that follows the mouse
            Item {
                id: dragProxy
                x: app.dragX; y: app.dragY
                width: 1; height: 1
                Drag.active: app.dragging && !app.dragExt
                Drag.dragType: Drag.Internal
                Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
                Drag.hotSpot.x: 0; Drag.hotSpot.y: 0
            }
            Item {
                id: dragProxyExt
                width: 1; height: 1
                Drag.active: app.dragExt
                Drag.dragType: Drag.Automatic
                Drag.supportedActions: Qt.CopyAction
                Drag.proposedAction: Qt.CopyAction
                Drag.mimeData: ({ "text/uri-list": app.dragUriText })
                Drag.onDragFinished: (dropAction) => app.extDragDone()
            }
            Rectangle {
                visible: app.dragging && !app.dragExt
                z: 20
                x: Math.min(app.dragX + 14, parent.width - width - 8); y: app.dragY + 14
                width: dlabel.implicitWidth + 24; height: 30; radius: 15
                color: Theme.surfaceHi
                border.width: 1
                border.color: Theme.accent
                Text {
                    id: dlabel
                    anchors.centerIn: parent
                    text: app.dropHint !== "" ? app.dropHint : app.plural(app.dragPaths.length)
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: 13
                }
            }

            // ---------- right-click menu
            Item {
                visible: app.menuOpen
                anchors.fill: parent
                z: 9
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: { app.menuOpen = false; keys.forceActiveFocus() }
                }
                Rectangle {
                    x: app.menuX; y: app.menuY
                    width: 240
                    height: mcol.implicitHeight + 12
                    radius: 16
                    color: Theme.surface
                    border.width: 1
                    border.color: Qt.alpha(Theme.tint, 0.12)
                    MouseArea { anchors.fill: parent }
                    Column {
                        id: mcol
                        x: 6; y: 6
                        width: parent.width - 12
                        Repeater {
                            model: app.menuModel
                            delegate: Item {
                                id: mrow
                                width: mcol.width
                                height: modelData.sep ? 9 : 34
                                Rectangle {
                                    visible: modelData.sep === true
                                    x: 10; y: 4
                                    width: parent.width - 20; height: 1
                                    color: Qt.alpha(Theme.tint, 0.14)
                                }
                                Rectangle {
                                    visible: modelData.sep !== true
                                    anchors.fill: parent
                                    radius: 10
                                    color: mm.containsMouse && modelData.on ? Theme.surfaceHi : "transparent"
                                    opacity: modelData.on ? 1 : 0.35
                                    Text {
                                        x: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.ic !== undefined ? modelData.ic : ""
                                        font.family: Theme.iconFont
                                        renderType: Text.NativeRendering
                                        font.pixelSize: 20
                                        color: modelData.danger === true ? Theme.danger : Theme.muted
                                    }
                                    Text {
                                        x: 40
                                        width: parent.width - 50 - (modelData.sub !== undefined ? 22 : 0)
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.lb !== undefined ? modelData.lb : ""
                                        font.family: Theme.uiFont
                                        font.pixelSize: 14
                                        color: modelData.danger === true ? Theme.danger : Theme.text
                                    }
                                    Text {
                                        visible: modelData.sub !== undefined
                                        x: parent.width - 28
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: app.icChevron
                                        font.family: Theme.iconFont
                                        renderType: Text.NativeRendering
                                        font.pixelSize: 20
                                        color: Theme.muted
                                    }
                                    MouseArea {
                                        id: mm
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: { if (modelData.sub !== undefined) { app.subModel = modelData.sub; app.subY = app.menuY + 6 + mrow.y } else app.subModel = [] }
                                        onClicked: {
                                            if (modelData.sub !== undefined) { app.subModel = modelData.sub; app.subY = app.menuY + 6 + mrow.y }
                                            else if (modelData.on) app.menuClick(modelData.a, modelData.arg, modelData.mp)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                // sub menu (Sort by): opens next to the main menu
                Rectangle {
                    visible: app.subModel.length > 0
                    x: (app.menuX + 244 + 240 > win.width - 8) ? app.menuX - 244 : app.menuX + 244
                    y: Math.max(8, Math.min(app.subY, win.height - scol.implicitHeight - 20))
                    width: 240
                    height: scol.implicitHeight + 12
                    radius: 16
                    color: Theme.surface
                    border.width: 1
                    border.color: Qt.alpha(Theme.tint, 0.12)
                    MouseArea { anchors.fill: parent }
                    Column {
                        id: scol
                        x: 6; y: 6
                        width: parent.width - 12
                        Repeater {
                            model: app.subModel
                            delegate: Item {
                                width: scol.width
                                height: modelData.sep ? 9 : 34
                                Rectangle {
                                    visible: modelData.sep === true
                                    x: 10; y: 4
                                    width: parent.width - 20; height: 1
                                    color: Qt.alpha(Theme.tint, 0.14)
                                }
                                Rectangle {
                                    visible: modelData.sep !== true
                                    anchors.fill: parent
                                    radius: 10
                                    color: sm.containsMouse ? Theme.surfaceHi : "transparent"
                                    Text {
                                        x: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.ic !== undefined ? modelData.ic : ""
                                        font.family: Theme.iconFont
                                        renderType: Text.NativeRendering
                                        font.pixelSize: 20
                                        color: Theme.accent
                                    }
                                    Text {
                                        x: 40
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.lb !== undefined ? modelData.lb : ""
                                        font.family: Theme.uiFont
                                        font.pixelSize: 14
                                        color: Theme.text
                                    }
                                    MouseArea {
                                        id: sm
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: app.menuClick(modelData.a, modelData.arg, "")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---------- toast (small notification)
            Rectangle {
                id: toastBox
                z: 8
                height: 40
                width: toastTxt.implicitWidth + 64
                radius: 20
                x: app.contentX + (parent.width - app.contentX - 12 - width) / 2
                y: parent.height - 86
                color: Theme.surfaceHi
                border.width: 1
                border.color: app.toastBad ? Theme.danger : Qt.alpha(Theme.accent, 0.7)
                opacity: app.toastShow ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Text {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: app.toastBad ? app.icEject : app.icCheck
                    visible: !app.toastBad
                    font.family: Theme.iconFont
                    renderType: Text.NativeRendering
                    font.pixelSize: 20
                    color: Theme.accent
                }
                Text {
                    id: toastTxt
                    x: app.toastBad ? 18 : 42
                    anchors.verticalCenter: parent.verticalCenter
                    text: app.toast
                    color: app.toastBad ? Theme.danger : Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: 14
                }
                MouseArea { anchors.fill: parent; onClicked: app.toastShow = false }
            }

            // ---------- name dialog (rename / new folder / confirm delete)
            Rectangle {
                visible: app.dlgMode !== ""
                anchors.fill: parent
                z: 10
                color: Qt.alpha("#000000", 0.45)
                MouseArea { anchors.fill: parent; onClicked: app.dlgCancel() }
                Rectangle {
                    width: app.dlgMode === "props" ? 540 : (app.dlgMode === "conflict" ? 520 : 440)
                    height: app.dlgMode === "props" ? propCol.implicitHeight + 110 : (app.dlgMode === "confirm" || app.dlgMode === "conflict" ? 264 : (app.dlgMode === "brename" ? 296 : 240))
                    radius: 22
                    anchors.centerIn: parent
                    color: Theme.surface
                    MouseArea { anchors.fill: parent }
                    Rectangle {                     // round icon badge (red for delete / conflict, accent for the rest)
                        visible: app.dlgMode !== "props"
                        width: 52; height: 52; radius: 26
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 20
                        readonly property bool bad: app.dlgMode === "confirm" || app.dlgMode === "conflict"
                        color: Qt.alpha(bad ? Theme.danger : Theme.accent, 0.16)
                        border.width: 1
                        border.color: Qt.alpha(bad ? Theme.danger : Theme.accent, 0.35)
                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.iconFont
                            renderType: Text.NativeRendering
                            font.pixelSize: 28
                            font.variableAxes: ({ "FILL": 1 })
                            color: parent.bad ? Theme.danger : Theme.accent
                            text: String.fromCodePoint(app.dlgMode === "confirm" ? (app.confirmKind === "trash" ? 0xe872 : 0xe92b) : app.dlgMode === "conflict" ? 0xe002 : app.dlgMode === "mkdir" ? 0xe2cc : app.dlgMode === "mkfile" ? 0xe89c : 0xe3c9)
                        }
                    }
                    Text {
                        x: 24; y: app.dlgMode === "props" ? 18 : 80
                        width: parent.width - 48
                        horizontalAlignment: Text.AlignHCenter
                        text: app.dlgMode === "props" ? "Properties" : app.dlgMode === "rename" ? "Rename" : app.dlgMode === "brename" ? "Rename " + app.plural(app.selCount) : app.dlgMode === "conflict" ? "Name already exists" : app.dlgMode === "mkfile" ? "New file" : app.dlgMode === "confirm" ? (app.confirmKind === "trash" ? "Move to Trash?" : app.confirmKind === "empty" ? "Empty Trash?" : "Delete permanently?") : "New folder"
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: 18
                    }
                    Item { id: dlgKeys; Keys.onReturnPressed: app.dlgAccept(); Keys.onEnterPressed: app.dlgAccept(); Keys.onEscapePressed: app.dlgCancel() }
                    Text {
                        visible: app.dlgMode === "confirm"
                        x: 24; y: 116
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - 48
                        height: 70
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        maximumLineCount: 3
                        text: app.confirmKind === "empty" ? "Empty the Trash? Everything in it (also from other drives) will be deleted for good."
                            : (app.confirmKind === "purge" || app.confirmKind === "delperm") ? (app.confirmPaths.length === 1 ? "Delete \"" + (app.confirmKind === "purge" && app.items[app.cur] ? app.items[app.cur].name : app.confirmPaths[0].replace(/^.*\//, "")) + "\" permanently? This cannot be undone." : "Delete " + app.plural(app.confirmPaths.length) + " permanently? This cannot be undone.")
                            : app.confirmPaths.length === 1 ? "Move \"" + app.confirmPaths[0].replace(/^.*\//, "") + "\" to the Trash?"
                            : "Move " + app.plural(app.confirmPaths.length) + " to the Trash?"
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: 15
                    }
                    Text {
                        visible: app.dlgMode === "brename"
                        x: 24; y: 164
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - 48
                        wrapMode: Text.Wrap
                        text: "Use ## for numbers: 'Holiday ##' gives Holiday 01, Holiday 02 ... (file extensions are kept, in the order shown)."
                        color: Theme.muted
                        font.family: Theme.uiFont
                        font.pixelSize: 13
                    }
                    Text {
                        visible: app.dlgMode === "conflict"
                        x: 24; y: 116
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - 48
                        height: 70
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        maximumLineCount: 3
                        text: (app.conflictNames.length === 1 ? "\"" + app.conflictNames[0] + "\" already exists here." : app.conflictNames.length + " of these items already exist here (" + app.conflictNames.slice(0, 2).join(", ") + " ...).") + " Replace puts the old one in the Trash."
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: 15
                    }
                    Column {
                        id: propCol
                        visible: app.dlgMode === "props"
                        x: 24; y: 58
                        width: parent.width - 48
                        spacing: 6
                        Repeater {
                            model: app.propRows
                            delegate: Row {
                                width: propCol.width
                                spacing: 12
                                Text {
                                    width: 100
                                    text: modelData[0]
                                    color: Theme.muted
                                    font.family: Theme.uiFont
                                    font.pixelSize: 14
                                }
                                Text {
                                    width: propCol.width - 112
                                    text: modelData[1]
                                    wrapMode: Text.WrapAnywhere
                                    color: Theme.text
                                    font.family: Theme.uiFont
                                    font.pixelSize: 14
                                }
                            }
                        }
                    }
                    Rectangle {
                        visible: app.dlgMode === "rename" || app.dlgMode === "brename" || app.dlgMode === "mkdir" || app.dlgMode === "mkfile"
                        x: 24; y: 116
                        width: parent.width - 48; height: 38; radius: 19
                        color: Theme.bg
                        border.width: 2
                        border.color: Theme.accent
                        TextInput {
                            id: dlgInput
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.uiFont
                            font.pixelSize: 15
                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.accentText
                            clip: true
                            onAccepted: app.dlgAccept()
                            Keys.onEscapePressed: app.dlgCancel()
                        }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height - 58
                        spacing: 10
                        Rectangle {
                            visible: app.dlgMode === "conflict"
                            width: 100; height: 34; radius: 17
                            color: cs.containsMouse ? Theme.surfaceHi : "transparent"
                            Text { anchors.centerIn: parent; text: "Skip"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: 14 }
                            MouseArea { id: cs; anchors.fill: parent; hoverEnabled: true; onClicked: app.conflictChoose("skip") }
                        }
                        Rectangle {
                            visible: app.dlgMode === "conflict"
                            width: 110; height: 34; radius: 17
                            color: cb.containsMouse ? Theme.surfaceHi : "transparent"
                            Text { anchors.centerIn: parent; text: "Keep both"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: 14 }
                            MouseArea { id: cb; anchors.fill: parent; hoverEnabled: true; onClicked: app.conflictChoose("both") }
                        }
                        Rectangle {
                            visible: app.dlgMode === "conflict"
                            width: 100; height: 34; radius: 17
                            color: Theme.accent
                            Text { anchors.centerIn: parent; text: "Replace"; color: Theme.accentText; font.family: Theme.uiFont; font.pixelSize: 14 }
                            MouseArea { anchors.fill: parent; onClicked: app.conflictChoose("replace") }
                        }
                        Rectangle {
                            visible: app.dlgMode !== "props"
                            width: 90; height: 34; radius: 17
                            color: c1.containsMouse ? Theme.surfaceHi : "transparent"
                            Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: 14 }
                            MouseArea { id: c1; anchors.fill: parent; hoverEnabled: true; onClicked: app.dlgCancel() }
                        }
                        Rectangle {
                            visible: app.dlgMode !== "conflict"
                            width: app.dlgMode === "confirm" ? (app.confirmKind === "trash" ? 130 : 160) : 90; height: 34; radius: 17
                            color: app.dlgMode === "confirm" ? Theme.danger : Theme.accent
                            Text { anchors.centerIn: parent; text: app.dlgMode === "confirm" ? (app.confirmKind === "trash" ? "Move to Trash" : app.confirmKind === "empty" ? "Empty Trash" : "Delete permanently") : (app.dlgMode === "props" ? "Close" : "OK"); color: app.dlgMode === "confirm" ? "#ffffff" : Theme.accentText; font.family: Theme.uiFont; font.pixelSize: 14 }
                            MouseArea { anchors.fill: parent; onClicked: app.dlgAccept() }
                        }
                    }
                }
            }

            // ---------- "Other programs ..." window: every installed program, search, "always use"
            Rectangle {
                visible: app.apOpen
                anchors.fill: parent
                z: 11
                color: Qt.alpha("#000000", 0.45)
                MouseArea { anchors.fill: parent; onClicked: app.apClose() }
                Rectangle {
                    id: apBox
                    width: Math.min(460, parent.width - 40)
                    height: Math.min(580, parent.height - 40)
                    radius: 22
                    anchors.centerIn: parent
                    color: Theme.surface
                    MouseArea { anchors.fill: parent }
                    Text {
                        x: 24; y: 16
                        width: parent.width - 48
                        elide: Text.ElideMiddle
                        text: "Open \"" + app.apName + "\" with"
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: 18
                    }
                    Text {
                        x: 24; y: 46
                        width: parent.width - 48
                        elide: Text.ElideRight
                        text: app.apCurrent !== "" ? "Now " + app.apExtLabel + " open with: " + app.apCurrent : "No default program set for " + app.apExtLabel
                        color: Theme.muted
                        font.family: Theme.uiFont
                        font.pixelSize: 13
                    }
                    Rectangle {
                        id: apSearchBox
                        x: 24; y: 74
                        width: parent.width - 48
                        height: 34; radius: 17
                        color: Theme.bg
                        border.width: apSearch.activeFocus ? 2 : 0
                        border.color: Theme.accent
                        Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: app.icSearch; font.family: Theme.iconFont; renderType: Text.NativeRendering; font.pixelSize: 18; color: Theme.muted }
                        Text { x: 34; anchors.verticalCenter: parent.verticalCenter; visible: apSearch.text === ""; text: "Search programs"; font.family: Theme.uiFont; font.pixelSize: 13; color: Theme.muted }
                        TextInput {
                            id: apSearch
                            x: 34
                            width: parent.width - 34 - 14
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.uiFont
                            font.pixelSize: 14
                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.accentText
                            clip: true
                            onTextChanged: { app.apFilter = text; app.apRefilter() }
                            onAccepted: { app.dlgT = Date.now(); if (app.apShown.length > 0) app.apChoose(app.apShown[0].id) }
                            Keys.onEscapePressed: app.apClose()
                        }
                    }
                    ListView {
                        id: apList
                        x: 24; y: 118
                        width: parent.width - 48
                        height: parent.height - 118 - 92
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: app.apShown
                        delegate: Rectangle {
                            width: apList.width - 12
                            height: 34; radius: 10
                            color: apMa.containsMouse ? Theme.surfaceHi : "transparent"
                            Text { x: 10; width: parent.width - 20; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; font.family: Theme.uiFont; font.pixelSize: 14; color: Theme.text }
                            MouseArea { id: apMa; anchors.fill: parent; hoverEnabled: true; onClicked: app.apChoose(modelData.id) }
                        }
                        Text { visible: app.apShown.length === 0; anchors.centerIn: parent; text: app.apAll.length === 0 ? "Loading ..." : "No program found"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 14 }
                    }
                    Item {
                        id: apBar
                        visible: apList.contentHeight > apList.height + 1
                        x: apList.x + apList.width - 8
                        y: apList.y
                        width: 8
                        height: apList.height
                        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 4; height: parent.height; radius: 2; color: Qt.alpha(Theme.tint, 0.08) }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 5; radius: 2.5
                            color: Qt.alpha(Theme.accent, 0.65)
                            height: Math.max(30, apBar.height * apList.height / Math.max(1, apList.contentHeight))
                            y: Math.max(0, Math.min(apBar.height - height, (apBar.height - height) * apList.contentY / Math.max(1, apList.contentHeight - apList.height)))
                        }
                    }
                    Rectangle {
                        x: 24; y: parent.height - 76
                        width: parent.width - 48; height: 30; radius: 10
                        color: apChk.containsMouse ? Theme.surfaceHi : "transparent"
                        Rectangle {
                            x: 6; anchors.verticalCenter: parent.verticalCenter
                            width: 20; height: 20; radius: 6
                            color: app.apAlways ? Theme.accent : "transparent"
                            border.width: 2
                            border.color: app.apAlways ? Theme.accent : Theme.muted
                            Text { anchors.centerIn: parent; visible: app.apAlways; text: app.icCheck; font.family: Theme.iconFont; renderType: Text.NativeRendering; font.pixelSize: 16; color: Theme.accentText }
                        }
                        Text { x: 36; width: parent.width - 42; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter; text: "Always use this program for " + app.apExtLabel; font.family: Theme.uiFont; font.pixelSize: 14; color: Theme.text }
                        MouseArea { id: apChk; anchors.fill: parent; hoverEnabled: true; onClicked: app.apAlways = !app.apAlways }
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.rightMargin: 24
                        y: parent.height - 40
                        width: 90; height: 34; radius: 17
                        color: apCx.containsMouse ? Theme.surfaceHi : "transparent"
                        border.width: 1; border.color: Qt.alpha(Theme.tint, 0.18)
                        Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: 14 }
                        MouseArea { id: apCx; anchors.fill: parent; hoverEnabled: true; onClicked: app.apClose() }
                    }
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
"u/.config/snow/state/fm-pins")
cat <<'SNOW_FILE_END_4b7d'
@HOME@/.config
@HOME@/fmtest
@HOME@/DK Final
SNOW_FILE_END_4b7d
;;
"u/.config/snow/state/fm-state.json")
cat <<'SNOW_FILE_END_4b7d'
{"view":"icon","isz":"xxl","sortKey":"name","sortDesc":false,"sideW":320,"wType":60,"wSize":50,"wDate":100}
SNOW_FILE_END_4b7d
;;
"u/.local/share/applications/snow-files.desktop")
cat <<'SNOW_FILE_END_4b7d'
[Desktop Entry]
Type=Application
Name=Files
GenericName=File manager
Comment=Snow file manager (Super+E)
Exec=@HOME@/.config/snow/bin/filemanager/fm.sh %f
Icon=snow-files
Terminal=false
Categories=Utility;System;FileTools;FileManager;
MimeType=inode/directory;
# snow-files
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
pre() {
apt_install libglib2.0-bin gvfs gvfs-backends zip unzip 7zip wl-clipboard udisks2 util-linux libgtk-3-bin kitty thunar
}
post() {
mkdir -p "$HOME/.local/share/icons/hicolor/256x256/apps"
base64 -d > "$HOME/.local/share/icons/hicolor/256x256/apps/snow-files.png" <<'SNOWICON'
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
SNOWICON
mkdir -p "$HOME/.local/share/icons/hicolor/64x64/apps"
base64 -d > "$HOME/.local/share/icons/hicolor/64x64/apps/snow-files.png" <<'SNOWICON'
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
SNOWICON
rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/snow-files.svg"
gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
pass "gold+black icon installed (snow-files)"
[ -f "$BIN/theme/icons-gen.sh" ] && bash "$BIN/theme/icons-gen.sh" >/dev/null 2>&1 && pass "icon folder ready (~/.config/snow/icons)"
command -v xdg-mime >/dev/null 2>&1 && { xdg-mime default snow-files.desktop inode/directory 2>/dev/null; pass "folders open in the Snow file manager (Snow Files)"; }
update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
}
extra_check() {
for c in gio zip unzip wl-copy lsblk; do have "$c" && pass "program $c" || warn "program $c not found (the file manager needs it)" "bash ~/Snow/Script/19-file-manager.sh"; done
for s in filemanager/fm.sh filemanager/fm-default.sh filemanager/fm-dev.sh filemanager/fm-find.sh filemanager/fm-icon.sh filemanager/fm-info.sh filemanager/fm-ls.sh filemanager/fm-op.sh filemanager/fm-open.sh filemanager/fm-side.sh filemanager/fm-trash.sh; do [ -f "$BIN/$s" ] || continue; bash -n "$BIN/$s" && pass "$s: syntax ok" || fail "$s: syntax error" "bash ~/Snow/Script/${MOD}.sh"; done
}
component_main "$@"
