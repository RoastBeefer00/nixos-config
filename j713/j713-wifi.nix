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

    services.openssh = {
      enable = true;
      settings = { PasswordAuthentication = false; KbdInteractiveAuthentication = false; PermitRootLogin = "no"; };
    };
    users.users.jake.openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
    users.users.${(import ../vars.nix).username} = {
      extraGroups = [ "networkmanager" ];
      openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
    };
    environment.systemPackages = [ pkgs.iw pkgs.wpa_supplicant ];
  };
}
