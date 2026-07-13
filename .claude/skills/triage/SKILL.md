---
name: triage
description: エコシステム全リポジトリの状況を ecosystem-manager で把握し、「今日対応すべき順」に優先順位を付けて提示する。引数なし（または --fast で GitHub API 省略の高速確認）
allowed-tools: Bash(git:*), Bash(gh:*), Bash(mix:*), Bash(./ecosystem-manager/ecosystem-manager:*), Read(*), Grep(*)
---

# エコシステム横断トリアージ

latex-ecosystem 配下の全リポジトリ（各サブディレクトリは独立 Git リポジトリ）の状況を収集し、優先順位付きの対応リストとして提示する。引数に `--fast` が指定されたら GitHub API を使わないローカル確認のみ行う。

## 手順

### 1. escript の準備

```bash
# バイナリが無ければビルド
ls ecosystem-manager/ecosystem-manager 2>/dev/null || (cd ecosystem-manager && mix escript.build)
```

### 2. 状況収集

```bash
# 全体像（branch / uncommitted changes / last commit / PRs / issues）
./ecosystem-manager/ecosystem-manager status --long

# 注意が必要なリポジトリの抽出
./ecosystem-manager/ecosystem-manager status --needs-review
./ecosystem-manager/ecosystem-manager status --urgent-issues
./ecosystem-manager/ecosystem-manager status --with-prs
```

`--fast` 指定時は `status --fast` のみ（GitHub API 呼び出し無し）。

### 3. ドリルダウン

`--long` の結果から要注意リポジトリを特定したら、該当ディレクトリで詳細を確認する。各サブディレクトリは独立リポジトリなので、**サブシェル `( ... )` で実行して現在位置のずれを防ぐ**（`cd` して戻る方式は途中エラーで位置がずれる）:

```bash
(cd <repo>/ && pwd && git status && git log --oneline main..HEAD)
(cd <repo>/ && gh pr list --state open && gh issue list)
(cd <repo>/ && gh pr checks <N>)   # open PR がある場合の CI 確認
```

### 4. 優先順位付きで提示

以下の順で「今日対応すべきリスト」として報告する:

1. **レビュー待ち PR**（--needs-review）— 学生の添削待ちを含むため最優先
2. **CI が red の open PR** — 放置すると merge 不能が続く
3. **urgent Issue**（--urgent-issues）
4. **dirty な作業ツリー / main 以外のブランチのまま**のリポジトリ — 作業の中断・commit 忘れの可能性
5. **その他の open PR / Issue**

各項目には「リポジトリ名・内容の一行要約・推奨アクション」を添える。推奨アクションは既存 Skill に接続する: PR 指摘対応は `/answer <N>`、merge 可能なら `/merge <N>`、Issue 着手は `/start <N>`、AI レビュー判断は `/ai-review`。

該当が何も無ければ「対応不要」と明言して終わる。
