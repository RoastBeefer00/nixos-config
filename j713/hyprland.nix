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
    wlogout
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

  # Power menu: big icon buttons for the mouse, and a key on each (l, e, s, r, p) for the keyboard. Esc closes it.
  xdg.configFile."wlogout/layout".text = lib.concatMapStrings (b: builtins.toJSON b + "\n") [
    { label = "lock"; action = "loginctl lock-session"; text = "Lock"; keybind = "l"; }
    { label = "logout"; action = "hyprctl dispatch 'hl.dsp.exit()'"; text = "Log out"; keybind = "e"; }
    { label = "suspend"; action = "systemctl suspend"; text = "Sleep"; keybind = "s"; }
    { label = "reboot"; action = "systemctl reboot"; text = "Restart"; keybind = "r"; }
    { label = "shutdown"; action = "systemctl poweroff"; text = "Shut down"; keybind = "p"; }
  ];
  xdg.configFile."wlogout/style.css".text = ''
    @import url("file://${config.home.homeDirectory}/.local/state/theme/current/colors.css");
    * { font-family: "FiraCode Nerd Font"; font-size: 18px; background-image: none; }
    window { background-color: alpha(@base, 0.6); }
    button {
      color: @text;
      background-color: alpha(@surface0, 0.85);
      border: 2px solid @surface1;
      border-radius: 24px;
      margin: 24px;
      background-repeat: no-repeat;
      background-position: center 40%;
      background-size: 25%;
    }
    button:focus, button:hover { background-color: @mauve; color: @base; border-color: @mauve; }
    #lock { background-image: url("${pkgs.wlogout}/share/wlogout/icons/lock.png"); }
    #logout { background-image: url("${pkgs.wlogout}/share/wlogout/icons/logout.png"); }
    #suspend { background-image: url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"); }
    #reboot { background-image: url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"); }
    #shutdown { background-image: url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"); }
  '';

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
