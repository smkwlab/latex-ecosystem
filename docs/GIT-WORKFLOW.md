# Git ワークフローのベストプラクティス

このドキュメントは、LaTeX エコシステムでの Git ワークフロー、すなわち「すべての変更を feature ブランチで行い、main ブランチのコンフリクトを避ける」方法を扱います。

## なぜ feature ブランチを使うか

ローカル `main` に直接 commit し、リモートで PR がマージされる間にローカル `main` を `origin/main` から乖離させると、避けられたはずのマージコンフリクトが生じます。以下のルールは、すべての変更を feature ブランチに載せ、`main` をリモートのクリーンなミラーに保つことで、`git pull` を常に fast-forward にします。

## 正しい Git ワークフロー

**❌ 問題のあるワークフロー (コンフリクトの原因)**:
```bash
# main への直接 commit (これは避ける)
git checkout main
git add . && git commit -m "Add feature X"
git add . && git commit -m "Fix bug Y"
# ... 複数の直接 commit ...
# 後で: 別の PR がリモートでマージされる
git pull origin main  # → コンフリクト!
```

**✅ 正しいワークフロー**:
```bash
# 1. 常にクリーンで最新の main から始める
git checkout main
git pull origin main

# 2. すべての変更に対して feature ブランチを作成する
git checkout -b feature/descriptive-name

# 3. feature ブランチ上で作業する
git add . && git commit -m "Implement feature X"
git add . && git commit -m "Add tests for feature X"

# 4. feature ブランチを push して PR を作成する
git push -u origin feature/descriptive-name
gh pr create --title "Add feature X" --body "Description..."

# 5. PR がマージされたら、ローカル main を更新する
git checkout main
git pull origin main
git branch -d feature/descriptive-name  # 後片付け
```

## ブランチ戦略のルール

**コンポーネントリポジトリの場合**:
1. **main ブランチに直接 commit しない**
2. **あらゆる変更に必ず feature ブランチを使う**
3. **feature ブランチは単一の機能/修正に集中させる**
4. **新しい feature を作る前に main ブランチをリモートと定期的に同期する**
5. **すべての変更に PR を使い**、レビュープロセスを維持する

**ブランチ命名規則**:
```bash
feature/add-student-id-normalization
fix/github-actions-bash-rematch
enhance/error-handling-improvements
docs/update-architecture-guide
```

## コンフリクトからの復旧

**コンフリクトが発生したとき** (緊急時手順):
```bash
# 1. 状況を把握する
git status
git log --oneline -n 10

# 2. リセットしても安全な場合 (重要な未 push 作業がない)
git fetch origin
git reset --hard origin/main

# 3. ローカルの変更を保存する必要がある場合
git stash push -m "WIP: local changes before sync"
git pull origin main
git stash pop  # 必要ならコンフリクトを手動で解消する

# 4. 新しい作業のために feature ブランチを作成する
git checkout -b feature/continue-work
```

## 予防策

**日々のワークフロー**:
```bash
# 一日の始まり: main を同期する
git checkout main && git pull origin main

# 新しい作業の前: feature ブランチを作成する
git checkout -b feature/today-work

# 一日の終わり: feature ブランチを push する
git push -u origin feature/today-work
```

**PR 前のチェックリスト**:
- [ ] feature ブランチが main と最新の状態に同期されている
- [ ] すべての commit が集中していて、よく説明されている
- [ ] ローカルでテストが通る
- [ ] main とのマージコンフリクトがない

## 緊急時手順

**main ブランチが壊れた場合**:
```bash
# ローカル main をリモートに合わせてリセットする
git checkout main
git fetch origin
git reset --hard origin/main

# バックアップ/stash から feature 作業を再作成する
git checkout -b feature/recovered-work
# 変更を適用する...
```

このワークフローは main ブランチのコンフリクト発生を防ぎ、エコシステム全体でのスムーズな協働を保証します。

## エコシステムワークフローとの統合

### エコシステム管理リポジトリの場合
- 同じブランチ戦略のルールを適用する
- エコシステム全体のドキュメント更新には feature ブランチを使う
- 複数のコンポーネントリポジトリにまたがる変更を調整する

### コンポーネントリポジトリの場合
- コンポーネント固有の変更にも同じワークフローに従う
- エコシステム管理リポジトリとの調整を確実に行う
- エコシステムとの互換性に対して変更をテストする
