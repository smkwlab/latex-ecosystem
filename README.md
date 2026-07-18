# LaTeX Ecosystem

九州産業大学 理工学部 下川研究室の LaTeX 論文テンプレートとツール群を統合管理するエコシステムです。

## リポジトリ構成

このディレクトリには、連携して LaTeX 学術文書管理システムを構成する複数の独立した Git リポジトリが含まれます。

```
latex-ecosystem/
├── ECOSYSTEM.md              # This management repository
├── setup.sh                  # Automated setup script
├── README.md                 # This file
├── docs/                     # Detailed documentation
│
# Everything above is tracked by this management repository.
# Everything below is a separate repository cloned by setup.sh:
#
#   Core infrastructure
├── texlive-ja-textlint/      # Docker images for Japanese LaTeX + textlint
├── latex-environment/        # DevContainer template
├── latex-release-action/     # PDF build / release GitHub Action
#
#   Document templates
├── sotsuron-template/        # Thesis (undergraduate + graduate)
├── ise-report-template/      # ISE report (HTML/textlint)
├── wr-template/              # Weekly report
├── latex-template/           # General-purpose LaTeX
├── sotsuron-report-template/ # Thesis report
├── poster-template/          # Academic poster (A0)
#
#   Management & automation
├── ecosystem-manager/        # Cross-repository management tool (Elixir escript)
├── student-repo-management/  # Repository creation / review tooling
├── thesis-student-registry/  # Student repository registry data (private, data-only)
├── ai-academic-paper-reviewer/ # AI review Action (ACADEMIC/CODE modes)
└── aldc/                     # Adds the LaTeX devcontainer to a repository
```

## 前提条件

### 必要なツール

- **Git**: バージョン管理システム
- **GitHub CLI (gh)**: PR / Issue の確認機能に必要
- **Elixir 1.17 以上**(Erlang/OTP を含む): ecosystem-manager escript のビルド・実行に必要
- **Bash**: シェル(バージョン 4.0 以上)

### GitHub CLI のセットアップ

ecosystem manager の全機能を使うには GitHub CLI が必要です。

```bash
# Install GitHub CLI (if not already installed)
# macOS
brew install gh

# Ubuntu/Debian
sudo apt install gh

# Other platforms: see https://cli.github.com/

# Authenticate with GitHub
gh auth login

# Verify authentication
gh auth status
```

**注**: GitHub CLI の認証がなくても ecosystem manager 自体は動作しますが、機能は限定されます(PR / Issue 数が表示されません)。

**注**: エコシステムの一部リポジトリ(`thesis-student-registry`、`ecosystem-manager` など)は private です。`setup.sh` がこれらを clone できるのは、GitHub CLI の認証(`gh auth login`)済みか、GitHub に SSH 鍵を登録済みの場合のみです。匿名 HTTPS フォールバックは public リポジトリにしか使えません。

## クイックスタート

### 初回セットアップ

**ワンライナーでのセットアップ:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/latex-ecosystem/main/setup.sh)"
```

カレントディレクトリの下に `latex-ecosystem-dev/` ディレクトリを作成し、その中に一式をセットアップします。

**手動での clone とセットアップ:**
```bash
gh repo clone smkwlab/latex-ecosystem latex-ecosystem-dev
cd latex-ecosystem-dev
./setup.sh
```

既存の latex-ecosystem チェックアウト内で実行した場合、`setup.sh` はそれを検出し、入れ子の `latex-ecosystem-dev/` を作らずにそのチェックアウト内へコンポーネントリポジトリを clone します。

**セットアップ先の指定:**
```bash
# Set LATEX_ECOSYSTEM_BASE to control where the ecosystem is set up
LATEX_ECOSYSTEM_BASE="$HOME/work/latex-ecosystem" \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/latex-ecosystem/main/setup.sh)"
```

### 日常のエコシステム管理

> **初回のみ**: escript をビルドしてください: `(cd ecosystem-manager && mix escript.build)`

```bash
# Check status of all repositories
./ecosystem-manager/ecosystem-manager status

# Detailed status (branch, uncommitted changes, last commit, PRs, issues)
./ecosystem-manager/ecosystem-manager status --long

# Fast status without GitHub API calls
./ecosystem-manager/ecosystem-manager status --fast

