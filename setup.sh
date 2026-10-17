#!/usr/bin/env bash
# macOS と Linux（WSL を含む）の開発環境を、このリポジトリの設定でそろえる。
# 各段階は、既に済んでいるかを先に調べ、済んでいれば何もしない。そのため何度実行してもよい。
#
# 使い方:
#   ./setup.sh              すべての段階を順に実行する
#   ./setup.sh link ruby    指定した段階だけを実行する
#
# 環境変数:
#   SETUP_DRY_RUN=1         パッケージの導入・ログインシェルの変更・システム設定の変更・Ruby のビルドを実行せず、実行するコマンドを表示する。
#                           ホームディレクトリの中のリンクと雛形のファイルは作る。
#   DOTFILES_RUBY_SCAN_DIR  .ruby-version を探すディレクトリ。既定は ~/workspace。
#   GIT_USER_NAME, GIT_USER_EMAIL  ~/.gitconfig に書く名前とメールアドレス。無ければ、ターミナルに入力を求める文を表示して受け取る。
#
# macOS の /bin/bash は 3.2 なので、連想配列や mapfile のような bash 4 以降の機能を使わない。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${SETUP_DRY_RUN:-0}"
RUBY_SCAN_DIR="${DOTFILES_RUBY_SCAN_DIR:-$HOME/workspace}"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
# コンテナの中では USER が設定されていないことがある。
USER="${USER:-$(id -un)}"

ALL_STAGES="prereqs homebrew brew_bundle link claude login_shell zshrc_local gitconfig hooks macos_hotkeys win32yank ruby"

IS_MAC=0
IS_LINUX=0
IS_WSL=0
case "$(uname -s)" in
  Darwin) IS_MAC=1 ;;
  Linux)
    IS_LINUX=1
    if grep -qi microsoft /proc/version 2>/dev/null; then
      IS_WSL=1
    fi
    ;;
  *)
    echo "setup.sh: この OS には対応していません: $(uname -s)" >&2
    exit 1
    ;;
esac

current_stage=""

stage_start() {
  current_stage="$1"
  printf '\n== %s ==\n' "$1"
}

did() {
  printf '[%s] 実行した: %s\n' "$current_stage" "$1"
}

# run_system を通した処理の結果を表示する。SETUP_DRY_RUN=1 のときは、実行していないことを表示する。
did_system() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '[%s] 実行していない (SETUP_DRY_RUN=1): %s\n' "$current_stage" "$1"
    return 0
  fi
  did "$1"
}

skipped() {
  printf '[%s] 飛ばした: %s\n' "$current_stage" "$1"
}

die() {
  printf '[%s] 失敗: %s\n' "$current_stage" "$1" >&2
  exit 1
}

# OS 全体を変えるコマンドは、この関数を通して実行する。SETUP_DRY_RUN=1 のときは表示だけする。
run_system() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '[%s] 実行しない (SETUP_DRY_RUN=1): %s\n' "$current_stage" "$*"
    return 0
  fi
  "$@"
}

