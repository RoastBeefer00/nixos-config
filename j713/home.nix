{ pkgs, lib, ... }:
{
  # Shell, editor tooling and CLI apps shared with the desktop, plus Hyprland.
  imports = [ ../hm_modules/common.nix ./hyprland.nix ];

  # common.nix's rtk hook expects this directory; a fresh home does not have it yet.
  home.activation.claudeDir = lib.hm.dag.entryBefore [ "rtkInit" ] ''
    run mkdir -p "$HOME/.claude"
  '';

  # This machine's rebuild.
  programs.fish.shellAbbrs.rebuild = lib.mkForce "nh os switch $HOME/projects/nixos-config -H j713";

  home.packages = with pkgs; [ btop eza htop lazygit nh ];

  home.username = (import ../vars.nix).username;
  home.homeDirectory = (import ../vars.nix).linuxHome;
  home.stateVersion = "26.05";
}
