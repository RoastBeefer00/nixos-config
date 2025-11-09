{ pkgs, niri, ... }:
{
  imports = [
    ./hm_modules/common.nix
    # ./nixvim
    ./hm_modules/btop.nix
    ./hm_modules/hyprland.nix
    ./hm_modules/mako.nix
    ./hm_modules/niri.nix
    ./hm_modules/fish.nix
    ./hm_modules/ghostty.nix
    ./hm_modules/rofi.nix
    ./hm_modules/tmux.nix
    # ./hm_modules/nixvim.nix
    ./hm_modules/waybar.nix
    ./hm_modules/wezterm.nix
    # ./hm_modules/zsh.nix
  ];

  home.packages = with pkgs; [
    alacritty
    bat
    btop
    cowsay
    docker
    eza
    fastfetch
    ghostty
    htop
    hyprshot
    lazygit
    mako
    opencode
    ripgrep
    runelite
    rofi
    rofi-power-menu
    skim
    swaybg
    protonup-qt
    wezterm
    # pkgs.wl-clipboard
    # pkgs.yazi
    # pkgs.zsh-powerlevel10k
  ];

  home.stateVersion = "25.11";
}
