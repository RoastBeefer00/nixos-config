{
  description = "NixOS and macOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    niri.url = "github:sodiboo/niri-flake";
    home-manager.url = "github:nix-community/home-manager";
    waybar-weather.url = "github:RoastBeefer00/waybar-weather-rust";
    rmatrix.url = "github:RoastBeefer00/rmatrix";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    tree-sitter-rstml.url = "github:rayliwell/tree-sitter-rstml/flake";
    aurora.url = "github:aurora-silicon/nixos-aurora";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      home-manager,
      niri,
      tree-sitter-rstml,
      waybar-weather,
      rmatrix,
      aurora,
      ...
    }:
    let
      vars = import ./vars.nix;
    in
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
              home-manager.users.${vars.username} = import ./home.nix;
              home-manager.sharedModules = [ inputs.nix-index-database.homeModules.nix-index ];
              home-manager.extraSpecialArgs = {
                inherit niri;
                isNixOS = true;
                isDarwin = false;
              };
            }
          ];
        };

        # M4 MacBook Air. Kernel and boot chain live on the ESP (aura + U-Boot + aurora-silicon/linux), not here.
        j713 = aurora.inputs.nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit tree-sitter-rstml;
            inherit rmatrix;
          };
          modules = [
            aurora.inputs.apple-silicon.nixosModules.default
            aurora.nixosModules.default
            aurora.nixosModules.installed
            { nixpkgs.overlays = [ aurora.inputs.apple-silicon.overlays.default aurora.overlays.default ]; }
            ./j713/configuration.nix
            ./j713/ssh-key.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.${vars.username} = import ./j713/home.nix;
              home-manager.sharedModules = [ inputs.nix-index-database.homeModules.nix-index ];
              home-manager.extraSpecialArgs = {
                inherit tree-sitter-rstml;
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
              home-manager.users.${vars.username} = import ./home-darwin.nix;
              home-manager.sharedModules = [ inputs.nix-index-database.homeModules.nix-index ];
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
