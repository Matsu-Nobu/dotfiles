return {
  {
    "rickhowe/diffchar.vim",
    lazy = false,
    config = function()
      -- diffchar.vim uses global variables for configuration
      -- Set diff unit to Word1 (default: handles words and individual characters)
      vim.g.DiffUnit = "Word1"

      -- Set diff algorithm (default: O(NP) algorithm)
      -- Other options: "basic", "compact", "minimum"
      vim.g.DiffAlgorithm = "histogram"

      -- Enable/disable automatic highlighting on diff mode
      vim.g.DiffModeSync = 1

      -- Color scheme for difference highlights
      -- 0: default, 1-3: alternative color schemes
      vim.g.DiffColors = 0

      -- Maximum number of lines to check for diff
      -- 0: unlimited (may impact performance on large files)
      vim.g.DiffMaxLines = 0
    end,
  },
}
