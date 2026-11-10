#!/usr/bin/env bash
# 18-hyprland-config.sh : Hyprland: hyprland.lua + look + panel keys
# hyprland.lua, snow-look.lua, snow-panel-keys.lua. Written after all panels, because Hyprland reloads by itself as soon as hyprland.lua changes.
#   bash Script/18-hyprland-config.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/18-hyprland-config.sh check    read-only check
MOD="18-hyprland-config"; TITLE="Hyprland: hyprland.lua + look + panel keys"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/hypr/snow-look.lua|644|0"
  "u|.config/hypr/snow-panel-keys.lua|644|0"
  "u|.config/hypr/hyprland.lua|644|0"
)
emit() {
case "$1" in
"u/.config/hypr/snow-look.lua")
cat <<'SNOW_FILE_END_4b7d'
-- ============================================================================
--  snow-look.lua  —  WINDOWS KA LOOK  (gap, kone, transparency, animation)
-- ----------------------------------------------------------------------------
--  Ye file hyprland.lua me SABSE AAKHIR me load hoti hai, isliye upar ki settings ko override karti hai.
--  Badalne ke baad:  hyprctl reload
--  NUMBERS (yahan badlo):
--    gaps_in        windows ke beech ki jagah (0 = bilkul chipki)
--    gaps_out       screen ke kinare se jagah
--    border_size    window ki border (0 = nahi)
--    resize_on_border / extend_border_grab_area   window ke kinare par mouse = size badlo (pakad ka chaudai pixel me)
--    rounding       window ke kone (0 = chaukor)
--    inactive_opacity  jo window focus me nahi hai wo kitni dhundli (1.0 = bilkul saaf)
--    speed          animation ki speed: chhota = tez, bada = dheema
-- ============================================================================
hl.config({
    -- resize_on_border: mouse window ke kinare / kone par le jao, cursor badal jata hai, left-drag = size badlo.
    -- extend_border_grab_area = kinare ke bahar kitne pixel tak pakad chale (border_size 0 hai, isliye ye zaroori hai).
    general    = { gaps_in = 1, gaps_out = 0, border_size = 0,
                   resize_on_border = true, extend_border_grab_area = 12, hover_icon_on_border = true },
    decoration = { rounding = 2, inactive_opacity = 0.9, active_opacity = 1.0 },
    -- naya app usi workspace par khule jis par tum ho (us par nahi jahan Quickshell start hua tha)
    misc       = { initial_workspace_tracking = 0 },
})

-- animation ka "curve" (naram ruk-ke-rukna)
hl.curve("snowOut", { type = "bezier", points = { {0.2, 0.9}, {0.3, 1} } })

hl.animation({ leaf = "global",      enabled = true, speed = 4, bezier = "snowOut" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3, bezier = "snowOut", style = "popin 95%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2, bezier = "snowOut", style = "popin 95%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "snowOut" })
hl.animation({ leaf = "fade",        enabled = true, speed = 3, bezier = "snowOut" })
hl.animation({ leaf = "layers",      enabled = true, speed = 3, bezier = "snowOut" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 3, bezier = "snowOut", style = "fade" })

-- ============================================================================
--  FLOATING WINDOWS  —  ye windows tile nahi hoti, tairti (float) hain
--    * Picture-in-Picture (YouTube / Brave / LibreWolf): float + sab workspaces par chipki (pin) + neeche-daayein kone me
--    * File chooser / save dialogs, zenity, volume / network helper windows: float + beech me
--  Naya rule: neeche ek line badhao (class ya title = regex). Har rule alag pcall me hai: ek galat rule baaki ko nahi todta.
-- ============================================================================
local function snowRule(r)
  local ok, err = pcall(hl.window_rule, r)
  if not ok then
    local f = io.open(os.getenv("HOME") .. "/.cache/snow-lua-errors.log", "a")
    if f then f:write("snow-look.lua window_rule " .. tostring(r.name) .. ": " .. tostring(err) .. "\n"); f:close() end
  end
end

snowRule({
  name  = "snow-pip",
  match = { title = "^([Pp]icture[- ]in[- ][Pp]icture)$" },
  float = true,
  pin   = true,
  move  = "monitor_w-window_w-24 monitor_h-window_h-24",
})

snowRule({
  name  = "snow-dialogs",
  match = { title = "^(Open File|Open Files|Open Folder|Save As|Save File|Choose .*|Select .*|File Upload|Export .*)$" },
  float  = true,
  center = true,
})

snowRule({
  name  = "snow-helper-windows",
  match = { class = "^(org\\.gnome\\.Zenity|zenity|pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor|blueman-manager|xdg-desktop-portal-gtk|org\\.freedesktop\\.impl\\.portal\\.desktop\\.gtk)$" },
  float  = true,
  center = true,
})

