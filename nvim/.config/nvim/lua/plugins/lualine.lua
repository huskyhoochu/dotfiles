return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	opts = function()
		local lualine_require = require("lualine_require")
		lualine_require.require = require

		local opts = {
			options = {
				theme = "palenight",
				component_separators = { left = "|", right = "|" },
				section_separators = { left = " ", right = " " },
			},
		}

		return opts
	end,
}
