# nixos/game-streaming.nix
#
# System-level NixOS module for game streaming.
# Handles: Sunshine service, kernel modules, uinput group, firewall ports,
# and avahi for network discovery.
#
# Import this in your configuration.nix:
#   imports = [ ./game-streaming.nix ];
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.gaming.streaming;
in
{
  options.gaming.streaming = {
    enable = lib.mkEnableOption "game streaming host (Sunshine + MoonDeck Buddy)";

    user = lib.mkOption {
      type = lib.types.str;
      description = "Username that will run Sunshine and MoonDeckBuddy.";
      example = "jake";
    };

    sunshine = {
      # capSysAdmin is required for virtual display/resolution switching on Wayland.
      # Safe to leave true on Wayland; harmless on Xorg.
      capSysAdmin = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Grant Sunshine the CAP_SYS_ADMIN capability. Required on Wayland for
          virtual display creation. Can be set to false if using Xorg.
        '';
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.sunshine;
        defaultText = lib.literalExpression "pkgs.sunshine";
        description = "The Sunshine package to use.";
      };

      # Expose the upstream settings passthrough for convenience.
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = ''
          Sunshine configuration settings. Passed directly to services.sunshine.settings.
          See https://docs.lizardbyte.dev/projects/sunshine/latest/about/advanced_config.html
        '';
        example = lib.literalExpression ''
          {
            encoder = "nvenc";   # or "vaapi", "software"
            fps     = "[30,60]";
            resolutions = "[1280x800,1920x1080]";
          }
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # ── Sunshine ─────────────────────────────────────────────────────────────
    services.sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = true;
      capSysAdmin = cfg.sunshine.capSysAdmin;
      package = cfg.sunshine.package;
      settings = cfg.sunshine.settings;

      # MoonDeckStream is registered as a Sunshine app so the Deck can launch
      # it. The command points at the wrapper script that home-manager writes.
      # "Continue streaming after app closes" must be false (auto-detach true).
      applications = {
        env = {
          PATH = "$(PATH):$(HOME)/.local/bin";
        };
        apps = [
          {
            name = "MoonDeckStream";
            # home-manager puts the wrapper at ~/.local/bin/MoonDeckStream
            cmd = "${pkgs.gamescope}/bin/gamescope -W 1280 -H 800 -f -- /home/roastbeefer/.local/bin/MoonDeckStream";
            auto-detach = "false";
            # No prep-cmd here — MoonDeckBuddy handles Steam state itself.
            # prep-cmd = [
            #   {
            #     do = "kscreen-doctor output.DP-2.mode.1280x800@60";
            #     undo = "kscreen-doctor output.DP-2.mode.3440x1440@144";
            #   }
            # ];
            prep-cmd = [
              {
                do = "${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor output.DP-2.mode.1280x800@60";
                undo = "${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor output.DP-2.mode.3440x1440@144";
                elevated = false;
              }
            ];
          }
        ];
      };
    };

    # ── Kernel / input ───────────────────────────────────────────────────────
    # uinput lets Sunshine inject keyboard/mouse/gamepad events from the client.
    hardware.uinput.enable = true;
    users.users.${cfg.user}.extraGroups = [
      "input"
      "uinput"
      "video"
    ];

    # ── Avahi (mDNS discovery) ───────────────────────────────────────────────
    # Lets Moonlight auto-discover this host on the local network.
    services.avahi = {
      enable = true;
      publish.enable = true;
      publish.userServices = true;
    };

    # ── MoonDeckBuddy firewall ───────────────────────────────────────────────
    # Port 59999 is the default MoonDeckBuddy communication port.
    networking.firewall.allowedTCPPorts = [ 59999 ];
  };
}
