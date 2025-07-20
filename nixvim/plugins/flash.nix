{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      flash-nvim
    ];

    extraConfigLua = builtins.readFile ./flash.lua;
  };
}
