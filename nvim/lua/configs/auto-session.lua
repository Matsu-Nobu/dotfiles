-- セッションに保存する項目を設定
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

local opts = {
  log_level = vim.log.levels.ERROR,

  -- 自動保存・復元・作成を明示的に有効化
  auto_save = true,
  auto_restore = true,
  auto_create = true,

  -- エラーがあっても復元を続行
  continue_restore_on_error = true,

  -- セッションを作成しないディレクトリ（macOSのデフォルトディレクトリ）
  suppressed_dirs = {
    "~/",
    "~/Downloads",
    "~/Documents",
    "~/Desktop",
    "~/Pictures",
    "~/Music",
    "~/Movies",
    "/",
  },

  -- ディレクトリ変更時の処理
  cwd_change_handling = {
    restore_upcoming_session = true,
    post_cwd_changed_hook = function()
      local ok, nvim_tree = pcall(require, "nvim-tree")
      if ok then
        nvim_tree.change_dir(vim.fn.getcwd())
        nvim_tree.refresh()
      end
    end,
  },

  -- Telescope統合
  session_lens = {
    load_on_setup = true,
    theme_conf = { border = true },
    previewer = false,
  },
}

require("auto-session").setup(opts)
