{ ... }:
{
  stylix.targets = {
    nixvim.enable = false; # managed manually in nixvim/default.nix
    tmux.enable = false;   # TPM plugins handle theming
    rofi.enable = false;   # custom layout, colors injected via lib.stylix.colors
    waybar.enable = false; # CSS generated inline with lib.stylix.colors
  };
}
