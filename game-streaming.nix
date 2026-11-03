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

  kscreen = "${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor";
  systemctl = "${pkgs.systemd}/bin/systemctl";

  # ── Headless streaming ──────────────────────────────────────────────────────
  # Each app streams a KWin virtual output ("Virtual-stream") sized to its
  # client, with DP-2 disabled for the session, so the physical monitor can be
  # off. Sunshine captures it via `capture = kwin` (virtual outputs aren't KMS
  # planes). The virtual output only exists while kwin-virtual-display runs,
  # so it lives in a templated user unit, headless-display@WIDTHxHEIGHT.
  kwinVirtualDisplay = pkgs.callPackage ./pkgs/kwin-virtual-display { };

  # Ensures DP-2 is back and the virtual output gone. A no-op when no virtual
  # output is up, so it's also safe as the Sunshine unit's ExecStopPost.
  headlessStop = pkgs.writeShellScript "headless-display-stop" ''
    if ${systemctl} --user list-units --state=active --no-legend 'headless-display@*' | grep -q .; then
      # Re-enable DP-2 before removing the virtual output so KWin is never
      # left without an enabled output.
      ${kscreen} output.DP-2.enable output.DP-2.mode.3440x1440@144 \
        output.DP-2.position.0,0 output.DP-2.priority.1 || true
      ${systemctl} --user stop 'headless-display@*.service'
    fi
  '';

  # usage: headless-display-start WIDTH HEIGHT REFRESH
  # Sunshine waits for a prep-cmd "do" to exit, hence the separate unit.
  headlessStart = pkgs.writeShellScript "headless-display-start" ''
    set -eu
    w=$1 h=$2 hz=$3
    outputs() { ${kscreen} -o | sed 's/\x1b\[[0-9;]*m//g'; }

    ${headlessStop}
    ${systemctl} --user start "headless-display@''${w}x''${h}.service"
    for _ in $(seq 1 50); do
      outputs | grep -q Virtual-stream && break
      sleep 0.1
    done
    if ! outputs | grep -q Virtual-stream; then
      echo "headless-display-start: virtual output never appeared" >&2
      exit 1
    fi

    # KWin's virtual outputs only offer 60Hz. kscreen-doctor exits 0 on an
    # unknown mode, so detect it from the message and add a custom mode (KWin
    # remembers custom modes, so this only happens the first time).
    if ${kscreen} "output.Virtual-stream.mode.''${w}x''${h}@''${hz}" 2>&1 | grep -q "not found"; then
      ${kscreen} "output.Virtual-stream.addCustomMode.$w.$h.$((hz * 1000)).full"
      ${kscreen} "output.Virtual-stream.mode.''${w}x''${h}@''${hz}"
    fi

    # Disable DP-2 so the desktop and anything launched land on the virtual
    # output. The virtual output sits right of DP-2 so that if DP-2 is
    # re-enabled mid-session (e.g. from Display Settings) they don't overlap
    # and confuse Plasma's panel placement.
    ${kscreen} output.Virtual-stream.position.3440,0 \
      output.Virtual-stream.priority.1 output.DP-2.disable
  '';

  # Sunshine only runs an app's undo when the app is quit, not when the client
  # just disconnects, so a forgotten desktop stream would keep DP-2 disabled
  # indefinitely. This follows Sunshine's log and, if no client reconnects
  # within the grace period while a virtual output is up, restarts Sunshine,
  # which ends the app and restores DP-2 via its ExecStopPost.
  idleGrace = 300;
  headlessIdleWatch = pkgs.writeShellScript "headless-idle-watch" ''
    deadline=
    while :; do
      timeout=3600
      if [ -n "$deadline" ]; then
        timeout=$((deadline - $(${pkgs.coreutils}/bin/date +%s)))
        if [ "$timeout" -le 0 ]; then
          deadline=
          if ${systemctl} --user list-units --state=active --no-legend 'headless-display@*' | grep -q .; then
            echo "no client for ${toString idleGrace}s, ending stream session"
            ${systemctl} --user --no-block restart sunshine.service
          fi
          continue
        fi
      fi
      if IFS= read -r -t "$timeout" line; then
        case $line in
          *"CLIENT DISCONNECTED"*)
            deadline=$(($(${pkgs.coreutils}/bin/date +%s) + ${toString idleGrace})) ;;
          *"New streaming session started"*)
            deadline= ;;
        esac
      elif [ $? -le 128 ]; then
        exit 1 # journalctl exited; let systemd restart us
      fi
    done < <(${pkgs.systemd}/bin/journalctl --user -u sunshine.service -f -n 0 -o cat)
  '';

  # prep-cmd for an app streamed at WIDTHxHEIGHT@REFRESH. With headless off,
  # falls back to switching DP-2's own mode (needs the mode in the EDID).
  prepFor =
    {
      w,
      h,
      hz,
    }:
    if cfg.headless.enable then
      {
        do = "${headlessStart} ${toString w} ${toString h} ${toString hz}";
        undo = "${headlessStop}";
        elevated = false;
      }
    else
      {
        do = "${kscreen} output.DP-2.mode.${toString w}x${toString h}@${toString hz}";
        undo = "${kscreen} output.DP-2.mode.3440x1440@144";
        elevated = false;
      };
