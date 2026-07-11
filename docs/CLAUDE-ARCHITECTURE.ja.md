# エコシステムアーキテクチャガイド

> 🌐 English version: [CLAUDE-ARCHITECTURE.md](CLAUDE-ARCHITECTURE.md)

このドキュメントでは、LaTeX 卒業論文環境エコシステムのアーキテクチャ、依存関係、連携パターンについて説明します。

## アーキテクチャ概要

### 依存チェーン
- **texlive-ja-textlint** → **latex-environment** → **テンプレート群**
- **サポートツール** はテンプレートおよび環境と統合される
- **管理ツール** はエコシステム全体を連携させる

### バージョン連携
- 各リポジトリは独立したバージョン管理を行う
- 互換性マトリクスは ECOSYSTEM.md に記載される
- 適切な箇所では更新チェーンを自動化する

### 学生ワークフロー
- 学生は自動化ツールを使ってリポジトリを作成する
- 管理上のオーバーヘッドのないクリーンなテンプレートを受け取る
- 教員はレビュー用ワークフローを指導に活用する

## Git リポジトリの境界

### 管理リポジトリの構造
```
latex-ecosystem/                 # この管理リポジトリ
├── .git/                       # 管理ファイル専用の Git
├── ECOSYSTEM.md                # 追跡対象 - エコシステム概要
├── README.md                   # 追跡対象 - リポジトリ概要
├── setup.sh                    # 追跡対象 - エコシステムセットアップスクリプト
├── ecosystem_manager/          # 追跡対象 - 連携ツール (Elixir escript)
├── CLAUDE.md                   # 追跡対象 - このファイル
├── .claude/                    # 追跡対象 - claude 設定
├── docs/                       # 追跡対象 - エコシステムドキュメント
│   ├── CLAUDE-ARCHITECTURE.md  # このファイル
│   └── CLAUDE-WORKFLOWS.md     # ワークフロー例
│
├── latex-environment/          # 独立したリポジトリ
│   ├── .git/                  # 別個の Git リポジトリ
│   ├── CLAUDE.md              # そのリポジトリ用の別の CLAUDE.md
│   └── docs/                  # コンポーネント固有のドキュメント
│
├── sotsuron-template/          # 独立したリポジトリ
│   ├── .git/                  # 別個の Git リポジトリ
│   ├── CLAUDE.md              # そのリポジトリ用の別の CLAUDE.md
│   └── docs/                  # コンポーネント固有のドキュメント
│
└── (その他の独立したリポジトリ...)
```

### リポジトリのカテゴリ

#### コアインフラストラクチャ
- **texlive-ja-textlint/**: 日本語 LaTeX コンパイル用の Docker イメージ
- **latex-environment/**: LaTeX 開発用の DevContainer テンプレート

#### テンプレート
- **sotsuron-template/**: 統合卒業論文テンプレート(学部/大学院)
- **sotsuron-report-template/**: 練習用の卒業論文レポートテンプレート
- **wr-template/**: 週次レポートテンプレート
- **latex-template/**: 基本的な LaTeX テンプレート
- **ise-report-template/**: HTML ベースのレポートテンプレート
- **poster-template/**: 学術ポスターテンプレート (A0, tikzposter + LuaLaTeX)

#### ツールと自動化
- **student-repo-management/**: 管理用ツールとワークフロー
- **thesis-student-registry/**: 学生リポジトリのレジストリデータ(プライベート、主にレジストリデータ。registry-manager が書き込み、thesis-monitor が読み取る)
- **registry-manager/**: レジストリデータ管理ツール(Elixir escript。thesis-student-registry の data/registry.json に書き込む)
- **thesis-monitor/**: 学生リポジトリ監視ツール(Elixir escript。レジストリを読み取る)
- **latex-release-action/**: LaTeX コンパイル用の GitHub Action
- **ai-academic-paper-reviewer/**: 自動レビュー用の GitHub Action (ACADEMIC モードと CODE モード)
- **aldc/**: LaTeX devcontainer を追加するコマンドラインツール

## 設計原則

### 管理リポジトリの原則
- **ファイルのみを追跡**: docs/ と ecosystem_manager/ を除きサブディレクトリの内容は追跡しない
- **連携重視**: リポジトリ横断の連携とドキュメント管理に注力する
- **独立したコンポーネント**: 各サブディレクトリは別個の Git リポジトリである
- **docs/ の例外**: エコシステム全体のドキュメントは一元管理する

### コンポーネントリポジトリの原則
- **独立したバージョン管理**: 各リポジトリが独自のリリースサイクルを持つ
- **自己完結**: 各リポジトリ内で機能が完結する
- **連携した更新**: 互換性のためにエコシステム管理を活用する
- **一貫した構造**: 確立されたパターン (CLAUDE.md, docs/ など) に従う

## エコシステム連携

### リポジトリ横断の依存関係
```
texlive-ja-textlint (ベースイメージ)
    ↓
latex-environment (devcontainer)
    ↓
sotsuron-template, sotsuron-report-template, ise-report-template,
wr-template, latex-template, poster-template (テンプレート群)
    ↓
student-repo-management (学生ワークフロー)
    ↓
thesis-student-registry (レジストリデータ)
    ↑ 書き込み: registry-manager   ↓ 読み取り: thesis-monitor
```

### 更新の伝播
1. **ベースレイヤーの変更** (texlive-ja-textlint) → latex-environment でテストする
2. **環境の変更** (latex-environment) → 依存するテンプレートを更新する
3. **テンプレートの変更** → 管理ツールと連携する
4. **ツールの変更** → 既存のテンプレートで検証する

### 互換性管理
- **バージョンマトリクス**: ECOSYSTEM.md に記載
- **テスト連携**: 検証には ecosystem_manager/ecosystem-manager を使用する
- **破壊的変更の伝達**: リポジトリ横断の issue で連携する
