# LaTeX エコシステム セットアップ・管理ガイド

> 🌐 English version: [CLAUDE-SETUP.md](CLAUDE-SETUP.md)

本ガイドは、九州産業大学の LaTeX エコシステムにおけるセットアップ、依存関係管理、リリースプロセスを包括的に解説します。

## 前提条件

### 必須ツール
- **Git**: バージョン管理システム
- **GitHub CLI (`gh`)**: PR/Issue の追跡に必須。クローンを容易にするため推奨
- **Elixir/Mix**（Erlang/OTP を含む）: `ecosystem-manager` escript のビルドと実行に必須
- **Bash**: シェルインタプリタ（バージョン 3.2 以上）

### 任意ツール
- **Docker**: Docker イメージのテスト用
- **VSCode**: 開発に推奨される IDE

### GitHub CLI のセットアップ

```bash
# GitHub CLI のインストール
# macOS
brew install gh

# Ubuntu/Debian  
sudo apt install gh

# Windows (Scoop を使用)
scoop install gh

# 認証
gh auth login

# 認証の確認
gh auth status
```

**注意**: エコシステム管理機能をフルに利用するには GitHub CLI の認証が必要です。認証がない場合、PR/Issue の追跡は動作しません。

## クイックセットアップ

```bash
# ワンライナーによるエコシステムのセットアップ
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/latex-ecosystem/main/setup.sh)"
```

## 手動セットアップ

### 1. 管理リポジトリのクローン

```bash
# 開発用ディレクトリの作成
mkdir latex-ecosystem-dev
cd latex-ecosystem-dev

# 管理リポジトリのクローン
gh repo clone smkwlab/latex-ecosystem .

# または git を使用
git clone https://github.com/smkwlab/latex-ecosystem.git .
```

### 2. セットアップスクリプトの実行

```bash
# セットアップスクリプトの実行
./setup.sh

# これにより、すべてのコンポーネントリポジトリがクローンされます:
# コア基盤:
# - texlive-ja-textlint
# - latex-environment
# - latex-release-action
# ドキュメントテンプレート:
# - sotsuron-template
# - wr-template
# - latex-template
# - sotsuron-report-template
# - ise-report-template
# - poster-template
# ツール:
# - student-repo-management
# - thesis-student-registry
# - ai-academic-paper-reviewer
# - aldc
```

### 3. インストールの確認

```bash
# マネージャを一度ビルドする (Elixir escript)
(cd ecosystem_manager && mix escript.build)

# エコシステムの状態を確認
./ecosystem_manager/ecosystem-manager status

# リポジトリ構成とソースを表示
./ecosystem_manager/ecosystem-manager repos
```

## 依存関係管理

### エコシステムの依存関係構造

```
texlive-ja-textlint (Docker base)
    ↓
latex-environment (DevContainer template)
    ↓
├── sotsuron-template (LaTeX thesis)
├── ise-report-template (HTML reports with textlint)
├── wr-template (Weekly reports)
├── latex-template (Basic LaTeX)
└── sotsuron-report-template (Thesis reports)

Supporting Infrastructure:
├── latex-release-action → (Used by templates)
├── ai-academic-paper-reviewer → (Used by thesis repos)  
├── aldc → latex-environment (release branch)
└── student-repo-management → (Management workflows)
```

### 標準的な更新プロセス

#### フェーズ 1: ベースイメージの更新 (texlive-ja-textlint)

```bash
cd texlive-ja-textlint/

# feature ブランチの作成
git checkout -b feature/update-2025d

# 変更を加える (パッケージ更新、セキュリティパッチなど)
# alpine/package.json, debian/package.json などを編集

# ローカルでテスト
docker build -f alpine/Dockerfile -t test-alpine .
docker build -f debian/Dockerfile -t test-debian .

# コミットとプッシュ
git add .
git commit -m "Update to TeXLive 2025d with security patches"
git push origin feature/update-2025d

# PR の作成
gh pr create --title "Update to TeXLive 2025d" --body "- Security updates
- Package compatibility fixes
- Multi-architecture support verified"

# PR の承認とマージの後
git checkout main && git pull origin main
git tag 2025d -m "TeXLive 2025d release"
git push origin 2025d
```

