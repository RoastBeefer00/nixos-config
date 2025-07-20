local flash = require("flash")
vim.keymap.set("n", "s", function()
	flash.jump()
end)
