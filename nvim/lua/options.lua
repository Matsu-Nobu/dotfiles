require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

local o = vim.o

-- clipboard settings
-- OSC52 plugin handles clipboard operations for SSH/remote sessions
o.clipboard = "unnamedplus" -- Use system clipboard for all yank/paste operations

-- WSL の中では Linux のクリップボードが Windows とつながっていないので、Windows のコマンドでやり取りする。
-- WSL のカーネルは /proc/version に microsoft を含む。
local function is_wsl()
  local f = io.open("/proc/version", "r")
  if not f then
    return false
  end
  local version = f:read("*a")
  f:close()
  return version:lower():find("microsoft", 1, true) ~= nil
end

if is_wsl() then
  if vim.fn.executable("win32yank.exe") == 1 then
    vim.g.clipboard = {
      name = "win32yank",
      copy = { ["+"] = "win32yank.exe -i --crlf", ["*"] = "win32yank.exe -i --crlf" },
      paste = { ["+"] = "win32yank.exe -o --lf", ["*"] = "win32yank.exe -o --lf" },
      cache_enabled = 0,
    }
  else
    -- clip.exe は UTF-8 の文字を正しく受け取れないことがあるので、win32yank.exe が無いときだけ使う。
    local paste = 'powershell.exe -NoLogo -NoProfile -Command [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))'
    vim.g.clipboard = {
      name = "wsl-clip",
      copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
      paste = { ["+"] = paste, ["*"] = paste },
      cache_enabled = 0,
    }
  end
end

-- general settings
o.expandtab = true   -- Use spaces instead of tabs
o.tabstop = 2        -- Number of spaces tabs count for
o.shiftwidth = 2     -- Number of spaces to use for autoindent
o.softtabstop = 2    -- Number of spaces a tab counts for in insert mode
o.autoindent = true  -- Copy indent from current line when starting a new line
o.smartindent = true -- Makes indenting smart
o.number = true      -- Show line numbers
o.relativenumber = false -- Show relative line numbers
o.hlsearch = true    -- Highlight search results
o.ignorecase = true  -- Case insensitive searching
o.laststatus = 2     -- Always display the status line
o.incsearch = true   -- Incremental search

-- nvim-ufo settings
-- fold levelを99に設定しないと、ファイルを開いたときにfoldされてしまう
o.foldlevel = 99
o.foldlevelstart = 99


local autocmd = vim.api.nvim_create_autocmd
-- highlight yank contents
autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank { highlight = "IncSearch", timeout = 100 }
  end,
})

-- notify on save
autocmd("BufWritePost", {
  callback = function()
    vim.notify("Saved", vim.log.levels.INFO, { timeout = 500 })
  end,
})
