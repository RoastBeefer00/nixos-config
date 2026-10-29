{ pkgs, niri, ... }:
{
  imports = [
    ./hm_modules/common.nix
    ./hm_modules/hyprland.nix
    ./hm_modules/mako.nix
    ./hm_modules/niri.nix
    ./hm_modules/rofi.nix
    ./hm_modules/jellyfin.nix
    ./hm_modules/waybar.nix
    ./hm_modules/wezterm.nix

    # Desktop-only modules
    ./hm_modules/moondeck-buddy.nix
  ];

  home.packages = with pkgs; [
    alacritty
    bat
    btop
    cowsay
    docker
    eza
    fastfetch
    gamescope
    ghostty
    htop
    hyprshot
    lazygit
    lsfg-vk-ui
    mako
    mangohud
    ripgrep
    runelite
    rofi
    rofi-power-menu
    skim
    swaybg
    protonup-qt
    vlc
    wezterm
    # pkgs.wl-clipboard
    # pkgs.yazi
    # pkgs.zsh-powerlevel10k
  ];

  services.moondeckBuddy = {
    enable = true;

    package = {
      version = "1.10.0";
      hash = "sha256-kuU6bE/I3oyLUq2qFvMOzrqu5DceqxDDwP34iTLpIgI=";
    };

    glazeVersion = "7.7.1";
    glazeHash = "sha256-CfN2mv1s+yv2HvRLBZhHUHBNfsgRzTT7USNYkkahh8M=";

    # GUI service follows graphical-session.target (recommended).
    guiSession = true;

    settings = {
      port = 59999; # must match firewall rule in game-streaming.nix
      preferHibernation = false;
      closeSteamBeforeSleep = true;
      sslProtocol = "SecureProtocols";
      logRules = ""; # set "buddy.*.debug=true" to troubleshoot
      envCaptureRegex = "^(?:SUNSHINE|APOLLO).*";

      # Leave empty — Buddy will find ~/.config/sunshine/apps.json automatically
      sunshineAppsFilepath = "";
      macAddressOverride = "";
      steamExecOverride = "/run/current-system/sw/bin/steam";
    };
  };

  # Wrapper for Sunshine's "Steam Big Picture" app (see game-streaming.nix).
  # `steam steam://open/bigpicture` only works if Steam is already running --
  # cold, it needs `-bigpicture` instead or it just opens the normal desktop
  # UI. Either way, invoking steam returns almost instantly (it just messages
  # the existing instance over IPC, or forks and detaches during its own
  # bootstrap), so it's useless as Sunshine's tracked cmd on its own: Sunshine
  # would see the process exit right away and immediately tear the stream
  # down. Instead, block here until every steam process is actually gone, so
  # Sunshine's normal (reliable) process-exit detection is what ends the
  # session and reverts the resolution -- not its client-disconnect
  # detection, which was observed to silently miss the revert on longer
  # sessions with a few reconnect blips.
  home.file.".local/bin/SteamBigPicture" = {
    executable = true;
    text = ''
      #!/bin/sh
      # TEMPORARY debug instrumentation while diagnosing an immediate-exit
      # bug -- remove once resolved.
      log() { echo "$(date +%T.%N) $*" >> /tmp/steam-bp-debug.log; }
      log "start pid=$$ ppid=$PPID PATH=$PATH HOME=$HOME"
      log "id: $(${pkgs.coreutils}/bin/id)"
      log "capsh: $(${pkgs.libcap}/bin/capsh --print 2>&1 | ${pkgs.coreutils}/bin/tr '\n' ';')"
      log "AT_SECURE/proc-status: $(grep -iE '^(NoNewPrivs|Seccomp|CapPrm|CapEff)' /proc/self/status | ${pkgs.coreutils}/bin/tr '\n' ';')"

      if ${pkgs.procps}/bin/pgrep -x steam >/dev/null 2>&1; then
        log "steam already running: $(${pkgs.procps}/bin/pgrep -x steam)"
        ${pkgs.steam}/bin/steam steam://open/bigpicture > /tmp/steam-bp-stdout.log 2> /tmp/steam-bp-stderr.log
        rc=$?
        log "steam steam://open/bigpicture returned $rc; stdout=$(${pkgs.coreutils}/bin/cat /tmp/steam-bp-stdout.log); stderr=$(${pkgs.coreutils}/bin/cat /tmp/steam-bp-stderr.log)"
      else
        log "steam not running, launching -bigpicture"
        ${pkgs.steam}/bin/steam -bigpicture > /tmp/steam-bp-stdout.log 2> /tmp/steam-bp-stderr.log
        rc=$?
        log "steam -bigpicture returned $rc; stdout=$(${pkgs.coreutils}/bin/cat /tmp/steam-bp-stdout.log); stderr=$(${pkgs.coreutils}/bin/cat /tmp/steam-bp-stderr.log)"

        # Cold start: steam's own launcher forks the real client and returns
        # almost instantly, well before that process registers -- racing
        # straight into the "wait for exit" loop below reads that gap as
        # "already closed" and reverts before Steam even opens. Wait up to a
        # minute for it to actually appear first.
        i=0
        while ! ${pkgs.procps}/bin/pgrep -x steam >/dev/null 2>&1; do
          i=$((i + 1))
          [ "$i" -ge 60 ] && break
          sleep 1
        done
        log "post-launch wait loop exited after i=$i, pgrep now: $(${pkgs.procps}/bin/pgrep -x steam)"
      fi

      log "entering exit-wait loop, pgrep now: $(${pkgs.procps}/bin/pgrep -x steam)"
      while ${pkgs.procps}/bin/pgrep -x steam >/dev/null 2>&1; do
        sleep 2
      done
      log "exit-wait loop done, script exiting"
    '';
  };

  # Wayland screen capture (OBS "Screen/Window Capture (PipeWire)", browser
  # screen share, etc.) goes through the xdg-desktop-portal ScreenCast backend.
  # Home-Manager's Hyprland module enables xdg.portal and exports
  # NIX_XDG_DESKTOP_PORTAL_DIR pointing at THIS profile's portals dir, which
  # overrides the system one for the whole graphical session. It only contained
  # hyprland.portal, so under KDE and niri the frontend loaded no ScreenCast
  # backend at all ("Requested kde.portal is unrecognized") and OBS showed no
  # capture sources. List every backend we actually use so the dir is complete:
  #   kde   -> ScreenCast on Plasma
  #   gnome -> ScreenCast on niri (niri implements the Mutter ScreenCast API)
  #   gtk   -> FileChooser / fallback
  # Routing per desktop already comes from each compositor's *-portals.conf.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      kdePackages.xdg-desktop-portal-kde
      xdg-desktop-portal-gnome
    ];
  };

  home.stateVersion = "25.11";
}
