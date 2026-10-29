# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  waybar-weather,
  ...
}:

let
  vars = import ./vars.nix;
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./game-streaming.nix
    ./nix-common.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "nvidia_uvm" ];
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    # Inject a 2560x1440@60 mode into DP-2 (LG UltraGear) via a custom EDID so
    # Sunshine can capture a clean 16:9 1440p signal for the TV. The panel only
    # advertises 3440x1440 (native) and 1920x1080. See hardware.firmware below.
    # NOTE: NVIDIA's DRM has historically ignored drm.edid_firmware; the open
    # kernel modules (hardware.nvidia.open = true) give this a real chance. If
    # 2560x1440 doesn't appear in `kscreen-doctor -o` after reboot, this override
    # isn't being honored -- fall back to a 1440p dummy plug.
    "drm.edid_firmware=DP-2:edid/lg-dp2.bin"
    # Force DP-2 to stay "connected" even when the monitor is powered off, so
    # the compositor keeps a live output (using the EDID above) for Sunshine to
    # capture headlessly. The EDID override is confirmed honored on this
    # driver; whether the force flag is too is untested -- after reboot, power
    # the monitor off and check `kscreen-doctor -o` still lists DP-2. If not,
    # use a DP dummy plug.
    "video=DP-2:e"
  ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Wake-on-LAN on the wired NIC, so the box can be woken remotely instead of
  # staying powered on 24/7. Also needs "Wake on LAN" (sometimes "Power On By
  # PCI-E/PCIE") enabled in the motherboard's BIOS/UEFI -- this setting alone
  # only re-arms it on every boot, it can't turn it on from a fully powered
  # off state if the firmware itself has it disabled.
  networking.interfaces.enp34s0.wakeOnLan.enable = true;

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
  # services.geoclue2.enable = true;
  # location.provider = "geoclue2";
  # location.longitude = 32.3;
  # location.latitude = -106.8;

  # services.redshift = {
  #   enable = true;
  #   package = pkgs.unstable.redshift;
  # };

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Auto-login straight into the Plasma Wayland session ("plasma" is the
  # Wayland session id registered by plasma-workspace; "plasmax11" is X11).
  services.displayManager.defaultSession = "plasma";
  services.displayManager.autoLogin = {
    enable = true;
    user = vars.username;
  };

  # Never sleep/suspend/hibernate -- this is a streaming host that needs to
  # stay reachable. Masking the targets makes systemctl suspend/hibernate (and
  # anything that calls into them, including Plasma's own power management) a
  # no-op, regardless of idle timers or lid/power-button handling.
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
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
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.enableRedistributableFirmware = true;

  # Custom merged EDID for DP-2. The stock LG UltraGear EDID only offers
  # 3440x1440 (native, incl. 144Hz) and 1920x1080. This adds extra detailed
  # timings (CVT-RB) injected into unused CTA-861 space so the native
  # 144Hz/FreeSync/HDR data is left byte-for-byte untouched:
  #   - 2560x1440@60 (actually 59.95) for 16:9 1440p TV streaming.
  #   - 1280x800@90 (actually 89.82) so MoonDeckStream can run the Steam
  #     Deck OLED's max refresh rate instead of being stuck at 60.
  # 1280x800@60 itself needs no custom timing -- it's already a standard DMT
  # timing in the base EDID -- but there's no stock 90Hz equivalent.
  # Loaded via the drm.edid_firmware kernel param above.
  hardware.firmware = [
    (pkgs.runCommand "edid-dp2-1440p" { } ''
      mkdir -p "$out/lib/firmware/edid"
      cp ${./edid/lg-dp2.bin} "$out/lib/firmware/edid/lg-dp2.bin"
    '')
  ];

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${vars.username} = {
    isNormalUser = true;
    description = vars.username;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [ ];
  };

  systemd.tmpfiles.rules = [
    "d ${vars.mediaDir} 0775 ${vars.username} users - -"
    "d ${vars.mediaDir}/movies 0775 ${vars.username} users - -"
    "d ${vars.mediaDir}/tvshows 0775 ${vars.username} users - -"
    "d ${vars.mediaDir}/downloads 0775 ${vars.username} users - -"
    "d ${vars.mediaDir}/downloads/incomplete 0775 ${vars.username} users - -"
    "d ${vars.mediaDir}/downloads/complete 0775 ${vars.username} users - -"
  ];

  virtualisation.docker.enable = true;

  nix.settings.trusted-users = [ "@wheel" ];
  nix.gc.dates = "weekly";
  nix.optimise.dates = [ "weekly" ];

  # Install firefox.
  programs.firefox.enable = true;

  gaming.streaming = {
    enable = true;
    user = vars.username;
    # Stream from a KWin virtual display sized per client, monitor off. To
    # revert to switching the physical monitor's resolution, set false.
    headless.enable = true;
    sunshine = {
      package = pkgs.sunshine.override {
        cudaSupport = true;
      };
      settings = {
        encoder = "nvenc";
      };
    };
  };

  # ── RustDesk (unattended remote desktop) ────────────────────────────────────
  # Runs as root, same model as the official .deb/.rpm install: is_installed()
  # recognizes /nix/store paths, so --service/--password/--get-id all work.
  # The root service scans /proc for the logged-in user's session to borrow
  # its DBUS_SESSION_BUS_ADDRESS/XDG_RUNTIME_DIR, then captures video via the
  # xdg-desktop-portal ScreenCast+PipeWire path (KWin supports this, unlike
  # the raw wlr-screencopy protocol dropped for OBS above) and injects input
  # via uinput (already enabled in game-streaming.nix). No inbound firewall
  # ports needed -- it connects outbound to RustDesk's public relay servers.
  #
  # NOTE: the very first ScreenCast request on Plasma Wayland may pop up an
  # in-person "Share your screen?" consent dialog; KWin persists that choice
  # afterward so it shouldn't prompt again. If that first-approval step turns
  # out to be a blocker, "plasmax11" has no such portal/consent step.
  #
  # After rebuilding, set the unattended password once (not stored in nix):
  #   sudo rustdesk --password 'yourpassword'
  #   rustdesk --get-id
  systemd.services.rustdesk = {
    description = "RustDesk remote desktop (unattended service)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    # The service launches its per-user --server via `sudo`, which on NixOS is
    # the setuid wrapper in /run/wrappers/bin -- not in a unit's default PATH.
    path = [
      "/run/wrappers"
      pkgs.procps
    ];
    # Wayland capture builds a GStreamer pipeline (pipewiresrc ! videoconvert !
    # appsink). nixpkgs' wrapper only exposes gstreamer core + base, so
    # pipewiresrc (shipped by pipewire) is missing -> "no GStreamer". The
    # per-user --server is the unwrapped binary spawned via `sudo -E`, so it
    # inherits this from the service environment.
    environment.GST_PLUGIN_SYSTEM_PATH_1_0 = pkgs.lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
      pkgs.gst_all_1.gstreamer
      pkgs.gst_all_1.gst-plugins-base
      pkgs.pipewire
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.rustdesk}/bin/rustdesk --service";
      ExecStop = "${pkgs.rustdesk}/bin/rustdesk --stop-service";
      # Accept sessions via the permanent password only -- the default asks
      # for an in-person click on the PC every time, which defeats unattended
      # access. --option talks to the running service over IPC, so retry until
      # it is up. The leading "-" means a failure here never fails the unit.
      ExecStartPost = "-${pkgs.writeShellScript "rustdesk-unattended-options" ''
        rd=${pkgs.rustdesk}/bin/rustdesk
        # --option set never reports failure, so verify by reading it back.
        for _ in $(seq 1 30); do
          sleep 2
          $rd --option approve-mode password >/dev/null 2>&1
          $rd --option verification-method use-permanent-password >/dev/null 2>&1
          if [ "$($rd --option approve-mode 2>/dev/null)" = password ] \
            && [ "$($rd --option verification-method 2>/dev/null)" = use-permanent-password ]; then
            exit 0
          fi
        done
        exit 1
      ''}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages =
    with pkgs;
    [
      git
      clang-tools
      curl
      devenv
      discord
      gammastep
      rustdesk
      gcc
      google-chrome
      lsfg-vk
      nerd-fonts.fira-code
      meson
      # OBS Studio. On Wayland, capture goes through the PipeWire ScreenCast
      # portal ("Screen Capture (PipeWire)" / "Window Capture (PipeWire)"),
      # which works on both KDE (kde portal) and niri (gnome portal). wlrobs was
      # dropped: it needs wlr-screencopy/wlr-export-dmabuf, which niri and KWin
      # don't expose -- it can't capture on either compositor. obs-vaapi dropped
      # too: NVIDIA has no VAAPI encode path. vkcapture stays for game capture.
      #
      # wrapOBS doesn't expose the NVIDIA encode/CUDA libs, so obs-nvenc-test
      # fails with "Cannot load libnvidia-encode.so.1" and NVENC is unavailable
      # (only x264/AV1 software encoders show up). Append the driver lib dir so
      # obs and the nvenc probe it spawns can dlopen libnvidia-encode/libcuda.
      (symlinkJoin {
        name = "obs-studio-nvenc";
        paths = [
          (wrapOBS {
            plugins = with obs-studio-plugins; [
              obs-pipewire-audio-capture
              obs-vkcapture
            ];
          })
        ];
        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          for b in obs obs-nvenc-test; do
            if [ -e "$out/bin/$b" ]; then
              wrapProgram "$out/bin/$b" \
                --suffix LD_LIBRARY_PATH : /run/opengl-driver/lib
            fi
          done
        '';
      })
      pavucontrol
      vim
      skim
      wayland-protocols
      wayland-utils
      # wayland-virtual-display
      wl-clipboard
      wlroots
      wlr-randr
      xdg-desktop-portal-wlr
      kdePackages.xdg-desktop-portal-kde
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
      xwayland
      xwayland-satellite
    ]
    ++ [
      waybar-weather.packages.${pkgs.system}.default
    ];

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
    # config = {
    #   common = {
    #     default = [ "kde" ];
    #   };
    #   kde = {
    #     default = [
    #       "kde"
    #       # "gtk"
    #     ];
    #     "org.freedesktop.impl.portal.ScreenCast" = [ "kde" ];
    #   };
    # };
  };

  systemd.user.services.gammastep = {
    description = "Gammastep colour temperature adjuster";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.gammastep}/bin/gammastep -l 32.3:-106.8";
      Restart = "on-failure";
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  # programs.neovim = {
  #   enable = true;
  #   defaultEditor = true;
  # };

  programs.direnv.enable = true;
  # programs.nix-ld.enable = true;
  # programs.zsh.enable = true;
  programs.fish.enable = true;

  users.defaultUserShell = pkgs.fish;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.niri = {
    enable = true;
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.MOZ_ENABLE_WAYLAND = "1";
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # LIBVA_DRIVER_NAME = "nvidia";
    # WLR_NO_HARDWARE_CURSORS dropped: it forced software cursors to dodge the
    # old NVIDIA hardware-cursor bug on wlroots compositors (niri/Hyprland).
    # Explicit sync (default since driver 555, active on 595) fixes that bug, so
    # hardware cursors work again -> lower latency, less per-frame overhead.
    # (No effect on KDE/KWin either way.) If the cursor misbehaves in niri or
    # Hyprland, or goes missing when streaming from those sessions, restore:
    #   WLR_NO_HARDWARE_CURSORS = "1";
  };
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
  networking.firewall.allowedTCPPorts = [ 8080 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
