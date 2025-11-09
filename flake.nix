{
  description = "NixOS and macOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    niri.url = "github:sodiboo/niri-flake";
    home-manager.url = "github:nix-community/home-manager";
    waybar-weather.url = "github:RoastBeefer00/waybar-weather-rust";
    rmatrix.url = "github:RoastBeefer00/rmatrix";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-darwin";
    tree-sitter-rstml.url = "github:rayliwell/tree-sitter-rstml/flake";
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-darwin,
      nix-darwin,
      home-manager,
      niri,
      tree-sitter-rstml,
      waybar-weather,
      rmatrix,
      ...
    }:
    {
      # NixOS configuration
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit tree-sitter-rstml;
            inherit waybar-weather;
            inherit niri;
          };
          modules = [
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
                isNixOS = true;
                isDarwin = false;
              };
            }
          ];
        };
      };

      # macOS nix-darwin configuration
      darwinConfigurations = {
        "Jakes-MacBook-Air" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin"; # or x86_64-darwin
          specialArgs = {
            inherit rmatrix;
          };
          modules = [
            ./darwin-configuration.nix

            # Integrate home-manager
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.roastbeefer = import ./home-darwin.nix;
              home-manager.extraSpecialArgs = {
                inherit tree-sitter-rstml;
                isNixOS = false;
                isDarwin = true;
              };
            }
          ];
        };
      };
    };
}
