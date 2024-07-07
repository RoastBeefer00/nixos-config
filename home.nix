{ pkgs, ... }:
{

                imports = [
                    # ./nixvim
                    ./hm_modules/btop.nix
                        ./hm_modules/hyprland.nix
                        ./hm_modules/mako.nix
                        ./hm_modules/rofi.nix
                        ./hm_modules/nixvim.nix
                        ./hm_modules/waybar.nix
                        ./hm_modules/wezterm.nix
                        ./hm_modules/zsh.nix
                ];

                home.packages = [
                    pkgs.alacritty
                        pkgs.bat
                        pkgs.btop
                        pkgs.cowsay
                        pkgs.docker
                        pkgs.eza
                        pkgs.htop
                        pkgs.hyprshot
                        pkgs.mako
                        pkgs.rofi-wayland
                        pkgs.skim
                        pkgs.swaybg
                        pkgs.thefuck
                        pkgs.protonup-qt
                        pkgs.wezterm
                        pkgs.wl-clipboard
                        pkgs.yazi
                        pkgs.zsh-powerlevel10k
                ];

                home.stateVersion = "24.05";
}
