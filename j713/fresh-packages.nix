# Self-contained apps come from the shared nixpkgs when it has a newer version than Aurora's.
# Everything else stays on Aurora's nixpkgs, which its hardware packages are built and cached against.
{ lib, pkgs, sharedNixpkgs, ... }:
let
  shared = import sharedNixpkgs { inherit (pkgs.stdenv.hostPlatform) system; config.allowUnfree = true; };
  # Command-line and terminal apps only: nothing else in the system may depend on them (or it rebuilds without
  # Aurora's cache), and none may touch the graphics, audio or other hardware. So not git, jq, Chrome or PipeWire tools.
  # Also not just (the cursor theme builds with it), fzf or fd (zoxide, cliphist and yazi's wrapper use them).
  fresh = [
    "atuin" "bat" "bluetui" "btop" "claude-code" "cliphist" "delta" "devenv" "direnv" "dust" "eza"
    "flutter_rust_bridge_codegen" "gh" "htop" "lazygit" "nh" "ripgrep" "skim" "starship"
    "tmux" "wifitui" "yazi" "zoxide"
  ];
in
{
  nixpkgs.overlays = [ (final: prev: lib.genAttrs fresh (name:
    if lib.versionOlder prev.${name}.version shared.${name}.version then shared.${name} else prev.${name})) ];
}