#### フェーズ 2: 環境の更新 (latex-environment)

```bash
cd ../latex-environment/

# texlive-ja-textlint の Docker イメージがビルドされるのを待つ
# レジストリを確認: ghcr.io/smkwlab/texlive-ja-textlint:2025d

# feature ブランチの作成
git checkout -b feature/update-texlive-2025d

# 新しいイメージを使うよう devcontainer を更新
vim .devcontainer/devcontainer.json
# 変更: "image": "ghcr.io/smkwlab/texlive-ja-textlint:2025d"

# 更新のテスト
# - VS Code で devcontainer を起動
# - サンプル文書をコンパイル
# - textlint の機能を確認

# コミットして PR を作成
git add .devcontainer/devcontainer.json
git commit -m "Update to texlive-ja-textlint 2025d"
git push origin feature/update-texlive-2025d
gh pr create --title "Update to texlive-ja-textlint 2025d" --body "- Update base Docker image
- Compatibility verified with sample documents"
```

#### フェーズ 3: テンプレートの更新

```bash
# 各テンプレートリポジトリを更新
for template in sotsuron-template wr-template latex-template ise-report-template; do
    echo "Updating $template..."
    cd ../$template/
    
    # テンプレートは latex-environment を継承するため、通常は直接の変更は不要
    # ただし互換性を確認し、必要なら更新する
    
    # コンパイルのテスト
    if [ -f "main.tex" ] || [ -f "sotsuron.tex" ]; then
        # devcontainer 付きの VS Code で開いてテスト
        echo "Manual testing required for $template"
    fi
done
```

## リリース管理

### リリースの種類

1. **通常更新**（毎月/隔月）
   - 機能追加、依存関係更新
   - 後方互換性を壊さない改善
   - 例: 2025a → 2025b

2. **セキュリティ更新**（必要に応じて）
   - 重大なセキュリティパッチ
   - 例: 2025b → 2025b-security

3. **メジャー更新**（年次）
   - TeXLive のメジャーバージョン更新
   - アーキテクチャの変更
   - 例: 2024c → 2025

### リリースワークフロー

#### 1. 計画フェーズ

```bash
# 主要リポジトリにリリース計画 issue を作成
gh issue create --title "Release Planning: texlive-ja-textlint 2025d" --body "
## Release Goals
- [ ] Security updates for base Alpine/Debian images
- [ ] Node.js 18 → 20 migration
- [ ] New textlint rules for academic writing

## Timeline
- Development: Week 1-2
- Testing: Week 3
- Release: Week 4

## Breaking Changes
- Node.js version requirement change
- Migration guide needed

## Testing Requirements
- [ ] Multi-architecture builds (AMD64, ARM64)
- [ ] Integration tests with latex-environment
- [ ] Template compilation verification
"
```

#### 2. 開発フェーズ

```bash
# フェーズ 1〜3 の依存関係更新プロセスに従う
# すべての変更が適切にテストされていることを確認
# テストの証跡を含む包括的な PR を作成
```

#### 3. テストフェーズ

```bash
# エコシステム全体の状態チェック (ブランチ、未コミット変更、PR)
./ecosystem_manager/ecosystem-manager status --long

# 重要なワークフローのテスト
cd student-repo-management/
./thesis-repo-manager.sh --test-mode

# 学生ワークフローの検証
cd test-repos/
# リポジトリ作成とコンパイルを確認
```

#### 4. リリースフェーズ

```bash
# 依存順にリリースをタグ付け
cd texlive-ja-textlint/
git tag 2025d && git push origin 2025d

cd ../latex-environment/
git tag 2025.1 && git push origin 2025.1

# エコシステムのトラッキングを更新
cd ../
vim ECOSYSTEM.md  # 互換性マトリクスを更新
git add ECOSYSTEM.md
git commit -m "Update compatibility matrix for 2025d release"
```

#### 5. 周知フェーズ

