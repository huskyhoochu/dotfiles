return {
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = function(_, opts)
      local logo = [[      
 _______  __   __  _______  ______    ___   _______  __    _ 
|       ||  | |  ||       ||    _ |  |   | |       ||  |  | |
|       ||  |_|  ||    _  ||   | ||  |   | |    ___||   |_| |
|       ||       ||   |_| ||   |_||_ |   | |   |___ |       |
|      _||_     _||    ___||    __  ||   | |    ___||  _    |
|     |_   |   |  |   |    |   |  | ||   | |   |___ | | |   |
|_______|  |___|  |___|    |___|  |_||___| |_______||_|  |__|
      ]]

      logo = string.rep("\n", 8) .. logo .. "\n\n"
      opts.config.header = vim.split(logo, "\n")
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    event = "VeryLazy",
    config = function()
      require("lualine").setup({
        options = {
          component_separators = "",
          section_separators = { left = "", right = "" },
        },
      })
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
      },
    },
  },
}
