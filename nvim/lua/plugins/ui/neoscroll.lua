-- スムーススクロール
return {
  "karb94/neoscroll.nvim",
  event = "VeryLazy",
  config = function()
    require("neoscroll").setup({
      mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>" }, -- スクロールコマンドを有効化
      hide_cursor = true, -- スクロール中はカーソルを非表示
      stop_eof = true, -- ファイル末尾で停止
      easing = "quadratic", -- スムーズなアニメーション
      duration_multiplier = 0.9, -- アニメーション速度調整
    })
  end,
}
