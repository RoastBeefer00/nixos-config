{ config, pkgs, ... }:

{
  # Configure Ghostty terminal
  programs.ghostty = {
    enable = true;
    
    settings = {
      theme = "tokyonight";
      window-decoration = true;
      window-padding-x = 4;
      window-padding-y = 4;
      font-family = "JetBrainsMono Nerd Font Propo";
      font-size = 14;
      confirm-close-surface = false;
    };
  };
  
  # Install the font if not already available system-wide
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    ghostty
    # Install JetBrains Mono Nerd Font
    # (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    nerd-fonts.jetbrains-mono
  ];
}
