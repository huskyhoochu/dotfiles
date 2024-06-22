return {
  "catppuccin/nvim",
  lazy = true,
  name = "catppuccin",
  priority = 1000,

  config = function()
    require("catppuccin").setup({
      flavour = "frappe",
      transparent_background = true,
    })
  end,
}
