return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  config = function()
    -- Tokyo Night colors
    local colors = {
      blue = "#7aa2f7",
      cyan = "#7dcfff",
      black = "#1a1b26",
      white = "#c0caf5",
      red = "#f7768e",
      violet = "#bb9af7",
      grey = "#565f89",
      green = "#9ece6a",
      yellow = "#e0af68",
      orange = "#ff9e64",
    }

    -- Custom theme with mode-specific colors
    local custom_theme = {
      normal = {
        a = { fg = colors.black, bg = colors.blue, gui = "bold" }, -- NORMAL: 落ち着いた青
        b = { fg = colors.white, bg = colors.grey },
        c = { fg = colors.white, bg = "NONE" },
      },
      insert = {
        a = { fg = colors.black, bg = colors.green, gui = "bold" }, -- INSERT: 緑系
        b = { fg = colors.white, bg = colors.grey },
        c = { fg = colors.white, bg = "NONE" },
      },
      visual = {
        a = { fg = colors.black, bg = colors.cyan, gui = "bold" }, -- VISUAL: シアン系
        b = { fg = colors.white, bg = colors.grey },
        c = { fg = colors.white, bg = "NONE" },
      },
      replace = {
        a = { fg = colors.black, bg = colors.red, gui = "bold" }, -- REPLACE: 赤系
        b = { fg = colors.white, bg = colors.grey },
        c = { fg = colors.white, bg = "NONE" },
      },
      command = {
        a = { fg = colors.black, bg = colors.yellow, gui = "bold" }, -- COMMAND: 黄色系
        b = { fg = colors.white, bg = colors.grey },
        c = { fg = colors.white, bg = "NONE" },
      },
      inactive = {
        a = { fg = colors.white, bg = colors.grey },
        b = { fg = colors.white, bg = colors.grey },
        c = { fg = colors.white, bg = "NONE" },
      },
    }

    -- Mode with icons
    local mode = {
      "mode",
      fmt = function(str)
        local mode_icons = {
          ["NORMAL"] = " " .. str,
          ["INSERT"] = "✏ " .. str,
          ["VISUAL"] = " " .. str,
          ["V-LINE"] = " " .. str,
          ["V-BLOCK"] = " " .. str,
          ["COMMAND"] = " " .. str,
          ["REPLACE"] = " " .. str,
          ["V-REPLACE"] = " " .. str,
          ["SELECT"] = " " .. str,
          ["S-LINE"] = " " .. str,
          ["S-BLOCK"] = " " .. str,
          ["TERMINAL"] = " " .. str,
        }
        return mode_icons[str] or str
      end,
    }

    -- Relative file path
    local filename = {
      "filename",
      path = 1, -- 0: filename only, 1: relative path, 2: absolute path
      symbols = {
        modified = " ●",
        readonly = " ",
        unnamed = "[No Name]",
      },
    }

    require("lualine").setup {
      options = {
        theme = custom_theme,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
        disabled_filetypes = {
          statusline = { "dashboard", "alpha", "nvdash" },
        },
      },
      sections = {
        lualine_a = { mode },
        lualine_b = { filename },
        lualine_c = {
          { "branch", icon = "" },
          {
            "diff",
            symbols = { added = " ", modified = " ", removed = " " },
          },
          {
            function()
              local navic = require("nvim-navic")
              if not navic.is_available() then return "" end
              return navic.get_location()
            end,
            cond = function()
              return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
            end,
          },
        },
        lualine_x = {
          {
            "diagnostics",
            sources = { "nvim_lsp" },
            symbols = { error = " ", warn = " ", info = " ", hint = " " },
          },
        },
        lualine_y = {
          {
            function()
              local clients = vim.lsp.get_clients { bufnr = 0 }
              if #clients == 0 then
                return ""
              end
              local names = {}
              for _, client in ipairs(clients) do
                table.insert(names, client.name)
              end
              return "  " .. table.concat(names, ", ")
            end,
            cond = function()
              return vim.fn.winwidth(0) > 100
            end,
          },
        },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
    }
  end,
}
