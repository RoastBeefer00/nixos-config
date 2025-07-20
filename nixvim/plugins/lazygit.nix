{ ... }:
{
  programs.nixvim = {
    plugins.lazygit = {
      enable = true;
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>gg";
        action = "<cmd>LazyGit<cr>";
        options = {
          desc = "LazyGit";
        };
    }
    ];
  };
}
