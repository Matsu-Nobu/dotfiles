return {
  'ojroques/nvim-osc52',
  lazy = false, -- 起動時に読み込んで xclip より先に設定を適用させる
  config = function()
    require('osc52').setup {
      max_length = 0,           -- No limit on selection size
      silent = false,            -- Show message on successful copy
      trim = false,              -- Don't trim surrounding whitespace
      tmux_passthrough = true,   -- Essential for tmux users
    }

    -- Set up clipboard provider using OSC52
    local function copy(lines, _)
      require('osc52').copy(table.concat(lines, '\n'))
    end

    local function paste()
      return {vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('')}
    end

    -- SSH接続時のみvim.g.clipboardを設定
    -- ローカル環境ではmacOS標準のクリップボード連携を使用
    if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
      vim.g.clipboard = {
        name = 'osc52',
        copy = {['+'] = copy, ['*'] = copy},
        paste = {['+'] = paste, ['*'] = paste},
      }
    end

    vim.keymap.set('n', '<leader>y', require('osc52').copy_operator, {
      expr = true,
      desc = 'Copy to clipboard'
    })
    vim.keymap.set('n', '<leader>yy', '<leader>y_', {
      remap = true,
      desc = 'Copy line to clipboard'
    })
    vim.keymap.set('v', '<leader>y', require('osc52').copy_visual, {
      desc = 'Copy selection to clipboard'
    })
  end,
}
