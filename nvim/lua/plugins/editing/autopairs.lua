-- lua/plugins/autopairs.lua
return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    local autopairs = require("nvim-autopairs")

    -- 基本設定（ブラケット自動ペア）
    autopairs.setup({
      check_ts = true,  -- Treesitter連携
    })

    -- Ruby end自動ペア追加
    autopairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))

    -- CMP連携（補完確定時のペア挿入）
    local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    local cmp = require("cmp")
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end,
}