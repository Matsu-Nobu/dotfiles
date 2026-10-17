return {
  "nvim-telescope/telescope-smart-history.nvim",
  dependencies = { "kkharji/sqlite.lua" },
  config = function()
    require("telescope").load_extension("smart_history")
  end,
}