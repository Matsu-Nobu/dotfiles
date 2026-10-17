# Neovim設定（NvChad ベース）

[NvChad](https://nvchad.com/)をベースに、カスタマイズした個人用Neovim設定です。

## 目次

- [プロジェクト構成](#プロジェクト構成)
- [プラグイン追加方法](#プラグイン追加方法)
- [Mason ツール管理](#mason-ツール管理)
- [主要機能](#主要機能)
- [セットアップ](#セットアップ)

## プロジェクト構成

```
nvim/
├── init.lua                      # Neovimのエントリーポイント
│                                  # lazy.nvimのブートストラップとプラグイン読み込み
├── lua/
│   ├── chadrc.lua               # NvChadの基本設定
│   │                             # - テーマの選択
│   │                             # - UI設定（tabuflineなど）
│   │                             # - ハイライトオーバーライド
│   │
│   ├── custom/
│   │   └── chadrc.lua           # カスタムカラースキーム管理
│   │                             # スキームプラグインの自動生成
│   │
│   ├── data/                    # データファイル
│   │   └── mason-tools.lua      # Masonツールリスト（言語別）
│   │
│   ├── configs/                 # プラグイン別の設定ファイル
│   │   ├── lspconfig.lua        # LSP（Language Server Protocol）の設定
│   │   ├── conform.lua          # コードフォーマッターの設定
│   │   ├── cmp.lua              # 補完エンジンの設定
│   │   ├── lazy.lua             # lazy.nvim自体の設定
│   │   └── auto-session.lua     # セッション管理の設定
│   │
│   ├── plugins/                 # プラグイン定義（カテゴリ別）
│   │   ├── init.lua             # メインプラグイン
│   │   │                         # - LSP/DAP
│   │   │                         # - コードフォーマッター
│   │   │                         # - 補完
│   │   │                         # - コード編集支援（surround等）
│   │   │
│   │   ├── mason.lua            # Mason関連プラグイン
│   │   ├── session/             # セッション管理関連
│   │   ├── ui/                  # UI拡張
│   │   │                         # - ステータスラインカスタマイズ
│   │   │                         # - 通知表示改善
│   │   │                         # - インデント可視化
│   │   │
│   │   ├── finder/              # ファイル・テキスト検索
│   │   │                         # - Telescope（メイン検索ツール）
│   │   │
│   │   ├── git/                 # Git統合
│   │   │                         # - gitsigns
│   │   │                         # - diffview
│   │   │                         # - git-conflict
│   │   │
│   │   └── markdown/            # Markdown関連
│   │
│   ├── mappings.lua             # キーマッピング定義
│   │                             # すべてのキーバインドをここに集約
│   │
│   ├── options.lua              # Neovimオプション設定
│   │                             # タブ、スペース、シンタックスハイライトなど
│   │
│   └── highlights.lua           # ハイライト設定
│                                  # カラースキームのカスタマイズ
│
├── lazy-lock.json               # プラグインのバージョン管理（自動生成）
├── .stylua.toml                 # Luaコードのフォーマッター設定
└── LICENSE
```

### 各ファイルの役割

| ファイル | 役割 |
|---------|------|
| `init.lua` | Neovim起動時の処理、lazy.nvimのセットアップ、プラグイン読み込み |
| `lua/chadrc.lua` | NvChad UIフレームワークの基本設定 |
| `lua/custom/chadrc.lua` | カスタムカラースキーム定義 |
| `lua/data/mason-tools.lua` | Masonで管理するツールのリスト |
| `lua/configs/*.lua` | 各プラグインの詳細設定 |
| `lua/plugins/*.lua` | プラグインの定義と軽量な設定 |
| `lua/mappings.lua` | すべてのキーバインド定義 |
| `lua/options.lua` | Neovimのエディタオプション |
| `lua/highlights.lua` | UI要素のハイライト設定 |

## プラグイン追加方法

### 基本的な流れ

プラグイン管理は **lazy.nvim** で行われています。新しいプラグインは以下の手順で追加できます：

1. **プラグイン定義ファイルの作成・編集**
2. **必要に応じて設定ファイル作成**（`lua/configs/`配下）
3. **キーマッピング追加**（`lua/mappings.lua`で）

### パターン1: シンプルなプラグインの追加

設定不要なプラグインは、以下のように簡潔に定義できます。

`lua/plugins/my-simple-plugin.lua`を作成：

```lua
return {
  {
    "plugin-author/plugin-name",
    lazy = false,  -- 起動時にロード。必要に応じて true に
  },
}
```

**init.lua** の `lazy_plugins` テーブルに以下を追加：

```lua
{ import = "plugins.my-simple-plugin" },
```

### パターン2: 設定が必要なプラグインの追加

プラグインに細かい設定が必要な場合は、設定ファイルを分けます。

`lua/plugins/my-configured-plugin.lua`を作成：

```lua
return {
  {
    "plugin-author/plugin-name",
    lazy = false,
    config = function()
      require "configs.my-configured-plugin"  -- 設定を外部ファイルから読み込む
    end,
  },
}
```

`lua/configs/my-configured-plugin.lua`を作成：

```lua
local options = {
  option1 = true,
  option2 = "value",
}

require("plugin-name").setup(options)
```

### パターン3: 依存関係があるプラグイン

複数のプラグインを組み合わせる場合：

```lua
return {
  {
    "main-plugin/name",
    dependencies = {
      "dependency-plugin/name",
      "another-dependency/name",
    },
    config = function()
      require "configs.my-plugin"
    end,
  },
}
```

### パターン4: カテゴリごとの分類

関連するプラグインをまとめたい場合は、ディレクトリを作成できます。

例：新しく「UI」カテゴリのプラグインを作りたい場合

1. `lua/plugins/my-ui/`ディレクトリを作成
2. `lua/plugins/my-ui/init.lua`にプラグイン定義を記述
3. **init.lua** に以下を追加：

```lua
{ import = "plugins.my-ui" },
```

すると、`lua/plugins/my-ui/`配下のすべてのモジュールが読み込まれます。

### パターン5: カラースキームの追加

カラースキームを追加する場合は特殊な方法で行います。

`lua/custom/chadrc.lua`の `M.schemes` テーブルに追加：

```lua
M.schemes = {
  ["onedark"] = {
    plugin = "navarasu/onedark.nvim",
    setup = function()
      require("onedark").setup({ transparent = true })
      vim.cmd("colorscheme onedark")
    end,
  },
  ["myscheme"] = {  -- ← 新しいスキーム
    plugin = "author/myscheme.nvim",
    setup = function()
      require("myscheme").setup({ ... })
      vim.cmd("colorscheme myscheme")
    end,
  },
}
```

その後、使用するスキームを選択：

```lua
M.colorscheme = "myscheme"  -- ← これを変更
```

プラグインリストは自動生成されるため、手動で `plugins` に追加する必要はありません。

### キーマッピングの追加

`lua/mappings.lua`にキーバインドを追加します：

```lua
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- 例：新しいプラグインのコマンド
map("n", "<leader>ps", function()
  require("my-plugin").do_something()
end, opts)
```

## Mason ツール管理

この設定では [mason.nvim](https://github.com/williamboman/mason.nvim) を使用して、LSPサーバー、フォーマッター、リンターを管理しています。

### ツールリストの設定

すべてのツールは `lua/data/mason-tools.lua` で言語ごとに宣言的に管理されています：

```lua
return {
  lua = {
    lsp = { "lua_ls" },
    formatters = { "stylua" },
  },
  typescript = {
    lsp = { "typescript-language-server", "biome" },
    formatters = { "biome" },
    linters = { "biome" },
  },
  -- ... 他の言語
}
```

### ツールのインストール

ツールは起動時に**自動インストールされません**（起動速度を保つため）。必要に応じて手動でインストールしてください：

```vim
:MasonToolsInstall    " リストにある不足ツールをインストール
:MasonToolsUpdate     " すべてのツールを更新
:MasonToolsClean      " リストにないツールを削除
```

Mason UIを使用することもできます：

```vim
:Mason    " 対話的なMasonインターフェースを開く
```

### 新しいツールの追加

1. `lua/data/mason-tools.lua` を編集
2. 適切な言語セクションにツールを追加
3. `:MasonToolsInstall` を実行して新しいツールをインストール

例：

```lua
-- 新しい言語を追加
golang = {
  lsp = { "gopls" },
  formatters = { "gofumpt" },
  linters = { "golangci-lint" },
},
```

## 主要機能

### NvChad フレームワーク
- 視覚的に洗練されたUIベース
- 多くの有用なプラグイン統合
- カスタマイズ可能なテーマ

### LSP（Language Server Protocol）統合
- 言語サーバーによるコード補完、定義ジャンプ、リファクタリング
- Mason経由で言語サーバーを宣言的に管理

### プラグインマネージャー（lazy.nvim）
- 遅延ロード対応で起動時間を最小化
- 簡潔なプラグイン定義
- 自動更新機能

### Mason
- LSP（言語サーバー）、DAP（デバッガー）、Linter、Formatterの一元管理
- 設定ファイルで宣言的に管理（`lua/data/mason-tools.lua`）
- `:Mason`コマンドで対話的にインストール・管理

## セットアップ

### 必要な環境

- Neovim 0.9以上
- Git
- curl（プラグインダウンロード用）

### インストール

1. このリポジトリをNeovimの設定ディレクトリにクローン：

```bash
git clone https://github.com/momonga/nvim ~/.config/nvim
```

2. Neovimを起動：

```bash
nvim
```

Lazy.nvimが自動的にプラグインをインストールします。初回起動時は少し時間がかかります。

### LSP・ツールのセットアップ

必要な開発ツールをインストール：

```vim
:MasonToolsInstall
```

または、Mason UIから個別にインストール：

```vim
:Mason
```

---

**参考**
- [NvChad ドキュメント](https://nvchad.com/)
- [lazy.nvim ドキュメント](https://github.com/folke/lazy.nvim)
- [mason.nvim ドキュメント](https://github.com/williamboman/mason.nvim)
