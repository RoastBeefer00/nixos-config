# home/hm_modules/moondeck-buddy.nix
#
# Home-manager module for MoonDeck Buddy.
# Builds from source via fetchFromGitHub.
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.moondeckBuddy;

  # ── Package ────────────────────────────────────────────────────────────────
  defaultPackage = pkgs.stdenv.mkDerivation {
    pname = "moondeck-buddy";
    version = cfg.package.version;

    src = pkgs.fetchFromGitHub {
      owner = "FrogTheFrog";
      repo = "moondeck-buddy";
      rev = "v${cfg.package.version}";
      hash = cfg.package.hash;
      fetchSubmodules = true;
    };

    nativeBuildInputs = with pkgs; [
      cmake
      ninja
      pkg-config
      qt6.wrapQtAppsHook
    ];

    buildInputs = with pkgs; [
      qt6.qtbase
      qt6.qtwebsockets
      qt6.qthttpserver
      openssl
      procps # provides libproc2
    ];

    cmakeFlags = [ "-DCMAKE_BUILD_TYPE=Release" ];

    meta = with lib; {
      description = "Server-side companion for the MoonDeck plugin on SteamDeck";
      homepage = "https://github.com/FrogTheFrog/moondeck-buddy";
      license = licenses.lgpl3Only;
      platforms = platforms.linux;
      mainProgram = "MoonDeckBuddy";
    };
  };

  resolvedPackage = if cfg.package.derivation != null then cfg.package.derivation else defaultPackage;

  # ── Settings JSON ──────────────────────────────────────────────────────────
  # Written by ExecStartPre only when the file doesn't already exist.
  # MoonDeckBuddy owns settings.json at runtime (writes paired clients, certs,
  # etc. back into it), so we must NOT use xdg.configFile which produces a
  # read-only nix store symlink — the app fatally aborts if it can't write.
  settingsJson = builtins.toJSON {
    port = cfg.settings.port;
    logRules = cfg.settings.logRules;
    sunshineAppsFilepath = cfg.settings.sunshineAppsFilepath;
    preferHibernation = cfg.settings.preferHibernation;
    sslProtocol = cfg.settings.sslProtocol;
    closeSteamBeforeSleep = cfg.settings.closeSteamBeforeSleep;
    macAddressOverride = cfg.settings.macAddressOverride;
    steamExecOverride = cfg.settings.steamExecOverride;
    envCaptureRegex = cfg.settings.envCaptureRegex;
  };

  # Shell script that seeds settings.json on first run (idempotent).
  initSettings = pkgs.writeShellScript "moondeckbuddy-init-settings" ''
    cfg_dir="$HOME/.config/moondeckbuddy"
    cfg_file="$cfg_dir/settings.json"
    mkdir -p "$cfg_dir"
    if [ ! -f "$cfg_file" ]; then
      printf '%s' ${lib.escapeShellArg settingsJson} > "$cfg_file"
    fi
  '';

in
{
  # ── Options ────────────────────────────────────────────────────────────────
  options.services.moondeckBuddy = {
    enable = lib.mkEnableOption "MoonDeck Buddy server-side companion";

    package = {
      version = lib.mkOption {
        type = lib.types.str;
        default = "1.9.2";
        description = "MoonDeck Buddy release tag to build from source.";
      };

      hash = lib.mkOption {
        type = lib.types.str;
        default = lib.fakeHash;
        description = ''
          Hash of the source tarball. Get with:
            nix-prefetch-url --unpack \
              https://github.com/FrogTheFrog/moondeck-buddy/archive/refs/tags/v<VERSION>.tar.gz
        '';
      };

      derivation = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "Override with a custom derivation. version and hash are ignored when set.";
      };
    };

    guiSession = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start in GUI mode when a graphical session is available.";
    };

    settings = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 59999;
      };
      logRules = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''Set "buddy.*.debug=true" to enable debug logs.'';
      };
      sunshineAppsFilepath = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Leave empty to use ~/.config/sunshine/apps.json.";
      };
      preferHibernation = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      sslProtocol = lib.mkOption {
        type = lib.types.enum [
          "SecureProtocols"
          "TlsV1_2"
          "TlsV1_2OrLater"
          "TlsV1_3"
          "TlsV1_3OrLater"
        ];
        default = "SecureProtocols";
      };
      closeSteamBeforeSleep = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      macAddressOverride = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      steamExecOverride = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      envCaptureRegex = lib.mkOption {
        type = lib.types.str;
        default = "^(?:SUNSHINE|APOLLO).*";
      };
    };
  };

  # ── Config ─────────────────────────────────────────────────────────────────
  config = lib.mkIf cfg.enable {

    # ── MoonDeckStream wrapper ────────────────────────────────────────────────
    home.file.".local/bin/MoonDeckStream" = {
      executable = true;
      text = ''
        #!/bin/sh
        exec ${resolvedPackage}/bin/MoonDeckStream "$@"
      '';
    };

    # ── Systemd user services ─────────────────────────────────────────────────

    systemd.user.services.moondeckbuddy = {
      Unit = {
        Description = "MoonDeck Buddy (headless)";
        After = [ "network.target" ];
        Conflicts = lib.mkIf cfg.guiSession [ "moondeckbuddy-gui-session.service" ];
      };

      Service = {
        Type = "simple";
        # Seed settings.json only when it doesn't exist yet.
        ExecStartPre = "${initSettings}";
        ExecStart = "${resolvedPackage}/bin/MoonDeckBuddy";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = [
          "NO_GUI=1"
          "XDG_CONFIG_HOME=%h/.config"
          "XDG_DATA_HOME=%h/.local/share"
          "PATH=/run/current-system/sw/bin:/home/roastbeefer/.nix-profile/bin"
        ];
      };

      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.services.moondeckbuddy-gui-session = lib.mkIf cfg.guiSession {
      Unit = {
        Description = "MoonDeck Buddy (GUI session)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        Conflicts = [ "moondeckbuddy.service" ];
      };

      Service = {
        Type = "simple";
        ExecStartPre = "${initSettings}";
        ExecStart = "${resolvedPackage}/bin/MoonDeckBuddy";
        ExecStop = "${pkgs.systemd}/bin/systemctl --user start moondeckbuddy.service";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = [
          "XDG_CONFIG_HOME=%h/.config"
          "XDG_DATA_HOME=%h/.local/share"
        ];
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };

    # systemd.user.services.steam = {
    #   Unit = {
    #     Description = "Steam (background)";
    #     After = [ "network.target" ];
    #   };
    #
    #   Service = {
    #     Type = "forking";
    #     ExecStart = "${pkgs.steam}/bin/steam -silent";
    #     Restart = "on-failure";
    #     RestartSec = "10s";
    #     Environment = [
    #       "HOME=%h"
    #       "DISPLAY=:0"
    #       "SDL_VIDEODRIVER=x11"
    #       "GDK_BACKEND=x11"
    #     ];
    #   };
    #
    #   Install.WantedBy = [ "default.target" ];
    # };

    home.packages = [ resolvedPackage ];
  };
}
