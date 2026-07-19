# 用語集（層別呼称マップ）

本エコシステムでは、同じ概念が**読者層ごとに意図的に異なる名称**で呼ばれています。呼び分け自体は方針です（統一しません）が、対応関係はここに集約します。用語を追加・変更するときは、本ファイルを起点に各文書へ伝播させてください。

## draft PR サイクル

**概念**: `0th-draft` などの draft ブランチで執筆し、Pull Request で添削を受け、自動作成される次の稿のブランチ（`1st-draft`, `2nd-draft`, ...）で改稿を続ける繰り返し。draft PR はマージせずクローズする。

**適用範囲**: thesis（卒業論文・修士論文）/ ise（情報科学演習レポート）/ poster（学会ポスター）の各テンプレートでは常時有効。latex（汎用 LaTeX 文書）は任意参加（作成時の `REVIEW_FLOW=true`、または自分で `0th-draft` ブランチを作成）。wr（週報）は対象外。

### 層別の呼称

| 層 | 主な文書 | 呼称 | 備考 |
|---|---|---|---|
| 学生向け・管理/開発者向け | [STUDENT-WORKFLOW.md](STUDENT-WORKFLOW.md)、各テンプレート README（sotsuron / ise / poster / latex）、latex-ecosystem CLAUDE.md、/propagate skill、[MULTI-ORG-DEPLOYMENT.md](MULTI-ORG-DEPLOYMENT.md)、student-repo-management | **draft PR サイクル**（英語文書では **draft PR cycle**） | エコシステム内の文書はこの語で統一。初出には一文定義を付ける。旧呼称「draft-to-draft PR workflow」「draft-chain」「ドラフトレビューワークフロー」は #137 で廃止 |
| 教員向け | [PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md) ほか教員向け文書 | 「Pull Request ベース添削」「添削フロー」 | 同一概念の言い換えではなく**上位概念**（次節参照） |
| 学術文書 | 研究会論文（例: toshi-iot74） | 「レビューの工程化」「草稿ブランチ」／英文は "draft-to-draft PR workflow" | 広い読者を想定し、システムに依存しない一般的表現を意図的に採用（統一の対象外） |

### 「Pull Request ベース添削」との関係（上位概念）

教員向け文書の「Pull Request ベース添削（添削フロー）」は、draft PR サイクルの言い換えではなく、**それを中核として複数の仕組みを束ねた全体**を指します:

- **draft PR サイクル**（中核）: 稿の反復そのもの
- **suggestion 運用**: 教員の suggestion 適用と、次稿ブランチへの自動伝播（sync-next-draft）
- **ブランチ保護**: main への誤マージ・直接 push の防止（prevent-draft-merge + branch protection）
- **AI レビュー**: PR ごとの自動レビュー（ai-academic-paper-reviewer）
- **レビュアー自動アサイン**、**最終提出処理**（`final-*` タグ）など

つまり「Pull Request ベース添削」⊃「draft PR サイクル」です。学生は中核のサイクルだけ理解すれば執筆でき、教員向け文書は周辺の仕組みを含めた全体を扱う、という役割分担です。

### 呼び分けの方針

- **エコシステム内の文書（学生向け・管理/開発者向け）**: 「draft PR サイクル」で統一（英語文書では draft PR cycle）。「draft サイクル」「draft PR のサイクル」などのゆらぎは使わない。学生に伝わりやすい表現は試行錯誤中であり、この語は**現時点の採用語**
- **教員向け**: 「Pull Request ベース添削」は上位概念のため別語のまま維持
- **論文**: システム非依存の一般表現を優先するため、統一の対象外

### 採用語を変更するときの手順

まず**本ファイルの呼称表と定義を更新**し、その後、次の文書へ伝播させる:

1. [STUDENT-WORKFLOW.md](STUDENT-WORKFLOW.md)（定義の本体）
2. 各テンプレート README: sotsuron-template（+ WRITING-GUIDE.md）/ ise-report-template / poster-template / latex-template
3. [PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md) の対応付けの一文
4. 管理・開発文書: latex-ecosystem の CLAUDE.md・ECOSYSTEM.md・[MULTI-ORG-DEPLOYMENT.md](MULTI-ORG-DEPLOYMENT.md)・`.claude/skills/propagate`、student-repo-management のスクリプトコメント

（経緯: [#137](https://github.com/smkwlab/latex-ecosystem/issues/137)、用語統一の議論は #135 / #136）
