return {
  "nvim-tree/nvim-tree.lua",
  config = function()
    require("nvim-tree").setup({
      git = {
        enable = true,
        ignore = false, -- Show gitignored files
      },
      update_focused_file = {
        enable = true, -- Auto-focus on current file
        update_root = false, -- Don't change root directory
        ignore_list = {}, -- Focus on all buffer types
      },
      renderer = {
        hidden_display = "all", -- Show hidden files
        icons = {
          show = {
            hidden = true, -- Show hidden file icons
          },
        },
      },
      filters = {
        dotfiles = false, -- Show .files
        git_clean = false,
        no_buffer = false,
        git_ignored = false, -- Show gitignored files
      },
    })
  end,
}