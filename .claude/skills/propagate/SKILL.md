---
name: propagate
description: 学生リポジトリの draft ブランチ階層へ workflow 更新を伝播する。引数はリポジトリ名（例 k22rs001-sotsuron）または --all --type thesis。registry-manager の準備確認 → dry-run → 実行 → PR diff 検証までを順序通りに行う
allowed-tools: Bash(git:*), Bash(gh:*), Bash(mix:*), Bash(./registry-manager/registry-manager:*), Read(*), Grep(*)
---

# 学生リポジトリへの workflow 伝播

引数: 対象リポジトリ名（例 `k22rs001-sotsuron`）、または `--all --type thesis`。GitHub 操作は toshi0806。

学生リポジトリは draft-to-draft PR ワークフロー（`2nd-draft` → `1st-draft` → `0th-draft` → `main`）を使う。workflow ファイルの更新が PR diff に現れると、GitHub Actions のセキュリティ制限で `pull_request` トリガの workflow がスキップされる。これを避けるため、**main から draft ブランチ階層を merge で辿って伝播する**必要がある。この手順は registry-manager の `propagate-workflow` コマンドが自動化している。

## 手順（必ずこの順序で）

### 1. 前提確認

registry-manager は latex-ecosystem 直下に checkout する構成（このマシンには未 clone の場合がある）:

```bash
# checkout が無ければ clone してビルド（latex-ecosystem 直下で）
ls registry-manager/registry-manager 2>/dev/null || {
  git clone git@github.com:smkwlab/registry-manager.git
  (cd registry-manager && mix escript.build)
}

# escript バイナリが古い場合は再ビルド
(cd registry-manager && git pull && mix escript.build)

# 設定確認: github_org と data_repo が必要（認証は gh CLI 任せ、token キーは無い）
cat ~/.config/registry-manager/config.json
gh auth status
```

`~/.config/registry-manager/config.json` の最低構成:
`{"github_org": "smkwlab", "data_repo": "smkwlab/thesis-student-registry"}`

### 2. dry-run で対象と作業内容を確認

```bash
# 単一リポジトリ
./registry-manager/registry-manager propagate-workflow <repo> --dry-run

# 全 thesis リポジトリ
./registry-manager/registry-manager propagate-workflow --all --type thesis --dry-run
```

dry-run の結果（対象リポジトリ・ブランチ・変更内容）をユーザーに提示し、想定と一致することを確認してから実行に進む。

### 3. 実行

```bash
./registry-manager/registry-manager propagate-workflow <repo>
# または
./registry-manager/registry-manager propagate-workflow --all --type thesis
```

### 4. 検証（実行後必ず）

対象リポジトリの open PR に workflow ファイルの diff が**含まれていない**ことを確認する:

```bash
gh pr list --repo smkwlab/<repo> --state open --json number -q '.[].number'
gh pr diff <PR番号> --repo smkwlab/<repo> --name-only | grep -E "\.github/workflows" 
# 空なら成功。何か出たら伝播が正しく行われていない
```

## やってはいけないこと

❌ **各ブランチへ同一変更を独立に commit / push しない**:

```bash
# 誤り — ブランチごとに別の commit 履歴ができる
git checkout 0th-draft && git add . && git commit && git push
git checkout 1st-draft && git add . && git commit && git push
```

内容が同一でも PR diff に workflow 変更が現れ、`pull_request` トリガの workflow（通知メール等）がスキップされる。

## 手動フォールバック（registry-manager が使えない場合のみ)

main を更新後、**merge で**階層を辿る（commit 履歴を共有させるのが目的）:

```bash
git checkout main
git add .github/workflows/ && git commit -m "ci: update workflow files" && git push

git checkout 0th-draft && git merge main -m "Merge workflow updates from main" && git push
git checkout 1st-draft && git merge 0th-draft -m "Merge workflow updates from 0th-draft" && git push
git checkout 2nd-draft && git merge 1st-draft -m "Merge workflow updates from 1st-draft" && git push
# 3rd-draft 以降が存在すれば同様に続ける
```

手動実施後も手順 4 の検証を必ず行う。
