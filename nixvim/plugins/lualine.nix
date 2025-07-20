{ programs, ... }:
{
  programs.nixvim = {
    plugins.lualine = {
      enable = true;
      luaConfig.content = builtins.readFile ./lualine.lua;
    };
  };
}
