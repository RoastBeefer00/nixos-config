{ pkgs, config, ... }:
{
  programs.aerospace = {
    enable = true;
    extraConfig = builtins.readFile ../aerospace/aerospace.toml;
  };
}
