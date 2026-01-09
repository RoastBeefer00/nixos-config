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
    bat
    direnv
    devenv
    fastfetch
    fd
    fzf
    git
    ripgrep
    skim
    # Add other cross-platform packages
  ];

  home.file = {
    ".local/scripts/tmux-sessionizer" = {
      source = ../scripts/tmux-sessionizer;
      executable = true;
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
