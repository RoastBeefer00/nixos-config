# Hyprland on the Air, with its own Lua config (the classic .conf format is on its way out).
{ config, lib, pkgs, ... }:
{
  imports = [ ../hm_modules/rofi.nix ./swaync.nix ./theme.nix ./themes.nix ./waybar.nix ];

  home.packages = with pkgs; [
    bluetui
    brightnessctl
    cliphist
    (google-chrome.override { commandLineArgs = "--ozone-platform-hint=auto --password-store=gnome-libsecret"; })
    hypridle
    hyprpolkitagent
    hyprshot
    pamixer
    rofi
    rofi-power-menu
    satty
    swayosd
    wifitui
    wiremix
    wl-clipboard
    yazi
  ] ++ import ./scripts.nix { inherit pkgs; };

  # The current theme preset sets the colours (with a translucent background, so the blur behind the menus shows).
  home.file.".local/share/rofi/themes/catppuccin-mocha.rasi".text = lib.mkForce (
    builtins.readFile ../rofi/catppuccin-mocha.rasi + "\n@import \"${config.home.homeDirectory}/.local/state/theme/current/rofi.rasi\"\n"
  );

  xdg.configFile."swayosd/style.css".text = builtins.replaceStrings [ "@THEME@" ] [ "${config.home.homeDirectory}/.local/state/theme/current" ] (builtins.readFile ./swayosd.css);

  # Lock before suspend. hypridle holds the suspend until the lock is up, so the desktop never shows on wake.
  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
      lock_cmd = pidof hyprlock || hyprlock
      before_sleep_cmd = loginctl lock-session
    }

    # Dim the screen and turn off the keyboard after 2 minutes, without going below 5% brightness.
    listener {
      timeout = 120
      on-timeout = brightnessctl -s -n25 set 20%-
      on-resume = brightnessctl -r
    }
    listener {
      timeout = 120
      on-timeout = brightnessctl -d kbd_backlight -s set 0
      on-resume = brightnessctl -d kbd_backlight -r
    }

    listener {
      timeout = 300
      on-timeout = hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'
      on-resume = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
    }

    listener {
      timeout = 600
      on-timeout = loginctl lock-session
    }
  '';
  xdg.configFile."hypr/hyprlock.conf".source = ./hyprlock.conf;

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ./hyprland.lua;
  };
}
