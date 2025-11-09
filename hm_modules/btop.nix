{ pkgs, config, ... }:
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "${config.xdg.configHome}/btop/themes/catppuccin_mocha.theme";
    };
    extraConfig = builtins.readFile ../btop/btop.conf;
  };
  
  xdg.configFile."btop/themes/catppuccin_mocha.theme".source = ../btop/themes/catppuccin_mocha.theme;
}
