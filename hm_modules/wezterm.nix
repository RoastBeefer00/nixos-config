{ pkgs, ... }:
{
  home.file = {
    ".local/scripts/wez-sess" = {
      source = ../wez-sess;
      executable = true;
    };
  };

  programs.wezterm = {
    enable = true;
    extraConfig = builtins.readFile ../wezterm/wezterm.lua;
  };
}
