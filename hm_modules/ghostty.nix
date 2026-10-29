{ config, pkgs, isNixOS ? false, isDarwin ? false, ... }:

{
  # Configure Ghostty terminal
  programs.ghostty = {
    enable = true;
    package = if isNixOS then pkgs.ghostty else null;
    
    settings = {
      theme = "Catppuccin Mocha";
      window-decoration = true;
      window-padding-x = 4;
      window-padding-y = 4;
      font-family = "JetBrainsMono Nerd Font Propo";
      font-size = 20;
      confirm-close-surface = false;
      # Pastes containing newlines (e.g. text sent from a phone via RustDesk)
      # are otherwise rejected until a confirm dialog is clicked, which you
      # can't do remotely. Trade-off: no prompt before pasting multi-line text.
      clipboard-paste-protection = false;
    };
  };
  
  # Install the font if not already available system-wide
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # ghostty
    # Install JetBrains Mono Nerd Font
    # (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    nerd-fonts.jetbrains-mono
  ];
}
