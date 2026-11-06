# M4 MacBook Air (J713). Hardware stack from github:aurora-silicon/nixos-aurora: aura, U-Boot, kernel, Mesa.
# Stage 1 lives in the macOS stub and is never touched from here. Each rebuild refreshes m1n1/boot.bin on the ESP.
{ config, lib, pkgs, ... }:
let
  vars = import ../vars.nix;
in
{
  imports = [ ../nix-common.nix ./j713-wifi.nix ];

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
  fileSystems."/" = { device = "/dev/disk/by-label/gravity-root"; fsType = "ext4"; };
  fileSystems."/boot/efi" = { device = "/dev/nvme0n1p6"; fsType = "vfat"; options = [ "nofail" "umask=0077" ]; };
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub.configurationLimit = 8;

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
  # Display suspend/resume is not qualified on this firmware session yet.
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Bring-up: visible boot messages, and the conservative CPU idle arguments until they are tested without.
  boot.plymouth.enable = false;
  boot.kernelParams = lib.mkAfter [ "console=tty0" "nohlt" "idle=nop" "arm64.nowfxt" "apple_dart.j713_dcp=1" "apple_dart.j713_display=1" ];
  boot.consoleLogLevel = 4;

  # This kernel rejects NixOS's ASLR entropy values, which would mark every rebuild as failed.
  environment.etc."sysctl.d/55-nixos-aslr-entropy.conf".source = lib.mkForce (pkgs.writeText "no-aslr-override" "");

  # jake is the bring-up account, kept as a way back in. Everything else follows vars.nix.
  users.users.jake = { isNormalUser = true; extraGroups = [ "wheel" "video" "input" "render" ]; };
  users.users.${vars.username} = {
    isNormalUser = true;
    description = vars.username;
    extraGroups = [ "wheel" "video" "input" "render" ];
    shell = pkgs.fish;
    hashedPasswordFile = "/var/lib/j713/user-password.hash";   # root-only, not in the store
  };
  programs.fish.enable = true;
  security.sudo.wheelNeedsPassword = false;   # bring-up convenience: I drive this machine over SSH with a key

  services.displayManager.autoLogin = { enable = true; user = vars.username; };
  services.displayManager.defaultSession = "hyprland";   # Plasma stays installed as the fallback session
  programs.hyprland.enable = true;
  fonts.packages = [ pkgs.nerd-fonts.fira-code ];

  networking.firewall.enable = false;   # bring-up
  documentation.nixos.enable = false;
  environment.systemPackages = with pkgs.kdePackages; [ konsole dolphin ];
}
