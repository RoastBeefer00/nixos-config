{ pkgs, ... }:
{
  programs.btop = {
    enable = true;
    extraConfig = builtins.readFile ../btop/btop.conf;
    # color_theme handled by Stylix
  };
}
