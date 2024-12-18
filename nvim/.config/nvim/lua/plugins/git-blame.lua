return {
	{
		-- git blame plugin
		"f-person/git-blame.nvim",
		-- dir = "~/git-blame.nvim",
		-- load the plugin at startup
		event = "VeryLazy",
		-- Because of the keys part, you will be lazy loading this plugin.
		-- The plugin wil only load once one of the keys is used.
		-- If you want to load the plugin at startup, add something like event = "VeryLazy",
		-- or lazy = false. One of both options will work.
		opts = {
			enabled = true,
			message_template = " <summary> • <date> • <author> • <<sha>>",
			date_format = "%Y-%m-%d %H:%M:%S",
			virtual_text_column = 1,
		},
	},
	{
		"folke/which-key.nvim",
		-- default show git blame when open git files
		opts = {
			spec = {
				{ "", group = "git blame+" },
			},
		},
	},
}
