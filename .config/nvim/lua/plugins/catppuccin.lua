return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "frappe",
      integrations = {
        telescope = {
          enable = true,
        },
        treesitter = true,
        neotree = true,
      }
    })
    
    vim.cmd.colorscheme "catppuccin-frappe"
  end
}

