# 概要

このリポジトリには、松山の開発環境の設定ファイルを置く。`setup.sh` を実行すると、Homebrew でコマンドを入れ、ホームディレクトリの決まった場所からこのリポジトリのファイルへシンボリックリンクを張る。リンクを張る場所とリポジトリのファイルの対応は `install.conf.yaml` に書いてあり、`setup.sh` が [dotbot](https://github.com/anishathalye/dotbot) を使ってその対応どおりにリンクを張る。

トークンのような秘密情報と仕事用の設定は、このリポジトリに入れない。それらは各マシンの `~/.zshrc.local` に書く（「手で書くファイル」の節を参照）。

# 含まれる設定

| ディレクトリ・ファイル | リンクを張る場所 | 内容 |
| --- | --- | --- |
| `zsh/.zshrc` | `~/.zshrc` | zsh の設定 |
| `zsh/aliases/` | `~/.config/zsh/aliases` | alias。zsh の起動時に、プラグイン管理の sheldon が読み込む |
| `sheldon/` | `~/.config/sheldon` | sheldon が読み込む zsh のプラグインの一覧 |
| `starship.toml` | `~/.config/starship.toml` | プロンプトを表示する starship の設定 |
| `fzf/.fzf.zsh` | `~/.fzf.zsh` | あいまい検索で候補を選ぶ fzf の設定と、fzf を使う関数 |
| `direnv/` | `~/.config/direnv` | ディレクトリごとに環境変数を切り替える direnv の設定 |
| `wezterm/` | `~/.config/wezterm` | 端末の WezTerm の設定 |
| `nvim/` | `~/.config/nvim` | Neovim の設定 |
| `git/` | `~/.config/git` | Git の alias と、すべてのリポジトリで無視するファイル |
| `gh/config.yml` | `~/.config/gh/config.yml` | GitHub CLI の設定 |
| `karabiner/` | `~/.config/karabiner` | Karabiner-Elements の設定。`setup.sh` は macOS のときだけリンクを張る |
| `bin/task` | `~/bin/task` | Obsidian の vault のタスクを作成・一覧・開始するコマンド |
| `claude/` | `~/.claude/CLAUDE.md` などの各ファイル | Claude Code の指示・規則・フック・設定 |
| `windows/` | なし | Windows 用のセットアップスクリプトと WezTerm の設定の入口 |

`claude/` は `~/.claude/` ディレクトリごとではなく、`install.conf.yaml` に書いたファイルとディレクトリに 1 つずつリンクを張る。`~/.claude/skills/` と `~/.claude/commands/` には、このリポジトリに入れないスキルとコマンドもマシンごとに置くからである。

# macOS と Linux のセットアップ

GitHub CLI で GitHub にログインしてから、このリポジトリを clone して `setup.sh` を実行する。macOS では、GitHub CLI を入れる前に Homebrew を[公式の手順](https://brew.sh/)で入れておく。

```sh
brew install gh
gh auth login
gh repo clone <GitHub のユーザー名>/dotfiles ~/dotfiles
~/dotfiles/setup.sh
```

`setup.sh` は、前提のパッケージ、Homebrew と `Brewfile` のコマンド、リンク、Claude Code、ログインシェルの zsh への変更、`~/.zshrc.local` の雛形、`~/.gitconfig` の名前とメールアドレス、コミット前の検査、Ruby を順に整える。どの段階も、既に済んでいれば何もしないので、何度実行してもよい。リンクを張る場所に既にファイルがあると、`setup.sh` はそのファイルを `~/.dotfiles-backup/<日時>/` に移してからリンクを張る。

Ruby は、`~/workspace` と、その 1 つ下のディレクトリにある `.ruby-version` に書かれたバージョンを `rbenv` で入れる。仕事のリポジトリを clone した後にもう一度 `./setup.sh` を実行すると、必要な Ruby が入る。

WezTerm は開発版を入れる。正式版は今の macOS で通知を表示できないからである。

# Windows のセットアップ

Windows では WezTerm とフォントだけを Windows に入れ、zsh や Neovim などの残りは WSL2 の Ubuntu の中で使う。`windows/setup.ps1` が、WSL と Ubuntu、WezTerm の開発版、MesloLGS Nerd Font Mono を入れ、Ubuntu の中で `~/dotfiles` を clone して `setup.sh` を実行する。最後に、Windows の WezTerm が Ubuntu の中の `~/dotfiles/wezterm` の設定を読むよう、`%USERPROFILE%\.wezterm.lua` を書く。

このリポジトリは private なので、`setup.ps1` を取得する前に Windows の GitHub CLI でログインする。PowerShell で次を実行する。

```powershell
winget install --id GitHub.cli --exact
gh auth login
Invoke-WebRequest -Headers @{ Authorization = "token $(gh auth token)"; Accept = "application/vnd.github.raw" } -Uri https://api.github.com/repos/<GitHub のユーザー名>/dotfiles/contents/windows/setup.ps1 -OutFile setup.ps1
powershell -ExecutionPolicy Bypass -File setup.ps1 -Repo <GitHub のユーザー名>/dotfiles
```

WSL を初めて入れたときは、`setup.ps1` が再起動を求めて終わる。再起動して Ubuntu のユーザーを作ってから、同じコマンドをもう一度実行する。Ubuntu の中では GitHub CLI のログインをもう一度求められる。

Claude Code の通知は WezTerm が表示する。Windows でも同じ仕組みで動く見込みだが、実機では確認していない。Karabiner-Elements の設定は Windows では使えない。

# 手で書くファイル

## ~/.zshrc.local

zsh は `~/.zshrc` の最後で、`~/.zshrc.local` があれば読み込む。仕事用の環境変数・alias・トークンは、このファイルに `export` や `alias` で書く。`setup.sh` は、このファイルが無ければ、他のユーザーが読めない権限（600）で空の雛形を作る。

Confluence のページ幅を最大にするスクリプト `claude/bin/confluence-max-width.sh` を使うマシンでは、Confluence のサイトのホスト名をこのファイルに `export ATLASSIAN_SITE=<ホスト名>` と書く。

## ~/.gitconfig

`setup.sh` は、`~/.gitconfig` に Git の名前とメールアドレスが無ければ尋ねて書く。手で書くときは、`--global` ではなく `--file ~/.gitconfig` を使う。`~/.gitconfig` が無いと `git config --global` は `~/.config/git/config` に書き、そのファイルはこのリポジトリへのリンクなので、名前とメールアドレスがリポジトリに入ってしまう。

```sh
git config --file ~/.gitconfig user.name "<名前>"
git config --file ~/.gitconfig user.email "<メールアドレス>"
```

# コミット前の検査

`setup.sh` は、このリポジトリで `git config core.hooksPath .githooks` を実行して、`.githooks/pre-commit` を有効にする。このフックは、コミットの前にステージした変更を次の 2 つの方法で調べ、どちらかに当てはまればコミットを止める。

| 検査 | コミットを止める条件 |
| --- | --- |
| betterleaks（`Brewfile` で入る秘密情報の検出ツール） | トークンや鍵のような秘密情報が見つかること |
| `~/.config/dotfiles/deny-patterns.txt` | このファイルの正規表現に一致する文字列が、ステージした変更で追加した行か、ステージしたファイルのパスにあること |

`~/.config/dotfiles/deny-patterns.txt` には、社名やリポジトリ名のような仕事の識別子を、1 行に 1 つの拡張正規表現で書く。このファイル自体が仕事の情報なので、リポジトリには入れず、マシンごとに作る。betterleaks か `deny-patterns.txt` が無いと、フックはコミットを止める。
