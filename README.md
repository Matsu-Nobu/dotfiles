# 概要

このリポジトリには、松山の開発環境の設定ファイルを置く。`setup.sh` は、`Brewfile` に書いたコマンドを Homebrew で入れ、ホームディレクトリの各所からこのリポジトリのファイルへシンボリックリンクを張る。リンクを張る場所とリポジトリのファイルの対応は `install.conf.yaml` に書いてあり、`setup.sh` は、その対応どおりにリンクを張るツール [dotbot](https://github.com/anishathalye/dotbot) を使う。

トークンのような秘密情報と仕事用の設定は、このリポジトリに入れない。それらは各マシンの `~/.zshrc.local` に書く（「手で書くファイル」の節を参照）。

# 含まれる設定

| ディレクトリ・ファイル | リンクを張る場所 | 内容 |
| --- | --- | --- |
| `zsh/.zshrc` | `~/.zshrc` | zsh の設定 |
| `zsh/aliases/` | `~/.config/zsh/aliases` | alias を書いたファイル。zsh の起動時に、プラグイン管理の sheldon がこのディレクトリの `*.zsh` を読み込む |
| `sheldon/` | `~/.config/sheldon` | sheldon が読み込む zsh のプラグインの一覧 |
| `starship.toml` | `~/.config/starship.toml` | プロンプトを表示する starship の設定 |
| `fzf/.fzf.zsh` | `~/.fzf.zsh` | あいまい検索で候補を選ぶ fzf の設定と、fzf を使う関数 |
| `direnv/` | `~/.config/direnv` | ディレクトリごとに環境変数を切り替える direnv の設定 |
| `wezterm/` | `~/.config/wezterm` | 端末の WezTerm の設定 |
| `nvim/` | `~/.config/nvim` | Neovim の設定 |
| `git/` | `~/.config/git` | Git の alias と、すべてのリポジトリで Git に無視させるファイル名の一覧（`git/ignore`） |
| `gh/config.yml` | `~/.config/gh/config.yml` | GitHub CLI の設定 |
| `karabiner/` | `~/.config/karabiner` | Karabiner-Elements の設定。`setup.sh` は macOS のときだけリンクを張る |
| `bin/task` | `~/bin/task` | Obsidian のノートを置くフォルダ（`~/workspace/obsidian`）に、タスクのファイルを作り、タスクの一覧を表示するコマンド |
| `claude/` | `install.conf.yaml` に書いた `~/.claude/` の中の各ファイル | Claude Code の指示・規則・フック・設定 |
| `windows/` | なし | Windows 用のセットアップスクリプト `setup.ps1` と、`%USERPROFILE%\.wezterm.lua` の雛形 `wezterm.lua` |

`setup.sh` は、`claude/` については `~/.claude/` ディレクトリごとではなく、`install.conf.yaml` に書いたファイルとディレクトリに 1 つずつリンクを張る。`~/.claude/skills/` と `~/.claude/commands/` には、このリポジトリに入れないスキルとコマンドもマシンごとに置くからである。

# macOS と Linux のセットアップ

GitHub CLI で GitHub にログインしてから、このリポジトリを clone して `setup.sh` を実行する。GitHub CLI は、macOS では Homebrew を[公式の手順](https://brew.sh/)で入れてから `brew install gh` で、Linux では `sudo apt install gh` で入れる。

```sh
gh auth login
gh repo clone <GitHub のユーザー名>/dotfiles ~/dotfiles
~/dotfiles/setup.sh
```

`setup.sh` は、次の順に実行する。既に済んでいる段階は飛ばすので、`setup.sh` は何度実行してもよい。

1. macOS では Xcode Command Line Tools を、Linux では Homebrew が必要とするパッケージを apt で入れる。
2. Homebrew を入れ、`Brewfile` に書いたコマンドを入れる。
3. リンクを張る。リンクを張る場所に既にファイルがあれば、そのファイルを `~/.dotfiles-backup/<日時>/` に移してから張る。
4. Claude Code を入れる。
5. ログインシェルを zsh に変える。
6. `~/.zshrc.local` が無ければ雛形を作る。`~/.gitconfig` に Git の `user.name` と `user.email` が無ければ、尋ねて書く。
7. このリポジトリのコミット前の検査を有効にする。
8. macOS では、Ctrl+←/→ に割り当てられた操作スペースの切り替えを無効にする。WezTerm がこのキーでタブを切り替えるからである。
9. WSL の Ubuntu では、Windows のクリップボードを使うための win32yank.exe を入れる。
10. Ruby を入れる。

Ruby の段階では、`setup.sh` は `~/workspace` と、その 1 つ下のディレクトリにある `.ruby-version` を探し、そこに書かれたバージョンを `rbenv` で入れる。そのため、仕事のリポジトリを `~/workspace` の下に clone した後に `~/dotfiles/setup.sh` をもう一度実行すると、必要な Ruby が入る。

`Brewfile` には、WezTerm の正式版ではなく開発版を書いてある。2024 年 2 月の正式版は、macOS 26 で Claude Code の通知を表示できないからである。

# Windows のセットアップ

Windows では、zsh や Neovim などは、Windows の中で Linux を動かす仕組みの WSL（バージョン 2）で動かす Ubuntu の中に入れ、Windows には WezTerm とフォントだけを入れる。`windows/setup.ps1` は、WSL と Ubuntu、WezTerm の開発版、フォントの Hack Nerd Font Mono と HackGen Console NF を入れ、Ubuntu の中で `~/dotfiles` を clone して `setup.sh` を実行する。最後に、`windows/wezterm.lua` の `__WSL_USER__` を Ubuntu のユーザー名に置き換えて `%USERPROFILE%\.wezterm.lua` に書き出す。Windows の WezTerm は、このファイルを通して Ubuntu の中の `~/dotfiles/wezterm` の設定を読む。

このリポジトリは private なので、`setup.ps1` を取得する前に Windows の GitHub CLI でログインする。PowerShell で次を実行する。

```powershell
winget install --id GitHub.cli --exact
gh auth login
Invoke-WebRequest -Headers @{ Authorization = "token $(gh auth token)"; Accept = "application/vnd.github.raw" } -Uri https://api.github.com/repos/<GitHub のユーザー名>/dotfiles/contents/windows/setup.ps1 -OutFile setup.ps1
powershell -ExecutionPolicy Bypass -File setup.ps1 -Repo <GitHub のユーザー名>/dotfiles
```

WSL を初めて入れたときは、`setup.ps1` が再起動を求めて終わる。再起動して Ubuntu のユーザーを作ってから、上のコードブロックの最後の行（`powershell -ExecutionPolicy Bypass ...`）をもう一度実行する。`setup.ps1` は、Ubuntu の中で clone する前に Ubuntu の中で `gh auth login` を実行するので、表示される案内に従って GitHub にログインする。

Windows でも macOS と同じく、Claude Code のフックが送った通知を WezTerm が表示する。Windows で表示されるかは、実機ではまだ確認していない。

# 手で書くファイル

## ~/.zshrc.local

zsh は、`~/.zshrc` の最後の行で、`~/.zshrc.local` があればそのファイルを読み込む。仕事用の環境変数・alias・トークンは、このファイルに `export` や `alias` で書く。`setup.sh` は、このファイルが無ければ、他のユーザーが読めない権限（600）で空の雛形を作る。

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
