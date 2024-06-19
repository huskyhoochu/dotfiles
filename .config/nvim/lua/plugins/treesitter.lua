return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local tsConfig = require("nvim-treesitter.configs")
    tsConfig.setup({
      ensure_installed = { "lua" },
      highlight = { enable = true },
      indent = { enable = true },  
    })
  end
}

