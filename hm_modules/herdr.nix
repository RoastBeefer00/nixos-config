{ pkgs, ... }:
let
  herdr = pkgs.callPackage ./herdr-pkg.nix { };
in
{
  home.packages = with pkgs; [
    herdr
    jq
    findutils
    # skim (sk) already in common.nix
  ];

  home.file = {
    ".config/herdr/config.toml".source = ../herdr/config.toml;
    ".config/herdr/plugins/vim-herdr-navigation".source = ../herdr/plugins/vim-herdr-navigation;
    ".local/scripts/herdr-sessionizer" = {
      source = ../scripts/herdr-sessionizer;
      executable = true;
    };
  };
}
