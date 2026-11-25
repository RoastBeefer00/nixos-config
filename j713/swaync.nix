# Notifications with a history panel and Do Not Disturb, opened from the bar's bell or Alt+N.
{ config, pkgs, ... }:
{
  home.packages = [ pkgs.libnotify pkgs.swaynotificationcenter ];

  xdg.configFile."swaync/config.json".text = builtins.toJSON {
    positionX = "right";
    positionY = "top";
    layer = "overlay";
    timeout = 8;
    timeout-low = 4;
    timeout-critical = 0;
    notification-window-width = 400;
    control-center-width = 420;
    control-center-margin-top = 6;
    control-center-margin-bottom = 14;
    control-center-margin-right = 14;
    fit-to-screen = true;
    keyboard-shortcuts = true;
    notification-grouping = true;
    relative-timestamps = true;
    image-visibility = "when-available";
    hide-on-clear = false;
    hide-on-action = true;
    widgets = [ "title" "buttons-grid" "dnd" "volume" "backlight" "backlight#kbd" "notifications" ];
    widget-config = {
      title = { text = "Notifications"; clear-all-button = true; button-text = "Clear"; };
      dnd.text = "Do not disturb";
      # Quick toggles. Each button's state is read back with update-command, so it stays right when changed elsewhere.
      buttons-grid.actions = [
        {
          label = "󰤨  Wi-Fi";
          type = "toggle";
          command = ''sh -c '[ "$SWAYNC_TOGGLE_STATE" = true ] && nmcli radio wifi on || nmcli radio wifi off' '';
          update-command = ''sh -c 'nmcli radio wifi | grep -q enabled && echo true || echo false' '';
        }
        {
          label = "󰂯  Bluetooth";
          type = "toggle";
          command = ''sh -c '[ "$SWAYNC_TOGGLE_STATE" = true ] && bluetoothctl power on || bluetoothctl power off' '';
          update-command = ''sh -c 'bluetoothctl show | grep -q "Powered: yes" && echo true || echo false' '';
        }
        {
          label = "󰀝  Airplane";
          type = "toggle";
          command = ''sh -c '[ "$SWAYNC_TOGGLE_STATE" = true ] && rfkill block all || rfkill unblock all' '';
          update-command = ''sh -c 'rfkill list | grep -q "Soft blocked: no" && echo false || echo true' '';
        }
        {
          label = "󰍭  Mic muted";
          type = "toggle";
          command = "pamixer --default-source -t";
          update-command = "pamixer --default-source --get-mute";
        }
      ];
      volume.label = "󰕾";
      backlight = { label = "󰃠"; device = "apple-panel-bl"; };
      "backlight#kbd" = { label = "󰌌"; device = "kbd_backlight"; subsystem = "leds"; };
    };
  };

  # Loaded on top of the stock style, so this only has to change the theme.
  xdg.configFile."swaync/style.css".text = builtins.replaceStrings [ "@THEME@" ] [ "${config.home.homeDirectory}/.local/state/theme/current" ] (builtins.readFile ./swaync.css);
}
