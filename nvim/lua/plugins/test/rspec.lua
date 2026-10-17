return {
  {
    "mogulla3/rspec.nvim",
    lazy = false,
    config = function()
      require("rspec").setup {
        -- Whether or not to open the quickfix window when the spec fails.
        open_quickfix_when_spec_failed = true,
      }
    end,
  },
}
