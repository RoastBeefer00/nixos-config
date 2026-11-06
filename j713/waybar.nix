# Waybar for the Air: lives in the notch strip, with everything on either side of the notch and nothing in the middle.
{ ... }:
{
  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        position = "top";
        exclusive = true;
        height = 40;
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ ];
        modules-right = [ "tray" "network" "backlight" "pulseaudio" "battery" "clock" ];
        "hyprland/window" = { max-length = 40; separate-outputs = true; };
        network = { format-wifi = "󰖩 {essid}"; format-disconnected = "󰖪"; tooltip-format = "{ipaddr}"; };
        backlight = { format = "󰖨 {percent}%"; };
        pulseaudio = { format = "󰕾 {volume}%"; format-muted = "󰖁"; on-click = "pamixer -t"; };
        battery = { format = "{icon} {capacity}%"; format-charging = "󰂄 {capacity}%"; format-icons = [ "󰂎" "󰁻" "󰁽" "󰁿" "󰂁" "󰁹" ]; };
        clock = { format = "{:%I:%M %p  %m/%d}"; };
      }
    ];
    style = ''
      * { border: none; border-radius: 0; font-family: "FiraCode Nerd Font"; font-weight: bold; font-size: 14px; min-height: 0; }
      window#waybar { background: #000000; color: #cdd6f4; }
      #workspaces button { padding: 0 8px; color: #cdd6f4; }
      #workspaces button.active { color: #9ccfd8; }
      #window, #tray, #network, #backlight, #pulseaudio, #battery, #clock { padding: 0 10px; }
    '';
  };
}
