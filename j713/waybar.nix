# Waybar for the Air: Catppuccin Mocha pills over the wallpaper, on either side of the notch and nothing behind it.
{ pkgs, ... }:
let
  power = pkgs.writeShellScript "waybar-power" ''
    export PATH=${pkgs.coreutils}/bin:${pkgs.gawk}/bin
    ${builtins.readFile ./waybar-power.sh}
  '';
  weather = pkgs.writeShellScript "waybar-weather" ''
    export PATH=${pkgs.coreutils}/bin:${pkgs.curl}/bin
    ${builtins.readFile ./waybar-weather.sh}
  '';
  # One coloured bar per CPU core, quiet at idle and hot under load.
  coreBars = map (b: "<span color='${b.color}'>${b.bar}</span>") [
    { bar = "▁"; color = "#74c7ec"; }
    { bar = "▂"; color = "#74c7ec"; }
    { bar = "▃"; color = "#94e2d5"; }
    { bar = "▄"; color = "#94e2d5"; }
    { bar = "▅"; color = "#f9e2af"; }
    { bar = "▆"; color = "#f9e2af"; }
    { bar = "▇"; color = "#f38ba8"; }
    { bar = "█"; color = "#f38ba8"; }
  ];
in
{
  programs.waybar = {
    enable = true;
    # Waybar 0.15 clicks workspaces with a classic dispatch, which Hyprland's Lua mode rejects.
    package = pkgs.waybar.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace src/modules/hyprland/workspace.cpp \
          --replace-fail '"dispatch workspace " + std::to_string(id())' \
                         '"dispatch hl.dsp.focus({ workspace = " + std::to_string(id()) + " })"'
      '';
    });
    settings = [
      {
        layer = "top";
        position = "top";
        exclusive = true;
        height = 48;
        spacing = 0;
        modules-left = [ "custom/launcher" "hyprland/workspaces" "cpu" "temperature" "memory" "hyprland/window" ];
        modules-center = [ "custom/notch" ];
        modules-right = [ "mpris" "tray" "bluetooth" "network" "backlight" "pulseaudio" "battery" "custom/power" "custom/weather" "clock" "custom/notification" "custom/powermenu" ];

        "custom/launcher" = {
          format = "";
          tooltip-format = "Apps";
          on-click = "rofi -show drun";
        };
        # Invisible and as wide as the notch: this keeps both sides out from behind it.
        "custom/notch" = { format = " "; tooltip = false; };

        "hyprland/workspaces" = {
          format = "{id}{windows}";
          format-window-separator = " ";
          persistent-workspaces."*" = 5;
          window-rewrite-default = " 󰣆";
          window-rewrite = {
            "class<google-chrome>" = " 󰊯";
            "class<com.mitchellh.ghostty>" = " 󰆍";
            "class<org.kde.konsole>" = " 󰆍";
            "class<org.kde.dolphin>" = " 󰉋";
            "class<firefox>" = " 󰈹";
          };
          on-scroll-up = "hyprctl dispatch 'hl.dsp.focus({ workspace = \"e-1\" })'";
          on-scroll-down = "hyprctl dispatch 'hl.dsp.focus({ workspace = \"e+1\" })'";
        };
        "hyprland/window" = {
          format = "{title}";
          max-length = 32;
          separate-outputs = true;
          icon = false;
        };

        cpu = {
          interval = 2;
          format = "{icon0}{icon1}{icon2}{icon3}{icon4}{icon5}{icon6}{icon7}{icon8}{icon9}";
          format-icons = coreBars;
          tooltip = true;
          on-click = "ghostty -e btop";
        };
        temperature = {
          thermal-zone = 1;
          interval = 5;
          critical-threshold = 95;
          format = "󰔏 {temperatureC}°";
          format-critical = "󰔏 {temperatureC}°";
        };
        memory = {
          interval = 10;
          format = "󰍛 {percentage}%";
          tooltip-format = "{used:0.1f} of {total:0.1f} GiB used";
          on-click = "ghostty -e btop";
        };

        mpris = {
          format = "{status_icon} {dynamic}";
          dynamic-order = [ "title" "artist" ];
          dynamic-len = 24;
          status-icons = { playing = "󰐊"; paused = "󰏤"; stopped = "󰝚"; };
        };
        tray = { icon-size = 18; spacing = 10; };
        bluetooth = {
          format = "󰂯";
          format-disabled = "";
          format-off = "󰂲";
          format-no-controller = "";
          format-connected = "󰂯 {num_connections}";
          tooltip-format = "{status}";
          tooltip-format-connected = "{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}";
        };
        network = {
          interval = 3;
          format-wifi = "{icon}";
          format-ethernet = "󰤨";
          format-disconnected = "󰤮";
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
          tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ipaddr}\n↓ {bandwidthDownBytes}  ↑ {bandwidthUpBytes}";
          tooltip-format-disconnected = "Offline. Click to connect.";
          on-click = "networkmanager_dmenu";
        };
        backlight = {
          device = "apple-panel-bl";
          format = "{icon} {percent}%";
          format-icons = [ "󰃞" "󰃟" "󰃠" ];
          on-scroll-up = "brightnessctl -q set 5%+";
          on-scroll-down = "brightnessctl -q set 5%-";
          tooltip = false;
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟";
          format-icons = { headphone = "󰋋"; default = [ "󰕿" "󰖀" "󰕾" ]; };
          scroll-step = 5;
          max-volume = 100;
          on-click = "pamixer -t";
          tooltip-format = "{desc}";
        };
        battery = {
          interval = 10;
          states = { warning = 25; critical = 10; };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰚥 {capacity}%";
          format-icons = [ "󰂎" "󰁺" "󰁼" "󰁾" "󰂀" "󰂂" "󰁹" ];
          tooltip-format = "{timeTo}, {cycles} cycles, {health}% health";
        };
        "custom/power" = {
          exec = "${power}";
          return-type = "json";
          interval = 5;
          format = "󱐋 {}";
        };
        "custom/weather" = {
          exec = "${weather}";
          return-type = "json";
          interval = 900;
        };
        clock = {
          interval = 1;
          format = "{:%a %b %d  %I:%M %p}";
          tooltip-format = "<tt>{calendar}</tt>";
          calendar = {
            mode = "month";
            format = {
              months = "<span color='#cba6f7'><b>{}</b></span>";
              weekdays = "<span color='#f9e2af'><b>{}</b></span>";
              today = "<span color='#94e2d5'><b><u>{}</u></b></span>";
            };
          };
          actions = { on-scroll-up = "shift_up"; on-scroll-down = "shift_down"; on-click-right = "shift_reset"; };
        };
        "custom/notification" = {
          exec = "swaync-client -swb";
          return-type = "json";
          escape = true;
          format = "{icon}";
          format-icons = {
            none = "󰂚";
            notification = "󰂞";
            dnd-none = "󰂛";
            dnd-notification = "󰂛";
            inhibited-none = "󰂚";
            inhibited-notification = "󰂞";
            dnd-inhibited-none = "󰂛";
            dnd-inhibited-notification = "󰂛";
          };
          tooltip = false;
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
        };
        "custom/powermenu" = {
          format = "󰐥";
          tooltip-format = "Power";
          on-click = "rofi -show power-menu -modi power-menu:rofi-power-menu";
        };
      }
    ];
    style = builtins.readFile ./waybar.css;
  };
}
