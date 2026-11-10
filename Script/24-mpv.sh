#!/usr/bin/env bash
# 24-mpv.sh : Video player: mpv (Snow player)
# apt mpv + the Snow player look (player-osc.lua), keys, playlist and one-window scripts, and the launcher entry that uses snow-mpv.sh.
#   bash Script/24-mpv.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/24-mpv.sh check    read-only check
MOD="24-mpv"; TITLE="Video player: mpv (Snow player)"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/mpv/input.conf|644|0"
  "u|.config/mpv/mpv.conf|644|0"
  "u|.config/mpv/scripts/player-add.lua|644|0"
  "u|.config/mpv/scripts/player-osc.lua|644|0"
  "u|.config/mpv/scripts/player-single.lua|644|0"
  "u|.config/snow/bin/mpv/snow-mpv.sh|755|0"
  "u|.local/share/applications/mpv.desktop|644|0"
)
emit() {
case "$1" in
"u/.config/mpv/input.conf")
cat <<'SNOW_FILE_END_4b7d'
# ============================================================================
#  input.conf  —  mpv KI KEYS AUR MOUSE      (live file: ~/.config/mpv/input.conf)
# ----------------------------------------------------------------------------
#  FORMAT :  KEY   kaam
#  mpv ki default keys band hain (mpv.conf me), isliye jo key yahan nahi likhi wo kuch nahi karegi.
#  To add a key: add one line. Changes take effect the next time mpv starts.
#  "no-osd" = mpv ka apna text nahi dikhao; "script-message player-flash" = hamari patli progress line dikhao.
#  Volume / mute / speed / audio / subtitle ka message HAMARA hai (player-osc.lua): upar-DAAYEIN, time wale text jaisi size.
# ============================================================================

