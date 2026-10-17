# macOS と Ubuntu

GitHub CLI を入れる。macOS では [Homebrew](https://brew.sh/) を入れてから `brew install gh` を、Ubuntu では `sudo apt install gh` を実行する。そのあと、次を実行する。

```sh
gh auth login
gh repo clone <GitHub のユーザー名>/dotfiles ~/dotfiles
~/dotfiles/setup.sh
```

`setup.sh` は、`~/.gitconfig` に Git の名前とメールアドレスが無ければ、ターミナルに入力を求める文を表示し、入力された値を `~/.gitconfig` に記入する。`setup.sh` は終えた処理を次の実行で飛ばすので、何度実行してもよい。仕事のリポジトリを `~/workspace` に clone した後にもう一度実行すると、各リポジトリの `.ruby-version` に記載された Ruby が入る。

`~/.gitconfig` に手で記入するときは、`git config --file ~/.gitconfig` を使う。`~/.gitconfig` が無いときに `git config --global` を使うと、このリポジトリの `git/config` に記入されてしまう。

# Windows

PowerShell で次を実行する。`setup.ps1` は、WSL の Ubuntu の中で、上の節の clone と `setup.sh` の実行も行う。

```powershell
winget install --id GitHub.cli --exact
gh auth login
Invoke-WebRequest -Headers @{ Authorization = "token $(gh auth token)"; Accept = "application/vnd.github.raw" } -Uri https://api.github.com/repos/<GitHub のユーザー名>/dotfiles/contents/windows/setup.ps1 -OutFile setup.ps1
powershell -ExecutionPolicy Bypass -File setup.ps1 -Repo <GitHub のユーザー名>/dotfiles
```

WSL を初めて入れたときは、`setup.ps1` が再起動を求める文を表示して終了する。Windows を再起動し、スタートメニューから Ubuntu を開いてユーザーを作る。そのあと、`setup.ps1` を保存したディレクトリで、最後の行の `powershell -ExecutionPolicy Bypass -File setup.ps1 ...` をもう一度実行する。

# 手で用意するファイル

次のファイルは、ホームディレクトリに手で作る。Windows では、WSL の Ubuntu のホームディレクトリに作る。

| ファイル | 用意するマシン | 記入すること |
| --- | --- | --- |
| `~/.zshrc.local` | すべて | 秘密情報と、仕事用の環境変数・alias。無ければ `setup.sh` が空のファイルを作る |
| `~/.config/dotfiles/deny-patterns.txt` | このリポジトリにコミットするマシン | コミットに含めてはいけない勤め先の名前・社内のリポジトリ名・個人名を、1 行に 1 つの正規表現で記入する。このファイルが無いと、コミットの前に動く Git のフックがコミットを止める |
| `~/.claude/work-settings.json` | 仕事用のマシン | リポジトリに入れない、仕事用の Claude Code の設定（許可するコマンドや自動モードの規則）。`~/.zshrc.local` に `alias claude='claude --settings ~/.claude/work-settings.json'` と記入すると、Claude Code がこのファイルを読む |
