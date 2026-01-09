return {
	"3rd/diagram.nvim",
	dependencies = { "3rd/image.nvim" },
	keys = {
		{
			"<leader>md", -- Mermaid Diagram
			function()
				require("diagram").show_diagram_hover()
			end,
			mode = "n",
			ft = { "markdown" },
			desc = "Show diagram",
		},
	},
	opts = {
		events = {
			render_buffer = {}, -- 자동 렌더링 비활성화
			clear_buffer = { "BufLeave" },
		},
		renderer_options = {
			mermaid = {
				background = "transparent",
				theme = "dark",
				scale = 2,
			},
			plantuml = {
				charset = nil,
				cli_args = nil, -- nil | { "-Djava.awt.headless=true" } | ...
			},
			d2 = {
				theme_id = nil,
				dark_theme_id = nil,
				scale = nil,
				layout = nil,
				sketch = nil,
				cli_args = nil, -- nil | { "--pad", "0" } | ...
			},
			gnuplot = {
				size = nil, -- nil | "800,600" | ...
				font = nil, -- nil | "Arial,12" | ...
				theme = nil, -- nil | "light" | "dark" | custom theme string
				cli_args = nil, -- nil | { "-p" } | { "-c", "config.plt" } | ...
			},
		},
	},
}
