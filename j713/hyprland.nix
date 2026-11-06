# Hyprland on the Air, with its own Lua config (the classic .conf format is on its way out).
{ pkgs, ... }:
let
  # Centres the Wi-Fi menu under the click. networkmanager_dmenu picks its password flags by this file's name, so it must be "rofi".
  wifiRofi = pkgs.writeShellScriptBin "rofi" ''
    width=360
    x=$(hyprctl cursorpos | ${pkgs.coreutils}/bin/cut -d, -f1)
    left=$((x - width / 2))
    max=$((1920 - width - 12))
    [ "$left" -gt "$max" ] && left=$max
    [ "$left" -lt 12 ] && left=12
    exec ${pkgs.rofi}/bin/rofi -i -theme-str "window { location: northwest; anchor: northwest; x-offset: ''${left}px; y-offset: 54px; width: ''${width}px; } listview { columns: 1; lines: 10; }" "$@"
  '';
in
{
  imports = [ ../hm_modules/mako.nix ../hm_modules/rofi.nix ./waybar.nix ];

  home.packages = with pkgs; [
    brightnessctl
    (google-chrome.override { commandLineArgs = "--ozone-platform-hint=auto"; })
    hyprshot
    networkmanager_dmenu
    pamixer
    rofi
    rofi-power-menu
    swaybg
    wl-clipboard
  ];

  # The Wi-Fi menu that drops down from the bar's network pill.
  xdg.configFile."networkmanager-dmenu/config.ini".text = ''
    [dmenu]
    dmenu_command = ${wifiRofi}/bin/rofi
    compact = True
    wifi_chars = ▂▄▆█

    [editor]
    terminal = ghostty
    gui_if_available = False
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ./hyprland.lua;
  };
}