brew_path() {
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

load_brew_env() {
  local brew
  if brew=$(brew_path); then
    eval "$("$brew" shellenv)"
  fi
}

stage_prereqs() {
  stage_start prereqs
  if [ "$IS_MAC" = "1" ]; then
    if xcode-select -p >/dev/null 2>&1; then
      skipped "Xcode Command Line Tools は入っている"
      return
    fi
    run_system xcode-select --install
    if [ "$DRY_RUN" = "1" ]; then
      return
    fi
    die "Xcode Command Line Tools のインストーラを開いた。インストールが終わったら、もう一度 ./setup.sh を実行してください"
  fi

  command -v apt-get >/dev/null 2>&1 || die "apt-get がありません。この Linux のディストリビューションには対応していません"
  # Homebrew on Linux が必要とするパッケージと、Ruby のビルドに要るライブラリと、win32yank.exe の展開に使う unzip。
  local packages="build-essential procps curl file git zsh python3 unzip libssl-dev libyaml-dev zlib1g-dev libffi-dev libreadline-dev"
  local missing="" package
  for package in $packages; do
    if ! dpkg -s "$package" >/dev/null 2>&1; then
      missing="$missing $package"
    fi
  done
  if [ -z "$missing" ]; then
    skipped "必要な apt のパッケージは入っている"
    return
  fi
  echo "[prereqs] apt でパッケージを入れるため、sudo がパスワードの入力を求めることがあります。"
  # shellcheck disable=SC2086 # パッケージ名を 1 つずつの引数に分けるため、意図して分割する。
  run_system sudo apt-get update && run_system sudo apt-get install -y $missing
  did_system "apt で入れた:$missing"
}

stage_homebrew() {
  stage_start homebrew
  if brew_path >/dev/null; then
    skipped "Homebrew は入っている ($(brew_path))"
  else
    if [ "$DRY_RUN" = "1" ]; then
      run_system /bin/bash -c "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash"
      return
    fi
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    did "Homebrew を入れた"
  fi
  load_brew_env
}

stage_brew_bundle() {
  stage_start brew_bundle
  if ! command -v brew >/dev/null 2>&1; then
    if [ "$DRY_RUN" = "1" ]; then
      run_system brew bundle --file="$REPO_DIR/Brewfile"
      return
    fi
    die "brew がありません。先に homebrew の段階を実行してください"
  fi
  # Homebrew は公式以外の tap のパッケージを、信頼すると明示しないと読み込まない。
  if [ "$(uname)" = Darwin ]; then
    run_system brew trust --cask terraform-linters/tap/tflint
  fi
  if brew bundle check --file="$REPO_DIR/Brewfile" >/dev/null 2>&1; then
    skipped "Brewfile のパッケージはすべて入っている"
    return
  fi
  run_system brew bundle --file="$REPO_DIR/Brewfile"
  did_system "Brewfile のパッケージを入れた"
}

# install.conf.yaml の link: に書いたリンクの置き場所を、1 行に 1 つずつ $HOME を展開して出す。
link_targets() {
  awk '
    /^- link:/ { in_link = 1; next }
    /^- / { in_link = 0 }
    in_link && /^    ~\// { sub(/:$/, "", $1); print $1 }
  ' "$REPO_DIR/install.conf.yaml" | sed "s|^~|$HOME|"
}

stage_link() {
  stage_start link
  # dotbot は既存の実ファイルを上書きしない設定にしているので、リンクの置き場所にある実ファイルは先に退避する。
  local target moved=0
  while IFS= read -r target; do
    if [ "$IS_MAC" != "1" ] && [ "$target" = "$HOME/.config/karabiner" ]; then
      continue
    fi
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "${target#"$HOME"/}")"
      mv "$target" "$BACKUP_DIR/${target#"$HOME"/}"
      echo "[link] 退避した: $target -> $BACKUP_DIR/${target#"$HOME"/}"
      moved=1
    fi
  done <<EOF
$(link_targets)
EOF
  if [ "$moved" = "0" ]; then
    echo "[link] 退避するファイルは無かった"
  fi
  "$REPO_DIR/install"
  did "dotbot でリンクを張った（既に張ってあるリンクは変えていない）"
}

stage_claude() {
  stage_start claude
  if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ]; then
    skipped "Claude Code は入っている"
    return
  fi
  run_system /bin/bash -c "curl -fsSL https://claude.ai/install.sh | bash"
  did_system "Claude Code を公式のインストーラで入れた"
}

login_shell_of_user() {
  if [ "$IS_MAC" = "1" ]; then
    dscl . -read "/Users/$USER" UserShell | awk '{print $2}'
  else
    getent passwd "$USER" | cut -d: -f7
  fi
}

