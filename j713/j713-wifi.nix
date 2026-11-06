# Wi-Fi + SSH on the J713. NetworkManager failed to associate on this driver; a plain supplicant + dhcpcd works.
{ config, lib, pkgs, ... }:
let cfg = config.j713.wifi; in
{
  options.j713.wifi.sshAuthorizedKeys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Public keys allowed to ssh in.";
  };

  config = {
    networking.networkmanager.enable = lib.mkForce false;
    networking.useDHCP = lib.mkForce true;

    # /var/lib/j713/wpa.conf is root-only and not in the store. brcmfmac and its firmware come from the kernel and ESP vendorfw.
    systemd.services.j713-wifi-link = {
      description = "J713 Wi-Fi link";
      wantedBy = [ "multi-user.target" ];
      before = [ "network.target" ];
      after = [ "aurora-vendor-firmware.service" ];
      unitConfig.ConditionPathExists = "/var/lib/j713/wpa.conf";
      path = [ pkgs.wpa_supplicant pkgs.coreutils pkgs.kmod ];
      preStart = ''
        # The driver can bind before the firmware path is in place and then gives up for good: reload it once if so.
        modprobe brcmfmac || true
        for i in $(seq 1 15); do
          for n in /sys/class/net/*; do [ -d "$n/wireless" ] && exit 0; done
          sleep 1
        done
        modprobe -r brcmfmac_wcc brcmfmac || true
        modprobe brcmfmac || true
        for i in $(seq 1 45); do
          for n in /sys/class/net/*; do [ -d "$n/wireless" ] && exit 0; done
          sleep 1
        done
        exit 1
      '';
      script = ''
        for n in /sys/class/net/*; do [ -d "$n/wireless" ] && IF=$(basename "$n"); done
        exec wpa_supplicant -i "$IF" -c /var/lib/j713/wpa.conf
      '';
      serviceConfig = { Restart = "always"; RestartSec = 5; };
    };

    services.openssh = {
      enable = true;
      settings = { PasswordAuthentication = false; KbdInteractiveAuthentication = false; PermitRootLogin = "no"; };
    };
    users.users.jake.openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
    users.users.${(import ../vars.nix).username}.openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
    environment.systemPackages = [ pkgs.iw pkgs.wpa_supplicant ];
  };
}