# Show repository configuration and sources
./ecosystem-manager/ecosystem-manager repos
```

### 学生向け

学生は自動リポジトリ作成プロセスを使ってください(執筆ワークフロー全体は [docs/STUDENT-WORKFLOW.md](docs/STUDENT-WORKFLOW.md) を参照)。

**基本セットアップ(依存ツール不要):**
```bash
bash <(curl -fsSL https://repo-setup.smkwlab.net) thesis
```

**学籍番号を指定する場合:**
```bash
STUDENT_ID=k21rs001 bash <(curl -fsSL https://repo-setup.smkwlab.net) thesis
```

> この短縮 URL は作成ツールの**最新安定リリース**(`v1` 移動タグ。`main` は決して使わない)を配信するため、未リリースの変更が学生に届くことはありません。
>
> また、この URL は **smkwlab デプロイメント**の入口です。他のデプロイメントでは、学生は**自 org のフォーク**の `setup.sh`([docs/MULTI-ORG-DEPLOYMENT.md](docs/MULTI-ORG-DEPLOYMENT.md) に従って設定したもの)を実行する必要があります — smkwlab の URL では smkwlab の既定値でリポジトリが作成されてしまいます。

### 教員向け

レビューワークフローのドキュメントは [docs/](docs/) に集約されています。まず [docs/TEACHER-ONBOARDING.md](docs/TEACHER-ONBOARDING.md) からお読みください。

## ドキュメント

- **[docs/README.md](docs/README.md)**: ドキュメントガイド — 役割に応じたドキュメントを探すならまずここから
- **教員・学生向けガイド**は docs/ に集約: [docs/TEACHER-ONBOARDING.md](docs/TEACHER-ONBOARDING.md)(教員)、[docs/STUDENT-WORKFLOW.md](docs/STUDENT-WORKFLOW.md)(学生)
- **[docs/GETTING-STARTED.md](docs/GETTING-STARTED.md)**: エコシステム運用を始めるための単一経路ガイド
- **[ECOSYSTEM.md](ECOSYSTEM.md)**: エコシステム全体のアーキテクチャと管理ガイド
- **[docs/](docs/)**: 詳細ドキュメント
  - **[RELEASE-OPERATIONS.md](docs/RELEASE-OPERATIONS.md)**: 依存関係管理・リリースプロセス
  - **[MANAGEMENT-REPOSITORY.md](docs/MANAGEMENT-REPOSITORY.md)**: この管理リポジトリの構造と境界(エコシステム全体のアーキテクチャは上記 ECOSYSTEM.md)
  - **[MANAGEMENT-WORKFLOWS.md](docs/MANAGEMENT-WORKFLOWS.md)**: エコシステム管理のワークフローと連携
  - **[GIT-WORKFLOW.md](docs/GIT-WORKFLOW.md)**: Git のベストプラクティスとコンフリクト解消
- **各リポジトリ**: それぞれに README.md と CLAUDE.md があります

## リポジトリ管理

### このリポジトリ (latex-ecosystem)

この管理リポジトリに含まれるのは次のとおりです。

- **ECOSYSTEM.md**: エコシステム全体のアーキテクチャドキュメント
- **docs/**: 各種ガイドを収めた詳細ドキュメントディレクトリ
- **setup.sh**: 全リポジトリを clone する自動セットアップスクリプト
- **README.md**: この概要ファイル

`ecosystem-manager` ツールは独立したリポジトリ(`smkwlab/ecosystem-manager`)で、setup.sh が他のコンポーネントと同様に clone します。

サブディレクトリはすべて setup.sh が clone する独立した Git リポジトリであり、このリポジトリのバージョン管理には**含まれません**。

### 各コンポーネントリポジトリ

各サブディレクトリは独立した Git リポジトリで、それぞれが次を持ちます。

- 独立したバージョン管理
- GitHub リポジトリと Issue
- リリースサイクルとタグ付け
- ドキュメントと README

## コントリビューション

### エコシステム全体に関わる変更

1. このリポジトリのドキュメントを更新する
2. ecosystem-manager/ecosystem-manager で変更を調整する
3. 関係する各リポジトリに Issue を作成する
4. エコシステム全体で変更をテストする

### コンポーネント固有の変更

対象リポジトリで、そのリポジトリのコントリビューションガイドラインに従って作業してください。

## アーキテクチャ概要

```
┌─────────────────────────────────────────────────────────────┐
│                    Dependency Flow                         │
└─────────────────────────────────────────────────────────────┘

texlive-ja-textlint (Docker Base)
    ↓
latex-environment (DevContainer Template)
    ↓
├── sotsuron-template (Student Templates)
├── ise-report-template (HTML-based quality-focused)
├── wr-template
├── latex-template
├── sotsuron-report-template
└── poster-template

Supporting Infrastructure:
├── latex-release-action → (Used by templates)
├── ai-academic-paper-reviewer → (AI review for thesis repos & code review, ACADEMIC/CODE modes)
├── aldc → latex-environment (release branch)
├── student-repo-management → (Management workflows)
└── thesis-student-registry → (Student repository registry data; managed by registry-manager, read by thesis-monitor)
```

## サポート

- **コンポーネントの問題**: 該当リポジトリに Issue を作成してください
- **エコシステムの問題**: 最も関係の深いコンポーネントリポジトリに Issue を作成してください
- **ドキュメント**: 詳細は ECOSYSTEM.md を参照してください

---

*アーキテクチャの詳細は [ECOSYSTEM.md](ECOSYSTEM.md) を参照*
