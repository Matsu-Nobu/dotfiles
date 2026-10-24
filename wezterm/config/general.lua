return {
   -- behaviours
   automatically_reload_config = true,
   -- Windows と macOS では既定で、別のウィンドウから戻ってきたときの最初のクリックがウィンドウを前面に出すだけで終わり、リンクを開かない。
   swallow_mouse_click_on_window_focus = false,
   use_ime = true, -- japanese input
   exit_behavior = 'CloseOnCleanExit', -- if the shell program exited with a successful status
   exit_behavior_messaging = 'Verbose',
   status_update_interval = 5000,
   notification_handling = 'SuppressFromFocusedTab',

   scrollback_lines = 20000,

   -- URL として拾う文字は ASCII の表示できる文字だけにする。
   -- `\S` や `\w` は日本語にも一致するので、URL の直後に続く全角の括弧や日本語まで URL に含めてしまう。
   hyperlink_rules = {
      -- Matches: a URL in parens: (URL)
      {
         regex = "\\(([a-zA-Z][a-zA-Z0-9+.-]*://[!-'*-~]+)\\)",
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in brackets: [URL]
      {
         regex = '\\[([a-zA-Z][a-zA-Z0-9+.-]*://[!-\\x5c^-~]+)\\]',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in curly braces: {URL}
      {
         regex = '\\{([a-zA-Z][a-zA-Z0-9+.-]*://[!-|~]+)\\}',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in angle brackets: <URL>
      {
         regex = '<([a-zA-Z][a-zA-Z0-9+.-]*://[!-=?-~]+)>',
         format = '$1',
         highlight = 1,
      },
      -- Then handle URLs not wrapped in brackets
      -- 括弧は対になっているものだけを URL に含める。
      -- 対になっていない閉じ括弧を含めると、`(URL)` の閉じ括弧まで URL になる。
      {
         regex = "[a-zA-Z][a-zA-Z0-9+.-]*://(?:[!-'*-~]|\\([!-'*-~]*\\))*(?:[/a-zA-Z0-9_=#-]|\\([!-'*-~]*\\))",
         format = '$0',
      },
      -- implicit mailto link
      {
         regex = '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)+',
         format = 'mailto:$0',
      },
   },
}