-- "Snow Downloads" (the download manager window) has NO rule on purpose: it opens as a normal TILED window like any other program.
-- The small windows "Snow DM Save" / "Snow DM Save Video" (below) stay floating.

snowRule({
  name  = "snow-dm-bridge",
  match = { title = "^Snow DM.*" },
  float  = true,
  center = true,
})
SNOW_FILE_END_4b7d
;;
"u/.config/hypr/snow-panel-keys.lua")
cat <<'SNOW_FILE_END_4b7d'
-- ============================================================================
--  snow-panel-keys.lua  —  LAUNCHER + POWER MENU KI KEYS, AUR AUTOSTART
-- ----------------------------------------------------------------------------
--  KYA HAI : Hyprland ki Lua config ka chhota hissa. hyprland.lua ke andar ek "hook block" (snow-panels-begin/end)
--            isse load karta hai. Agar yahan koi galti ho to sirf ye file fail hoti hai, poora Hyprland nahi
--            (error ~/.cache/snow-lua-errors.log me likha jata hai).
--  KEY BADALNI HO : neeche "SUPER + space" jaisi string badlo, phir terminal me:  hyprctl reload
--  NOTE : Super+L kabhi bind mat karna (lock). Agli key pehle se kahin aur bind to nahi — dhyan rakho.
--  Hyprland 0.55 (Debian 13 backports) ke liye.
-- ============================================================================
local home = os.getenv("HOME")
local qs = home .. "/.config/snow/bin/core/qs.sh"      -- Quickshell ko command bhejne wali script

-- Super + Space  = launcher (search; Home = saari apps)
hl.bind("SUPER + space", hl.dsp.exec_cmd(qs .. " ipc call launcher toggle"))
-- Super + Escape = power menu (ek gol icon)
hl.bind("SUPER + Escape", hl.dsp.exec_cmd(qs .. " ipc call power toggle"))

-- "Screen off" ke baad koi bhi key ya mouse hilane se screen jaag jaye
hl.config({
    misc = {
        key_press_enables_dpms  = true,
        mouse_move_enables_dpms = true,
    },
})

-- Hyprland start hote hi: panels chalu + idle timers (hypridle) chalu
hl.on("hyprland.start", function()
  hl.exec_cmd(qs .. " start")
  hl.exec_cmd("bash " .. home .. "/.config/snow/bin/power/power.sh start")
  hl.exec_cmd("bash " .. home .. "/.config/snow/bin/core/defaults.sh")   -- one-time default volume 40%
  hl.exec_cmd("bash " .. home .. "/.config/snow/bin/downloads/dm.sh daemon")   -- download engine (aria2): unfinished downloads continue after login
end)
-- snow-fm2-key: Super+E = Snow file manager
hl.bind("SUPER + E", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/snow/bin/filemanager/fm.sh"))
-- Super + Q = Thunar (second file manager, installed by script 19)
hl.bind("SUPER + Q", hl.dsp.exec_cmd("thunar"))
-- snow-dm-key: Super+D = Snow download manager (aria2)
hl.bind("SUPER + D", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/snow/bin/downloads/dm.sh"))
SNOW_FILE_END_4b7d
;;
"u/.config/hypr/hyprland.lua")
cat <<'SNOW_FILE_END_4b7d'
-- This is an example Hyprland Lua config file.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/configuring/

-- Please note not all available settings / options are set here.
-- For a full list, see the wiki

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/
hl.monitor({
    output   = "",
    mode     = "2560x1440@120",
    position = "auto",
    scale    = 1,
})


---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"


-------------------
---- AUTOSTART ----
-------------------

-- AUTOSTART

hl.on("hyprland.start", function () 
   -- Direct path to the agent
   -- hl.exec_cmd("/usr/libexec/hyprpolkitagent")   -- replaced by the Snow polkit agent (PolkitDialog.qml); shell.qml starts hyprpolkitagent only as a fallback
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/configuring/core/environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")      -- nvidia-vaapi-driver (hardware video decode)
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")



-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/configuring/core/config-options/
hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 0,

        border_size = 0,

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/configuring/extra/tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves and animations, see https://wiki.hypr.land/configuring/core/animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })


-- See https://wiki.hypr.land/configuring/layouts/dwindle-layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/configuring/layouts/master-layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/configuring/layouts/scrolling-layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        initial_workspace_tracking = 0,  -- apps open on the workspace you are on (not on the one where Quickshell started)
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/configuring/core/binds/ for more
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave-origin"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/snow/bin/osd/workspace.sh " .. i))   -- snow: switch + number badge (also when already there)
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/configuring/core/rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- snow-panels-begin
do
  local p = os.getenv("HOME") .. "/.config/hypr/snow-panel-keys.lua"
  local ok, err = pcall(dofile, p)
  if not ok then
    local f = io.open(os.getenv("HOME") .. "/.cache/snow-lua-errors.log", "a")
    if f then f:write(p .. ": " .. tostring(err) .. "\n"); f:close() end
  end
