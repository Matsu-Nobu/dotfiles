-- see nvim-lspconfig for more info on server configurations
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

-- Mason 関連プラグインの設定
return {
  -- Mason 本体
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    config = function()
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },

  -- LSP との統合
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      local tools = require("data.mason-tools")

      -- 各言語から LSP サーバーのみを抽出
      local lsp_servers = {}
      for _, lang in pairs(tools) do
        if lang.lsp then
          vim.list_extend(lsp_servers, lang.lsp)
        end
      end

      require("mason-lspconfig").setup({
        ensure_installed = lsp_servers,
        automatic_installation = true,
      })
    end,
  },

  -- 全ツールの自動インストール
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      local tools = require("data.mason-tools")

      -- 全言語・全カテゴリのツールを統合
      local all_tools = {}
      for _, lang in pairs(tools) do
        for _, category_tools in pairs(lang) do
          vim.list_extend(all_tools, category_tools)
        end
      end

      require("mason-tool-installer").setup({
        ensure_installed = all_tools,
        auto_update = false,
        run_on_start = false,
      })
    end,
  },
}