stage_login_shell() {
  stage_start login_shell
  local zsh_path current
  zsh_path="$(command -v zsh)" || die "zsh がありません"
  current="$(login_shell_of_user)"
  if [ "$(basename "$current")" = "zsh" ]; then
    skipped "ログインシェルは zsh ($current)"
    return
  fi
  if ! grep -qx "$zsh_path" /etc/shells; then
    echo "[login_shell] $zsh_path を /etc/shells に足すため、sudo がパスワードの入力を求めることがあります。"
    run_system sudo sh -c "echo '$zsh_path' >> /etc/shells"
  fi
  if [ "$IS_LINUX" = "1" ]; then
    run_system sudo chsh -s "$zsh_path" "$USER"
  else
    run_system chsh -s "$zsh_path"
  fi
  did_system "ログインシェルを $current から $zsh_path に変えた"
}

stage_zshrc_local() {
  stage_start zshrc_local
  local file="$HOME/.zshrc.local"
  if [ -e "$file" ]; then
    skipped "$file はある"
    return
  fi
  (
    umask 077
    cat > "$file" <<'EOF'
# このマシンだけで使う zsh の設定。~/.zshrc の最後で読み込まれる。
# トークンのような秘密情報と、仕事用の環境変数・alias はここに書く。このファイルは dotfiles リポジトリに入れない。
#
# 例:
# export ATLASSIAN_SITE="<Confluence のサイトのホスト名>"
EOF
  )
  chmod 600 "$file"
  did "$file の雛形を作った"
}

ask() {
  local prompt="$1" env_value="$2" answer
  if [ -n "$env_value" ]; then
    printf '%s\n' "$env_value"
    return 0
  fi
  if [ ! -t 0 ]; then
    return 1
  fi
  read -r -p "$prompt" answer
  [ -n "$answer" ] || return 1
  printf '%s\n' "$answer"
}

stage_gitconfig() {
  stage_start gitconfig
  # git config --global は、~/.gitconfig が無いと ~/.config/git/config に書く。
  # ~/.config/git はこのリポジトリへのリンクなので、名前とメールアドレスがリポジトリに入らないよう ~/.gitconfig を明示する。
  local file="$HOME/.gitconfig" key value prompt env_value
  for key in user.name user.email; do
    if git config --file "$file" --get "$key" >/dev/null 2>&1; then
      skipped "$file に $key はある"
      continue
    fi
    if [ "$key" = "user.name" ]; then
      prompt="Git の名前: "
      env_value="${GIT_USER_NAME:-}"
    else
      prompt="Git のメールアドレス: "
      env_value="${GIT_USER_EMAIL:-}"
    fi
    if ! value=$(ask "$prompt" "$env_value"); then
      skipped "$key の入力を受け取れなかった（端末から実行していない）。後で git config --file ~/.gitconfig $key <値> を実行してください"
      continue
    fi
    git config --file "$file" "$key" "$value"
    did "$file に $key を書いた"
  done
}

stage_hooks() {
  stage_start hooks
  if [ "$(git -C "$REPO_DIR" config --get core.hooksPath || true)" = ".githooks" ]; then
    skipped "core.hooksPath は .githooks になっている"
    return
  fi
  git -C "$REPO_DIR" config core.hooksPath .githooks
  did "core.hooksPath を .githooks にした"
}

# 操作スペースを左右に切り替えるショートカット（Ctrl+← が 79、Ctrl+→ が 81）が無効になっているかを返す。
hotkeys_disabled() {
  defaults export com.apple.symbolichotkeys - 2>/dev/null | python3 -c '
import plistlib, sys
try:
    keys = plistlib.loads(sys.stdin.buffer.read()).get("AppleSymbolicHotKeys", {})
except Exception:
    sys.exit(1)
sys.exit(0 if all(keys.get(k, {}).get("enabled") is False for k in ("79", "81")) else 1)
'
}

