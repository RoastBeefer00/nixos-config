{
  config,
  pkgs,
  lib,
  isNixOS,
  isDarwin,
  ...
}:

let
  rtk = pkgs.callPackage ./rtk.nix { };
in
{
  imports = [
    ./btop.nix
    ./fish.nix
    ./ghostty.nix
    ./tmux.nix
    # ./zsh.nix
    # Add other cross-platform modules here
  ];

  # Shared packages that work on both systems
  home.packages =
    (with pkgs; [
      # Add other cross-platform packages
      bat
      claude-code
      devenv
      fastfetch
      fd
      flutter_rust_bridge_codegen
      fzf
      gh
      git
      just
      ripgrep
      skim
    ])
    ++ [ rtk ];

  home.file = {
    ".local/scripts/tmux-sessionizer" = {
      source = ../scripts/tmux-sessionizer;
      executable = true;
    };
  };

  # Install the rtk Claude Code hook once. Idempotent: skips when the hook is
  # already registered in ~/.claude/settings.json, so rebuilds are no-ops.
  home.activation.rtkInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    if [ ! -f "$settings" ] || ! ${pkgs.gnugrep}/bin/grep -q '"rtk hook claude"' "$settings"; then
      run ${rtk}/bin/rtk init -g --auto-patch
    fi
  '';

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      global = {
        hide_env_diff = true;
      };
    };
  };

  # Shared git config, etc.
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Jake Jasmin";
        email = "roastbeefer000@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };
}
