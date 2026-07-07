{ pkgs, niri, ... }:
{
  imports = [
    ./hm_modules/common.nix
    ./hm_modules/hyprland.nix
    ./hm_modules/mako.nix
    ./hm_modules/niri.nix
    ./hm_modules/rofi.nix
    ./hm_modules/jellyfin.nix
    ./hm_modules/waybar.nix
    ./hm_modules/wezterm.nix

    # Desktop-only modules
    ./hm_modules/moondeck-buddy.nix
  ];

  home.packages = with pkgs; [
    alacritty
    bat
    btop
    cowsay
    docker
    eza
    fastfetch
    gamescope
    ghostty
    htop
    hyprshot
    lazygit
    lsfg-vk-ui
    mako
    ripgrep
    runelite
    rofi
    rofi-power-menu
    skim
    swaybg
    protonup-qt
    wezterm
    # pkgs.wl-clipboard
    # pkgs.yazi
    # pkgs.zsh-powerlevel10k
  ];

  services.moondeckBuddy = {
    enable = true;

    package = {
      version = "1.9.2";
      hash = "sha256-GhZlmdI+oa5BjEzr9bkR2sY/nVpd1nuJlT2hYYv6zGU=";
    };

    # GUI service follows graphical-session.target (recommended).
    guiSession = true;

    settings = {
      port = 59999; # must match firewall rule in game-streaming.nix
      preferHibernation = false;
      closeSteamBeforeSleep = true;
      sslProtocol = "SecureProtocols";
      logRules = ""; # set "buddy.*.debug=true" to troubleshoot
      envCaptureRegex = "^(?:SUNSHINE|APOLLO).*";

      # Leave empty — Buddy will find ~/.config/sunshine/apps.json automatically
      sunshineAppsFilepath = "";
      macAddressOverride = "";
      steamExecOverride = "/run/current-system/sw/bin/steam";
    };
  };

  home.stateVersion = "25.11";
}
