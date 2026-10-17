vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- Build plugin list
local lazy_plugins = {
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
    config = function()
      require "options"
    end,
  },

  { import = "plugins.lsp" },
  { import = "plugins.debug" },
  { import = "plugins.test" },
  { import = "plugins.lang" },
  { import = "plugins.syntax" },
  { import = "plugins.editing" },
  { import = "plugins.navigation" },
  { import = "plugins.dev-tools" },
  { import = "plugins.session" },
  { import = "plugins.ui" },
  { import = "plugins.finder" },
  { import = "plugins.git" },
  { import = "plugins.markdown" },
  { import = "plugins.ai" },
}

-- Load custom plugins from custom.chadrc
-- Custom colorscheme plugins are auto-generated in lua/custom/chadrc.lua
local custom_chadrc = require "custom.chadrc"
for _, plugin in ipairs(custom_chadrc.plugins or {}) do
  table.insert(lazy_plugins, plugin)
end

require("lazy").setup(lazy_plugins, lazy_config)

-- comment
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions = vim.opt_local.formatoptions - { "c", "r", "o" }
  end,
})

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)

-- Apply custom colorscheme (overrides base46)
local active_scheme = custom_chadrc.schemes[custom_chadrc.colorscheme]
if active_scheme and active_scheme.setup then
  active_scheme.setup()
end
