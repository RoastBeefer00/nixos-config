# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # <home-manager/nixos>
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Denver";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.enableRedistributableFirmware = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.roastbeefer = {
    isNormalUser = true;
    description = "roastbeefer";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [
    ];
  };

  # # Home Manager
  # home-manager.users.roastbeefer =
  #   { pkgs, ... }:
  #   {
  #     home.packages = [
  #       pkgs.alacritty
  #       pkgs.bat
  #       pkgs.btop
  #       pkgs.cowsay
  #       pkgs.docker
  #       pkgs.eza
  #       pkgs.htop
  #       pkgs.hyprshot
  #       pkgs.mako
  #       pkgs.nixfmt-rfc-style
  #       pkgs.rofi-wayland
  #       pkgs.skim
  #       pkgs.swaybg
  #       pkgs.thefuck
  #       pkgs.protonup-qt
  #       pkgs.wezterm
  #       pkgs.wl-clipboard
  #       pkgs.yazi
  #       pkgs.zsh-powerlevel10k
  #     ];
  #
  #     programs.zsh = {
  #       enable = true;
  #       enableCompletion = true;
  #       autosuggestion.enable = true;
  #       syntaxHighlighting.enable = true;
  #
  #       oh-my-zsh = {
  #         enable = true;
  #         plugins = [
  #           "git"
  #           "thefuck"
  #         ];
  #         theme = "";
  #       };
  #
  #       plugins = [
  #         {
  #           name = "zsh-nix-shell";
  #           file = "nix-shell.plugin.zsh";
  #           src = pkgs.fetchFromGitHub {
  #             owner = "chisui";
  #             repo = "zsh-nix-shell";
  #             rev = "v0.8.0";
  #             sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
  #           };
  #         }
  #         {
  #           name = "powerlevel10k";
  #           src = pkgs.zsh-powerlevel10k;
  #           file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  #         }
  #         {
  #           name = "powerlevel10k-config";
  #           src = ./p10k-config;
  #           file = ".p10k.zsh";
  #         }
  #       ];
  #
  #       shellAliases = {
  #         update = "sudo nixos-rebuild switch";
  #         edit = "sudoedit /etc/nixos/configuration.nix";
  #         zshconfig = "sudoedit /etc/nixos/.zshrc";
  #         vim = "nvim .";
  #         ll = "eza -la";
  #         ls = "eza -a";
  #         tree = "eza --tree";
  #       };
  #
  #       envExtra = ''
  #       '';
  #
  #       initExtra = builtins.readFile ./.zshrc;
  #
  #       # history = {
  #       #   size = 10000;
  #       #   path = "${config.xdg.dataHome}/zsh/history";
  #       # };
  #     };
  #
  #     wayland.windowManager.hyprland = {
  #       enable = true;
  #       extraConfig = builtins.readFile ./hypr/hyprland.conf;
  #     };
  #
  #     programs.waybar = {
  #       enable = true;
  #       style = builtins.readFile ./waybar/style.css;
  #       settings = [
  #         {
  #           layer = "top";
  #           position = "top";
  #           mod = "dock";
  #           exclusive = true;
  #           passtrough = false;
  #           gtk-layer-shell = true;
  #           height = 0;
  #           modules-left = [
  #             "hyprland/workspaces"
  #             "custom/divider"
  #             "custom/weather"
  #             "custom/divider"
  #             "cpu"
  #             "custom/divider"
  #             "memory"
  #           ];
  #           modules-center = [ "hyprland/window" ];
  #           modules-right = [
  #             "tray"
  #             "pulseaudio"
  #             "custom/divider"
  #             "clock"
  #           ];
  #           "hyprland/window" = {
  #             format = "{}";
  #           };
  #           "wlr/workspaces" = {
  #             on-scroll-up = "hyprctl dispatch workspace e+1";
  #             on-scroll-down = "hyprctl dispatch workspace e-1";
  #             all-outputs = true;
  #             on-click = "activate";
  #           };
  #           battery = {
  #             format = "󰁹 {}%";
  #           };
  #           cpu = {
  #             interval = 10;
  #             format = "󰻠 {}%";
  #             max-length = 10;
  #             on-click = "";
  #           };
  #           memory = {
  #             interval = 30;
  #             format = "  {}%";
  #             format-alt = " {used:0.1f}G";
  #             max-length = 10;
  #           };
  #           backlight = {
  #             format = "󰖨 {}";
  #             device = "acpi_video0";
  #           };
  #           "custom/weather" = {
  #             tooltip = true;
  #             format = "{}";
  #             restart-interval = 300;
  #             exec = "/home/roastbeefer/.local/scripts/weather";
  #           };
  #           tray = {
  #             icon-size = 13;
  #             tooltip = false;
  #             spacing = 10;
  #           };
  #           network = {
  #             format = "󰖩 {essid}";
  #             format-disconnected = "󰖪 disconnected";
  #           };
  #           clock = {
  #             format = " {:%I:%M %p   %m/%d} ";
  #             tooltip-format = ''
  #               <big>{:%Y %B}</big>
  #               <tt><small>{calendar}</small></tt>'';
  #           };
  #           pulseaudio = {
  #             format = "{icon} {volume}%";
  #             tooltip = false;
  #             format-muted = " Muted";
  #             on-click = "pamixer -t";
  #             on-scroll-up = "pamixer -i 5";
  #             on-scroll-down = "pamixer -d 5";
  #             scroll-step = 5;
  #             format-icons = {
  #               headphone = "";
  #               hands-free = "";
  #               headset = "";
  #               phone = "";
  #               portable = "";
  #               car = "";
  #               default = [
  #                 ""
  #                 ""
  #                 ""
  #               ];
  #             };
  #           };
  #           "pulseaudio#microphone" = {
  #             format = "{format_source}";
  #             tooltip = false;
  #             format-source = " {volume}%";
  #             format-source-muted = " Muted";
  #             on-click = "pamixer --default-source -t";
  #             on-scroll-up = "pamixer --default-source -i 5";
  #             on-scroll-down = "pamixer --default-source -d 5";
  #             scroll-step = 5;
  #           };
  #           "custom/divider" = {
  #             format = " | ";
  #             interval = "once";
  #             tooltip = false;
  #           };
  #           "custom/endright" = {
  #             format = "_";
  #             interval = "once";
  #             tooltip = false;
  #           };
  #         }
  #       ];
  #     };
  #
  #     services.mako = {
  #       enable = true;
  #       extraConfig = builtins.readFile ./mako/config;
  #     };
  #
  #     programs.btop = {
  #       enable = true;
  #       extraConfig = builtins.readFile ./btop/btop.conf;
  #     };
  #
  #     programs.wezterm = {
  #         enable = true;
  #         extraConfig = builtins.readFile ./wezterm/wezterm.lua;
  #     };
  #
  #     # Rofi
  #     home.file.".config/rofi/config.rasi".text = builtins.readFile ./rofi/config.rasi;
  #     home.file.".local/share/rofi/themes/catppuccin-mocha.rasi".text = builtins.readFile ./rofi/catppuccin-mocha.rasi;
  #
  #     home.stateVersion = "24.05";
  #   };
  # home-manager.useGlobalPkgs = true;
  # home-manager.useUserPackages = true;

  # Enable automatic login for the user.
  # services.xserver.displayManager.autoLogin.enable = false;
  # services.xserver.displayManager.autoLogin.user = "roastbeefer";

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    clang-tools
    curl
    gcc
    fira-code-nerdfont
    meson
    nodejs
    vim
    wayland-protocols
    wayland-utils
    wlroots
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    xwayland
  ];

  programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
  programs.nix-ld.enable = true;
  programs.zsh.enable = true;

  users.defaultUserShell = pkgs.zsh;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
