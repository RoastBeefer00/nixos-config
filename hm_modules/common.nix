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
  vars = import ../vars.nix;

  # Plugin hooks (e.g. ponytail) shell out to node; expose it only to claude.
  # Suffix so a project's own node (devenv) still wins.
  claude-code = pkgs.symlinkJoin {
    name = "claude-code-wrapped";
    paths = [ pkgs.claude-code ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude --suffix PATH : ${lib.makeBinPath [ pkgs.nodejs ]}
    '';
  };
in
{
  imports = [
    ./btop.nix
    ./fish.nix
    ./ghostty.nix
    ./herdr.nix
    ./tmux.nix
    # Add other cross-platform modules here
  ];

  # Shared packages that work on both systems
  home.packages =
    (with pkgs; [
      # Add other cross-platform packages
      bat
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
    ++ [
      claude-code
      rtk
    ];

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

  # Tell Claude Code to get tools from Nix. Appended, not linked, because rtk also edits this file.
  home.activation.claudeNixRule = lib.hm.dag.entryAfter [ "rtkInit" ] ''
    rules="$HOME/.claude/CLAUDE.md"
    if [ ! -f "$rules" ] || ! ${pkgs.gnugrep}/bin/grep -qxF '# Packages' "$rules"; then
      run mkdir -p "$HOME/.claude"
      run ${pkgs.bash}/bin/bash -c 'printf "%s\n" "$1" >> "$2"' _ ${lib.escapeShellArg ''

        # Packages

        If `nix` is on the system and a task needs a tool that isn't installed, get it from Nix instead of building it, downloading a binary, or using another package manager. Use `nix shell nixpkgs#<pkg>` for one-off use, including versioned attributes such as `wasm-bindgen-cli_0_2_118`. If the project has a devenv or flake, use its environment first, and add the tool there when the project needs it long term. Only fall back to other sources when nixpkgs doesn't have what's needed, and say so.''} "$rules"
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
        name = vars.fullName;
        email = vars.email;
      };
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };
}