# ---- awaaz ----
UP          script-message player-vol 5
DOWN        script-message player-vol -5
m           script-message player-mute
`           script-message player-mute

# ---- aage-peeche ----
LEFT        no-osd seek -5 ; script-message player-flash
RIGHT       no-osd seek 5 ; script-message player-flash
Shift+LEFT  no-osd seek -30 ; script-message player-flash
Shift+RIGHT no-osd seek 30 ; script-message player-flash
Alt+LEFT    no-osd frame-back-step ; script-message player-flash
Alt+RIGHT   no-osd frame-step ; script-message player-flash

# ---- playlist ----
Ctrl+LEFT   playlist-prev
Ctrl+RIGHT  playlist-next
# z = playlist menu (file ke NAAM dikhata hai)
z           script-message player-playlist
# x = shuffle on/off (dobara dabao = purana order)
x           script-message player-shuffle-toggle

# ---- speed ----
Ctrl+UP     script-message player-speed 0.1
Ctrl+DOWN   script-message player-speed -0.1
Ctrl+r      script-message player-speed reset

# ---- play / pause / band ----
SPACE       cycle pause
Ctrl+w      quit
q           quit

# ---- audio track / subtitle ----
# a = agla audio track (awaaz chalu bhi kar deta hai), Shift+a = audio menu
a           script-message player-track audio
Shift+a     script-binding select/select-aid
# s = agla subtitle (off -> 1 -> 2 -> off), Shift+s = subtitle menu
s           script-message player-track sub
Shift+s     script-binding select/select-sid

# ---- screen ----
f           cycle fullscreen
ESC         set fullscreen no
# o = poora bar dikhao/chhupao (dobara o dabane tak rukta hai)
o           script-message player-osd-toggle
# i = video ki jaankari (stats)
i           script-binding stats/display-stats-toggle

# ---- mouse ----
# left click: khali window = video chuno; warna pause/play
MBTN_LEFT       script-message player-click
MBTN_LEFT_DBL   cycle fullscreen
MBTN_RIGHT      script-binding select/menu
WHEEL_UP        script-message player-vol 5
WHEEL_DOWN      script-message player-vol -5
SNOW_FILE_END_4b7d
;;
"u/.config/mpv/mpv.conf")
cat <<'SNOW_FILE_END_4b7d'
# ============================================================================
#  mpv.conf  —  mpv PLAYER KI SETTINGS      (live file: ~/.config/mpv/mpv.conf)
# ----------------------------------------------------------------------------
#  NOTE: mpv me comment sirf APNI LINE par likha jata hai ("#" se shuru). Value ke saath ek hi line me comment mat likhna.
#  Changes take effect the next time mpv starts.
# ============================================================================

# --- video kahan se shuru ho ---
# video ruke hue jagah yaad na rakhe
save-position-on-quit=no
# hamesha shuru se
resume-playback=no
# video khatam hone par aakhri frame par ruke (band na ho)
keep-open=yes

# --- hardware decoding (NVIDIA) ---
# nvdec = graphics card se video decode. Agar video shuru hone me deri ho ya atke to "hwdec=no" kar do.
hwdec=nvdec

# --- awaaz ---
# volume 130% tak badh sakta hai
volume-max=130
# PipeWire pehle try karo
ao=pipewire,pulse,alsa
mute=no
aid=auto
# audio bhasha ka order: Hindi, English
alang=hi,hin,en,eng
# milti-julti naam wali alag audio file apne aap lagao
audio-file-auto=fuzzy

# --- subtitles ---
sub-visibility=yes
sid=auto
slang=en,eng,hi,hin
# milte-julte naam wali subtitle file apne aap lagao
sub-auto=fuzzy

# --- window ---
# screen ki 90% se badi window nahi
autofit-larger=90%x90%
# mpv ki apni border band (hamari player-osc.lua apna bar banati hai)
border=no
osd-bar=no
screenshot-directory=~/Pictures

# --- likhawat (OSD) ---
osd-font=Inter
osd-font-size=32
osd-border-size=2
# kitni der dikhe (milliseconds)
osd-duration=1500
# seek ke baad samay ka text
osd-status-msg="${time-pos} / ${duration}"

# --- keys ---
# mpv ki apni default keys band: sirf input.conf ki keys chalti hain
input-default-bindings=no
input-builtin-bindings=no
SNOW_FILE_END_4b7d
;;
"u/.config/mpv/scripts/player-add.lua")
cat <<'SNOW_FILE_END_4b7d'
-- ============================================================================
--  player-add.lua  —  PLAYLIST KE CHHOTE KAAM
-- ----------------------------------------------------------------------------
--  script-message player-add-files      file-picker (zenity) kholo, chuni video playlist me jodo (Playlist icon par right-click)
--  script-message player-click          left click: khali window = video chuno; warna pause/play
--  script-message player-shuffle-toggle shuffle on/off (key x)
--  script-message player-playlist       playlist menu — file ke NAAM dikhata hai, title nahi (key z)
--  Zaroorat: zenity (file chooser), mpv 0.39+.
-- ============================================================================

local mp = require 'mp'
local utils = require 'mp.utils'
local input_ok, input = pcall(require, 'mp.input')   -- needs mpv 0.39+

-- message top-right (player-osc.lua draw karta hai). Pichhla 'seconds' argument ab zaroori nahi.
local function say(txt) mp.commandv('script-message', 'player-msg', txt) end

local function add_files()
    local args = {
        'zenity', '--file-selection', '--multiple',
        '--title=Add videos to the playlist',
        '--separator=\n',
        '--file-filter=Videos | *.mkv *.mp4 *.avi *.mov *.webm *.m4v *.flv *.wmv *.ts *.mpg *.mpeg *.MKV *.MP4 *.AVI *.MOV *.WEBM',
        '--file-filter=Audio | *.mp3 *.flac *.m4a *.ogg *.opus *.wav',
        '--file-filter=All files | *',
    }
    -- open the picker in the folder of the file that is playing
    local path = mp.get_property('path')
    if path and not path:find('^%a[%w+.-]*://') then
        local dir = utils.split_path(utils.join_path(mp.get_property('working-directory') or '', path))
        if dir and dir ~= '' then args[#args + 1] = '--filename=' .. dir end
    end

    mp.command_native_async({
        name = 'subprocess', args = args, capture_stdout = true, playback_only = false,
    }, function(success, res)
        if not success or not res or res.status < 0 or res.status > 1 then
            say('zenity is missing: sudo apt install zenity')
            return
        end
        if res.status == 1 then return end   -- cancelled
        local n = 0
        for line in (res.stdout or ''):gmatch('[^\r\n]+') do
            mp.commandv('loadfile', line, 'append-play')   -- append; starts playing only if nothing is playing
            n = n + 1
        end
        if n > 0 then say('Added ' .. n .. ' file' .. (n > 1 and 's' or '') .. ' to the playlist', 3) end
    end)
end

mp.register_script_message('player-add-files', add_files)

-- left click: empty window -> Add videos; otherwise pause / play
mp.register_script_message('player-click', function()
    if mp.get_property_bool('idle-active') then add_files() else mp.commandv('cycle', 'pause') end
end)

-- Shuffle on / off (key x): first press shuffles the playlist, the next press puts it back in the original order.
local shuffled = false
mp.register_script_message('player-shuffle-toggle', function()
    if shuffled then mp.commandv('playlist-unshuffle') else mp.commandv('playlist-shuffle') end
    shuffled = not shuffled
    mp.set_property_native('user-data/player/shuffle', shuffled)   -- the bar (player-osc.lua) colours the shuffle button from this
    say('Shuffle: ' .. (shuffled and 'on' or 'off'), 2)
end)

-- Playlist menu with FILE names (mpv's own menu shows the media title when a file has one; we never want titles).
mp.register_script_message('player-playlist', function()
    local n = mp.get_property_number('playlist-count', 0)
    if n == 0 then say('Playlist is empty', 2); return end
    if not input_ok or not input.select then say('The playlist menu needs mpv 0.39 or newer', 4); return end
    local items = {}
    for i = 0, n - 1 do
        local f = mp.get_property('playlist/' .. i .. '/filename') or ''
        if not f:find('^%a[%w+.-]*://') then
            local _, name = utils.split_path(f)
            if name and name ~= '' then f = name end
        end
        items[#items + 1] = f
    end
    input.select({
        prompt = 'Playlist:',
        items = items,
        default_item = mp.get_property_number('playlist-pos-1', 1),
        submit = function(id) mp.set_property_number('playlist-pos-1', id) end,
    })
end)
SNOW_FILE_END_4b7d
;;
"u/.config/mpv/scripts/player-osc.lua")
cat <<'SNOW_FILE_END_4b7d'
-- ============================================================================
--  player-osc.lua  —  mpv KA APNA CONTROL BAR  ("ONE-LINE" design)
-- ----------------------------------------------------------------------------
--  DIKHTA KYA HAI : Neeche EK patli line, koi background panel nahi. Har icon/text ke aas-paas halki kali outline,
--                   taaki kisi bhi video par padhne me aaye.
--      LEFT   : previous / -10s / play-pause / +10s / next, phir samay (01:23 / 10:00)
--      BEECH  : seek bar (jitni jagah bachi sab)       -> click/drag = aage-peeche, mouse wheel = +-5 sec
--      RIGHT  : volume, playlist, audio, subtitles, speed, loop, screenshot, shuffle, info, fullscreen
--      UPAR-BEECH : file ka naam (bar dikhte waqt).  UPAR-DAAYEIN : window buttons (jab window ki frame nahi hai)
--  KAB DIKHTA HAI :
--      mouse neeche le jao          -> poori bar
--      Left/Right key (seek)        -> sirf patli progress line + samay (upar-left)
--      pause / nayi video           -> thodi der bar
--      key o                        -> bar tab tak dikhti hai jab tak dobara o na dabao
--  RANG : ~/.config/snow/state/theme.json se (load_colors). Theme badalne ke baad agli video par naya rang.
--  APNE AAP BADLO (neeche "O" table me): hide_timeout, row_h, step, show_title, seek_h, jump ...
--  ICONS : Material Symbols Rounded font (install hona chahiye). "CP" table me code points.
--  mpv 0.39+ chahiye (Lua 5.1 / LuaJIT).
--  CODE KA NAKSHA (upar se neeche): settings -> icons -> colours -> state -> ASS drawing helpers -> bar drawing
--                  -> mouse -> properties (mpv se jaankari) -> events.
-- ============================================================================

local mp = require 'mp'
local utils = require 'mp.utils'

mp.set_property('osc', 'no')          -- switch mpv's own bar off

-- ------------------------------------------------------------------ settings (logical pixels at 720 p; scaled with the window)
local O = {
    hide_timeout   = 1.5,    -- seconds until the bar hides when the mouse is still
    fade_time      = 0.20,   -- fade in / out
    flash_time     = 1.5,    -- how long the thin progress line stays after a key seek
    show_on_start  = true,   -- show the bar for a moment when a file starts
    trigger_from   = 0.80,   -- mouse movement below this part of the window height shows the bar (0 = whole window)
    row_h          = 34,     -- height of the one line (the only space the bar uses at the bottom)
    step           = 36,     -- distance between two buttons
    show_title     = true,   -- file name at the top centre while the bar is visible
    title_size     = 20,
    time_size      = 15,
    seek_h         = 4,      -- seek bar thickness
    jump           = 10,     -- seconds for the -10 / +10 buttons
    jump_more      = 60,     -- seconds on right click
    outline        = 0.6,    -- icon / text outline width (0 = none; before: 1.3)
    shadow         = 0.4,    -- icon / text shadow distance (0 = none; before: 1.0)
    msg_time       = 1.5,    -- seconds: volume / mute / speed ... message top-right
    osd_size       = 26,     -- font size of mpv's own messages (Volume, Mute, Shuffle ...) = same as the time text at the top-left
    edge_alpha     = 0.35,   -- darkness of the thin edge under the seek bar and the knob (before: 0.55)
    ui_font        = 'Inter',
    icon_font      = 'Material Symbols Rounded',
}

-- ------------------------------------------------------------------ icons (Material Symbols Rounded code points)
local CP = {
    play = 0xE037, pause = 0xE034, prev = 0xE045, next = 0xE044, back10 = 0xE059, fwd10 = 0xE056,
    vol_up = 0xE050, vol_down = 0xE04D, vol_mute = 0xE04E, vol_off = 0xE04F,
    subs = 0xE048, audio = 0xE405, playlist = 0xE05F, fs = 0xE5D0, fs_exit = 0xE5D1,
    loop = 0xE040, loop_one = 0xE041, shot = 0xE412, info = 0xE88E, pin = 0xF10D,
    shuffle = 0xE043, close = 0xE5CD, minimize = 0xE931, maximize = 0xE3C6, restore = 0xE3E0, add = 0xE03B,
}
local function U(cp)   -- code point -> UTF-8 string (utf8.char does not exist in Lua 5.1)
    if cp < 0x80 then return string.char(cp)
    elseif cp < 0x800 then return string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64)
    else return string.char(0xE0 + math.floor(cp / 4096), 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64) end
end
local function icon(name) return U(CP[name]) end

-- ------------------------------------------------------------------ colours (fixed palette; change these 5 values to restyle)
local C = { bg = '#1e1e2e', surface = '#2a2b3c', text = '#ffffff', muted = '#8b90a6', accent = '#6366f1' }
local function load_colors()   -- Snow theme: ~/.config/snow/state/theme.json (if it is missing, the colours above stay)
    local f = io.open((os.getenv('HOME') or '') .. '/.config/snow/state/theme.json', 'r')
    if not f then return end
    local data = f:read('*a'); f:close()
    local t = utils.parse_json(data)
    if type(t) ~= 'table' then return end
    for _, k in ipairs({ 'bg', 'surface', 'text', 'muted', 'accent' }) do
        if type(t[k]) == 'string' and t[k]:match('^#%x%x%x%x%x%x$') then C[k] = t[k] end
    end
end
-- mpv's own messages (Volume: 50, Mute, Speed, Shuffle ...): top-right, same font size / thin outline / shadow / colour as our time text
local function style_osd()
    mp.set_property('osd-align-x', 'right')
    mp.set_property('osd-align-y', 'top')
    mp.set_property_number('osd-margin-x', 22)
    mp.set_property_number('osd-margin-y', 16)
    mp.set_property_number('osd-font-size', O.osd_size)
    mp.set_property_number('osd-border-size', O.outline)
    mp.set_property_number('osd-shadow-offset', O.shadow)
    mp.set_property('osd-border-color', '#99000000')
    mp.set_property('osd-shadow-color', '#59000000')
    mp.set_property('osd-color', C.text)
end
load_colors()
style_osd()
mp.register_event('file-loaded', function() load_colors(); style_osd() end)   -- picks up a new theme every time a video starts
local function darken(hex, f)
    local r, g, b = hex:match('^#(%x%x)(%x%x)(%x%x)$')
    return string.format('#%02X%02X%02X', math.floor(tonumber(r, 16) * f + 0.5), math.floor(tonumber(g, 16) * f + 0.5), math.floor(tonumber(b, 16) * f + 0.5))
end
local function bgr(hex)   -- '#RRGGBB' -> 'BBGGRR' (ASS order)
    local r, g, b = hex:match('^#(%x%x)(%x%x)(%x%x)$')
    return (b or 'FF') .. (g or 'FF') .. (r or 'FF')
end

-- ------------------------------------------------------------------ state
local st = {
    w = 0, h = 0, sc = 1,
    pos = 0, dur = 0, pause = false, volume = 100, mute = false, speed = 1,
    fullscreen = false, maximized = false, ontop = false, border = true,
    loop_file = false, loop_pl = false, shuffled = false, pinned = false, pl_count = 0, pl_pos = 0,
    audio_n = 0, sub_n = 0, idle = true, filename = '', cache = {},
    vol_max = 130,
    mx = -1, my = -1, inside = false,
    visible = false, alpha = 0, hide_at = 0, flash_until = 0, msg = '', msg_until = 0,
    hover = nil, pressed = nil, drag = nil, drag_was_paused = false, drag_last = 0,
}
local els = {}          -- clickable elements of the last frame
local ov = mp.create_osd_overlay('ass-events')
local timer, timer_on = nil, false
local now = function() return mp.get_time() end

local function wake()
    if timer and not timer_on then timer_on = true; timer:resume() end
end

-- ------------------------------------------------------------------ ASS helpers
local ass = {}
local function ev(s) ass[#ass + 1] = s end
local function A(op)   -- opacity 0..1 (times the fade) -> ASS alpha tag value
    local o = op * st.alpha
    if o < 0 then o = 0 elseif o > 1 then o = 1 end
    return string.format('&H%02X&', math.floor((1 - o) * 255 + 0.5))
end
local function esc(s)
    s = s:gsub('\\', '\\\239\187\191'):gsub('{', '\\{'):gsub('\n', ' ')
    return s
end
local function rrect(x0, y0, x1, y1, r, col, op)
    if x1 <= x0 or y1 <= y0 then return end
    local hw, hh = (x1 - x0) / 2, (y1 - y0) / 2
    if r > hw then r = hw end
    if r > hh then r = hh end
    local k = r * 0.5523
    local p
    if r <= 0.5 then
        p = string.format('m %.1f %.1f l %.1f %.1f %.1f %.1f %.1f %.1f', x0, y0, x1, y0, x1, y1, x0, y1)
    else
        p = string.format('m %.1f %.1f l %.1f %.1f b %.1f %.1f %.1f %.1f %.1f %.1f l %.1f %.1f b %.1f %.1f %.1f %.1f %.1f %.1f l %.1f %.1f b %.1f %.1f %.1f %.1f %.1f %.1f l %.1f %.1f b %.1f %.1f %.1f %.1f %.1f %.1f',
            x0 + r, y0, x1 - r, y0,
            x1 - r + k, y0, x1, y0 + r - k, x1, y0 + r,
            x1, y1 - r,
            x1, y1 - r + k, x1 - r + k, y1, x1 - r, y1,
            x0 + r, y1,
            x0 + r - k, y1, x0, y1 - r + k, x0, y1 - r,
            x0, y0 + r,
            x0, y0 + r - k, x0 + r - k, y0, x0 + r, y0)
    end
    ev(string.format('{\\an7\\pos(0,0)\\bord0\\shad0\\1c&H%s&\\1a%s\\p1}%s{\\p0}', bgr(col), A(op), p))
end
local function circle(cx, cy, r, col, op) rrect(cx - r, cy - r, cx + r, cy + r, r, col, op) end

-- dark outline + soft shadow for every text / icon (this is what keeps them readable without a background)
local function outline()
    return string.format('\\bord%.1f\\shad%.1f\\3c&H000000&\\4c&H000000&\\3a%s\\4a%s', O.outline * st.sc, O.shadow * st.sc, A(0.6), A(0.35))
end
local function text(x, y, an, str, fs, col, op, font, extra)
    ev(string.format('{\\an%d\\pos(%.1f,%.1f)\\fn%s\\fs%.1f%s\\1c&H%s&\\1a%s%s}%s',
        an, x, y, font or O.ui_font, fs, outline(), bgr(col), A(op), extra or '', str))
end
-- thin dark line under a bar, so the bar is visible on a bright picture
local function underlay(x0, y0, x1, y1, op)
    local g = 1.0 * st.sc
    rrect(x0 - g, y0 - g, x1 + g, y1 + g, (y1 - y0) / 2 + g, '#000000', op)
end

-- ------------------------------------------------------------------ small helpers
local function fmt_time(t)
    if not t or t < 0 then t = 0 end
    t = math.floor(t)
    local h, m, s = math.floor(t / 3600), math.floor(t / 60) % 60, t % 60
    if h > 0 then return string.format('%d:%02d:%02d', h, m, s) end
    return string.format('%02d:%02d', m, s)
end
local function in_box(x, y, e) return x >= e.x1 and x <= e.x2 and y >= e.y1 and y <= e.y2 end
local function cmd(...) local a = { ... }; return function() mp.commandv(unpack(a)) end end
if not unpack then unpack = table.unpack end

local function refresh_title()
    local f = mp.get_property('filename')
    if not f or f == '' then f = mp.get_property('media-title') or '' end
    st.filename = f
end

-- ------------------------------------------------------------------ MESSAGE TOP-RIGHT (volume, mute, speed, loop ...)
-- mpv ka apna OSD text top-LEFT me aata tha. Ab hum khud draw karte hain: top-RIGHT me, time wale text jaisi hi size (O.osd_size).
-- Kisi bhi jagah se message dikhana ho:  mp.commandv('script-message', 'player-msg', 'Mera text')
local function say(txt)
    st.msg = txt or ''
    st.msg_until = now() + O.msg_time
    wake()
end

local function say_volume()
    if mp.get_property_bool('mute') then say('Muted')
    else say(string.format('Volume: %d%%', math.floor((mp.get_property_number('volume') or 0) + 0.5))) end
end
local function vol_add(d) mp.commandv('no-osd', 'add', 'volume', d); say_volume() end
local function toggle_mute() mp.commandv('no-osd', 'cycle', 'mute'); say_volume() end

local function say_speed()
    local sp = string.format('%.2f', mp.get_property_number('speed') or 1):gsub('0+$', ''):gsub('%.$', '')
    say('Speed: ' .. sp .. 'x')
end
local function speed_add(d) mp.commandv('no-osd', 'add', 'speed', d); say_speed() end
local function speed_set(v) mp.commandv('no-osd', 'set', 'speed', v); say_speed() end

-- audio / subtitle track ka naam (language ya title)
local function track_label(kind)
    local id = mp.get_property_number(kind == 'audio' and 'aid' or 'sid')
    if not id then return nil end
    for _, t in ipairs(mp.get_property_native('track-list') or {}) do
        if t.type == kind and t.id == id then
            local name = t.title or t.lang or ('#' .. id)
            if t.title and t.lang then name = t.title .. ' (' .. t.lang .. ')' end
            return name
        end
    end
    return '#' .. id
end
local function cycle_track(kind)
    if kind == 'audio' then mp.commandv('no-osd', 'set', 'mute', 'no'); mp.commandv('no-osd', 'cycle', 'audio')
    else mp.commandv('no-osd', 'set', 'sub-visibility', 'yes'); mp.commandv('no-osd', 'cycle', 'sub') end
    local lb = track_label(kind)
    say((kind == 'audio' and 'Audio: ' or 'Subtitles: ') .. (lb or 'off'))
end

local function draw_msg(t)
    local sc, w = st.sc, st.w
    local left = st.msg_until - t
    local save = st.alpha
    st.alpha = math.min(1, left / 0.25)
    -- window ke upar-daayein buttons (jab frame nahi hai aur bar dikh rahi hai) se na takraye
    local rx = w - 22 * sc
    if save > 0.01 and not st.border and not st.fullscreen then rx = w - 150 * sc end
    text(rx, 16 * sc, 9, esc(st.msg), O.osd_size * sc, C.text, 1)       -- an9 = top-right
    st.alpha = save
end

-- ------------------------------------------------------------------ layout + drawing of the one-line bar
local function add_button(x, y, sc, name_icon, opts)
    -- opts: size, col, on_click, on_right, on_wheel, hit (half width), id
    local size = (opts.size or 20) * sc
    local hw = (opts.hit or 16) * sc
    local e = { x1 = x - hw, x2 = x + hw, y1 = y - 17 * sc, y2 = y + 17 * sc,
                click = opts.on_click, right = opts.on_right, wheel = opts.on_wheel, id = opts.id }
    els[#els + 1] = e
    local hovered = (st.hover == e.id and e.id ~= nil)
    local fs = size * ((hovered and not st.pressed) and 1.15 or 1)
    text(x, y, 5, name_icon, fs, hovered and C.accent or (opts.col or C.text), 1, O.icon_font)
end

local function seek_pct_from_x(x, e)
    local p = (x - e.sx0) / (e.sx1 - e.sx0)
    if p < 0 then p = 0 elseif p > 1 then p = 1 end
    return p
end

local function draw_bar()
    local sc, w, h = st.sc, st.w, st.h
    local lw = w / sc
    local S = O.step * sc
    local rowY = h - (O.row_h / 2) * sc          -- centre of the one line
    st.panel_top = h - O.row_h * sc - 6 * sc     -- the mouse over this strip keeps the bar visible

    -- file name at the top centre (not at the left: mpv's own messages like "Volume 50" use the top-left)
    if O.show_title and st.filename ~= '' then
        local lim = 170 * sc
        text(w / 2, 14 * sc, 8, esc(st.filename), O.title_size * sc, C.text, 1, O.ui_font,
            string.format('\\clip(%.0f,0,%.0f,%.0f)', lim, w - lim, 70 * sc))
    end

    -- ---------- left: previous, -10, play / pause, +10, next, time
    local lx = 14 * sc
    local function lbtn(id, name, o)
        o.id = id
        add_button(lx + S / 2, rowY, sc, icon(name), o)
        lx = lx + S
    end
    local pl = st.pl_count > 1 and lw >= 620
    if pl then lbtn('prev', 'prev', { on_click = cmd('playlist-prev') }) end
    if lw >= 460 then lbtn('back', 'back10', { on_click = cmd('seek', -O.jump, 'relative'), on_right = cmd('seek', -O.jump_more, 'relative') }) end
    lbtn('play', (st.pause or st.idle) and 'play' or 'pause', { size = 26, on_click = cmd('cycle', 'pause') })
    if lw >= 460 then lbtn('fwd', 'fwd10', { on_click = cmd('seek', O.jump, 'relative'), on_right = cmd('seek', O.jump_more, 'relative') }) end
    if pl then lbtn('next', 'next', { on_click = cmd('playlist-next') }) end
    if st.dur > 0 and lw >= 420 then
        local label = fmt_time(st.pos) .. ' / ' .. fmt_time(st.dur)
        ev(string.format('{\\an4\\pos(%.1f,%.1f)\\fn%s\\fs%.1f%s\\1c&H%s&\\1a%s}%s{\\1c&H%s&} / %s',
            lx + 4 * sc, rowY, O.ui_font, O.time_size * sc, outline(), bgr(C.text), A(1), fmt_time(st.pos), bgr(C.muted), fmt_time(st.dur)))
        lx = lx + (#label * 0.57 * O.time_size + 14) * sc
    end

    -- ---------- right: from the right edge to the left: fullscreen, info, shuffle, screenshot, loop, speed, subtitles, audio, playlist, volume
    local re = w - 14 * sc
    local function rbtn(minw, id, name, o)
        if lw < minw then return end
        o.id = id
        add_button(re - S / 2, rowY, sc, icon(name), o)
        re = re - S
    end
    rbtn(400, 'fs', st.fullscreen and 'fs_exit' or 'fs', { on_click = cmd('cycle', 'fullscreen'), on_right = cmd('cycle', 'window-maximized') })
    rbtn(700, 'info', 'info', { on_click = cmd('script-binding', 'stats/display-stats-toggle') })
    rbtn(760, 'shuffle', 'shuffle', { col = st.shuffled and C.accent or C.text, on_click = cmd('script-message', 'player-shuffle-toggle') })
    rbtn(820, 'shot', 'shot', { on_click = function() mp.commandv('no-osd', 'screenshot', 'video'); say('Screenshot saved') end })
    rbtn(880, 'loop', st.loop_file and 'loop_one' or 'loop', {
        col = (st.loop_file or st.loop_pl) and C.accent or C.text,
        on_click = function() mp.commandv('no-osd', 'cycle-values', 'loop-file', 'inf', 'no'); say('Loop: ' .. (((mp.get_property('loop-file') or 'no') == 'no') and 'off' or 'on')) end,
        on_right = function() mp.commandv('no-osd', 'cycle-values', 'loop-playlist', 'inf', 'no'); say('Playlist loop: ' .. (((mp.get_property('loop-playlist') or 'no') == 'no') and 'off' or 'on')) end })
    if lw >= 960 then          -- speed shows as text
        local cx = re - S / 2
        local sp = { x1 = cx - 18 * sc, x2 = cx + 18 * sc, y1 = rowY - 17 * sc, y2 = rowY + 17 * sc, id = 'speed',
                     click = function() speed_add(0.25) end,
                     right = function() speed_set(1) end,
                     wheel = function(d) speed_add(d * 0.25) end }
        els[#els + 1] = sp
        local s = string.format('%.2f', st.speed):gsub('0+$', ''):gsub('%.$', '')
        text(cx, rowY, 5, s .. 'x', 15 * sc, (st.hover == 'speed') and C.accent or C.text, 1)
        re = re - S
    end
    if lw >= 580 and st.sub_n > 0 then
        rbtn(0, 'subs', 'subs', { on_click = cmd('script-binding', 'select/select-sid'), on_right = cmd('cycle', 'sub'),
                                  on_wheel = function(d) mp.commandv('cycle', 'sub', d > 0 and 'down' or 'up') end })
    end
    if lw >= 640 and st.audio_n > 0 then
        rbtn(0, 'audio', 'audio', { on_click = cmd('script-binding', 'select/select-aid'), on_right = cmd('cycle', 'audio'),
                                    on_wheel = function(d) mp.commandv('cycle', 'audio', d > 0 and 'down' or 'up') end })
    end
    if lw >= 520 and st.pl_count >= 1 then
        rbtn(0, 'playlist', 'playlist', { on_click = cmd('script-message', 'player-playlist'), on_right = cmd('script-message', 'player-add-files') })
    end
    if lw >= 600 then          -- volume: icon only (click = mute, mouse wheel on it = volume); there is no slider
        local vname = (st.mute or st.volume <= 0) and 'vol_off' or (st.volume < 34 and 'vol_mute' or (st.volume < 67 and 'vol_down' or 'vol_up'))
        rbtn(0, 'vol', vname, { on_click = toggle_mute, on_wheel = function(d) vol_add(d * 5) end })
    end

    -- ---------- middle: seek bar (all the free width)
    local sx0, sx1 = lx + 6 * sc, re - 6 * sc
    if sx1 - sx0 < 60 * sc then sx1 = sx0 + 60 * sc end
    local seekY = rowY
    local hov_seek = (st.hover == 'seek') or (st.drag == 'seek')
    local th = (hov_seek and O.seek_h + 2 or O.seek_h) * sc
    local pct = (st.dur > 0) and (st.pos / st.dur) or 0
    if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
    local seek = { x1 = sx0 - 4 * sc, x2 = sx1 + 4 * sc, y1 = seekY - 16 * sc, y2 = seekY + 16 * sc, id = 'seek',
                   sx0 = sx0, sx1 = sx1, slider = true,
                   wheel = function(d) mp.commandv('seek', d * 5, 'relative') end }   -- mouse wheel on the seek bar: up = +5 s, down = -5 s
    els[#els + 1] = seek
    underlay(sx0, seekY - th / 2, sx1, seekY + th / 2, O.edge_alpha)
    rrect(sx0, seekY - th / 2, sx1, seekY + th / 2, th / 2, C.muted, 0.55)
    for _, r in ipairs(st.cache) do          -- cached ranges
        local a = sx0 + (sx1 - sx0) * r[1]
        local b = sx0 + (sx1 - sx0) * r[2]
        rrect(a, seekY - th / 2, b, seekY + th / 2, th / 2, C.text, 0.30)
    end
    local px = sx0 + (sx1 - sx0) * pct
    rrect(sx0, seekY - th / 2, px, seekY + th / 2, th / 2, C.accent, 1)
    local hr = (hov_seek and 7.5 or 6) * sc
    circle(px, seekY, hr + 1.0 * sc, '#000000', O.edge_alpha)
    circle(px, seekY, hr, C.accent, 1)
    if hov_seek and st.dur > 0 and st.mx >= 0 then      -- time over the mouse (text with outline, no box)
        local hp = seek_pct_from_x(st.mx, seek)
        local label = fmt_time(hp * st.dur)
        local bw = (#label * 9 + 18) * sc
        local bx = math.max(sx0 + bw / 2, math.min(sx1 - bw / 2, st.mx))
        text(bx, seekY - 24 * sc, 5, label, 14 * sc, C.text, 1)
    end
end

-- top bar: window buttons (only when the window has no frame)
local function draw_top()
    local sc, w = st.sc, st.w
    if st.border or st.fullscreen then st.top_h = 0; return end
    st.top_h = 44 * sc
    local x = w - 30 * sc
    local y = 24 * sc
    local function wb(name, id, col, fn)
        local e = { x1 = x - 18 * sc, x2 = x + 18 * sc, y1 = y - 18 * sc, y2 = y + 18 * sc, click = fn, id = id }
        els[#els + 1] = e
        local hov = (st.hover == id)
        text(x, y, 5, icon(name), (hov and 24 or 21) * sc, hov and col or C.text, 1, O.icon_font)
        x = x - 38 * sc
    end
    wb('close', 'wclose', '#ef4444', cmd('quit'))
    wb(st.maximized and 'restore' or 'maximize', 'wmax', '#fbbf24', cmd('cycle', 'window-maximized'))
    wb('minimize', 'wmin', '#4ade80', cmd('cycle', 'window-minimized'))
end

-- thin progress line (keyboard seek)
local function draw_flash(op)
    local sc, w, h = st.sc, st.w, st.h
    local th = 4 * sc
    local pct = (st.dur > 0) and math.min(1, math.max(0, st.pos / st.dur)) or 0
    local save = st.alpha
    st.alpha = op
    local label = fmt_time(st.pos)
    if st.dur > 0 then label = label .. ' / ' .. fmt_time(st.dur) end
    text(22 * sc, 16 * sc, 7, label, O.osd_size * sc, C.text, 1)      -- time only: no icon, no percent
    rrect(0, h - th - 1.0 * sc, w, h, 0, '#000000', 0.35)
    rrect(0, h - th, w, h, 0, C.muted, 0.55)
    rrect(0, h - th, w * pct, h, 0, C.accent, 1)
    st.alpha = save
end

local function draw_idle()
    local sc, w, h = st.sc, st.w, st.h
    local save = st.alpha
    st.alpha = 1
    text(w / 2, h / 2 - 28 * sc, 5, icon('add'), 64 * sc, C.muted, 0.9, O.icon_font)
    text(w / 2, h / 2 + 28 * sc, 5, 'Click to add videos, or drop files here', 20 * sc, C.muted, 0.9)
    st.alpha = save
end

-- ------------------------------------------------------------------ hover / mouse areas
local function set_area(e, name)
    if e then mp.set_mouse_area(math.floor(e.x1), math.floor(e.y1), math.floor(e.x2), math.floor(e.y2), name)
    else mp.set_mouse_area(0, 0, 0, 0, name) end
end

local function update_hover()
    local found, fclick, fwheel = nil, nil, nil
    if st.visible and st.mx >= 0 then
        for _, e in ipairs(els) do
            if in_box(st.mx, st.my, e) then
                found = e.id or found
                if e.click or e.right or e.slider then fclick = e end
                if e.wheel then fwheel = e end
            end
        end
    end
    st.hover = (fclick and fclick.id) or (fwheel and fwheel.id) or found
    st.hover_click, st.hover_wheel = fclick, fwheel
    set_area(fclick, 'player_input')
    set_area(fwheel, 'player_wheel')
end

-- ------------------------------------------------------------------ render loop
local function render()
    local w, h = mp.get_osd_size()
    if not w or w <= 0 or h <= 0 then return end
    st.w, st.h = w, h
    st.sc = math.max(0.85, math.min(2.0, h / 720))
    ass = {}
    els = {}
    local t = now()

    if st.idle then
        draw_idle()
    end
    if st.alpha > 0.01 then
        draw_bar()
        draw_top()
    elseif t < st.flash_until and not st.idle then
        local left = st.flash_until - t
        draw_flash(math.min(1, left / 0.25))
    end
    if t < st.msg_until then draw_msg(t) end
    ov.res_x, ov.res_y = w, h
    ov.data = table.concat(ass, '\n')
    ov:update()
    update_hover()
end

local function tick()
    local t = now()
    -- fade
    local target = st.visible and 1 or 0
    if st.alpha ~= target then
        local step = (1 / 30) / O.fade_time
        if st.alpha < target then st.alpha = math.min(target, st.alpha + step) else st.alpha = math.max(target, st.alpha - step) end
    end
    -- auto hide: not while the mouse is on the bar or while dragging
    if st.visible and not st.drag and not st.pinned then
        local over = st.inside and ((st.panel_top and st.my >= st.panel_top) or (st.top_h and st.top_h > 0 and st.my <= st.top_h))
        if over then st.hide_at = t + O.hide_timeout end
        if t >= st.hide_at then st.visible = false end
    end
    local flashing = (t < st.flash_until) or (t < st.msg_until)
    if st.alpha <= 0 and not st.visible and not flashing then
        if st.idle then render() else ov:remove() end
        els = {}
        update_hover()
        timer:stop(); timer_on = false
        return
    end
    render()
end

local function show_bar()
    if st.idle then return end
    st.visible = true
    st.hide_at = now() + O.hide_timeout
    wake()
end

-- ------------------------------------------------------------------ mouse input
local function mouse_pos()
    local x, y = mp.get_mouse_pos()
    st.mx, st.my = x or -1, y or -1
end

local function drag_to(x)
    local e
    for _, el in ipairs(els) do if el.id == st.drag then e = el end end
    if not e then return end
    local p = seek_pct_from_x(x, e)
    if st.drag == 'seek' then
        local t = now()
        if t - st.drag_last > 0.04 then
            st.drag_last = t
            mp.commandv('seek', string.format('%.4f', p * 100), 'absolute-percent+keyframes')
        end
        st.drag_pct = p
    else
        mp.commandv('set', 'volume', string.format('%.0f', p * st.vol_max))
    end
end

local function on_move()
    mouse_pos()
    st.inside = true
    if st.drag then drag_to(st.mx); wake(); return end
    local zone = (st.h > 0) and (st.my >= st.h * O.trigger_from or (not st.border and st.my <= 44 * st.sc)) or false
    if st.visible or zone then
        if zone or st.visible then show_bar() end
    end
    wake()
end

local function on_leave()
    st.inside = false
    st.mx, st.my = -1, -1
    if not st.drag then st.hide_at = 0 end
    wake()
end

local function down(which)
    mouse_pos()
    update_hover()
    if which == 'left' then
        local e = st.hover_click
        st.pressed = e and e.id or nil
        if e and e.slider then
            st.drag = e.id
            if e.id == 'seek' then
                st.drag_was_paused = st.pause
                if not st.pause then mp.set_property_bool('pause', true) end
            end
            drag_to(st.mx)
        end
    end
    wake()
end

local function up(which)
    mouse_pos()
    if not st.drag then update_hover() end
    local e = st.hover_click
    if which == 'left' then
        if st.drag then
            if st.drag == 'seek' then
                mp.commandv('seek', string.format('%.4f', (st.drag_pct or 0) * 100), 'absolute-percent+exact')
                if not st.drag_was_paused then mp.set_property_bool('pause', false) end
            end
            st.drag = nil
        elseif e and e.click and e.id == st.pressed then
            e.click()
        end
        st.pressed = nil
    elseif which == 'right' then
        if e and e.right then e.right() end
    end
    show_bar()
end

local function wheel(dir)
    local e = st.hover_wheel
    if e and e.wheel then e.wheel(dir) end
    show_bar()
end

mp.set_key_bindings({
    { 'mouse_move', on_move },
    { 'mouse_leave', on_leave },
}, 'player_showhide', 'force')
mp.enable_key_bindings('player_showhide', 'allow-vo-dragging+allow-hide-cursor')

mp.set_key_bindings({
    { 'mbtn_left', function() up('left') end, function() down('left') end },
    { 'mbtn_right', function() up('right') end, function() down('right') end },
    { 'mbtn_left_dbl', 'ignore' },
    { 'mbtn_right_dbl', 'ignore' },
}, 'player_input', 'force')
mp.enable_key_bindings('player_input')

mp.set_key_bindings({
    { 'wheel_up', function() wheel(1) end },
    { 'wheel_down', function() wheel(-1) end },
}, 'player_wheel', 'force')
mp.enable_key_bindings('player_wheel')
mp.set_mouse_area(0, 0, 0, 0, 'player_input')
mp.set_mouse_area(0, 0, 0, 0, 'player_wheel')

-- ------------------------------------------------------------------ properties
local function obs(name, kind, fn) mp.observe_property(name, kind, function(_, v) fn(v); wake() end) end
obs('time-pos', 'number', function(v) st.pos = v or 0 end)
obs('duration', 'number', function(v) st.dur = v or 0 end)
obs('pause', 'bool', function(v) local changed = (st.pause ~= v); st.pause = v and true or false; if changed then show_bar() end end)
obs('volume', 'number', function(v) st.volume = v or 0 end)
obs('volume-max', 'number', function(v) st.vol_max = (v and v > 0) and v or 100 end)
obs('mute', 'bool', function(v) st.mute = v and true or false end)
obs('speed', 'number', function(v) st.speed = v or 1 end)
obs('fullscreen', 'bool', function(v) st.fullscreen = v and true or false end)
obs('window-maximized', 'bool', function(v) st.maximized = v and true or false end)
obs('ontop', 'bool', function(v) st.ontop = v and true or false end)
obs('border', 'bool', function(v) st.border = (v ~= false) end)
obs('loop-file', 'string', function(v) st.loop_file = (v ~= nil and v ~= 'no') end)
obs('loop-playlist', 'string', function(v) st.loop_pl = (v ~= nil and v ~= 'no') end)
obs('playlist-count', 'number', function(v) st.pl_count = v or 0 end)
obs('idle-active', 'bool', function(v) st.idle = v and true or false; if st.idle then st.visible = false; st.alpha = 0 end end)
obs('osd-dimensions', 'native', function() end)
obs('user-data/player/shuffle', 'native', function(v) st.shuffled = (v == true) end)   -- set by player-add.lua
obs('filename', 'string', function() refresh_title() end)
obs('media-title', 'string', function() refresh_title() end)
obs('track-list', 'native', function(v)
    local a, s = 0, 0
    for _, t in ipairs(v or {}) do
        if t.type == 'audio' then a = a + 1 elseif t.type == 'sub' then s = s + 1 end
    end
    st.audio_n, st.sub_n = a, s
end)
obs('demuxer-cache-state', 'native', function(v)
    local out = {}
    if v and v['seekable-ranges'] and st.dur > 0 then
        for _, r in ipairs(v['seekable-ranges']) do
            local a, b = (r.start or 0) / st.dur, (r['end'] or 0) / st.dur
            if b > a then out[#out + 1] = { math.max(0, a), math.min(1, b) } end
        end
    end
    st.cache = out
end)

mp.register_event('start-file', function()
    refresh_title()
    if O.show_on_start then show_bar() end
end)

-- key o: the bar stays on screen until o is pressed again
mp.register_script_message('player-osd-toggle', function()
    if st.idle then return end
    st.pinned = not st.pinned
    st.visible = st.pinned
    st.hide_at = now() + O.hide_timeout
    wake()
end)

-- ---- input.conf se aane wale commands (volume / mute / speed / track / message) ----
mp.register_script_message('player-vol', function(d) vol_add(tonumber(d) or 5) end)
mp.register_script_message('player-mute', toggle_mute)
mp.register_script_message('player-speed', function(d) if d == 'reset' then speed_set(1) else speed_add(tonumber(d) or 0.1) end end)
mp.register_script_message('player-track', function(kind) cycle_track(kind == 'sub' and 'sub' or 'audio') end)
mp.register_script_message('player-msg', function(...) say(table.concat({ ... }, ' ')) end)

-- keyboard seek: thin progress line only
mp.register_script_message('player-flash', function()
    if st.idle then return end
    st.flash_until = now() + O.flash_time
    wake()
end)

timer = mp.add_periodic_timer(1 / 30, tick)
timer:stop()
refresh_title()
wake()
SNOW_FILE_END_4b7d
;;
"u/.config/mpv/scripts/player-single.lua")
cat <<'SNOW_FILE_END_4b7d'
-- ============================================================================
--  player-single.lua  —  EK HI mpv WINDOW
-- ----------------------------------------------------------------------------
--  Jab file manager se nayi video kholi jaye aur mpv pehle se chal raha ho, snow-mpv.sh path ek "queue file" me likh deta hai.
--  Ye script us file ko har 0.4 sec dekhti hai, nayi videos playlist me jodti hai aur pehli nayi ko chalu kar deti hai.
--  Files: $XDG_RUNTIME_DIR/snow-mpv.pid (chalte mpv ka pid), $XDG_RUNTIME_DIR/snow-mpv.queue (ek line = ek path)
-- ============================================================================

local mp = require 'mp'
local utils = require 'mp.utils'

local rt = os.getenv('XDG_RUNTIME_DIR') or '/tmp'
local PIDF, Q = rt .. '/snow-mpv.pid', rt .. '/snow-mpv.queue'
local me = tostring(utils.getpid())

local f = io.open(PIDF, 'w')
if f then f:write(me, '\n'); f:close() end

mp.register_event('shutdown', function()
    local g = io.open(PIDF, 'r')
    if not g then return end
    local p = g:read('*l'); g:close()
    if p == me then os.remove(PIDF) end
end)

local function poll()
    local tmp = Q .. '.' .. me
    if not os.rename(Q, tmp) then return end          -- no queue file
    local g = io.open(tmp, 'r')
    if not g then return end
    local items = {}
    for line in g:lines() do
        if line ~= '' then items[#items + 1] = line end
    end
    g:close()
    os.remove(tmp)
    if #items == 0 then return end
    local first = mp.get_property_number('playlist-count', 0)   -- index of the first new entry
    for _, item in ipairs(items) do
        mp.commandv('loadfile', item, 'append')
    end
    mp.commandv('playlist-play-index', tostring(first))          -- start the new video now; the old ones stay in the playlist
end

mp.add_periodic_timer(0.4, poll)
SNOW_FILE_END_4b7d
;;
"u/.config/snow/bin/mpv/snow-mpv.sh")
cat <<'SNOW_FILE_END_4b7d'
#!/bin/bash
# ============================================================================
#  snow-mpv.sh  —  "EK HI mpv WINDOW"  (launcher / file manager ki "mpv" entry yahi chalati hai)
# ----------------------------------------------------------------------------
#  Agar Snow ka mpv pehle se chal raha ho to nayi video us ki PLAYLIST me jud jati hai aur chalu ho jati hai
#  (player-single.lua ye kaam karta hai). Warna naya mpv window khulta hai.
#  Chalaye: snow-mpv.sh VIDEO1 [VIDEO2 ...]
# ============================================================================
RT="${XDG_RUNTIME_DIR:-/tmp}"; PIDF="$RT/snow-mpv.pid"; Q="$RT/snow-mpv.queue"
alive() { local p; p=$(cat "$PIDF" 2>/dev/null) || return 1; [ -n "$p" ] && [ "$(cat "/proc/$p/comm" 2>/dev/null)" = mpv ]; }
if [ "$#" -gt 0 ] && alive; then
  for f in "$@"; do printf '%s\n' "$f" >> "$Q"; done
  hyprctl dispatch focuswindow class:mpv >/dev/null 2>&1 || true     # bring the player to you (best effort)
  exit 0
fi
exec mpv --player-operation-mode=pseudo-gui -- "$@"
SNOW_FILE_END_4b7d
;;
"u/.local/share/applications/mpv.desktop")
cat <<'SNOW_FILE_END_4b7d'
[Desktop Entry]
Type=Application
Name=mpv Media Player
Name[ar]=مشغل وسائط mpv
Name[ca]=Reproductor multimèdia mpv
Name[cs]=mpv přehrávač
Name[da]=mpv-medieafspiller
Name[fr]=Lecteur multimédia mpv
Name[it]=Lettore multimediale mpv
Name[ja]=mpv メディアプレイヤー
Name[pl]=Odtwarzacz mpv
Name[ru]=Проигрыватель mpv
Name[tr]=mpv Ortam Oynatıcı
Name[zh_CN]=mpv 媒体播放器
Name[zh_TW]=mpv 媒體播放器
GenericName=Multimedia player
GenericName[ar]=مُشَغِّل وسائط متعددة
GenericName[cs]=Multimediální přehrávač
GenericName[da]=Multimedieafspiller
GenericName[fr]=Lecteur multimédia
GenericName[it]=Lettore multimediale
GenericName[ja]=マルチメディアプレイヤー
GenericName[ru]=Мультимедийный проигрыватель
GenericName[tr]=Çoklu ortam oynatıcı
GenericName[zh_CN]=多媒体播放器
GenericName[zh_TW]=多媒體播放器
Comment=Play movies and songs
Comment[ar]=شَغِّل الأفلام والأغاني
Comment[ca]=Reproduïu vídeos i cançons
Comment[cs]=Přehrává filmy a hudbu
Comment[da]=Afspil film og sange
Comment[de]=Filme und Musik abspielen
Comment[es]=Reproduzca vídeos y canciones
Comment[fr]=Lire des vidéos et des musiques
Comment[ja]=映画や音楽を再生する
Comment[it]=Riproduci video e canzoni
Comment[pl]=Odtwarzaj filmy i muzykę
Comment[ru]=Воспроизведение фильмов и музыки
Comment[tr]=Filmleri ve şarkıları oynatın
Comment[zh_CN]=播放电影和歌曲
Comment[zh_TW]=播放電影和歌曲
Icon=mpv
TryExec=mpv
Exec=@HOME@/.config/snow/bin/mpv/snow-mpv.sh %U
Terminal=false
Categories=AudioVideo;Audio;Video;Player;TV;
MimeType=application/ogg;application/x-ogg;application/mxf;application/sdp;application/smil;application/x-smil;application/streamingmedia;application/x-streamingmedia;application/vnd.rn-realmedia;application/vnd.rn-realmedia-vbr;audio/aac;audio/x-aac;audio/vnd.dolby.heaac.1;audio/vnd.dolby.heaac.2;audio/aiff;audio/x-aiff;audio/m4a;audio/x-m4a;application/x-extension-m4a;audio/mp1;audio/x-mp1;audio/mp2;audio/x-mp2;audio/mp3;audio/x-mp3;audio/mpeg;audio/mpeg2;audio/mpeg3;audio/mpegurl;audio/x-mpegurl;audio/mpg;audio/x-mpg;audio/rn-mpeg;audio/musepack;audio/x-musepack;audio/ogg;audio/scpls;audio/x-scpls;audio/vnd.rn-realaudio;audio/wav;audio/x-pn-wav;audio/x-pn-windows-pcm;audio/x-realaudio;audio/x-pn-realaudio;audio/x-ms-wma;audio/x-pls;audio/x-wav;video/mpeg;video/x-mpeg2;video/x-mpeg3;video/mp4v-es;video/x-m4v;video/mp4;application/x-extension-mp4;video/divx;video/vnd.divx;video/msvideo;video/x-msvideo;video/ogg;video/quicktime;video/vnd.rn-realvideo;video/x-ms-afs;video/x-ms-asf;audio/x-ms-asf;application/vnd.ms-asf;video/x-ms-wmv;video/x-ms-wmx;video/x-ms-wvxvideo;video/x-avi;video/avi;video/x-flic;video/fli;video/x-flc;video/flv;video/x-flv;video/x-theora;video/x-theora+ogg;video/x-matroska;video/mkv;audio/x-matroska;application/x-matroska;video/webm;audio/webm;audio/vorbis;audio/x-vorbis;audio/x-vorbis+ogg;video/x-ogm;video/x-ogm+ogg;application/x-ogm;application/x-ogm-audio;application/x-ogm-video;application/x-shorten;audio/x-shorten;audio/x-ape;audio/x-wavpack;audio/x-tta;audio/AMR;audio/ac3;audio/eac3;audio/amr-wb;video/mp2t;audio/flac;audio/mp4;application/x-mpegurl;video/vnd.mpegurl;application/vnd.apple.mpegurl;audio/x-pn-au;video/3gp;video/3gpp;video/3gpp2;audio/3gpp;audio/3gpp2;video/dv;audio/dv;audio/opus;audio/vnd.dts;audio/vnd.dts.hd;audio/x-adpcm;application/x-cue;audio/m3u;audio/vnd.wave;video/vnd.avi;
X-KDE-Protocols=appending,file,ftp,hls,http,https,mms,mpv,rist,rtmp,rtmps,rtmpt,rtmpts,rtp,rtsp,rtsps,sftp,srt,srtp,webdav,webdavs
StartupWMClass=mpv
Keywords=mpv;media;player;video;audio;tv;
Keywords[ar]=mpv;إم بي في;ام بي في;وسائط;مشغل;فيديو;مرئية;صوتي;تلفاز;
# snow-mpv
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
pre() {
apt_install mpv zenity
}
post() {
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1
flatpak info io.mpv.Mpv >/dev/null 2>&1 && warn "Flatpak mpv is installed: it ignores ~/.config/mpv" "flatpak uninstall io.mpv.Mpv"
have mpv && pass "mpv found: $(mpv --version 2>/dev/null | head -1)" || fail "mpv not found" "sudo apt-get install mpv"
}
extra_check() {
have mpv && pass "mpv installed" || fail "mpv is not installed" "bash ~/Snow/Script/24-mpv.sh"
[ -f "$HOME/.local/share/applications/mpv.desktop" ] && pass "launcher entry for mpv exists" || warn "launcher entry for mpv is missing" "bash ~/Snow/Script/24-mpv.sh"
}
component_main "$@"
