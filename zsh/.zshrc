# aliases
alias ccc='caffeinate -is claude --permission-mode auto'

# XDG Base Directory仕様に準拠
# macOSでも~/.configを設定ディレクトリとして使用する
# これにより gh 等のツールが Linux と同じパスを参照する
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Editor
export EDITOR=nvim
export VISUAL="$EDITOR"

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY          # 複数タブ間で履歴を即座に共有
setopt HIST_IGNORE_ALL_DUPS   # 重複したコマンドを履歴に追加しない
setopt HIST_FIND_NO_DUPS      # 履歴検索時に重複を表示しない
setopt HIST_REDUCE_BLANKS     # 余分な空白を削除して履歴に保存
setopt HIST_SAVE_NO_DUPS      # 保存時に重複を削除

# Homebrew (Mac Apple Silicon / Linux 両対応)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # Mac (Apple Silicon)
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  # Linux (system-wide)
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# User-local binaries (task CLI etc.)
export PATH="$HOME/bin:$PATH"

# zsh/parameter モジュールを先にロード（deferred pluginとの競合回避）
zmodload zsh/parameter 2>/dev/null

# zsh
eval "$(sheldon source)"

# direnv (.envrc自動読み込み)
export DIRENV_LOG_FORMAT=""
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# color theme
export CLICOLOR=1
export TERM=xterm-256color

# zsh-vi-mode初期化後にfzf/starshipを初期化（競合回避）
function zvm_after_init() {
  # fzf
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

  # starship
  eval "$(starship init zsh)"

  # インサートモードでEmacsキーバインド（行内編集）
  bindkey -M viins '^A' beginning-of-line
  bindkey -M viins '^E' end-of-line
  bindkey -M viins '^K' kill-line
  bindkey -M viins '^U' backward-kill-line
  bindkey -M viins '^W' backward-kill-word
}

zstyle ':completion:*' completer _complete _prefix

# autosuggestion
if type brew &>/dev/null; then
 FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
fi

# exclude unneeded history
zshaddhistory() {
  local line="${1%%$'\n'}"
  [[ ! "$line" =~ "^(cd|jj?|la|ll|ls|rm|rmdir)($| )" ]]
}

# pipx や Claude Code のネイティブ版が置くコマンド
export PATH="$HOME/.local/bin:$PATH"

# rbenv (Ruby のバージョン管理)
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# 仕事用の秘密情報・alias・環境変数はリポジトリに載せず、このファイルに置く。
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
