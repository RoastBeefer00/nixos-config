# Self-contained apps come from the shared nixpkgs when it has a newer version than Aurora's.
# Everything else stays on Aurora's nixpkgs, which its hardware packages are built and cached against.
{ lib, pkgs, sharedNixpkgs, ... }:
let
  shared = import sharedNixpkgs { inherit (pkgs.stdenv.hostPlatform) system; config.allowUnfree = true; };
  # Only apps that don't touch the graphics or audio stack.
  fresh = [ "claude-code" ];
in
{
  nixpkgs.overlays = [ (final: prev: lib.genAttrs fresh (name:
    if lib.versionOlder prev.${name}.version shared.${name}.version then shared.${name} else prev.${name})) ];
}
