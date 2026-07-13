# エコシステム管理ワークフロー

> 🌐 English version: [MANAGEMENT-WORKFLOWS.md](MANAGEMENT-WORKFLOWS.md)

このドキュメントは、LaTeX エコシステム管理リポジトリを用いたエコシステム管理タスクに特化したワークフロー例を提供する。

## エコシステム管理コマンド

### コマンドリファレンス

manager は Elixir escript である。最初に
`(cd ecosystem-manager && mix escript.build)`
で一度ビルドしておき、その後は以下を実行する:

```bash
# 全リポジトリの状態を表示(デフォルトコマンド)
./ecosystem-manager/ecosystem-manager status

# 詳細な状態: ブランチ、未コミットの変更、最新コミット、PR、issue
./ecosystem-manager/ecosystem-manager status --long

# GitHub API 呼び出しなしの高速な状態表示
./ecosystem-manager/ecosystem-manager status --fast

# フィルタ: 緊急 issue / オープンな PR / レビュー待ちの PR
./ecosystem-manager/ecosystem-manager status --urgent-issues
./ecosystem-manager/ecosystem-manager status --with-prs
./ecosystem-manager/ecosystem-manager status --needs-review

# 全ワークスペースの状態、または名前指定で特定のワークスペースの状態
./ecosystem-manager/ecosystem-manager status --all
./ecosystem-manager/ecosystem-manager status -w dns   # または --workspace NAME

# 並列度を調整(デフォルト: 8)
./ecosystem-manager/ecosystem-manager status --max-concurrency 4

# リポジトリ設定とソースを表示
./ecosystem-manager/ecosystem-manager repos

# ワークスペースのリポジトリを自動探索し、ユーザ設定に記録して
# ワークスペースを登録
./ecosystem-manager/ecosystem-manager repos --sync

# 解決されるワークスペースパスを表示 / 全ワークスペースを一覧表示
./ecosystem-manager/ecosystem-manager workspace
./ecosystem-manager/ecosystem-manager workspace --list

# サンプルのユーザ設定ファイルを作成
./ecosystem-manager/ecosystem-manager init-config

# 現在の設定を表示
./ecosystem-manager/ecosystem-manager config
```

### 状態監視の例
```bash
# エコシステムの簡易ヘルスチェック(ブランチ/コミット/変更情報を含む行)
./ecosystem-manager/ecosystem-manager status --long

# 対応が必要なリポジトリのみを表示
./ecosystem-manager/ecosystem-manager status --urgent-issues
./ecosystem-manager/ecosystem-manager status --needs-review

# バージョン互換性は ECOSYSTEM.md(互換性マトリクス)で管理している
```

## リポジトリ間の移動と操作

### シェルコマンドの落とし穴

#### ディレクトリ間の移動
```bash
# エコシステム管理リポジトリでの作業
pwd  # /path/to/latex-ecosystem (管理リポジトリ)
git status  # 管理リポジトリの状態を表示

# コンポーネントでの作業
cd latex-environment/
pwd  # /path/to/latex-ecosystem/latex-environment (別リポジトリ)
git status  # latex-environment リポジトリの状態を表示

# 管理リポジトリに戻る
cd ..
git status  # 再び管理リポジトリの状態を表示
```

#### Git 操作
```bash
# 管理リポジトリの操作
git add ECOSYSTEM.md docs/
git commit -m "Update ecosystem documentation"

# コンポーネントリポジトリの操作
cd latex-environment/
git add .devcontainer/devcontainer.json
git commit -m "Update devcontainer config"
git push origin feature-branch

# 管理リポジトリに戻る
cd ..
git status  # まったく別の Git 履歴
```

## ワークフローガイドライン

### エコシステムレベルの変更

#### ドキュメントの更新
```bash
# エコシステムドキュメントの更新
vim ECOSYSTEM.md  # エコシステム概要を編集
vim docs/MANAGEMENT-REPOSITORY.md  # 管理リポジトリの構造・境界を編集

# エコシステムの変更をコミット
git add ECOSYSTEM.md docs/
git commit -m "Update ecosystem architecture documentation"
git push origin main
```

#### リポジトリ横断の連携
```bash
# 現在の状態を確認
./ecosystem-manager/ecosystem-manager status

# 更新の調整
vim ECOSYSTEM.md  # 予定している変更を記録

# 影響を受けるリポジトリに issue を作成
cd latex-environment/
gh issue create --title "Update for texlive-ja-textlint v2025c"

cd ../sotsuron-template/
gh issue create --title "Align with updated latex-environment"
```

### コンポーネント固有の変更

#### コンポーネント内での作業
```bash
# 特定のリポジトリへ移動
cd latex-environment/

# feature ブランチを作成
git checkout -b feature/update-textlint-config

# 変更を加える
vim .textlintrc
git add .textlintrc
git commit -m "Update textlint configuration"

# push して PR を作成
git push origin feature/update-textlint-config
gh pr create --title "Update textlint configuration"

# エコシステム管理リポジトリに戻る
cd ..
```

#### コンポーネントの変更追跡
```bash
# コンポーネントリポジトリの変更を監視
cd latex-environment/
git log --oneline -10

# 変更が他のコンポーネントに影響するか確認
cd ../sotsuron-template/
# 更新された latex-environment でテスト

# 互換性ドキュメントを更新
cd ..
vim ECOSYSTEM.md  # 互換性マトリクスを更新
```

