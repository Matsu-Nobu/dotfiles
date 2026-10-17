-- Windows 側の WezTerm が、WSL の Ubuntu の中に clone した dotfiles の wezterm/ の設定を読むための入口。
-- windows/setup.ps1 が __WSL_USER__ を WSL のユーザー名に置き換えて、%USERPROFILE%\.wezterm.lua に書き出す。
local wezterm = require('wezterm')

local dir = [[\\wsl.localhost\Ubuntu\home\__WSL_USER__\dotfiles\wezterm]]

-- wezterm/ の中のファイルは require('config') のように wezterm/ を起点にした名前で互いを読み込むので、検索先に加える。
package.path = dir .. [[\?.lua;]] .. dir .. [[\?\init.lua;]] .. package.path

-- WSL の中のファイルを編集したときにも設定を読み直させる。
wezterm.add_to_config_reload_watch_list(dir)

return dofile(dir .. [[\wezterm.lua]])
