{
  config,
  pkgs,
  rmatrix,
  ...
}:

let
  vars = import ./vars.nix;
in
{
  imports = [ ./nix-common.nix ];

  # System packages (available to all users)
  environment.systemPackages = with pkgs; [
    cocoapods
    discord
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
      orientation = "left";
      show-recents = false;
      tilesize = 24;
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
      "com.apple.swipescrolldirection" = false; # Disable natural scrolling
    };

    screencapture.location = "~/Pictures/screenshots";
  };

  nix.gc.interval.Day = 7;
  nix.optimise.interval = [{ Day = 7; }];
  nix.settings.trusted-users = [ "@admin" ];

  system.primaryUser = vars.username;
  users.users.${vars.username} = {
    name = vars.username;
    home = vars.darwinHome;
    shell = pkgs.fish;
  };

  # Used for backwards compatibility
  system.stateVersion = 5;
}