## リポジトリ横断の issue 管理

### 連携した issue 作成
```bash
# 複数リポジトリに影響するエコシステム全体の変更向け
echo "Creating coordinated issues for texlive update..."

# エコシステム管理リポジトリに記録
vim ECOSYSTEM.md  # Known Issues または Planned Updates に追加

# 影響を受けるリポジトリに issue を作成
repositories=("texlive-ja-textlint" "latex-environment" "sotsuron-template")
for repo in "${repositories[@]}"; do
    cd "$repo/"
    gh issue create --title "Update for TeXLive 2025c" --body "See latex-ecosystem issue #XX"
    cd ..
done
```

### issue の追跡と連携
```bash
# リポジトリ横断で進捗を追跡
./ecosystem-manager/ecosystem-manager status --with-prs

# エコシステム全体で issue の状態を確認
for repo in */; do
    if [ -d "$repo/.git" ]; then
        echo "=== $repo ==="
        cd "$repo"
        gh issue list --label "ecosystem-update"
        cd ..
    fi
done
```

## テストと検証

### エコシステム全体のテスト
```bash
# 全リポジトリを検証(ブランチ、未コミットの変更)
./ecosystem-manager/ecosystem-manager status --long

# テンプレート横断でコンパイルをテスト
templates=("sotsuron-template" "wr-template" "latex-template")
for template in "${templates[@]}"; do
    echo "Testing $template..."
    cd "$template/"
    if [ -f "test.tex" ]; then
        latexmk -pdf test.tex
    fi
    cd ..
done
```

### 互換性検証
```bash
# バージョン互換性は ECOSYSTEM.md(互換性マトリクス)に記載されている。
# 更新を調整する際に参照すること。

# 依存関係チェーンを検証
echo "Checking texlive-ja-textlint → latex-environment compatibility..."
cd latex-environment/
grep -r "texlive-ja-textlint" .devcontainer/

# テンプレートの互換性を確認
cd ../sotsuron-template/
grep -r "latex-environment" .devcontainer/
```

## エコシステム連携タスク

### リポジトリ横断のドキュメント更新
```bash
# エコシステム全体で CLAUDE.md の構成が変わったとき
./ecosystem-manager/ecosystem-manager status  # 現在の状態を確認

# ドキュメント更新を計画
for repo in texlive-ja-textlint latex-environment sotsuron-template; do
    cd $repo/
    echo "Planning docs update for $repo"
    # feature ブランチを作成し、docs/ を更新し、PR を作成
    cd ..
done

# 進捗を追跡
./ecosystem-manager/ecosystem-manager status  # 更新を確認
```

### issue の連携
```bash
# エコシステム全体の変更向けに連携した issue を作成
echo "Creating coordinated issues for major update..."

# エコシステム管理リポジトリに記録
vim ECOSYSTEM.md  # Known Issues または Planned Updates に追加

# 影響を受けるリポジトリに issue を作成
repositories=("texlive-ja-textlint" "latex-environment" "sotsuron-template")
for repo in "${repositories[@]}"; do
    cd "$repo/"
    gh issue create --title "Update for ecosystem change XYZ" --body "See latex-ecosystem management repository for coordination"
    cd ..
done
```

## 学生リポジトリワークフロー

### 学生リポジトリの作成
```bash
# 学生の卒論リポジトリを作成(自動化)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/student-repo-management/v1/create-repo/setup.sh)" bash thesis

# 週報リポジトリを作成
STUDENT_ID=k21rs001 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/student-repo-management/v1/create-repo/setup.sh)" bash wr

# 末尾の引数で文書タイプを選択する。setup.sh は 5 種類に対応:
# thesis, wr, latex, ise, poster。
```

### 学生の進捗監視
```bash
# 全学生の卒論進捗を監視
./thesis-monitor/thesis-monitor status

# 保護状態のみを表示
./thesis-monitor/thesis-monitor status --show-protection

# 詳細出力
./thesis-monitor/thesis-monitor status --verbose
```

## ベストプラクティス

### リポジトリ境界の管理
- git 操作の前に必ず `pwd` を確認する
- `git status` で作業中のリポジトリを確認する
- エコシステムドキュメントは管理リポジトリの docs/ に置く
- コンポーネントドキュメントはコンポーネントリポジトリの docs/ に置く

### ドキュメント管理
- **管理リポジトリの docs/**: エコシステム全体のアーキテクチャ、連携ワークフロー
- **コンポーネントの docs/**: コンポーネント固有の開発、使用方法、トラブルシューティング
- **相互参照**: 適切な箇所で管理ドキュメントとコンポーネントドキュメントを相互にリンクする

### コミュニケーションのパターン
- アーキテクチャ上の決定にはエコシステム管理リポジトリを用いる
- リポジトリ横断の変更には連携した issue を作成する
- 互換性マトリクスと更新手順を文書化する
- エコシステムとコンポーネントの関心事の明確な分離を維持する

## 関連ドキュメント

- [ECOSYSTEM.md](../ECOSYSTEM.md) - エコシステム全体のアーキテクチャ、依存関係、バージョン互換性
- [MANAGEMENT-REPOSITORY.ja.md](MANAGEMENT-REPOSITORY.ja.md) - 本管理リポジトリの構造と境界
- [SETUP-AND-RELEASE.ja.md](SETUP-AND-RELEASE.ja.md) - エコシステム管理のための環境セットアップ
- [PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md) - Pull Request レビューガイドライン
