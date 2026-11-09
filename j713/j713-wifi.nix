# Wi-Fi + SSH on the J713. NetworkManager with iwd; its wpa_supplicant backend failed to associate on this driver.
{ config, lib, pkgs, ... }:
let cfg = config.j713.wifi; in
{
  options.j713.wifi.sshAuthorizedKeys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Public keys allowed to ssh in.";
  };

  config = {
    networking.networkmanager.enable = lib.mkForce true;
    networking.networkmanager.wifi.backend = "iwd";
    networking.useDHCP = lib.mkForce false;

    # The driver can bind before the firmware path is in place and then gives up for good: reload it once if so.
    # udev's automatic load at boot always hit that (firmware -2) and cost the full 15 s wait below, so only this service loads it.
    boot.blacklistedKernelModules = [ "brcmfmac" ];
    systemd.services.j713-wifi-driver = {
      description = "Make sure the J713 Wi-Fi driver bound";
      wantedBy = [ "multi-user.target" ];
      before = [ "iwd.service" "NetworkManager.service" ];
      after = [ "aurora-vendor-firmware.service" ];
      path = [ pkgs.coreutils pkgs.kmod ];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      script = ''
        modprobe brcmfmac || true
        for i in $(seq 1 15); do
          for n in /sys/class/net/*; do [ -d "$n/wireless" ] && exit 0; done
          sleep 1
        done
        modprobe -r brcmfmac_wcc brcmfmac || true
        modprobe brcmfmac || true
      '';
    };

    # Bluetooth firmware comes from macOS and isn't in the ESP's bundle. Add it to the live firmware tree,
    # and retry the driver in case it already gave up. The Wi-Fi function has to bind first.
    systemd.services.j713-bluetooth-firmware = {
      description = "Install the J713 Bluetooth firmware";
      wantedBy = [ "multi-user.target" ];
      after = [ "aurora-vendor-firmware.service" "j713-wifi-driver.service" ];
      path = [ pkgs.coreutils ];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      script = ''
        cp /var/lib/j713/firmware/brcm/brcmbt* /run/aurora-firmware/vendorfw/brcm/
        for i in $(seq 1 30); do
          [ -e /sys/class/bluetooth/hci0 ] && exit 0
          [ -e /sys/bus/pci/drivers/brcmfmac/0000:01:00.0 ] && [ ! -e /sys/bus/pci/devices/0000:01:00.1/driver ] &&
            { echo 0000:01:00.1 > /sys/bus/pci/drivers/hci_bcm4377/bind || true; }
          sleep 1
        done
      '';
    };

    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = { PasswordAuthentication = false; KbdInteractiveAuthentication = false; PermitRootLogin = "no"; };
    };
    users.users.${(import ../vars.nix).username} = {
      extraGroups = [ "networkmanager" ];
      openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
    };
    environment.systemPackages = [ pkgs.iw pkgs.wpa_supplicant ];
  };
}
