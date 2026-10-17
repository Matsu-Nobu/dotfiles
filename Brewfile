# setup.sh が brew bundle --file=Brewfile で入れる。
# Claude Code は Homebrew ではなく、setup.sh が公式のインストーラで入れる。

tap "terraform-linters/tap"

# シェル
brew "sheldon"
brew "starship"
brew "direnv"

# エディタと Git
brew "neovim"
brew "git"
brew "gh"
brew "ghq"

# 言語のランタイム
brew "rbenv"
brew "ruby-build"
# ruby-build が Ruby をビルドするときに使うライブラリ
brew "openssl@3"
brew "libyaml"
# Node.js は LTS の系列の node@24 を使う。keg-only なので link: true で PATH に出す。
brew "node@24", link: true
brew "deno"
brew "python"

# 開発用の CLI
brew "curl"
brew "jq"
brew "gettext"
brew "ripgrep"
brew "bat"
brew "fd"
brew "eza"
brew "tree"
# tldr の formula は無効化されたので、同じ tldr コマンドを持つ tealdeer を入れる。
brew "tealdeer"
brew "duf"
brew "glances"
brew "lefthook"
brew "actionlint"
brew "trivy"
brew "betterleaks"

if OS.mac?
  # tflint の開発元の tap は、macOS 用の cask だけを配布している。
  cask "terraform-linters/tap/tflint"
  # 正式版の WezTerm は今の macOS で通知を表示できないので、開発版を入れる。
  cask "wezterm@nightly"
  # 手で入れた Karabiner-Elements を Homebrew で入れ直すと管理者のパスワードが要るので、既にあれば飛ばす。
  cask "karabiner-elements" unless File.exist?("/Applications/Karabiner-Elements.app")
  cask "font-hack-nerd-font"
  cask "font-hackgen-nerd"
end