```bash
# リリースアナウンスの作成
gh release create 2025d --title "TeXLive 2025d Release" --notes "
## New Features
- Updated TeXLive packages
- Enhanced security
- Improved multi-architecture support

## Breaking Changes
- Node.js 18 → 20 (update your local development)

## Migration Guide
See docs/CLAUDE-SETUP.md for update instructions
"

# 関係者への通知
# - 研究室ドキュメントの更新
# - 必要な対応を学生に周知
# - 必要なら講義資料を更新
```

## 緊急時手順

### 重大なセキュリティ更新

```bash
# セキュリティパッチのための緊急ワークフロー
# 1. 脆弱性の影響を評価
# 2. hotfix ブランチを作成
git checkout -b hotfix/security-CVE-2025-XXXX

# 3. 最小限の修正を適用
# 4. 迅速なテスト
# 5. 明確な周知を伴う緊急リリース
git tag 2025b-security1
gh release create 2025b-security1 --title "Security Hotfix" --notes "
⚠️ SECURITY UPDATE

Addresses CVE-2025-XXXX in base image.
All users should update immediately.
"
```

### ロールバック手順

```bash
# リリースが問題を引き起こした場合
# 1. 問題のあるバージョンを特定
# 2. 直前の安定タグに戻す

cd texlive-ja-textlint/
git checkout 2025c  # 直前の安定バージョン
git tag 2025d-rollback
git push origin 2025d-rollback

# 3. ロールバック版を使うよう latex-environment を更新
cd ../latex-environment/
# devcontainer.json を 2025c または 2025d-rollback を使うよう更新

# 4. ロールバックをユーザに周知
gh issue create --title "ROLLBACK: 2025d → 2025c" --body "
Issue identified in 2025d release.
Temporarily rolling back to 2025c.
Investigation ongoing.
"
```

## エコシステムの保守

### 定常的な保守タスク

```bash
# 週次の保守
./ecosystem_manager/ecosystem-manager status --long

# 月次の保守
# 必要に応じて各リポジトリの最新変更を取得する (git pull)
# ドキュメントのレビューと更新
# 上流の更新を確認する (TeXLive, Node.js など)

# 四半期の保守
# セキュリティ監査
# パフォーマンスレビュー
# 学生フィードバックの反映
```

### 監視とアラート

```bash
# 以下の監視を設定する:
# - Docker イメージのビルド失敗
# - GitHub Actions の失敗
# - 学生リポジトリ作成の問題
# - テンプレートのコンパイル失敗

# 状態チェックには ecosystem-manager を利用する (cron / CI など)
./ecosystem_manager/ecosystem-manager status --fast
```

## 開発のベストプラクティス

### ブランチ戦略
- 常に feature ブランチを使う
- main へ直接コミットしない
- 説明的なブランチ名を使う: `feature/`, `fix/`, `hotfix/`

### テスト要件
- すべての変更は自動テストをパスする必要がある
- テンプレート変更には手動テストを行う
- クロスプラットフォーム互換性の検証

### ドキュメント
- ユーザ向けの変更については CHANGELOG.md を更新する
- 互換性マトリクスを維持する
- 破壊的変更には移行ガイドを提供する

## トラブルシューティング

### よくある問題

**セットアップスクリプトの失敗**:
```bash
# GitHub CLI の認証を確認
gh auth status

# リポジトリへのアクセスを確認
gh repo view smkwlab/latex-ecosystem

# 自動セットアップが失敗する場合は手動でクローン
git clone https://github.com/smkwlab/texlive-ja-textlint.git
```

**依存関係更新の問題**:
```bash
# Docker イメージの利用可否を確認
docker pull ghcr.io/smkwlab/texlive-ja-textlint:2025d

# イメージの互換性を確認
docker run --rm ghcr.io/smkwlab/texlive-ja-textlint:2025d tlmgr --version
```

**リリースプロセスの問題**:
```bash
# GitHub Actions の状態を確認
gh run list --repo smkwlab/texlive-ja-textlint

# タグ作成を確認
git tag -l | grep 2025

# レジストリへのアップロードを確認
# 参照: https://github.com/orgs/smkwlab/packages
```

追加のトラブルシューティングについては、各リポジトリのドキュメントおよび [CLAUDE-WORKFLOWS.md](CLAUDE-WORKFLOWS.ja.md) を参照してください。
