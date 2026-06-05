#!/usr/bin/env bash
#
# build-dashboard.sh — Render the Ecosystem Update Dashboard issue body.
#
# Collects the current update state across the LaTeX ecosystem and prints a
# Markdown body to stdout. Read-only: it queries GitHub but never triggers any
# workflow. The update-dashboard.yml workflow captures this output and upserts
# it into a single pinned issue.
#
# Requires: gh (authenticated via GH_TOKEN), jq, base64.
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
pin_of() {
  gh api "repos/${OWNER}/latex-environment/contents/.devcontainer/devcontainer.json?ref=$1" \
    --jq '.content' | base64 -d | sed -e 's|//.*||g' | jq -r '.image' \
    | sed -n 's/.*texlive-ja-textlint://p'
}
MAIN_PIN="$(pin_of main || echo '?')"
REL_PIN="$(pin_of release || echo '?')"

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

## 🎓 学生リポジトリへの伝播（thesis-student-registry チェックアウトのルートから）

\`\`\`bash
(cd registry_manager && mix escript.build)   # 初回のみ
./registry_manager/registry-manager propagate-workflow --all --type thesis --dry-run
./registry_manager/registry-manager propagate-workflow --all --type thesis
\`\`\`
EOF
