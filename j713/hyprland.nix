# Hyprland on the Air, with its own Lua config (the classic .conf format is on its way out).
{ pkgs, ... }:
{
  imports = [ ../hm_modules/mako.nix ../hm_modules/rofi.nix ./waybar.nix ];

  home.packages = with pkgs; [
    brightnessctl
    (google-chrome.override { commandLineArgs = "--ozone-platform-hint=auto"; })
    hyprshot
    pamixer
    rofi
    rofi-power-menu
    swaybg
    wl-clipboard
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ./hyprland.lua;
  };
}
