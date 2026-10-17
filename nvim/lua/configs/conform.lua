local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    go = { 'goimports' },
    rust = { 'rustfmt' },
    python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
    javascript = { "biome" },
    typescript = { "biome" },
    javascriptreact = { "biome" },
    typescriptreact = { "biome" },
    json = { "biome" },
    -- css = { "prettier" },
    -- html = { "prettier" },
  },

  -- format_on_save = {
  --   -- These options will be passed to conform.format()
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

require("conform").setup(options)
