# 用語集

本エコシステムの文書で使う中核概念の用語を定義します。用語を追加・変更するときは、まず本ファイルを更新し、末尾の手順で各文書へ伝播させてください。

## draft PR サイクル

`0th-draft` などの draft ブランチで執筆し、Pull Request で添削を受け、自動作成される次稿ブランチ（`1st-draft`, `2nd-draft`, ...）で改稿を続ける繰り返し。draft PR はマージせずクローズする。

- **英語文書・コード中の表記**: draft PR cycle
- **適用範囲**: thesis（卒業論文・修士論文）/ ise（情報科学演習レポート）/ poster（学会ポスター）の各テンプレートでは常時有効。latex（汎用 LaTeX 文書）は任意参加（作成時の `REVIEW_FLOW=true`、または自分で `0th-draft` ブランチを作成）。wr（週報）と sotsuron-report（卒業論文調査報告）は対象外
- **表記ルール**: 文書の初出には一文定義を付ける。「draft サイクル」「draft PR のサイクル」などのゆらぎは使わない
- **旧称（廃止）**: draft-to-draft PR workflow、draft-chain、ドラフトレビューワークフロー
- **備考**: 学生に伝わりやすい名称は試行錯誤中であり、本語は現時点の採用語

## 稿・前稿ブランチ・次稿ブランチ

draft PR サイクルで提出する各版を**稿**と呼び、その執筆に使うブランチを **draft ブランチ**（`0th-draft`, `1st-draft`, `2nd-draft`, ...）と呼ぶ。ある稿から見て 1 つ前の稿のブランチが**前稿ブランチ**、PR 作成時に GitHub Actions が自動作成する 1 つ後の稿のブランチが**次稿ブランチ**（create-next-draft）。

- **英語文書・コード中の表記**: draft branch / previous draft branch / next draft branch
- **表記ルール**: 繰り返される手順の説明では、リテラルのブランチ名ではなく「前稿ブランチ」「次稿ブランチ」と書く。`1st-draft` などのリテラルは、初回サイクルの例としてのみ併記する（手順文をリテラルで書くと 2 巡目以降で説明が成り立たなくなるため）
- **旧称（廃止）**: 次版ブランチ、次稿用ブランチ、次の稿のブランチ、次の draft ブランチ

## draft PR の base

draft PR は**前稿ブランチを base（マージ先）**にして作成する。前の稿がない最初の `0th-draft` の PR だけ `base: main` とする。

- **表記ルール**: 例示は GitHub の PR 作成画面と同じ **`base: 0th-draft` ← `compare: 1st-draft`** の形式で書く。`0th-draft → main` のように矢印だけで示す表記は、どちらが base か読み取れないため使わない
- **理由**: 差分が前稿からの変更点だけになり、教員がその稿で何が変わったかを追える
- **注意**: GitHub Desktop の `Create Pull Request` から開く画面では base が既定ブランチ（`main`）のままになるため、学生向け文書では base を変更する操作を明示する

## Pull Request ベース添削（添削フロー）

draft PR サイクルを**中核として、添削に関わる複数の仕組みを束ねた全体**。主に教員向け文書（[PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md) ほか）が扱う。構成要素:

- **draft PR サイクル**（中核）: 稿の反復そのもの
- **suggestion 運用**: 教員の suggestion 適用と、次稿ブランチへの自動伝播（sync-next-draft）
- **ブランチ保護**: main への誤マージ・直接 push の防止（prevent-draft-merge + branch protection）
- **AI レビュー**: PR ごとの自動レビュー（ai-academic-paper-reviewer）
- **レビュアー自動アサイン**、**最終提出処理**（`final-*` タグ）など

## 用語を変更するときの手順

まず**本ファイルの定義を更新**し、その後、次の文書へ伝播させる:

1. [STUDENT-WORKFLOW.md](STUDENT-WORKFLOW.md)（学生向け説明の本体。流れとルール）
2. [GITHUB-DESKTOP-GUIDE.md](GITHUB-DESKTOP-GUIDE.md)（学生向けの操作手順。テンプレート共通）
3. 各テンプレート README: sotsuron-template（+ 卒論固有の WRITING-GUIDE.md）/ ise-report-template / poster-template / latex-template
4. [PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md) の対応付けの一文
5. 管理・開発文書: latex-ecosystem の CLAUDE.md・ECOSYSTEM.md・[MULTI-ORG-DEPLOYMENT.md](MULTI-ORG-DEPLOYMENT.md)・`.claude/skills/propagate`、student-repo-management のスクリプトコメント
