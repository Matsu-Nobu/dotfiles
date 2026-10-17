return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  ft = { "markdown" },
  config = function()
    require("render-markdown").setup {
      enabled = true,
      heading = {
        enabled = true,
        sign = true,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
      code = {
        enabled = true,
        sign = true,
        style = "full",
        position = "left",
        width = "block",
      },
      bullet = {
        enabled = true,
        icons = { "●", "○", "◆", "◇" },
      },
    }
  end,
}
