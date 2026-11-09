# M4 MacBook Air (J713). Hardware stack from github:aurora-silicon/nixos-aurora: aura, U-Boot, kernel, Mesa.
# Stage 1 lives in the macOS stub and is never touched from here. Each rebuild refreshes m1n1/boot.bin on the ESP.
{ config, lib, pkgs, rmatrix, ... }:
let
  vars = import ../vars.nix;
in
{
  imports = [ ../nix-common.nix ./j713-wifi.nix ./agent-sudo.nix ./fresh-packages.nix ];

  # Test suites that failed building natively, on hardware this Mac does not have:
  # libfprint on egis_etu905 (another vendor's reader), upower on test_wacom_bluetooth.
  nixpkgs.overlays = lib.mkAfter [ (final: prev: {
    libfprint = prev.libfprint.overrideAttrs { doInstallCheck = false; };
    upower = prev.upower.overrideAttrs { doCheck = false; doInstallCheck = false; postConfigure = ""; };
  }) ];

  aurora.desktop = "kde";
  aurora.fexMesa.enable = false;   # x86 guest Mesa needs an x86 builder; only for running x86 apps through FEX
  aurora.flatpak.enable = false;   # the Flatpak GL extension fails to build here; Flatpak is not used on this machine
  aurora.openssh.startAtBoot = true;
  aurora.stage2.requiredBoards = [ "j713" ];
  system.stateVersion = lib.mkForce "26.05";
  networking.hostName = "j713";
  networking.hostId = "4a373133";
  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";

  # GRUB on the ESP (installed as the removable loader U-Boot looks for); /boot itself is on the root filesystem.
  fileSystems."/" = { device = "/dev/disk/by-label/linux-root"; fsType = "ext4"; };
  fileSystems."/boot/efi" = { device = "/dev/nvme0n1p6"; fsType = "vfat"; options = [ "nofail" "umask=0077" ]; };
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub.configurationLimit = 8;
  # The menu is the way back to an older generation (the keyboard works there). Any arrow key stops the countdown.
  boot.loader.grub.timeoutStyle = "menu";
  boot.loader.timeout = 3;
  boot.loader.grub.theme = pkgs.callPackage ./grub-theme.nix { };
  # Text screens (the menu editor, "e") use this font; GRUB's default is tiny at this resolution.
  boot.loader.grub.font = "${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSansMono.ttf";
  boot.loader.grub.fontSize = 32;
  nix.gc.options = lib.mkForce "--delete-older-than 7d";   # 91 GB root, far less room than the desktop

  # The 10-core Air's loaded GPU firmware hash, missing from the driver's table.
  # Given to the package directly: boot.kernelPatches would be applied twice (once by the Apple Silicon module, once by NixOS).
  boot.kernelPackages = lib.mkForce (pkgs.linux-asahi.override {
    _kernelPatches = [ { name = "j713-g16-10core-firmware"; patch = ./g16-10core-firmware.patch; } ];
  });

  # Native display: admit the retained display DARTs at boot; appledrm then takes over from simpledrm.
  # The GPU driver must load after the display (Documentation/gpu/apple-dcp-m4.rst), so it is not left to chance.
  systemd.services.j713-gpu = {
    description = "Load the J713 GPU driver after the native display";
    wantedBy = [ "multi-user.target" ];
    before = [ "display-manager.service" ];
    after = [ "systemd-udev-settle.service" "systemd-modules-load.service" ];
    path = [ pkgs.kmod pkgs.coreutils ];
    serviceConfig = { Type = "oneshot"; RemainAfterExit = true; TimeoutStartSec = 90; };
    script = ''
      modprobe appledrm
      for i in $(seq 1 45); do
        for c in /sys/class/drm/card?; do
          [ "$(basename "$(readlink -f "$c/device/driver")")" = apple-drm ] && { modprobe asahi; exit 0; }
        done
        sleep 1
      done
      echo "native display did not appear; not loading the GPU driver"
    '';
  };
  systemd.targets.hibernate.enable = false;

  # Boot splash instead of kernel messages. It starts on simpledrm; j713-gpu switches the panel to appledrm mid-boot.
  # To see boot messages again, set enable = false and drop "quiet" "splash" below.
  boot.plymouth = {
    enable = true;
    theme = "catppuccin-mocha";
    themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
  };
  # powersupersave lets the Wi-Fi link use PCIe L1.2: about 0.13 W less at idle, measured over 5 runs.
  boot.kernelParams = lib.mkAfter [ "console=tty0" "apple_dart.j713_dcp=1" "apple_dart.j713_display=1" "pcie_aspm.policy=powersupersave"
    "quiet" "splash" "udev.log_level=3" ];
  boot.consoleLogLevel = 3;

  # This kernel rejects NixOS's ASLR entropy values, which would mark every rebuild as failed.
  environment.etc."sysctl.d/55-nixos-aslr-entropy.conf".source = lib.mkForce (pkgs.writeText "no-aslr-override" "");

  users.users.${vars.username} = {
    isNormalUser = true;
    description = vars.username;
    extraGroups = [ "wheel" "video" "input" "render" "docker" ];
    shell = pkgs.fish;
    hashedPasswordFile = "/var/lib/j713/user-password.hash";   # root-only, not in the store
  };
  programs.fish.enable = true;
  virtualisation.docker.enable = true;
  zramSwap.enable = true;
  # This kernel has no J713 Touch ID yet, so asking fprintd only stalls the password prompt until it times out.
  security.pam.services.sudo.fprintAuth = lib.mkForce false;
  security.pam.services.polkit-1.fprintAuth = lib.mkForce false;
  # Newer Aurora kernels can start the security chip macOS also uses, and Aurora's loader turns on writes to their shared storage.
  # Keep it off until Touch ID is a deliberate choice. An install rule also beats the options on the loader's modprobe command.
  boot.extraModprobeConfig = "install apple_sep ${pkgs.coreutils}/bin/false";
  systemd.timers.aurora-sep.enable = false;
  systemd.services.aurora-sep.enable = false;
  systemd.services.aurora-sep-ready.enable = false;
  systemd.services.aurora-touchid-setup.enable = false;
  # Waits 30 s for a device only apple_sep creates, holding up the login on every boot.
  systemd.services.aurora-touchid-boot.enable = false;

  services.displayManager.autoLogin = { enable = true; user = vars.username; };
  services.displayManager.defaultSession = "hyprland";   # Plasma stays installed as the fallback session
  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;   # also sets up its PAM service, which it needs to accept a password
  # hyprlock also turns on a hypridle service, but hyprland.lua already starts one. Two of them leave a stuck hyprlock that blocks every later lock.
  services.hypridle.enable = lib.mkForce false;
  fonts.packages = [ pkgs.nerd-fonts.fira-code ];

  networking.firewall.enable = true;   # only SSH is open, through services.openssh
  documentation.nixos.enable = false;
  environment.systemPackages = [ pkgs.kdePackages.konsole pkgs.kdePackages.dolphin rmatrix.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
