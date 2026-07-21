# テンプレートアーキテクチャ（派生モデル）

エコシステムの文書テンプレート群がどう共通化されているか、新しいテンプレートを追加するときに何をすればよいかをまとめる。読者はテンプレートを保守・新設する教員・開発者。

LaTeX 系テンプレートは、独立したリポジトリの見た目に反して、実体は **latex-template を基底とする派生**である。テンプレート固有の実装はごく薄く、大半は共通レイヤーが担う。この構造を知らずにテンプレートを個別に修正すると、共通部分がリポジトリ間で食い違っていく（実際に caller workflow の permissions 行などで発生した）。共通部分は必ず共通レイヤー側で変更し、テンプレートには固有物だけを置くこと。

## 共通化の4層

| 層 | 実体 | テンプレートに置かれるもの |
|---|---|---|
| ツールチェーン | [texlive-ja-textlint](https://github.com/smkwlab/texlive-ja-textlint)（Docker イメージ） | なし（reusable workflow と devcontainer が参照） |
| ワークフローのロジック | [smkwlab/.github](https://github.com/smkwlab/.github) の reusable workflows | 薄い caller（10〜20 行の呼び出しファイル）のみ |
| caller の配布 | smkwlab/.github の `scripts/distribute-workflow.sh` + `scripts/callers/` | 配布された caller（手で編集しない） |
| 執筆環境 | [aldc](https://github.com/smkwlab/aldc) / [latex-environment](https://github.com/smkwlab/latex-environment)（devcontainer + textlint） | なし（リポジトリ作成時に aldc が注入） |

このほかに、リポジトリ作成時の挙動（リポジトリ名・ブランチ初期化・保護・不要ファイル削除・registry 登録）は [student-repo-management](https://github.com/smkwlab/student-repo-management) の `create-repo` がタイプ設定として持つ。

## 派生モデル

LaTeX 系テンプレートは次の式で表せる。

> テンプレート = 基底（latex-template 相当）+ 内容（tex ファイル・README・CLAUDE.md）+ **3軸の選択** + （任意の）上乗せ

### 3軸

| 軸 | 選択肢 | 実現箇所 |
|---|---|---|
| エンジン | uplatex / lualatex | `.latexmkrc`（2 種類のどちらかを置く） |
| ビルド様式 | all-PR（PR で全対象文書をビルド）/ modified-push（push で変更 tex だけビルド） | caller の選択: `latex-build.yml` / `latex-build-modified.yml` |
| draft PR サイクル | 常時 / オプトイン / なし | student-repo-management の `USE_DRAFT_FLOW`（ブランチ初期化 + 保護） |

draft PR サイクルの有無は**テンプレートの構造差ではない**。draft 系 workflow（create-next-draft / prevent-draft-merge / sync-next-draft）は reusable 側が draft ブランチ名でガードしており、`main` しか持たないリポジトリでは発火しない。したがってテンプレートには常に搭載しておき（休眠搭載）、サイクルを使うかどうかは作成時のブランチ初期化だけで決まる。latex-template の `REVIEW_FLOW` オプトインはこの性質を利用している。

ビルド様式の使い分け: 学期を通してファイルが増え続け PR を使わない文書（週報）は modified-push、提出物一式を稿ごとにレビューする文書は all-PR。

### 現行テンプレートの位置づけ

| テンプレート | エンジン | ビルド様式 | draft サイクル | 上乗せ |
|---|---|---|---|---|
| [latex-template](https://github.com/smkwlab/latex-template)（基底） | uplatex | all-PR | オプトイン（`REVIEW_FLOW`） | — |
| [wr-template](https://github.com/smkwlab/wr-template) | uplatex | modified-push | なし | 図サンプル（`img/`） |
| [sotsuron-report-template](https://github.com/smkwlab/sotsuron-report-template) | uplatex | all-PR | なし | — |
| [poster-template](https://github.com/smkwlab/poster-template) | lualatex | all-PR | 常時 | — |
| [sotsuron-template](https://github.com/smkwlab/sotsuron-template) | uplatex | all-PR | 常時 | 下記参照 |

sotsuron-template の上乗せ:

- **fat template + 作成時剪定**: 卒業論文用（`sotsuron.tex` ほか）と修士論文用（`thesis.tex` ほか）の両方を持ち、student-repo-management が学籍番号から判定して不要な方を削除する。「1 テンプレートで 2 種の文書」はテンプレートを分けずこの方式で実現する
- textlint のカスタム語彙（`.textlintrc` / `.textlintignore` を自前で持つ。aldc の注入より優先される）
- `WRITING-GUIDE.md`（詳細な執筆ガイド）と `plistings.sty`
- `auto-final-merge.yml`（`final-*` タグによる最終提出処理）

### ise-report-template は派生ではない

[ise-report-template](https://github.com/smkwlab/ise-report-template) は HTML スタック（独自 devcontainer、html-validation）であり、LaTeX 派生モデルの対象外。共有しているのはレビューフロー層（draft 系 caller）と caller 配布の仕組みだけである。本文書の派生モデルを適用しないこと。

## テンプレートに置くもの・置かないもの

置くもの（テンプレート固有物）:

- 文書の tex ファイル（と付随素材）
- `.latexmkrc`（uplatex 版 / lualatex 版のどちらか）
- `README.md`（著者情報のひな形。学生リポジトリのトップに表示される）と `.github/README.md`（テンプレート説明。テンプレートリポジトリのトップに表示され、作成時に削除される）— 使い分けの詳細は各テンプレートの CLAUDE.md「Which README is shown where」
- `CLAUDE.md`
- caller workflow（配布物。**個別に手で編集しない**。変更は smkwlab/.github の callers を直してから再配布する）

置かないもの（共通レイヤーが担う）:

- devcontainer・textlint 設定（aldc が注入。sotsuron-template のカスタム語彙のような明確な理由がある場合のみ例外）
- workflow のロジック（reusable workflows に置く）
- リポジトリ作成時の挙動（student-repo-management のタイプ設定に置く）

## 新テンプレート追加チェックリスト

LaTeX 系の新しいテンプレート（例: 新しい提出物種別）を追加する手順。

1. **リポジトリ作成**: smkwlab に `<name>-template` を作成し、Template repository を有効化する
2. **内容**: 文書の tex ファイル、`README.md`（著者情報ひな形）、`.github/README.md`（テンプレート説明）、`CLAUDE.md` を置く
3. **軸の選択**:
   - `.latexmkrc` を uplatex 版 / lualatex 版のどちらかから複製する
   - ビルド様式を決める（all-PR / modified-push）
4. **caller の配布**: smkwlab/.github の `scripts/distribute-workflow.sh` で caller 一式（ビルド、draft 系、notify-ml-on-pr、AI レビュー系）をスタンプする。手でコピーしない
5. **student-repo-management**: `create-repo` にタイプを追加する（テンプレートリポジトリ名・リポジトリ名規則・`USE_DRAFT_FLOW` などの設定と、完了メッセージ）。`docs/RELEASE.md` に従いリリースする
6. **docs の追随**: 本文書の位置づけ表、[GLOSSARY](GLOSSARY.md)・[STUDENT-WORKFLOW](STUDENT-WORKFLOW.md) の対象一覧、教員向け文書（[TEACHER-GUIDE](TEACHER-GUIDE.md) ほか）を確認・更新する。registry の語彙（`review_flow` / type）への追加が要る場合は registry-manager 側も確認する

## 採らない設計

- **メタテンプレートからの生成・同期**（基底リポジトリから各テンプレートを自動生成する方式）: テンプレート 5 個の規模では、同期機構の保守コストが drift 防止の利益を上回る。共通部分は「配布」（caller）と「注入」（aldc）で足りる
- **1 リポジトリへの統合**（作成時に選択剪定する方式の全面化）: GitHub の Template repository 機能・Use this template 運用と両立せず、Issue/PR の管理も混線する
