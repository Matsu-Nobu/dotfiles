-- ========================================
-- LSP サーバー管理
-- ========================================
--
-- LSP サーバーは mason-lspconfig.nvim (lua/plugins/mason.lua) で自動管理されています。
-- 新しい LSP を追加する場合は lua/data/mason-tools.lua を編集してください。
--

-- NvChadのデフォルト設定を取得
local on_attach = function(client, bufnr)
  -- NvChadのデフォルトon_attachを呼び出し
  require("nvchad.configs.lspconfig").on_attach(client, bufnr)

  -- nvim-navicをアタッチ（documentSymbolProviderをサポートしている場合のみ）
  if client.server_capabilities.documentSymbolProvider then
    require("nvim-navic").attach(client, bufnr)
  end
end

local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"

-- mason-lspconfig に完全に任せるため、空リストに設定
local servers = {}

require("mason-lspconfig").setup {
  ensure_installed = vim.tbl_keys(servers),
  handlers = {
    function(server_name)
      lspconfig[server_name].setup {
        on_init = on_init,
        on_attach = on_attach,
        capabilities = capabilities,
      }
    end,
  },
}
