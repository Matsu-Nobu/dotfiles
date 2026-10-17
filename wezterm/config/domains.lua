local platform = require('utils.platform')

local options = {
   -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
   ssh_domains = {},

   -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
   unix_domains = {},

   -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
   -- username と default_cwd を書かないと、WSL の既定のユーザーとそのホームディレクトリで開く。
   wsl_domains = {
      {
         name = 'WSL:Ubuntu',
         distribution = 'Ubuntu',
         default_prog = { 'zsh', '-l' },
      },
   },
}

-- Windows では、WezTerm を開いたときに WSL の Ubuntu の zsh を開く。
if platform.is_win then
   options.default_domain = 'WSL:Ubuntu'
end

return options
