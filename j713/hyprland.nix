# Hyprland on the Air: the shared hyprland.conf plus what differs on this laptop. Later lines override the shared file.
{ pkgs, lib, ... }:
{
  imports = [ ../hm_modules/hyprland.nix ../hm_modules/mako.nix ../hm_modules/rofi.nix ./waybar.nix ];

  home.packages = with pkgs; [ brightnessctl hyprshot pamixer rofi rofi-power-menu swaybg wl-clipboard ];

  # hypr/hyprland.conf is in the classic format; Home Manager would otherwise generate Lua around it.
  wayland.windowManager.hyprland.configType = "hyprlang";

  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''

    # --- j713 overrides ---
    # 2560x1664 panel. The top 64 rows (43 logical pixels at this scale) are the notch strip, which Waybar owns.
    monitor = eDP-1, 2560x1664@60, 0x0, 1.5

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
