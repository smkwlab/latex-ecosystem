# 用語集

本エコシステムの文書で使う中核概念の用語を定義します。用語を追加・変更するときは、まず本ファイルを更新し、末尾の手順で各文書へ伝播させてください。

## draft PR サイクル

`0th-draft` などの draft ブランチで執筆し、Pull Request で添削を受け、自動作成される次の稿のブランチ（`1st-draft`, `2nd-draft`, ...）で改稿を続ける繰り返し。draft PR はマージせずクローズする。

- **英語文書・コード中の表記**: draft PR cycle
- **適用範囲**: thesis（卒業論文・修士論文）/ ise（情報科学演習レポート）/ poster（学会ポスター）の各テンプレートでは常時有効。latex（汎用 LaTeX 文書）は任意参加（作成時の `REVIEW_FLOW=true`、または自分で `0th-draft` ブランチを作成）。wr（週報）と sotsuron-report（卒業論文調査報告）は対象外
- **表記ルール**: 文書の初出には一文定義を付ける。「draft サイクル」「draft PR のサイクル」などのゆらぎは使わない
- **旧称（廃止）**: draft-to-draft PR workflow、draft-chain、ドラフトレビューワークフロー
- **備考**: 学生に伝わりやすい名称は試行錯誤中であり、本語は現時点の採用語

## Pull Request ベース添削（添削フロー）

draft PR サイクルを**中核として、添削に関わる複数の仕組みを束ねた全体**。主に教員向け文書（[PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md) ほか）が扱う。構成要素:

- **draft PR サイクル**（中核）: 稿の反復そのもの
- **suggestion 運用**: 教員の suggestion 適用と、次稿ブランチへの自動伝播（sync-next-draft）
- **ブランチ保護**: main への誤マージ・直接 push の防止（prevent-draft-merge + branch protection）
- **AI レビュー**: PR ごとの自動レビュー（ai-academic-paper-reviewer）
- **レビュアー自動アサイン**、**最終提出処理**（`final-*` タグ）など

## 用語を変更するときの手順

まず**本ファイルの定義を更新**し、その後、次の文書へ伝播させる:

1. [STUDENT-WORKFLOW.md](STUDENT-WORKFLOW.md)（学生向け説明の本体）
2. 各テンプレート README: sotsuron-template（+ WRITING-GUIDE.md）/ ise-report-template / poster-template / latex-template
3. [PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md) の対応付けの一文
4. 管理・開発文書: latex-ecosystem の CLAUDE.md・ECOSYSTEM.md・[MULTI-ORG-DEPLOYMENT.md](MULTI-ORG-DEPLOYMENT.md)・`.claude/skills/propagate`、student-repo-management のスクリプトコメント
