# 管理リポジトリガイド

> 🌐 English version: [MANAGEMENT-REPOSITORY.md](MANAGEMENT-REPOSITORY.md)

このドキュメントでは、**latex-ecosystem 管理リポジトリそのもの** — その Git 境界、
ディレクトリ構造、そして何を追跡するかを定める原則 — について説明します。

**エコシステム全体のアーキテクチャ**（全コンポーネントリポジトリ、依存関係マトリクス、
バージョン互換性、更新チェーン）については
[../ECOSYSTEM.md](../ECOSYSTEM.md) を参照してください。

## このリポジトリの位置づけ

`latex-ecosystem` は LaTeX 卒業論文環境の連携ハブです。コンポーネントそのものは
**含みません** — 各コンポーネントは独立した Git リポジトリです — が、エコシステム
レベルの連携用資材（概要・ドキュメント）を追跡し、`ecosystem-manager` ツールを
含むコンポーネントリポジトリを横に並べて clone するためのワークスペースを提供します。

## Git リポジトリの境界

### 管理リポジトリの構造

```
latex-ecosystem/                 # この管理リポジトリ
├── .git/                       # 管理ファイル専用の Git
├── ECOSYSTEM.md                # 追跡対象 - エコシステム概要
├── README.md                   # 追跡対象 - リポジトリ概要
├── setup.sh                    # 追跡対象 - エコシステムセットアップスクリプト
├── CLAUDE.md                   # 追跡対象 - 管理リポジトリ向け指示
├── .claude/                    # 追跡対象 - claude 設定
├── docs/                       # 追跡対象 - エコシステムドキュメント
│   ├── MANAGEMENT-REPOSITORY.md   # このファイル
│   ├── MANAGEMENT-WORKFLOWS.md    # 管理ワークフロー例
│   └── ...                        # その他のガイド (setup, git, multi-org, review)
│
├── ecosystem-manager/          # 独立したリポジトリ (横に clone; Elixir escript 連携ツール)
│   ├── .git/                  # 別個の Git リポジトリ
│   └── ...
│
├── latex-environment/          # 独立したリポジトリ (横に clone)
│   ├── .git/                  # 別個の Git リポジトリ
│   ├── CLAUDE.md              # そのリポジトリ用の別の CLAUDE.md
│   └── docs/                  # コンポーネント固有のドキュメント
│
├── sotsuron-template/          # 独立したリポジトリ (横に clone)
│   ├── .git/                  # 別個の Git リポジトリ
│   └── ...
│
└── (その他の独立したリポジトリ...)
```

コンポーネントリポジトリ（`latex-environment`、`sotsuron-template`、…）の一覧と
分類は [../ECOSYSTEM.md](../ECOSYSTEM.md#repository-overview) にあります。この
リポジトリはそれらの内容を追跡しません。

## 設計原則

### 管理リポジトリの原則
- **ファイルのみを追跡**: `docs/` を除きサブディレクトリの内容は追跡しない
- **連携重視**: リポジトリ横断の連携とドキュメント管理に注力する
- **独立したコンポーネント**: 各サブディレクトリは別個の Git リポジトリである
- **docs/ の例外**: エコシステム全体のドキュメントはここで一元管理する
- **ドキュメントの配置**: 読者向け（学生・教員・運用者）ドキュメントは本リポジトリの
  `docs/` に集約する。各コンポーネントリポジトリの `docs/` は開発者向け
  （`CLAUDE-*.md` 等）に限り、読者向けの入口はそのリポジトリのトップレベル
  （README、WRITING-GUIDE.md など）に置く

### コンポーネントリポジトリをまたぐ作業
- 各サブディレクトリは、独自の履歴・`CLAUDE.md`・リリースサイクルを持つ独立した
  Git リポジトリです。
- Git 操作の前に、必ず今どのリポジトリにいるか（`pwd` / `git status`）を確認して
  ください — [MANAGEMENT-WORKFLOWS.ja.md](MANAGEMENT-WORKFLOWS.ja.md) を参照。
- エコシステム全体にまたがる変更は、この管理リポジトリを通じて調整し、
  [../ECOSYSTEM.md](../ECOSYSTEM.md) を最新に保ってください。
