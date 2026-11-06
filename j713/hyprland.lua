-- Hyprland on the Air. Same keys and look as the desktop's hypr/hyprland.conf, in the format Hyprland is moving to.

-- 2560x1664 panel at 4/3 (1920x1248 logical). The top 64 rows (48 logical pixels) are the notch strip, which Waybar owns.
hl.monitor({ output = "eDP-1", mode = "2560x1664@60", position = "0x0", scale = 1.333333 })

hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("mako")
  hl.exec_cmd("swaybg -m fill -i ~/Pictures/clearnight.jpg")
end)

hl.config({
  input = {
    kb_layout = "us",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
      tap_to_click = true,
      clickfinger_behavior = true,
    },
  },
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 4,
    col = {
      active_border = "rgb(9ccfd8)",
      inactive_border = "rgba(595959aa)",
    },
    layout = "dwindle",
  },
  decoration = {
    rounding = 10,
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },
  },
  animations = { enabled = true },
  dwindle = { preserve_split = true },
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

local mainMod = "ALT"
local function bind(keys, dispatcher, opts)
  hl.bind(mainMod .. " + " .. keys, dispatcher, opts)
end

bind("Q", hl.dsp.window.close())
bind("SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("M", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind("SHIFT + Q", hl.dsp.exit())
bind("T", hl.dsp.exec_cmd("dolphin"))
bind("F", hl.dsp.exec_cmd("google-chrome-stable"))
bind("V", hl.dsp.window.float({ action = "toggle" }))
bind("Space", hl.dsp.exec_cmd("rofi -show drun"))
bind("X", hl.dsp.layout("togglesplit"))
bind("Return", hl.dsp.exec_cmd("ghostty"))
bind("S", hl.dsp.exec_cmd("rofi -show power-menu -modi power-menu:rofi-power-menu"))
bind("P", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))

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

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
