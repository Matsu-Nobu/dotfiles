local wezterm = require('wezterm')
local platform = require('utils.platform')
local act = wezterm.action

local mod = {}

if platform.is_mac then
   mod.SUPER = 'SUPER'
   mod.SUPER_REV = 'SUPER|SHIFT'
elseif platform.is_win or platform.is_linux then
   mod.SUPER = 'ALT' -- to not conflict with Windows key shortcuts
   mod.SUPER_REV = 'ALT|SHIFT'
end

-- stylua: ignore
local keys = {
   -- misc/useful --
   { key = 'F1', mods = 'NONE', action = 'ActivateCopyMode' },
   { key = 'F2', mods = 'NONE', action = act.ActivateCommandPalette },
   { key = 'F3', mods = 'NONE', action = act.ShowLauncher },
   { key = 'F4', mods = 'NONE', action = act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }) },
   {
      key = 'F5',
      mods = 'NONE',
      action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }),
   },
   { key = 'F11', mods = 'NONE',    action = act.ToggleFullScreen },
   { key = 'F12', mods = 'NONE',    action = act.ShowDebugOverlay },
   { key = 'f',   mods = mod.SUPER, action = act.Search({ CaseInSensitiveString = '' }) },
   {
      key = 'u',
      mods = mod.SUPER_REV,
      action = wezterm.action.QuickSelectArgs({
         label = 'open url',
         patterns = {
            '\\((https?://\\S+)\\)',
            '\\[(https?://\\S+)\\]',
            '\\{(https?://\\S+)\\}',
            '<(https?://\\S+)>',
            '\\bhttps?://\\S+[)/a-zA-Z0-9-]+'
         },
         action = wezterm.action_callback(function(window, pane)
            local url = window:get_selection_text_for_pane(pane)
            wezterm.log_info('opening: ' .. url)
            wezterm.open_with(url)
         end),
      }),
   },

   -- cursor movement --
   { key = 'LeftArrow',  mods = mod.SUPER,     action = act.SendString '\u{01}' },
   { key = 'RightArrow', mods = mod.SUPER,     action = act.SendString '\u{05}' },
   { key = 'Backspace',  mods = mod.SUPER,     action = act.SendString '\u{15}' },

   -- tabs: navigation --
   -- macOS では Ctrl+矢印が既定で操作スペースの切り替えに割り当てられている。
   -- システム設定でその割り当てを外さないと、この 2 つのキーは WezTerm に届かない。
   { key = 'LeftArrow',  mods = 'CTRL',        action = act.ActivateTabRelative(-1) },
   { key = 'RightArrow', mods = 'CTRL',        action = act.ActivateTabRelative( 1) },

   -- copy/paste --
   -- Cmd+C: 改行を空白に潰してコピー (ソフトラップやコマンドの \ 継続で入る改行を除去)
   -- 改行を残したままコピーしたい時は Cmd+Shift+C を使う
   {
      key = 'c',
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, pane)
         local sel = window:get_selection_text_for_pane(pane)
         if sel == nil or sel == '' then return end
         local joined = sel:gsub('\\\r?\n%s*', ' '):gsub('\r?\n', ' ')
         window:copy_to_clipboard(joined, 'Clipboard')
      end),
   },
   { key = 'c',          mods = mod.SUPER_REV, action = act.CopyTo('Clipboard') },
   { key = 'v',          mods = mod.SUPER,     action = act.PasteFrom('Clipboard') },

   -- tabs --
   -- tabs: spawn+close
   { key = 'm',          mods = mod.SUPER,     action = act.HideApplication },
   { key = 't',          mods = mod.SUPER,     action = act.SpawnTab('DefaultDomain') },
   { key = 't',          mods = mod.SUPER_REV, action = act.SpawnTab({ DomainName = 'WSL:Ubuntu' }) },
   { key = 'w',          mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },
   { key = 'q',          mods = mod.SUPER,     action = act.QuitApplication },

   -- tabs: navigation
   { key = '[',          mods = mod.SUPER,     action = act.ActivateTabRelative(-1) },
   { key = ']',          mods = mod.SUPER,     action = act.ActivateTabRelative(1) },
   { key = '[',          mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
   { key = ']',          mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },

   -- tab: title
   { key = '0',          mods = mod.SUPER,     action = act.EmitEvent('tabs.manual-update-tab-title') },
   { key = '0',          mods = mod.SUPER_REV, action = act.EmitEvent('tabs.reset-tab-title') },

   -- tab: hide tab-bar
   { key = '9',          mods = mod.SUPER,     action = act.EmitEvent('tabs.toggle-tab-bar'), },

   -- window --
   -- window: spawn windows
   { key = 'n',          mods = mod.SUPER,     action = act.SpawnWindow },

   -- window: zoom window
   {
      key = '-',
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         local dimensions = window:get_dimensions()
         if dimensions.is_full_screen then
            return
         end
         local new_width = dimensions.pixel_width - 50
         local new_height = dimensions.pixel_height - 50
         window:set_inner_size(new_width, new_height)
      end)
   },
   {
      key = '=',
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         local dimensions = window:get_dimensions()
         if dimensions.is_full_screen then
            return
         end
         local new_width = dimensions.pixel_width + 50
         local new_height = dimensions.pixel_height + 50
         window:set_inner_size(new_width, new_height)
      end)
   },

   -- theme toggle (dark/light) --
   {
      key = 'l',
      mods = 'LEADER',
      action = wezterm.action_callback(function(window, _pane)
         local overrides = window:get_config_overrides() or {}
         if overrides.__is_light then
            overrides.colors = nil
            overrides.window_background_opacity = nil
            overrides.freetype_load_target = nil
            overrides.freetype_render_target = nil
            overrides.freetype_load_flags = nil
            overrides.font = nil
            overrides.__is_light = nil
         else
            overrides.colors = {
               foreground = '#24292e',
               background = '#ffffff',
               cursor_bg = '#24292e',
               cursor_border = '#24292e',
               cursor_fg = '#ffffff',
               selection_bg = '#0366d6',
               selection_fg = '#ffffff',
               ansi = {
                  '#24292e', '#cb2431', '#22863a', '#b08800',
                  '#0366d6', '#6f42c1', '#1b7c83', '#6a737d',
               },
               brights = {
                  '#959da5', '#f97583', '#85e89d', '#ffea7f',
                  '#79b8ff', '#b392f0', '#56d4dd', '#fafbfc',
               },
               compose_cursor = '#24292e',
            }
            overrides.window_background_opacity = 1.0
            overrides.freetype_load_target = 'Normal'
            overrides.freetype_render_target = 'Normal'
            overrides.freetype_load_flags = 'DEFAULT'
            overrides.font = wezterm.font_with_fallback({
               { family = 'Hack Nerd Font Mono', weight = 'Bold' },
               { family = 'HackGen Console NF', weight = 'Bold' },
            })
            overrides.__is_light = true
         end
         window:set_config_overrides(overrides)
      end),
   },

   -- panes --
   -- panes: split panes
   {
      key = [[\]],
      mods = mod.SUPER,
      action = act.SplitVertical({ domain = 'CurrentPaneDomain' }),
   },
   {
      key = [[\]],
      mods = mod.SUPER_REV,
      action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
   },

   -- panes: zoom+close pane
   { key = 'Enter', mods = mod.SUPER,     action = act.TogglePaneZoomState },
   { key = 'w',     mods = mod.SUPER,     action = act.CloseCurrentPane({ confirm = false }) },

   -- panes: navigation
   { key = 'k',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Up') },
   { key = 'j',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Down') },
   { key = 'h',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Left') },
   { key = 'l',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Right') },
   {
      key = 'p',
      mods = mod.SUPER_REV,
      action = act.PaneSelect({ alphabet = '1234567890', mode = 'SwapWithActiveKeepFocus' }),
   },

   -- panes: scroll pane
   { key = 'u',        mods = mod.SUPER, action = act.ScrollByLine(-5) },
   { key = 'd',        mods = mod.SUPER, action = act.ScrollByLine(5) },
   { key = 'PageUp',   mods = 'NONE',    action = act.ScrollByPage(-0.75) },
   { key = 'PageDown', mods = 'NONE',    action = act.ScrollByPage(0.75) },

   -- key-tables --
   -- resizes fonts
   {
      key = 'f',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_font',
         one_shot = false,
         timemout_miliseconds = 1000,
      }),
   },
   -- resize panes
   {
      key = 'p',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_pane',
         one_shot = false,
         timemout_miliseconds = 1000,
      }),
   },
   -- rename tab
   {
      key = 'r',
      mods = 'LEADER',
      action = act.EmitEvent('tabs.manual-update-tab-title'),
   },
   -- show tab navigator
   {
      key = 'w',
      mods = 'LEADER',
      action = act.ShowTabNavigator,
   },
   -- show keybindings help
   {
      key = '/',
      mods = 'LEADER',
      action = wezterm.action_callback(function(window, pane)
         for _ = 1, 4 do
            window:perform_action(act.IncreaseFontSize, pane)
         end
         window:perform_action(act.InputSelector({
            title = '⌨️  キーバインド一覧 (Esc で閉じる)',
            choices = {
               { label = '── 一般 ─────────────────────────────────' },
               { label = 'F1                  コピーモード' },
               { label = 'F2                  コマンドパレット' },
               { label = 'F3                  ランチャー' },
               { label = 'F4                  タブ検索' },
               { label = 'F5                  ワークスペース検索' },
               { label = 'F11                 全画面切替' },
               { label = 'Cmd + F             検索' },
               { label = 'Cmd + Shift + U     URL選択' },
               { label = 'Cmd + C / Cmd + V   コピー / ペースト' },
               { label = 'Cmd + ← / Cmd + →   行頭 / 行末へ移動' },
               { label = 'Cmd + Delete        行頭まで削除' },
               { label = '── タブ ─────────────────────────────────' },
               { label = 'Cmd + T             新しいタブ' },
               { label = 'Cmd + Shift + W     タブを閉じる' },
               { label = 'Cmd + [ / Ctrl + ←  前のタブ' },
               { label = 'Cmd + ] / Ctrl + →  次のタブ' },
               { label = 'Cmd + Shift + [/]   タブを左右に移動' },
               { label = 'Cmd + 0             タブ名変更' },
               { label = 'Cmd + 9             タブバー表示切替' },
               { label = '── ペイン ───────────────────────────────' },
               { label = 'Cmd + \\             縦分割' },
               { label = 'Cmd + Shift + \\     横分割' },
               { label = 'Cmd + Enter         ペインズーム切替' },
               { label = 'Cmd + W             ペインを閉じる' },
               { label = 'Cmd + Shift + HJKL  ペイン移動' },
               { label = 'Cmd + Shift + P     ペイン入替' },
               { label = 'Cmd + U / Cmd + D   上下スクロール' },
               { label = '── ウィンドウ ────────────────────────────' },
               { label = 'Cmd + N             新しいウィンドウ' },
               { label = 'Cmd + - / Cmd + =   ウィンドウ縮小/拡大' },
               { label = '── リーダー (Cmd + J) ────────────────────' },
               { label = 'Cmd + J → /         このヘルプ' },
               { label = 'Cmd + J → F         フォントサイズ変更 (K/J/R, Esc)' },
               { label = 'Cmd + J → P         ペインサイズ変更 (H/J/K/L, Esc)' },
               { label = 'Cmd + J → R         タブ名変更' },
               { label = 'Cmd + J → W         タブナビゲーター' },
               { label = 'Cmd + J → L         ライト/ダーク テーマ切替' },
               { label = 'Cmd + J → S         ワークスペース作成/切替' },
               { label = 'Cmd + J → 1-9       タブ番号で移動' },
            },
            action = wezterm.action_callback(function(win, p)
               for _ = 1, 4 do
                  win:perform_action(act.DecreaseFontSize, p)
               end
            end),
         }), pane)
      end),
   },
   -- workspace: create/switch by name
   {
      key = 's',
      mods = 'LEADER',
      action = act.PromptInputLine({
         description = 'ワークスペース名を入力 (作成/切替)',
         action = wezterm.action_callback(function(window, pane, line)
            if line and #line > 0 then
               window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
            end
         end),
      }),
   },
   -- activate tab by number (1-9)
   { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
   { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
   { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },
   { key = '4', mods = 'LEADER', action = act.ActivateTab(3) },
   { key = '5', mods = 'LEADER', action = act.ActivateTab(4) },
   { key = '6', mods = 'LEADER', action = act.ActivateTab(5) },
   { key = '7', mods = 'LEADER', action = act.ActivateTab(6) },
   { key = '8', mods = 'LEADER', action = act.ActivateTab(7) },
   { key = '9', mods = 'LEADER', action = act.ActivateTab(8) },
}

-- stylua: ignore
local key_tables = {
   resize_font = {
      { key = 'k',      action = act.IncreaseFontSize },
      { key = 'j',      action = act.DecreaseFontSize },
      { key = 'r',      action = act.ResetFontSize },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q',      action = 'PopKeyTable' },
   },
   resize_pane = {
      { key = 'k',      action = act.AdjustPaneSize({ 'Up', 1 }) },
      { key = 'j',      action = act.AdjustPaneSize({ 'Down', 1 }) },
      { key = 'h',      action = act.AdjustPaneSize({ 'Left', 1 }) },
      { key = 'l',      action = act.AdjustPaneSize({ 'Right', 1 }) },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q',      action = 'PopKeyTable' },
   },
}

local mouse_bindings = {
   -- Ctrl-click will open the link under the mouse cursor
   {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
   },
   -- マウス操作を受け取る TUI (Claude Code など) の画面では、mouse_reporting を指定しない割り当ては使われず、クリックが TUI に送られる。
   -- mouse_reporting = true を指定した割り当ては、その画面でも WezTerm がクリックを受け取って処理する。
   {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
      mouse_reporting = true,
   },
   -- ボタンを押したときのイベントも WezTerm が受け取る。
   -- 押したイベントだけが TUI に届くと、TUI の中で文字の選択が始まったままになる。
   {
      event = { Down = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.Nop,
      mouse_reporting = true,
   },
   -- 修飾キーなしの左ボタンも、マウス操作を受け取る TUI の画面で WezTerm が処理する。
   -- 押す・ドラッグ・離すの 3 つをそろえて WezTerm に割り当てないと、TUI には一部のイベントだけが届いて操作が途切れる。
   -- この 3 つは、マウス操作を受け取らない画面での WezTerm の既定の割り当てと同じ動作にしている。
   -- その代わり、TUI には左ボタンのクリックとドラッグが届かない。
   {
      event = { Down = { streak = 1, button = 'Left' } },
      mods = 'NONE',
      action = act.SelectTextAtMouseCursor('Cell'),
      mouse_reporting = true,
   },
   {
      event = { Drag = { streak = 1, button = 'Left' } },
      mods = 'NONE',
      action = act.ExtendSelectionToMouseCursor('Cell'),
      mouse_reporting = true,
   },
   {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'NONE',
      action = act.CompleteSelectionOrOpenLinkAtMouseCursor('ClipboardAndPrimarySelection'),
      mouse_reporting = true,
   },

   -- alternate screen buffer (Claude Code / less / vim 等の TUI) ではマウスホイールを
   -- PageUp/PageDown として送る。WezTerm デフォルトは wheel を ↑/↓ に変換するため、
   -- Claude Code 4.x が "Scroll wheel is sending arrow keys" 警告を出してしまう。
   -- alt_screen = true 条件付きなので、通常のシェル画面では WezTerm 自身の
   -- scrollback に対する wheel 操作（オリジナル挙動）が維持される。
   {
      event = { Down = { streak = 1, button = { WheelUp = 1 } } },
      mods = 'NONE',
      action = act.SendKey({ key = 'PageUp' }),
      alt_screen = true,
   },
   {
      event = { Down = { streak = 1, button = { WheelDown = 1 } } },
      mods = 'NONE',
      action = act.SendKey({ key = 'PageDown' }),
      alt_screen = true,
   },
}

return {
   disable_default_key_bindings = true,
   -- disable_default_mouse_bindings = true,
   leader = { key = 'j', mods = mod.SUPER, timeout_milliseconds = 3000 },
   keys = keys,
   key_tables = key_tables,
   mouse_bindings = mouse_bindings,
}
