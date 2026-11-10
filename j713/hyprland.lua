-- Hyprland on the Air. Same keys and look as the desktop's hypr/hyprland.conf, in the format Hyprland is moving to.

-- 2560x1664 panel at 4/3 (1920x1248 logical). The top 64 rows (48 logical pixels) are the notch strip, which Waybar owns.
hl.monitor({ output = "eDP-1", mode = "2560x1664@60", position = "0x0", scale = 1.333333 })

hl.env("XCURSOR_THEME", "catppuccin-mocha-mauve-cursors")
hl.env("XCURSOR_SIZE", "24")
-- The session doesn't read Home Manager's variables, so the Qt theme has to be set here too.
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

-- Border colours of the current theme preset; Catppuccin Mocha if none is set up yet.
local ok, theme = pcall(dofile, os.getenv("HOME") .. "/.local/state/theme/current/hypr.lua")
if not ok then theme = { active = "rgb(cba6f7)", inactive = "rgba(45475aaa)" } end

hl.on("hyprland.start", function()
  -- Autologin skips the password, so the session starts locked. Unlocking also unlocks the keyring (PAM).
  hl.exec_cmd("hyprlock")
  hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
  hl.exec_cmd("j713-night-light")
  hl.exec_cmd("j713-battery-warn")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("waybar")
  hl.exec_cmd("swaync")
  hl.exec_cmd("swayosd-server")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("wl-paste --watch cliphist store")
  -- Wallpaper and colours of the current theme preset (j713/themes.nix; Super+Shift+T to change).
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("j713-theme --restore")
end)

hl.config({
  input = {
    kb_layout = "us",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = false,
      scroll_factor = 0.5,
      tap_to_click = true,
      clickfinger_behavior = true,
    },
  },
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 4,
    col = {
      active_border = theme.active,
      inactive_border = theme.inactive,
    },
    layout = "scrolling",
  },
  decoration = {
    rounding = 10,
    blur = { enabled = true, size = 6, passes = 2 },
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },
  },
  animations = { enabled = true },
  -- Out of the way while typing or reading; moving the mouse brings it back.
  cursor = { hide_on_key_press = true, inactive_timeout = 3 },
  dwindle = { preserve_split = true },
  -- If hyprlock ever dies, a new one can be started instead of the session staying stuck.
  misc = { allow_session_lock_restore = true },
})

hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

for _, class in ipairs({ "^(onboard)$", "^(.*.exe)$", "^(steam_app_.*)$", "^(steam_proton)$" }) do
  hl.window_rule({ match = { class = class }, float = true })
end

-- The bar's Bluetooth and audio menus.
hl.window_rule({ match = { class = "^(com.j713.popup)$" }, float = true, center = true, size = { 900, 600 } })

-- Blur only behind the menus: windows are opaque and the wallpaper needn't be redrawn for them.
for _, namespace in ipairs({ "rofi", "swaync-control-center", "swaync-notification-window" }) do
  hl.layer_rule({ match = { namespace = namespace }, blur = true, ignore_alpha = 0.3 })
end

local mainMod = "ALT"
local function bind(keys, dispatcher, opts)
  hl.bind(mainMod .. " + " .. keys, dispatcher, opts)
end

bind("Q", hl.dsp.window.close())
bind("SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("M", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind("SHIFT + Q", hl.dsp.exit())
bind("T", hl.dsp.exec_cmd("ghostty -e yazi"))
bind("C", hl.dsp.exec_cmd("cliphist list | rofi -dmenu -p Clipboard | cliphist decode | wl-copy"))
bind("F", hl.dsp.exec_cmd("google-chrome-stable"))
bind("V", hl.dsp.window.float({ action = "toggle" }))
bind("Space", hl.dsp.exec_cmd("rofi -show drun"))
bind("X", hl.dsp.layout("consume_or_expel prev"))
bind("R", hl.dsp.layout("colresize +conf"))
bind("N", hl.dsp.exec_cmd("swaync-client -t -sw"))
bind("SHIFT + N", hl.dsp.exec_cmd("swaync-client -d -sw"))
bind("period", hl.dsp.layout("move +col"))
bind("comma", hl.dsp.layout("move -col"))
bind("Return", hl.dsp.exec_cmd("ghostty"))
bind("S", hl.dsp.exec_cmd("rofi -show power-menu -modi power-menu:rofi-power-menu"))
bind("P", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
bind("SHIFT + P", hl.dsp.exec_cmd("hyprshot -m region --raw | satty --filename - --early-exit --copy-command wl-copy"))
bind("SHIFT + C", hl.dsp.exec_cmd("j713-color-pick"))
bind("SHIFT + R", hl.dsp.exec_cmd("j713-screen-record"))
bind("SHIFT + T", hl.dsp.exec_cmd("j713-theme"))

for _, d in ipairs({
  { "left", "H", "left" }, { "right", "L", "right" }, { "up", "K", "up" }, { "down", "J", "down" },
}) do
  bind(d[1], hl.dsp.focus({ direction = d[3] }))
  bind(d[2], hl.dsp.focus({ direction = d[3] }))
  bind("SHIFT + " .. d[2], hl.dsp.window.move({ direction = d[3] }))
end

for i = 1, 10 do
  local key = i % 10
  bind(key, hl.dsp.focus({ workspace = i }))
  bind("SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

bind("mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind("mouse_up", hl.dsp.focus({ workspace = "e-1" }))
bind("mouse:272", hl.dsp.window.drag(), { mouse = true })
bind("mouse:273", hl.dsp.window.resize(), { mouse = true })

bind("SHIFT + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
bind("SHIFT + left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
bind("SHIFT + up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
bind("SHIFT + down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume +5 --max-volume 100"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume -5"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --device apple-panel-bl --brightness +5"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --device apple-panel-bl --brightness -5"), { locked = true, repeating = true })
bind("equal", hl.dsp.exec_cmd("swayosd-client --device kbd_backlight --brightness +10"), { locked = true, repeating = true })
bind("minus", hl.dsp.exec_cmd("swayosd-client --device kbd_backlight --brightness -10"), { locked = true, repeating = true })
