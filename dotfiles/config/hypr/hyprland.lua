-- Hyprland Lua config (0.55+ syntax, migrated from hyprland.conf).
-- Refer to the wiki for more information:
-- https://wiki.hyprland.org/Configuring/

----------------
--- MONITORS ---
----------------

-- See https://wiki.hyprland.org/Configuring/Basics/Monitors/
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = 1 })

-------------------
--- MY PROGRAMS ---
-------------------

local browser = "thorium-browser --enable-features=UseOzonePlatform --ozone-platform=wayland"
local terminal = "footclient"

local fileManager = "nautilus"
local menu = "qs -c noctalia-shell ipc call launcher toggle"
local powermenu = "qs -c noctalia-shell ipc call sessionMenu toggle"
local barToggle = "qs -c noctalia-shell ipc call bar toggle" -- top bar toggle show/hide
-- local lockscreen = "qs -c noctalia-shell ipc call lockScreen lock"
local lockscreen = [[sh -c 'busctl --user call org.keepassxc.KeePassXC.MainWindow /keepassxc org.keepassxc.KeePassXC.MainWindow lockAllDatabases; qs -c noctalia-shell ipc call lockScreen lock']]
local passwordManager = [[SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket" keepassxc]]

-- Apps that should open floating. Add a new app by appending another
-- `|class` alternative to the regex; the window rule below picks it up.
local floatingApps = [[^(org\.gnome\.Calculator|org\.keepassxc\.KeePassXC)$]]

local mail = "/opt/google/chrome/google-chrome --profile-directory=Default --app-id=faolnafnngnfdaknnbpnkhgohbobgegn %U"
local chat = "mattermost-desktop"

-----------------
--- AUTOSTART ---
-----------------

hl.on("hyprland.start", function()
  hl.exec_cmd("~/.config/hypr/scripts/autostart.sh")

  -- Noctalia session initialization
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")
  -- Activate the systemd user graphical session so xdg-desktop-portal can start.
  -- Portal 1.22+ has Requisite=graphical-session.target; without this the portal
  -- never starts and GTK/libadwaita apps fall back to the light theme.
  hl.exec_cmd("systemctl --user start hyprland-session.target")
  hl.exec_cmd("qs -c noctalia-shell")

  -- Clipboard history for Noctalia
  hl.exec_cmd("wl-paste --watch cliphist store")
  hl.exec_cmd("wl-clip-persist --clipboard regular")

  -- Start apps on their designated workspaces
  hl.exec_cmd(browser, { workspace = "1 silent" })
  -- Terminal on workspace 2 is started by autostart.sh (footclient) and pinned via window rule below
  hl.exec_cmd(mail, { workspace = "3 silent" })
  hl.exec_cmd(chat, { workspace = "4 silent" })

  -- Hyprland doesn't have a clean "monitor connected" hook, but you can listen on its IPC socket
  hl.exec_cmd("~/.config/hypr/scripts/monitor-watcher.sh")
end)

-- Reconcile lid state on every config (re)load, like the old `exec` keyword:
-- top-level code runs at startup and again on each `hyprctl reload`. This
-- catches the thunderbolt re-negotiation case on monitor hotplug.
hl.exec_cmd("~/.config/hypr/scripts/lid-monitor.sh")

-------------------------------
--- ENVIRONMENT VARIABLES ---
-------------------------------

-- See https://wiki.hyprland.org/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-------------------
--- PERMISSIONS ---
-------------------

-- See https://wiki.hyprland.org/Configuring/Permissions/
-- Permission changes require a Hyprland restart and are not applied on-the-fly
-- for security reasons.
-- hl.config({ ecosystem = { enforce_permissions = true } })

-------------------------
--- LOOK AND FEEL ---
-------------------------

-- See https://wiki.hyprland.org/Configuring/Basics/Variables/
hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 5,

    border_size = 2,

    ["col.active_border"] = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
    ["col.inactive_border"] = "rgba(595959aa)",

    -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
    resize_on_border = false,

    -- See https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
    allow_tearing = false,

    layout = "dwindle",
  },

  decoration = {
    rounding = 0,
    rounding_power = 0,

    -- Transparency of focused and unfocused windows
    active_opacity = 1.0,
    inactive_opacity = 1.0,

    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },

    blur = {
      enabled = true,
      size = 3,
      passes = 1,

      vibrancy = 0.1696,
    },
  },

  animations = {
    enabled = true,
  },

  -- See https://wiki.hyprland.org/Configuring/Layouts/Dwindle-Layout/
  dwindle = {
    preserve_split = true, -- You probably want this
  },

  -- See https://wiki.hyprland.org/Configuring/Layouts/Master-Layout/
  master = {
    new_status = "master",
  },

  misc = {
    force_default_wallpaper = 0, -- 0 or 1 disables the anime mascot wallpapers, -1 default
    disable_hyprland_logo = true,
    focus_on_activate = true,
  },

  group = {
    groupbar = {
      enabled = true,
      render_titles = true,
      font_size = 13,
      height = 22,
      indicator_height = 3,
      ["col.active"] = "rgba(00ff00ff)",
      ["col.inactive"] = "rgba(7aa2f7ff)",
      text_color = "rgba(ffffffff)",
      gradients = false,
      stacked = false,
      keep_upper_gap = false,
    },
  },

  input = {
    kb_layout = "us,rs,rs",
    kb_variant = ",latin,",
    kb_options = "grp:win_space_toggle",
    numlock_by_default = true,

    follow_mouse = 1,

    sensitivity = 0, -- -1.0 - 1.0, 0 means no modification

    touchpad = {
      natural_scroll = false,
    },
  },

  -- no nagging
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
})

