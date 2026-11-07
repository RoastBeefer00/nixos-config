# Checks Aurora's update channel every 6 hours and notifies when there's something new. Nothing updates by itself.
{ lib, pkgs, ... }:
let
  check = pkgs.writeShellApplication {
    name = "aurora-update-check";
    runtimeInputs = with pkgs; [ coreutils curl gnused hyprland jq libnotify ];
    text = builtins.readFile ./aurora-update-check.sh;
  };
  update = pkgs.writeShellApplication {
    name = "j713-update";
    runtimeInputs = with pkgs; [ curl git jq ];
    text = builtins.readFile ./j713-update.sh;
  };
in
{
  home.packages = [ check update ];

  systemd.user.services.aurora-update-check = {
    Unit.Description = "Check for Aurora updates";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe check;
    };
  };

  systemd.user.timers.aurora-update-check = {
    Unit.Description = "Check for Aurora updates every 6 hours";
    Timer = {
      OnCalendar = "00/6:00";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
