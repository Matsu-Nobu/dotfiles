return {
  {
    "SmiteshP/nvim-navic",
    lazy = true, -- LSP添付時に自動ロード
    opts = {
      highlight = true,
      separator = " > ",
      depth_limit = 0,
      depth_limit_indicator = "..",
      safe_output = true,
    },
  },
}