------------------
--- ANIMATIONS ---
------------------

-- See https://wiki.hyprland.org/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- "Smart gaps" / "No gaps when only" -- uncomment to use.
-- See https://wiki.hyprland.org/Configuring/Basics/Workspace-Rules/
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]" }, border_size = 0, rounding = 0 })

-- Example per-device config
-- See https://wiki.hyprland.org/Configuring/Basics/Keywords/#per-device-input-configs
-- hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

-------------------
--- KEYBINDINGS ---
-------------------

-- See https://wiki.hyprland.org/Configuring/Basics/Binds/
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
-- Toggle floating, then resize to half the screen and center
hl.bind(mainMod .. " + V", function()
  hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  hl.dispatch(hl.dsp.window.resize({ x = "50%", y = "50%" }))
  hl.dispatch(hl.dsp.window.center())
end)
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + escape", hl.dsp.exec_cmd(powermenu))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(lockscreen))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd(passwordManager))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd(barToggle))
hl.bind(mainMod .. " + Tab", hl.dsp.group.next())
hl.bind(mainMod .. " + R", hl.dsp.window.swap({ next = true }))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(fileManager .. " trash:///"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd([[bash -c 'trash-empty && notify-send "Trash" "Trash emptied"']]))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd([[hyprshot -m region -o "$HOME/Pictures/Screenshots"]])) -- Screenshot a region
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprpicker -a")) -- color picker

-- Noctalia controls
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call clipboard toggle"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call notifications toggle"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call settings focusOrToggle"))
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call hypr toggleOverview"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for key = 0, 9 do
  local ws = key == 0 and 10 or key
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = ws }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(ws), follow = true }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = true }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + page_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + page_up", hl.dsp.focus({ workspace = "e-1" }))

-- Switch to a submap called `resize`.
hl.bind("ALT + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
  -- Repeating binds for resizing the active window.
  hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
  hl.bind("left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
  hl.bind("up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
  hl.bind("down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })

  -- Use `reset` to go back to the global submap
  hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call audio increment 5"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call audio decrement 5"), { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call audio mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call audio micmute"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call brightness increment 5"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call brightness decrement 5"), { repeating = true, locked = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Lid open/close event
hl.bind("switch:Lid Switch", hl.dsp.exec_cmd("~/.config/hypr/scripts/lid-monitor.sh"), { locked = true })

--------------------------------
--- WINDOWS AND WORKSPACES ---
--------------------------------

-- See https://wiki.hyprland.org/Configuring/Basics/Window-Rules/
-- See https://wiki.hyprland.org/Configuring/Basics/Workspace-Rules/

-- Ignore maximize requests from apps.
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Fix some dragging issues with XWayland
hl.window_rule({
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})

-- Float any app whose class matches floatingApps (size stays app-default)
hl.window_rule({ match = { class = floatingApps }, float = true })

-- Pin the foot startup client (custom app-id) to workspace 2
hl.window_rule({ match = { class = "^(foot-startup)$" }, workspace = "2 silent" })

-- Layer rules: no_anim prevents animation glitches on shell overlays
hl.layer_rule({ match = { namespace = "hyprpicker" }, no_anim = true })
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^(noctalia)$" }, no_anim = true })

-- Noctalia dynamic theme (generated by noctalia setup). Pre-0.55 these were
-- hyprlang .conf files; only .lua files can be loaded now. The wildcard picks
-- up whatever Noctalia emits; pcall keeps a missing dir from aborting the config.
pcall(require, "./noctalia/*")
