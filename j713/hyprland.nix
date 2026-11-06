# Hyprland on the Air: the shared hyprland.conf plus what differs on this laptop. Later lines override the shared file.
{ pkgs, lib, ... }:
{
  imports = [ ../hm_modules/mako.nix ../hm_modules/rofi.nix ./waybar.nix ];

  home.packages = with pkgs; [ brightnessctl hyprshot pamixer rofi rofi-power-menu swaybg wl-clipboard ];

  wayland.windowManager.hyprland = {
    enable = true;
    # hypr/hyprland.conf is in the classic format; Home Manager would otherwise generate Lua around it.
    configType = "hyprlang";
  };

  # The shared file, with the lines Hyprland 0.56 no longer accepts translated, then this laptop's overrides.
  wayland.windowManager.hyprland.extraConfig = builtins.replaceStrings
    [
      "    pseudotile = yes # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below\n"
      "    workspace_swipe = off\n"
      "windowrule=float,class:^(onboard)$"
      "windowrule=float,class:^(.*.exe)$"
      "windowrule=float,class:^(steam_app_.*)$"
      "windowrule=float,class:^(steam_proton)$"
      "bind = $mainMod, X, togglesplit, # dwindle"
      "swaybg -i ~/Pictures/waves.jpg"
    ]
    [
      ""
      ""
      "windowrule = float on, match:class ^(onboard)$"
      "windowrule = float on, match:class ^(.*.exe)$"
      "windowrule = float on, match:class ^(steam_app_.*)$"
      "windowrule = float on, match:class ^(steam_proton)$"
      "bind = $mainMod, X, layoutmsg, togglesplit"
      "swaybg -m fill -i ~/Pictures/waves.jpg"
    ]
    (builtins.readFile ../hypr/hyprland.conf) + ''

    # --- j713 overrides ---
    # 2560x1664 panel at 1.6 (1600x1040 logical). The top 64 rows (40 logical pixels) are the notch strip, which Waybar owns.
    monitor = eDP-1, 2560x1664@60, 0x0, 1.6

    gesture = 3, horizontal, workspace

    input {
      touchpad {
        natural_scroll = yes
        tap-to-click = yes
        clickfinger_behavior = yes
      }
    }

    unbind = $mainMod, F
    unbind = $mainMod, T
    bind = $mainMod, F, exec, firefox
    bind = $mainMod, T, exec, dolphin

    unbind = , XF86AudioRaiseVolume
    unbind = , XF86AudioLowerVolume
    unbind = , XF86AudioMute
    unbind = , XF86MonBrightnessUp
    unbind = , XF86MonBrightnessDown
    bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
    bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
    bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
  '';
}
