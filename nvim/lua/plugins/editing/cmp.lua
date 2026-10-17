return {
  "hrsh7th/nvim-cmp",
  opts = function(_, opts)
    local cmp = require "cmp"
    opts.mapping = vim.tbl_extend("force", opts.mapping or {}, {
      -- NOTE: Neovim 0.11でfallback()を使用すると自動インデントが保持されない問題の回避策
      -- 参考: https://github.com/hrsh7th/nvim-cmp/issues/2161
      ["<CR>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.abort() -- 補完候補を閉じる
          -- fallback()の代わりにvim.api.nvim_input()を使用してインデントを保持
          vim.api.nvim_input('<CR>')
        else
          -- 補完メニューが表示されていない場合は通常のfallback()でOK
          fallback()
        end
      end, {"i"}), -- 挿入モードのみに制限
      ["<C-k>"] = cmp.mapping.confirm { select = true }, -- 確定
      ["<Tab>"] = cmp.mapping.select_next_item(), -- 次の候補
      ["<S-Tab>"] = cmp.mapping.select_prev_item(), -- 前の候補
    })
    return opts
  end,
}