in
{
  options.gaming.streaming = {
    enable = lib.mkEnableOption "game streaming host (Sunshine + MoonDeck Buddy)";

    user = lib.mkOption {
      type = lib.types.str;
      description = "Username that will run Sunshine and MoonDeckBuddy.";
      example = "jake";
    };

    headless.enable = lib.mkEnableOption ''
      headless streaming: each app streams a KWin virtual display sized to its
      client, with the physical monitor (DP-2) disabled for the session. When
      false, apps instead switch DP-2's own resolution and Sunshine uses KMS
      capture'';

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

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # ── Sunshine ─────────────────────────────────────────────────────────
        services.sunshine = {
          enable = true;
          autoStart = true;
          openFirewall = true;
          capSysAdmin = cfg.sunshine.capSysAdmin;
          package = cfg.sunshine.package;
          # When the named output doesn't exist (no stream running), Sunshine
          # falls back to the first output, so startup is unaffected.
          settings =
            cfg.sunshine.settings
            // lib.optionalAttrs cfg.headless.enable {
              capture = "kwin";
              output_name = "Virtual-stream";
            };

          applications = {
            env = {
              PATH = "$(PATH):$(HOME)/.local/bin";
            };
            apps = [
              {
                # MoonDeckStream is registered as a Sunshine app so the Deck can
                # launch it. The command points at the wrapper script that
                # home-manager writes. MoonDeckBuddy handles Steam state itself.
                # 1280x800@90 matches the Steam Deck OLED.
                name = "MoonDeckStream";
                cmd = "${pkgs.gamescope}/bin/gamescope -W 1280 -H 800 -f -- /home/${cfg.user}/.local/bin/MoonDeckStream";
                auto-detach = "false";
                prep-cmd = [
                  (prepFor {
                    w = 1280;
                    h = 800;
                    hz = 90;
                  })
                ];
              }
              {
                # Desktop capture (no cmd) for the living room TV. 16:9 1440p
                # (fills the TV, upscaled to 4K) rather than native 4K to keep
                # encode load reasonable. Set the Moonlight client to 1440p.
                # Quit the app in Moonlight to restore the monitor.
                name = "TV";
                prep-cmd = [
                  (prepFor {
                    w = 2560;
                    h = 1440;
                    hz = 60;
                  })
                ];
              }
              {
                # Desktop capture for a Pixel 9 (2424x1080 @ 120Hz panel). A
                # virtual display can match it exactly; without headless, DP-2's
                # closest mode is 1920x1080@75 (letterboxed). Set the Moonlight
                # client to the matching resolution and frame rate.
                name = "Pixel 9";
                prep-cmd = [
                  (prepFor (
                    if cfg.headless.enable then
                      {
                        w = 2424;
                        h = 1080;
                        hz = 120;
                      }
                    else
                      {
                        w = 1920;
                        h = 1080;
                        hz = 75;
                      }
                  ))
                ];
              }
              {
                # Couch-friendly Steam launcher: boots straight into Big
                # Picture / gamepad UI, navigable with a controller over
                # Moonlight. cmd points at the SteamBigPicture wrapper
                # (home.nix) rather than invoking steam directly: that wrapper
                # picks `-bigpicture` vs steam://open on whether Steam is
                # already running (the URL form silently no-ops into desktop
                # mode on a cold start), then blocks until Steam actually
                # exits. auto-detach = false ties the stream to that block, so
                # quitting Steam is what reverts the display -- relying on
                # Moonlight-disconnect detection instead (auto-detach = true)
                # was observed to sometimes never fire the undo command on
                # longer sessions with a few reconnects.
                #
                # NOTE: for smooth UI, enable Steam > Settings > Interface >
                # "Enable GPU accelerated rendering in web views" (Linux forces
                # it off by default -> software-rendered, laggy Big Picture).
                #
                # If enabling that causes corruption on NVIDIA instead, swap the
                # cmd below for a gamescope-wrapped launch (like MoonDeckStream):
                #   cmd = "${pkgs.gamescope}/bin/gamescope -W 2560 -H 1440 -f -- ${pkgs.steam}/bin/steam -gamepadui";
                name = "Steam Big Picture";
                cmd = "/home/${cfg.user}/.local/bin/SteamBigPicture";
                auto-detach = "false";
                prep-cmd = [
                  (prepFor {
                    w = 2560;
                    h = 1440;
                    hz = 60;
                  })
                ];
              }
            ];
          };
        };

        # ── Kernel / input ───────────────────────────────────────────────────
        # uinput lets Sunshine inject keyboard/mouse/gamepad events from the client.
        hardware.uinput.enable = true;
        users.users.${cfg.user}.extraGroups = [
          "input"
          "uinput"
          "video"
        ];

        # ── Avahi (mDNS discovery) ───────────────────────────────────────────
        # Lets Moonlight auto-discover this host on the local network.
        services.avahi = {
          enable = true;
          publish.enable = true;
          publish.userServices = true;
        };

        # ── MoonDeckBuddy firewall ───────────────────────────────────────────
        # Port 59999 is the default MoonDeckBuddy communication port.
        networking.firewall.allowedTCPPorts = [ 59999 ];
      }

      (lib.mkIf cfg.headless.enable {
        # The package's .desktop file grants KWin's screencast protocol to the
        # binary, which is why it must be installed system-wide.
        environment.systemPackages = [ kwinVirtualDisplay ];

        systemd.user.services."headless-display@" = {
          description = "KWin virtual display %i for headless streaming";
          partOf = [ "graphical-session.target" ];
          serviceConfig.ExecStart = "${kwinVirtualDisplay}/bin/kwin-virtual-display --name stream --size %i";
        };

        # If Sunshine stops mid-session (crash, restart, rebuild), bring DP-2
        # back instead of leaving the desktop on a vanished virtual output.
        systemd.user.services.sunshine.serviceConfig.ExecStopPost = "${headlessStop}";

        systemd.user.services.headless-idle-watch = {
          description = "End abandoned headless streaming sessions";
          wantedBy = [ "sunshine.service" ];
          after = [ "sunshine.service" ];
          partOf = [ "sunshine.service" ];
          serviceConfig = {
            ExecStart = "${headlessIdleWatch}";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      })
    ]
  );
}
