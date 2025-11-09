{ config, pkgs, rmatrix, ... }:

{
  # Allow unfree packages system-wide
  nixpkgs.config.allowUnfree = true;

  # System packages (available to all users)
  environment.systemPackages = with pkgs; [
    aerospace
    ghostty-bin
    git
    google-chrome
    jankyborders
    rmatrix.packages.${pkgs.system}.default
    vim
  ];
  
  programs.fish.enable = true;
  environment.shells = with pkgs; [
    fish
  ];

  # macOS system settings
  system.defaults = {
    dock = {
      autohide = true;
      orientation = "bottom";
      show-recents = false;
      tilesize = 48;
    };
    
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      ShowPathbar = true;
    };
    
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      "com.apple.swipescrolldirection" = false;  # Disable natural scrolling
    };
    
    screencapture.location = "~/Pictures/screenshots";
  };

  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [ "root" "@admin" "roastbeefer" ];
  };

  system.primaryUser = "roastbeefer";
  users.users.roastbeefer = {
    name = "roastbeefer";
    home = "/Users/roastbeefer";
    shell = pkgs.fish;
  };

  # Used for backwards compatibility
  system.stateVersion = 5;
}
