# ツール CLI 規約

エコシステムの 3 つの Elixir CLI ツール — **registry-manager** /
**thesis-monitor** / **ecosystem-manager** — が共有するコマンド体系の正準定義。
読者はエコシステムの維持運用者を想定する。

3 ツールは共通基盤ライブラリ
[smkwlab/elixir-tool-kit](https://github.com/smkwlab/elixir-tool-kit) の
CLI エンジン上に実装されている。アーキテクチャ上の位置づけは
[ECOSYSTEM.md](../ECOSYSTEM.md) の「ツール CLI 規約」を参照。

## 体系の骨格

- **宣言的 spec**: 各ツールはオプションカタログ(名前・型・短フラグ・enum・
  説明)とコマンド表(usage・summary・コマンド別オプション・例)を
  `<Tool>.CLI.Spec` モジュールに単一情報源として持つ
- **strict パース**: spec に無いオプション、enum 違反、コマンドに属さない
  オプションはすべてパース段階のエラー(exit 1)
- **help の自動生成**: `--help`(全体)と `<command> --help`(コマンド別)は
  spec から生成される。help を手で編集することはない
- **デフォルトコマンド**: thesis-monitor と ecosystem-manager はサブコマンド
  省略時に `status` を実行する
- **exit code**: 成功 0 / エラー 1

## 正準オプション語彙

同じフラグは全ツールで同じ意味を持つ。ツール列は そのフラグを持つツール
(rm = registry-manager、tm = thesis-monitor、em = ecosystem-manager)。

### グローバルオプション

| フラグ | 意味 | ツール |
|---|---|---|
| `-h`, `--help` | ヘルプを表示 | rm / tm / em |
| `-v`, `--verbose` | 詳細ログを表示 | rm / tm |
| `-c`, `--config` | 設定ファイルのパスを上書き | rm / tm |
| `--version` | バージョン情報を表示(long のみ) | tm |
| `--registry-repo` | registry_repo を上書き(owner/repo) | rm / tm(init) |
| `--org` | 対象の GitHub organization | rm / tm(init) |
| `-w`, `--workspace` | 対象ワークスペース名 | em |

### 共有語彙(コマンド別オプション)

| フラグ | 意味 | ツール |
|---|---|---|
| `--format table\|csv\|json` | 出力形式(**long のみ**) | rm / tm |
| `--type` | リポジトリタイプで絞り込み(enum 検証) | rm / tm |
| `-l`, `--long` | 詳細表示 | rm / tm / em |
| `-t` | 時刻順ソート | rm / tm(短縮形のみ・long なし)/ em(`--time-sort` の短縮形) |
| `-r`, `--reverse` | ソート順を反転 | rm / tm |
| `--no-cache` | キャッシュを使用しない | rm / tm / em |
| `-d`, `--dry-run` | 実際の変更を行わない | rm |
| `-f`, `--force` | 確認スキップ / 既存を上書き | rm / tm(init: long のみ) |
| `--fast` | GitHub API を呼ばない高速モード(long のみ) | em |

### 予約

- **`-f` は force に予約**する。`--format` と `--fast` に短縮形はない
- **`-v` は verbose**。バージョン表示は `--version`(long のみ)または
  `version` コマンド

## ライブラリの提供モジュールと責務境界

| モジュール | 機構 |
|---|---|
| `ToolKit.CLI.Spec` / `Parser` / `Exit` | spec からの導出(strict switches / 検証 / help)・パースパイプライン・exit 規律 |
| `ToolKit.Output.TextWidth` / `Table` / `CSV` | East Asian 表示幅計算・幅対応テーブル描画・CSV エスケープ |
| `ToolKit.Config.Layers` | 4 層マージ(defaults ⊕ YAML ⊕ env ⊕ CLI)・org 派生などの規約ヘルパ |
| `ToolKit.GitHub.Client` | Req ベースの REST ラッパ(token はプロバイダ注入、既定は `gh auth token`) |
| `ToolKit.Cache` | カテゴリ + TTL のファイルキャッシュと `get_or_fetch/3` |

コマンド語彙・位置引数の解釈・設定スキーマ・ドメインロジック・出力の印字は
各ツールの責務である(機構はライブラリ、方針はツール)。

## 依存の張り方

ツールは elixir-tool-kit を git 依存の semver タグ固定で参照する:

```elixir
{:tool_kit, github: "smkwlab/elixir-tool-kit", tag: "vX.Y.Z"}
```

- タグは semver。ライブラリの変更は新タグとして発行する
- 採用側は PR で明示的に pin を上げる。`mix.lock` の commit hash が再現性を
  担保する
- ブランチ参照は使わない

## 実装・テスト規約

CLI 体系の採用に伴って 3 ツールが共有する実装上の規約:

- CLI の exit 検証: 各ツールの test_helper が
  `Application.put_env(:<app>, :test_mode, true)` を設定し、テストは
  `catch_throw(... ) == {:cli_test_exit, code}` で検証する
- dialyzer の no_return 抑制は構造化形式 `dialyzer.ignore-warnings.exs`
  (`{"path", :warning_type}` のタプル)で行う
