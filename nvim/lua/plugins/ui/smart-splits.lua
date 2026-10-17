-- smart-splits.nvim: ウィンドウ循環移動とtmux連携
-- 端から端へ循環移動する機能を提供
return {
  "mrjones2014/smart-splits.nvim",
  -- VeryLazyイベントで遅延ロード（起動直後、UIレンダリング完了後）
  -- keys指定ではマッピング競合が発生するため、eventベースに変更
  event = "VeryLazy",
  config = function()
    require("smart-splits").setup({
      -- 端に到達したときの動作
      -- 'wrap': 反対側に循環移動（推奨）
      -- 'split': 新しい分割を作成
      -- 'stop': 移動を停止（通常のVim動作）
      at_edge = "wrap",

      -- tmux連携を有効化
      -- Neovimとtmuxのペイン間をシームレスに移動可能
      multiplexer_integration = "tmux",

      -- デフォルト設定（必要に応じて調整可能）
      -- ignored_filetypes = { "nofile", "quickfix", "prompt" },
      -- ignored_buftypes = { "nofile" },
    })
  end,
}
