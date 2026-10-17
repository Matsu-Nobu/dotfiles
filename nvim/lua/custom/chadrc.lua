local M = {}

-- Colorscheme selection
M.colorscheme = "onedark" -- Change this to switch colorschemes

-- Colorscheme definitions
-- To add a new colorscheme, just add an entry here
M.schemes = {
  ["onedark"] = {
    plugin = "navarasu/onedark.nvim",
    setup = function()
      require("onedark").setup({
        transparent = true,
      })
      vim.cmd("colorscheme onedark")
    end,
  },
  ["monokai-pro"] = {
    plugin = "loctvl842/monokai-pro.nvim",
    setup = function()
      require("monokai-pro").setup({
        transparent_background = true,
      })
      vim.cmd("colorscheme monokai-pro")
    end,
  },
}

-- Auto-generate plugins list from schemes
-- This avoids duplicating plugin names in multiple files
-- Only load the active colorscheme, others are lazy loaded
M.plugins = {}
for name, scheme in pairs(M.schemes) do
  local is_active = (name == M.colorscheme)
  table.insert(M.plugins, {
    scheme.plugin,
    lazy = not is_active,
    priority = is_active and 1000 or nil
  })
end

return M
