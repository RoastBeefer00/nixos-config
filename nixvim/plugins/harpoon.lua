local harpoon = require("harpoon")

-- REQUIRED
harpoon:setup()
-- REQUIRED

vim.keymap.set("n", "<leader>a", function()
	harpoon:list():add()
end)
vim.keymap.set("n", "<leader>h", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end)

vim.keymap.set("n", "<C-A-S-h>", function()
	harpoon:list():select(1)
end)
vim.keymap.set("n", "<C-A-S-t>", function()
	harpoon:list():select(2)
end)
vim.keymap.set("n", "<C-A-S-s>", function()
	harpoon:list():select(3)
end)
vim.keymap.set("n", "<C-A-S-n>", function()
	harpoon:list():select(4)
end)
