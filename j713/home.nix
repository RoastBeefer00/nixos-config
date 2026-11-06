{ pkgs, lib, ... }:
{
  # Shell, editor tooling and CLI apps shared with the desktop. Hyprland and Waybar join once the GPU works.
  imports = [ ../hm_modules/common.nix ];

  # common.nix's rtk hook expects this directory; a fresh home does not have it yet.
  home.activation.claudeDir = lib.hm.dag.entryBefore [ "rtkInit" ] ''
    run mkdir -p "$HOME/.claude"
  '';

  # This machine's rebuild. path: because the Air's copy is not a git checkout (and j713/ is not committed yet).
  programs.fish.shellAbbrs.rebuild = lib.mkForce "sudo nixos-rebuild switch --flake path:$HOME/projects/nixos-config#j713";

  home.packages = with pkgs; [ btop eza htop lazygit ];

  home.username = (import ../vars.nix).username;
  home.homeDirectory = (import ../vars.nix).linuxHome;
  home.stateVersion = "26.05";
}
