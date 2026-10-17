return {
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    lazy = false,
    config = function()
      require("git-conflict").setup {
        default_mappings = true, -- Enable default mappings (co, ct, cb, c0, ]x, [x)
        default_commands = true, -- Enable default commands
        disable_diagnostics = false, -- Keep diagnostics enabled during conflicts
        list_opener = 'copen', -- Command to open quickfix list
        highlights = {
          incoming = 'DiffAdd',
          current = 'DiffText',
        }
      }
    end,
  },
}
