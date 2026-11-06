# Temporary passwordless sudo for a working session over SSH. Off by default.
# `agent-sudo on` lasts 4 hours or until reboot, whichever comes first. `agent-sudo off` ends it now.
{ pkgs, ... }:
let
  rule = "/run/sudoers.d/agent";
  agentSudo = pkgs.writeShellScriptBin "agent-sudo" ''
    set -eu
    case "''${1:-}" in
      on)
        sudo install -d -m 755 /run/sudoers.d
        echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo install -m 440 /dev/stdin ${rule}
        sudo systemctl stop agent-sudo-off.timer 2>/dev/null || true
        sudo systemd-run --quiet --on-active=4h --unit=agent-sudo-off ${pkgs.coreutils}/bin/rm -f ${rule}
        echo "Passwordless sudo is on for 4 hours or until reboot."
        ;;
      off)
        sudo rm -f ${rule}
        sudo systemctl stop agent-sudo-off.timer 2>/dev/null || true
        echo "Passwordless sudo is off."
        ;;
      *)
        echo "usage: agent-sudo on|off" >&2
        exit 1
        ;;
    esac
  '';
in
{
  security.sudo.extraConfig = "@includedir /run/sudoers.d";
  environment.systemPackages = [ agentSudo ];
}