stage_macos_hotkeys() {
  stage_start macos_hotkeys
  if [ "$IS_MAC" != "1" ]; then
    skipped "macOS ではない"
    return
  fi
  if hotkeys_disabled; then
    skipped "Ctrl+←/→ の操作スペース切り替えは無効になっている"
    return
  fi
  # WezTerm でタブの切り替えに Ctrl+←/→ を使うので、macOS がこのキーを先に取らないようにする。
  # parameters の 3 つの値は、文字コード（使わないので 65535）、キーコード（← が 123、→ が 124）、修飾キー（Ctrl と矢印キーの組み合わせ）を表す。
  run_system defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 \
    '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>123</integer><integer>8650752</integer></array><key>type</key><string>standard</string></dict></dict>'
  run_system defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 \
    '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>124</integer><integer>8650752</integer></array><key>type</key><string>standard</string></dict></dict>'
  # defaults write だけでは再ログインまで反映されないので、設定を読み直させる。
  run_system /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  did_system "Ctrl+←/→ の操作スペース切り替えを無効にした"
}

stage_win32yank() {
  stage_start win32yank
  if [ "$IS_WSL" != "1" ]; then
    skipped "WSL ではない"
    return
  fi
  if command -v win32yank.exe >/dev/null 2>&1 || [ -x "$HOME/.local/bin/win32yank.exe" ]; then
    skipped "win32yank.exe は入っている"
    return
  fi
  if [ "$DRY_RUN" = "1" ]; then
    run_system curl -fsSL https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
    return
  fi
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/win32yank.zip" https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
  unzip -q -o "$tmp/win32yank.zip" win32yank.exe -d "$tmp"
  mkdir -p "$HOME/.local/bin"
  install -m 755 "$tmp/win32yank.exe" "$HOME/.local/bin/win32yank.exe"
  rm -rf "$tmp"
  did "win32yank.exe を ~/.local/bin に入れた"
}

# $RUBY_SCAN_DIR とその 1 つ下のディレクトリにある .ruby-version から、Ruby のバージョンを重複なく出す。
ruby_versions_wanted() {
  find "$RUBY_SCAN_DIR" -maxdepth 2 -name .ruby-version -type f 2>/dev/null |
    while IFS= read -r file; do
      head -n 1 "$file" | tr -d '[:space:]' | sed 's/^ruby-//'
      echo
    done | grep -v '^$' | sort -u
}

stage_ruby() {
  stage_start ruby
  if [ ! -d "$RUBY_SCAN_DIR" ]; then
    skipped "$RUBY_SCAN_DIR が無い"
    return
  fi
  local wanted installed="" version
  wanted="$(ruby_versions_wanted || true)"
  if [ -z "$wanted" ]; then
    skipped "$RUBY_SCAN_DIR に .ruby-version が無い"
    return
  fi
  if command -v rbenv >/dev/null 2>&1; then
    installed="$(rbenv versions --bare 2>/dev/null || true)"
  elif [ "$DRY_RUN" != "1" ]; then
    die "rbenv がありません。先に brew_bundle の段階を実行してください"
  fi
  echo "[ruby] .ruby-version に書かれたバージョン: $(printf '%s' "$wanted" | tr '\n' ' ')"
  while IFS= read -r version; do
    if printf '%s\n' "$installed" | grep -qx "$version"; then
      skipped "Ruby $version は入っている"
      continue
    fi
    run_system rbenv install -s "$version"
    did_system "Ruby $version を入れた"
  done <<EOF
$wanted
EOF
}

main() {
  local stages="$*" stage
  if [ -z "$stages" ]; then
    stages="$ALL_STAGES"
  fi
  for stage in $stages; do
    case " $ALL_STAGES " in
      *" $stage "*) ;;
      *)
        echo "setup.sh: 段階の名前が違います: $stage（使える名前: $ALL_STAGES）" >&2
        exit 2
        ;;
    esac
  done

  if [ "$DRY_RUN" = "1" ]; then
    echo "SETUP_DRY_RUN=1: OS 全体を変えるコマンドは実行せず、表示だけします。"
  fi
  load_brew_env
  for stage in $stages; do
    "stage_$stage"
  done
  printf '\nsetup.sh: 終わりました。\n'
}

main "$@"
