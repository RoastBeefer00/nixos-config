{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    niri.url = "github:sodiboo/niri-flake";
    home-manager.url = "github:nix-community/home-manager";
    waybar-weather.url = "github:RoastBeefer00/waybar-weather-rust";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # nixvim = {
    #   url = "github:nix-community/nixvim";
    #   # If using a stable channel you can use `url = "github:nix-community/nixvim/nixos-<version>"`
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    tree-sitter-rstml.url = "github:rayliwell/tree-sitter-rstml/flake";
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      niri,
      # nixvim,
      tree-sitter-rstml,
      waybar-weather,
      ...
    }:
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { 
            inherit tree-sitter-rstml; 
            inherit waybar-weather;
            inherit niri;
          };
          modules = [
            # nixvim.nixosModules.nixvim
            # ./nixvim
            ./configuration.nix
            ./hardware-configuration.nix
            {
                nixpkgs.overlays = [ niri.overlays.niri ];
            }
            niri.nixosModules.niri
            {
              programs.niri.package = nixpkgs.legacyPackages.x86_64-linux.niri;
            }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.roastbeefer = import ./home.nix;
              home-manager.extraSpecialArgs = {
                inherit niri;
              };

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix-
            }
          ];
        };
      };
    };
}