end
-- snow-panels-end

-- snow-quick-begin
do
  local p = os.getenv("HOME") .. "/.config/hypr/snow-quick-keys.lua"
  local ok, err = pcall(dofile, p)
  if not ok then
    local f = io.open(os.getenv("HOME") .. "/.cache/snow-lua-errors.log", "a")
    if f then f:write(p .. ": " .. tostring(err) .. "\n"); f:close() end
  end
end
-- snow-quick-end

-- snow-osd-begin
do
  local p = os.getenv("HOME") .. "/.config/hypr/snow-osd-keys.lua"
  local ok, err = pcall(dofile, p)
  if not ok then
    local f = io.open(os.getenv("HOME") .. "/.cache/snow-lua-errors.log", "a")
    if f then f:write(p .. ": " .. tostring(err) .. "\n"); f:close() end
  end
end
-- snow-osd-end

-- snow-shot-begin
do
  local p = os.getenv("HOME") .. "/.config/hypr/snow-shot-keys.lua"
  local ok, err = pcall(dofile, p)
  if not ok then
    local f = io.open(os.getenv("HOME") .. "/.cache/snow-lua-errors.log", "a")
    if f then f:write(p .. ": " .. tostring(err) .. "\n"); f:close() end
  end
end
-- snow-shot-end

-- snow-cursor-begin
-- software cursor: fixes the cursor disappearing (NVIDIA hardware cursor problem)
hl.config({ cursor = { no_hardware_cursors = 1 } })
-- snow-cursor-end

-- snow-look-begin
do
  local p = os.getenv("HOME") .. "/.config/hypr/snow-look.lua"
  local ok, err = pcall(dofile, p)
  if not ok then
    local f = io.open(os.getenv("HOME") .. "/.cache/snow-lua-errors.log", "a")
    if f then f:write(p .. ": " .. tostring(err) .. "\n"); f:close() end
  end
end
-- snow-look-end
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
pre() {
mkdir -p "$HOME/.cache" "$HYPR"
# Super+1..0 in hyprland.lua calls workspace.sh: make sure it exists first (it comes with the workspace-osd script)
[ -x "$BIN/osd/workspace.sh" ] || bash "$SCRIPT_DIR/10-workspace-osd.sh" run
[ -s "$HOME/.cache/snow-lua-errors.log" ] && mv -f "$HOME/.cache/snow-lua-errors.log" "$HOME/.cache/snow-lua-errors.old"   # old entries must not look like new errors
}
post() {
for b in panels quick osd shot cursor look; do grep -q "snow-$b-begin" "$HYPR/hyprland.lua" 2>/dev/null && pass "hyprland.lua has the snow-$b block" || fail "hyprland.lua misses the snow-$b block"; done
reload_live
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && have hyprctl; then sleep 2; ERR=$(hyprctl configerrors 2>&1); { [ -z "$ERR" ] || echo "$ERR" | grep -qi '^no errors'; } && pass "hyprctl configerrors is empty" || fail "hyprctl configerrors: $ERR"; fi
}
extra_check() {
for b in panels quick osd shot cursor look; do grep -q "snow-$b-begin" "$HYPR/hyprland.lua" 2>/dev/null && pass "hyprland.lua has the snow-$b block" || fail "hyprland.lua misses the snow-$b block" "bash ~/Snow/Script/18-hyprland-config.sh"; done
n=$(grep -c '^[[:space:]]*hl.bind(mainMod .. " + S"' "$HYPR/hyprland.lua" 2>/dev/null); [ "${n:-0}" = 0 ] && pass "no old Super+S bind in hyprland.lua" || warn "hyprland.lua still binds Super+S twice"
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && have hyprctl; then ERR=$(hyprctl configerrors 2>&1); { [ -z "$ERR" ] || echo "$ERR" | grep -qi '^no errors'; } && pass "hyprctl configerrors: none" || fail "hyprctl configerrors: $ERR" "bash ~/Snow/Script/18-hyprland-config.sh"; fi
[ -s "$HOME/.cache/snow-lua-errors.log" ] && warn "Lua errors were logged: ~/.cache/snow-lua-errors.log" "tail ~/.cache/snow-lua-errors.log   (old entries? mv ~/.cache/snow-lua-errors.log ~/.cache/snow-lua-errors.old)"
}
component_main "$@"
