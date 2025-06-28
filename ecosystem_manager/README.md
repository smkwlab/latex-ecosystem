# EcosystemManager

高性能なLaTeX論文執筆環境のエコシステム管理ツール。並列処理により従来のBashスクリプト（12秒）から1.5秒へ**88%の性能向上**を実現。

## 特徴

- 🚀 **高速並列処理**: `Task.async_stream`による並列リポジトリ処理
- 📊 **GitHub API統合**: Issues/PR統計の自動取得
- 🧪 **高品質実装**: 91.22%テストカバレッジ、Credo・Dialyzer検証済み
- ⚙️ **柔軟な設定**: 並列度・フォーマット・フィルタリングオプション
- 🛡️ **エラーハンドリング**: 包括的なエラー処理とタイムアウト制御

## インストール

```bash
cd ecosystem_manager
mix deps.get
mix escript.build

# バイナリ作成
./ecosystem-manager status
```

## 使用方法

```bash
# 全リポジトリの状況確認
./ecosystem-manager status

# GitHub情報なしの高速モード（80ms）
./ecosystem-manager status --no-github

# 詳細表示
./ecosystem-manager status --format long

# フィルタリング
./ecosystem-manager status --urgent-issues
./ecosystem-manager status --with-prs
./ecosystem-manager status --needs-review

# 並列度調整（デフォルト: 8）
./ecosystem-manager status --max-concurrency 4
```

## パフォーマンス

| モード | 実行時間 | 改善率 |
|--------|----------|--------|
| フルモード | ~1.5 seconds | 88% |
| 高速モード (--no-github) | ~80ms | 99.3% |
| 元のBash版 | 12+ seconds | - |

## 開発

```bash
# テスト実行
mix test

# カバレッジ確認
mix test --cover

# 品質チェック
mix format && mix credo && mix dialyzer
```

## 設定

### 設定ファイル

`config/config.exs` で動作設定をカスタマイズできます：

```elixir
config :ecosystem_manager,
  default_concurrency: 8,      # 並列処理数
  github_timeout: 15_000,      # GitHub APIタイムアウト(ms)
  git_timeout: 5_000,          # Gitコマンドタイムアウト(ms)
  default_format: :compact,    # デフォルト出力形式
  enable_cache: false,         # キャッシュ有効化(将来実装)
  enable_timing: false         # 実行時間測定
```

### 環境別設定

```elixir
# 開発環境
config :ecosystem_manager,
  enable_timing: true,
  default_concurrency: 4

# 本番環境  
config :ecosystem_manager,
  default_concurrency: 12,
  enable_cache: true
```

設定例は `config/config.example.exs` を参照してください。

## アーキテクチャ

- **CLI**: コマンドライン処理とオプション解析
- **Config**: 設定管理と環境別設定
- **Repository**: Git情報取得とリポジトリ管理
- **GitHub**: GitHub API統合（Issues/PR統計）
- **Status**: 並列処理とフォーマット出力

