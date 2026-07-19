# 用語集（層別呼称マップ）

本エコシステムでは、同じ概念が**読者層ごとに意図的に異なる名称**で呼ばれています。呼び分け自体は方針です（統一しません）が、対応関係はここに集約します。用語を追加・変更するときは、本ファイルを起点に各文書へ伝播させてください。

## draft PR サイクル

**概念**: `0th-draft` などの draft ブランチで執筆し、Pull Request で添削を受け、自動作成される次の稿のブランチ（`1st-draft`, `2nd-draft`, ...）で改稿を続ける繰り返し。draft PR はマージせずクローズする。

**適用範囲**: thesis（卒業論文・修士論文）/ ise（情報科学演習レポート）/ poster（学会ポスター）の各テンプレートでは常時有効。latex（汎用 LaTeX 文書）は任意参加（作成時の `REVIEW_FLOW=true`、または自分で `0th-draft` ブランチを作成）。wr（週報）は対象外。

### 層別の呼称

| 層 | 主な文書 | 呼称 | 備考 |
|---|---|---|---|
| 学生向け | [STUDENT-WORKFLOW.md](STUDENT-WORKFLOW.md)、各テンプレート README（sotsuron / ise / poster / latex） | **draft PR サイクル** | 採用語。初出には一文定義を付ける |
| 教員向け | [PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md) ほか教員向け文書 | 「Pull Request ベース添削」「添削フロー」 | **サイクルより広い概念**（suggestion 運用・ブランチ保護・AI レビューを含む仕組み全体）を指す。その中核が draft PR サイクル |
| 管理・開発者向け | latex-ecosystem CLAUDE.md、/propagate skill、[MULTI-ORG-DEPLOYMENT.md](MULTI-ORG-DEPLOYMENT.md)、student-repo-management | 「draft-to-draft PR workflow」「draft-chain」「ドラフトレビューワークフロー」 | 実装視点の呼称（ブランチ階層・workflow 群を指す文脈で使用） |
| 学術文書 | 研究会論文（例: toshi-iot74） | 「レビューの工程化」「草稿ブランチ」／英文は "draft-to-draft PR workflow" | 広い読者を想定し、システムに依存しない一般的表現を意図的に採用 |

### 呼び分けの方針

- **学生向け**: 「これから学ぶ学生に伝わりやすいか」を試行錯誤している最中であり、「draft PR サイクル」は**現時点の採用語**。学生向け文書内ではこの語で統一し、「draft サイクル」「draft PR のサイクル」などのゆらぎは使わない
- **教員向け**: 「Pull Request ベース添削」は同一概念の言い換えではなく上位概念のため、統一の対象外
- **論文**: システム非依存の一般表現を優先するため、統一の対象外

### 学生向け採用語を変更するときの手順

まず**本ファイルの呼称表と定義を更新**し、その後、次の文書へ伝播させる:

1. [STUDENT-WORKFLOW.md](STUDENT-WORKFLOW.md)（定義の本体）
2. 各テンプレート README: sotsuron-template（+ WRITING-GUIDE.md）/ ise-report-template / poster-template / latex-template
3. [PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md) の対応付けの一文

（経緯: [#137](https://github.com/smkwlab/latex-ecosystem/issues/137)、用語統一の議論は #135 / #136）
