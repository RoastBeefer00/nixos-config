{
  config,
  pkgs,
  isNixOS,
  isDarwin,
  ...
}:

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
  home.packages = with pkgs; [
    # Add other cross-platform packages
    bat
    claude-code
    devenv

    fastfetch
    fd
    flutter_rust_bridge_codegen
    fzf
    git
    ripgrep
    skim
  ];

  home.file = {
    ".local/scripts/tmux-sessionizer" = {
      source = ../scripts/tmux-sessionizer;
      executable = true;
    };
  };

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
