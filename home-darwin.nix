{ config, pkgs, ... }:

{
  # home.username = "roastbeefer";
  # home.homeDirectory = "/Users/roastbeefer";
  home.stateVersion = "25.11"; # Match your home-manager version

  # Import shared config if desired
  # imports = [ ./home-common.nix ];
  imports = [
    ./hm_modules/common.nix
  ];

  # macOS-specific packages and configuration
  home.packages = with pkgs; [
    cowsay
    lolcat
  ];

  launchd.agents = {
    aerospace = {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.aerospace}/bin/aerospace"
        ];
        RunAtLoad = true;
        KeepAlive = true; # Restart if it crashes
        ProcessType = "Interactive"; # Important for window managers
      };
    };
    jankyborders = {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.jankyborders}/bin/borders"
          "active_color=0xffcba6f7"
          "inactive_color=0xff45475a"
          "width=5.0"
          "hidpi=on"
          "style=round"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Interactive";
      };
    };
  };

  programs.home-manager.enable = true;
}
