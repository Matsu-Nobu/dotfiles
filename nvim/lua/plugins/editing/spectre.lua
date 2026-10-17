return {
  "nvim-pack/nvim-spectre",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = "Spectre",
  keys = {
    {
      "<leader>S",
      function()
        require("spectre").toggle()
      end,
      desc = "Toggle Spectre (Search & Replace)",
    },
    {
      "<leader>sw",
      function()
        require("spectre").open_visual({ select_word = true })
      end,
      desc = "Search current word",
    },
    {
      "<leader>sw",
      mode = "v",
      function()
        require("spectre").open_visual()
      end,
      desc = "Search selected text",
    },
    {
      "<leader>sf",
      function()
        require("spectre").open_file_search({ select_word = true })
      end,
      desc = "Search in current file",
    },
  },
  opts = {
    open_cmd = 'botright 15new',  -- 画面下部に高さ15行で水平分割
    -- 内部キーマップ:
    -- <Tab>: 次の項目
    -- <S-Tab>: 前の項目
    -- dd: 行の除外/含める
    -- <CR>: ファイルを開く
    -- <leader>q: Quickfixへ送る
  },
}
