#!/usr/bin/env bash
#
# build-dashboard.sh — Render the Ecosystem Update Dashboard issue body.
#
# Collects the current update state across the LaTeX ecosystem and prints a
# Markdown body to stdout. Read-only: it queries GitHub but never triggers any
# workflow. The update-dashboard.yml workflow captures this output and upserts
# it into a single pinned issue.
#
# Requires: gh (authenticated via GH_TOKEN), jq.
set -euo pipefail

OWNER="${DASHBOARD_OWNER:-smkwlab}"
NOW="$(date -u +"%Y-%m-%d %H:%M UTC")"

# --- collect -----------------------------------------------------------------

# Latest texlive-ja-textlint release tag (YYYY[letter], version-sorted).
# Degrade to "?" instead of aborting if the API is flaky or returns no tags,
# so a transient hiccup never leaves the dashboard stale.
LATEST="$(gh api "repos/${OWNER}/texlive-ja-textlint/tags" --paginate --jq '.[].name' 2>/dev/null \
  | grep -E '^[0-9]{4}[a-z]*$' | sort -V | tail -1 || true)"
[ -z "$LATEST" ] && LATEST="?"

# Image tag pinned in latex-environment's devcontainer.json on a given ref.
#
# Accept: raw returns the body directly, so no base64 stage can stand in for
# gh's exit code. jq -e fails on an .image that is absent or null, rather than
# printing the string "null" and exiting 0.
#
# Anything else that yields no texlive-ja-textlint tag -- another registry, a
# non-string .image -- reaches the trailing sed, matches nothing, and comes out
# empty. That is not a defect but an answer this script cannot use, so the
# callers read it as unknown instead of failing.
pin_of() {
  gh api -H 'Accept: application/vnd.github.raw' \
    "repos/${OWNER}/latex-environment/contents/.devcontainer/devcontainer.json?ref=$1" \
    | sed -e 's|//.*||g' | jq -e -r '.image' \
    | sed -n 's/.*texlive-ja-textlint://p'
}

# Two kinds of failure, two different catches. A stage that exits non-zero -- a
# bad ref, an absent .image -- travels out through pipefail and is taken by the
# `||` before errexit can abort the script. A stage that succeeds while yielding
# nothing never gets there, and is taken by the -z guard instead; without it
# state() matches neither "?" nor the latest tag and reports 更新可能, inventing
# an update out of a read that came back empty.
MAIN_PIN="$(pin_of main || echo '?')"
[ -z "$MAIN_PIN" ] && MAIN_PIN="?"
REL_PIN="$(pin_of release || echo '?')"
[ -z "$REL_PIN" ] && REL_PIN="?"

# Status cell: ❓ when either side is unknown, ✅ when already current, ⚠️ when
# the pin lags the latest release.
state() {
  if [ "$LATEST" = "?" ] || [ "$1" = "?" ]; then
    echo "❓ 判定不可"
  elif [ "$1" = "$LATEST" ]; then
    echo "✅ 最新"
  else
    echo "⚠️ 更新可能"
  fi
}

# Open update PRs in latex-environment (title mentions texlive).
# --paginate so the list stays complete beyond the first 30 results.
PRS="$(gh api --paginate "repos/${OWNER}/latex-environment/pulls?state=open&per_page=100" \
  --jq '.[] | select(.title|test("texlive";"i")) | "- \(.html_url) — \(.title)"' 2>/dev/null || true)"
[ -z "$PRS" ] && PRS="- (なし)"

# --- render ------------------------------------------------------------------

cat <<EOF
# 📊 Ecosystem Update Dashboard

_最終更新: ${NOW}・このIssueはワークフローが自動生成します（手動編集は次回更新で上書きされます）_

このダッシュボードは読み取り専用です。状態を一覧し、実行コマンドを案内します。

## 🐳 Docker イメージ (texlive-ja-textlint)

最新リリース: \`${LATEST}\`

| 参照箇所 | 現在のpin | 最新 | 状態 |
|---|---|---|---|
| latex-environment \`main\` | \`${MAIN_PIN}\` | \`${LATEST}\` | $(state "$MAIN_PIN") |
| latex-environment \`release\`（aldc配布元） | \`${REL_PIN}\` | \`${LATEST}\` | $(state "$REL_PIN") |

## 🔀 進行中の更新 PR

${PRS}

## ▶️ 手動アクション（コピペで実行）

\`\`\`bash
# 1) texlive 更新PRを生成（latex-environment）
gh workflow run check-texlive-updates.yml --repo ${OWNER}/latex-environment

# 2) マージ後: release ブランチを更新
gh workflow run update-release-branch.yml --repo ${OWNER}/latex-environment
\`\`\`

## 🎓 学生リポジトリへの伝播（latex-ecosystem ルートから）

\`\`\`bash
[ -d registry-manager ] || git clone git@github.com:smkwlab/registry-manager.git
(cd registry-manager && mix escript.build)   # 初回のみ
./registry-manager/registry-manager propagate-workflow --all --type thesis --dry-run
./registry-manager/registry-manager propagate-workflow --all --type thesis
\`\`\`
EOF
