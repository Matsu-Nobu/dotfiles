-- インデントとコードブロックの視覚化
return {
  "shellRaining/hlchunk.nvim",
  event = "VeryLazy", -- 遅延読み込みでパフォーマンス改善
  config = function()
    require("hlchunk").setup({
      chunk = {
        enable = true, -- コードブロックのハイライトを有効化
        priority = 15, -- 描画優先度（高いほど優先）
        exclude_filetypes = {
          aerial = true,
          dashboard = true,
          NvimTree = true,
          lazy = true,
          mason = true,
        },
      },
      indent = {
        enable = true, -- インデントガイドを有効化
        priority = 10, -- chunkより低い優先度
        exclude_filetypes = {
          aerial = true,
          dashboard = true,
          NvimTree = true,
          lazy = true,
          mason = true,
        },
      },
      line_num = {
        enable = false, -- 行番号ハイライトは無効（必要に応じて有効化）
      },
      blank = {
        enable = false, -- 空行ハイライトは無効（パフォーマンス重視）
      },
    })
  end,
}
