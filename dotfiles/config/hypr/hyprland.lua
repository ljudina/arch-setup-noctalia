-- Hyprland 0.55+ native Lua configuration.
-- API reference: https://wiki.hypr.land/Configuring/Start/

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = 1 })

local browser = "thorium-browser --enable-features=UseOzonePlatform --ozone-platform=wayland"
local terminal = "footclient"
local file_manager = "nautilus"
local menu = "qs -c noctalia-shell ipc call launcher toggle"
local powermenu = "qs -c noctalia-shell ipc call sessionMenu toggle"
local bar_toggle = "qs -c noctalia-shell ipc call bar toggle"
local lockscreen = "sh -c 'busctl --user call org.keepassxc.KeePassXC.MainWindow /keepassxc org.keepassxc.KeePassXC.MainWindow lockAllDatabases; qs -c noctalia-shell ipc call lockScreen lock'"
local password_manager = 'SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket" keepassxc'
local mail = "/opt/google/chrome/google-chrome --profile-directory=Default --app-id=faolnafnngnfdaknnbpnkhgohbobgegn %U"
local chat = "mattermost-desktop"

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/autostart.sh")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("qs -c noctalia-shell")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
    hl.exec_cmd(browser, { workspace = "1 silent" })
    hl.exec_cmd(mail, { workspace = "3 silent" })
    hl.exec_cmd(chat, { workspace = "4 silent" })
    hl.exec_cmd("~/.config/hypr/scripts/monitor-watcher.sh")
    hl.exec_cmd("~/.config/hypr/scripts/lid-monitor.sh")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 5,
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgba(33ccffee)", "rgba(00ff99ee)" },
                angle = 45,
            },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 0,
        rounding_power = 0,
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
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
    misc = {
        force_default_wallpaper = 0,
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
            col = {
                active = "rgba(00ff00ff)",
                inactive = "rgba(7aa2f7ff)",
            },
            text_color = "rgba(ffffffff)",
            gradients = false,
            stacked = false,
            keep_upper_gap = false,
        },
    },
    input = {
        kb_layout = "us,rs,rs",
        kb_variant = ",latin,",
        kb_model = "",
        kb_options = "grp:win_space_toggle",
        kb_rules = "",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = false },
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
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

hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

local main_mod = "SUPER"
local function bind(keys, dispatcher, options)
    return hl.bind(main_mod .. " + " .. keys, dispatcher, options)
end

bind("RETURN", hl.dsp.exec_cmd(terminal))
bind("SHIFT + Q", hl.dsp.window.close())
bind("M", hl.dsp.exit())
bind("E", hl.dsp.exec_cmd(file_manager))
bind("V", function()
    local win = hl.get_active_window()
    local was_floating = win and win.floating
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    if win and not was_floating then
        local mon = hl.get_active_monitor()
        if mon then
            -- resize takes logical pixels only, no percent strings
            hl.dispatch(hl.dsp.window.resize({
                x = math.floor(mon.width / mon.scale / 2),
                y = math.floor(mon.height / mon.scale / 2),
            }))
            hl.dispatch(hl.dsp.window.center())
        end
    end
end)
bind("D", hl.dsp.exec_cmd(menu))
bind("escape", hl.dsp.exec_cmd(powermenu))
bind("L", hl.dsp.exec_cmd(lockscreen))
bind("K", hl.dsp.exec_cmd(password_manager))
bind("P", hl.dsp.window.pseudo())
bind("J", hl.dsp.layout("togglesplit"))
bind("G", hl.dsp.group.toggle())
bind("H", hl.dsp.exec_cmd(bar_toggle))
bind("Tab", hl.dsp.group.next())
bind("R", hl.dsp.window.swap({ next = true }))
bind("F", hl.dsp.exec_cmd(file_manager))
bind("B", hl.dsp.exec_cmd(browser))
bind("T", hl.dsp.exec_cmd(file_manager .. " trash:///"))
bind("SHIFT + T", hl.dsp.exec_cmd([[bash -c 'trash-empty && notify-send "Trash" "Trash emptied"']]))
bind("SHIFT + P", hl.dsp.exec_cmd([[hyprshot -m region -o "$HOME/Pictures/Screenshots"]]))
bind("SHIFT + L", hl.dsp.exec_cmd("hyprpicker -a"))

bind("SHIFT + V", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call clipboard toggle"))
bind("N", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call notifications toggle"))
bind("comma", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call settings focusOrToggle"))
bind("TAB", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call hypr toggleOverview"))

bind("left", hl.dsp.focus({ direction = "left" }))
bind("right", hl.dsp.focus({ direction = "right" }))
bind("up", hl.dsp.focus({ direction = "up" }))
bind("down", hl.dsp.focus({ direction = "down" }))

for workspace = 1, 10 do
    local key = workspace % 10
    bind(tostring(key), hl.dsp.focus({ workspace = workspace }))
    bind("SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

bind("S", hl.dsp.workspace.toggle_special("magic"))
bind("SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
bind("mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind("mouse_up", hl.dsp.focus({ workspace = "e-1" }))
bind("page_down", hl.dsp.focus({ workspace = "e+1" }))
bind("page_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind("ALT + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
    hl.bind("left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
    hl.bind("up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
    hl.bind("down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

bind("mouse:272", hl.dsp.window.drag(), { mouse = true })
bind("mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call audio increment 5"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call audio decrement 5"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call audio mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call audio micmute"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call brightness increment 5"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call brightness decrement 5"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("switch:Lid Switch", hl.dsp.exec_cmd("~/.config/hypr/scripts/lid-monitor.sh"), { locked = true })

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "float-dialog-apps",
    match = { class = "^(org\\.gnome\\.Calculator|org\\.keepassxc\\.KeePassXC)$" },
    float = true,
})

hl.window_rule({
    name = "foot-startup-workspace",
    match = { class = "^(foot-startup)$" },
    workspace = "2 silent",
})

for _, namespace in ipairs({ "hyprpicker", "selection", "^(noctalia)$" }) do
    hl.layer_rule({
        name = "no-animation-" .. namespace,
        match = { namespace = namespace },
        no_anim = true,
    })
end

require("noctalia.colors")
require("noctalia.layout")
require("noctalia.outputs")
