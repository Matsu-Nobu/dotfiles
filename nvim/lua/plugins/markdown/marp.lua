return {
  "nwiizo/marp.nvim",
  ft = { "markdown" },
  config = function()
    require("marp").setup({
      -- デフォルト設定を使用
      -- 必要に応じて後でカスタマイズ可能
    })
  end,
}
