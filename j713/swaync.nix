# Notifications with a history panel and Do Not Disturb, opened from the bar's bell or Alt+N.
{ pkgs, ... }:
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
    widgets = [ "title" "dnd" "volume" "backlight" "backlight#kbd" "notifications" ];
    widget-config = {
      title = { text = "Notifications"; clear-all-button = true; button-text = "Clear"; };
      dnd.text = "Do not disturb";
      volume.label = "󰕾";
      backlight = { label = "󰃠"; device = "apple-panel-bl"; };
      "backlight#kbd" = { label = "󰌌"; device = "kbd_backlight"; subsystem = "leds"; };
    };
  };

  # Loaded on top of the stock style, so this only has to change the theme.
  xdg.configFile."swaync/style.css".source = ./swaync.css;
}
