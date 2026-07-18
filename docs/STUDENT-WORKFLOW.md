# 学生向け執筆ワークフローガイド

本エコシステムの文書リポジトリ（卒業論文・修士論文・各種レポートなど）で執筆する学生向けに、リポジトリ作成前の準備から最終提出までの**流れとルール**をまとめたガイドです。draft PR のサイクルはどのテンプレートでも共通です。

- テンプレートの使い方・環境の詳細 → **使用中のリポジトリの README**（卒業論文・修士論文の例: [sotsuron-template の README](https://github.com/smkwlab/sotsuron-template/blob/main/README.md)）
- LaTeX や GitHub Desktop の具体的な操作 → 使用中のテンプレートの執筆ガイド（例: [sotsuron-template の WRITING-GUIDE.md](https://github.com/smkwlab/sotsuron-template/blob/main/WRITING-GUIDE.md)）
- 本書 → 執筆プロセス全体の流れとルール（全テンプレート共通）

> 本ガイド中の org 名・URL は **smkwlab organization での運用を例**に記述しています。所属する研究室の運用が異なる場合は、担当教員の指示に従ってください。

## 1. 全体像

文書は一度に書き上げるのではなく、**段階的に稿を重ねて**完成させます。

```
0th-draft（アウトライン）
    ↓ PR 作成 → 教員レビュー → 対応後、自分で PR をクローズ
1st-draft（初稿）
    ↓ PR 作成 → 教員レビュー → 対応後、自分で PR をクローズ
2nd-draft（改稿）
    ↓ 以降、必要なだけ繰り返し（3rd-draft, 4th-draft, ...）
最終提出（教員の指示でタグ付与）
```

各段階で守ること：

1. その段階のブランチ（`0th-draft`, `1st-draft`, ...）で執筆する
2. 書き上がったら Pull Request（PR）を作成し、教員のレビューを受ける
3. レビューコメントに対応する
4. 対応が完了したら、**自分で PR をクローズ**する（**マージはしない**）
5. 自動作成された次の draft ブランチで執筆を続ける

各段階で「何を書くか」と「教員が何を見るか」の対応：

| 段階 | ブランチ | 書くこと | 教員のレビュー観点 |
|------|----------|----------|--------------------|
| アウトライン | `0th-draft` | 章立て・見出し構造のみ | 論理構成、対象範囲 |
| 初稿 | `1st-draft` | 各章の基本的な文章 | 内容の妥当性、論理展開、表現方法 |
| 改稿 | `2nd-draft` 以降 | 詳細な説明、図表、参考文献 | 文章品質、学術的妥当性、完成度 |
| 概要（卒業論文・修士論文の場合） | `gaiyou-1st` / `abstract-1st` など | 概要（教員の指示後） | 概要としての完成度 |

## 2. リポジトリを作る前に

以下を済ませておいてください。

1. **GitHub アカウントの作成** — アカウントを持っていなければ [github.com](https://github.com/) で作成する
2. **org 招待の受諾** — 所属研究室の organization（例: smkwlab）への招待メールが届いたら受諾する
3. **Docker Desktop のインストール** — LaTeX 環境の実行に必要
4. **GitHub CLI (gh) のインストール** — リポジトリ作成スクリプトの実行に必要。入っていない場合は [インストール方法](https://github.com/smkwlab/student-repo-management/blob/main/docs/INSTALL-GH.md) を参照する

準備ができたら、ターミナル（macOS のターミナル、または Windows の WSL）で次のワンライナーを実行してリポジトリを作成します（例は卒業論文・修士論文の `thesis`。文書タイプは担当教員の指示に従ってください）。

```bash
bash <(curl -fsSL https://repo-setup.smkwlab.net) thesis
```

> 担当教員から**別の URL やコマンドを指示された場合は、必ずそちらを使ってください**（上記は smkwlab での実行例です）。

> 実行前にスクリプトの中身を確認したい場合は、配信されているものと同じ内容を
> [student-repo-management/create-repo/setup.sh](https://github.com/smkwlab/student-repo-management/blob/v1/create-repo/setup.sh)
> で読めます。

学籍番号を入力すると、文書リポジトリの作成とセットアップ（`0th-draft` ブランチの作成を含む）が自動で完了します。

## 3. 環境を起動する

1. 作成されたリポジトリを手元にクローンする（GitHub Desktop 推奨）
2. VS Code で開く。**Dev Containers 拡張機能**を入れておくと、開くだけで執筆環境（LaTeX Workshop・textlint など）が自動で使えるようになる

具体的な手順は使用中のリポジトリの README を参照してください（卒業論文・修士論文の例: [sotsuron-template README の「学生向けクイックスタート」](https://github.com/smkwlab/sotsuron-template/blob/main/README.md#-学生向けクイックスタート)）。

## 4. 第0稿（アウトライン）を提出する

最初の提出は**章立てだけ**です。本文はまだ書きません。

1. ブランチが `0th-draft` になっていることを確認する
2. 文書のメインファイルに章・節の構成を書く（内容は未記入で OK）。卒業論文の場合は `sotsuron.tex`、修士論文の場合は `thesis.tex` に `\chapter`, `\section` などで書く。ファイル名は使用中のリポジトリの README を参照
3. PDF（または成果物）を生成して構成を確認する
4. commit & push して PR を作成する
   - タイトル例: `[0th-draft] アウトライン提出`

この段階の教員レビューの観点は**構成のみ**です（章立て・対象範囲・論理構成）。文章の完成度はまだ問われません。

## 5. レビューを受けて次の稿へ進む

PR を作成すると、次の稿のブランチ（`1st-draft` など）が**自動で作成**されます。以降は次のサイクルの繰り返しです。

1. **レビューコメントを確認する** — GitHub の PR ページで教員のコメントや Suggestion を確認する
2. **指摘に対応する** — 修正・追記して commit & push する（Suggestion はそのまま適用でき、適用した修正は次稿ブランチへも自動で取り込まれる）
3. **自分で PR をクローズする** — 対応が完了したら、PR ページの「Close pull request」ボタンでクローズする（**マージはしない**）
4. **次の draft ブランチに切り替えて執筆を続ける** — GitHub Desktop で `Fetch origin` してから、自動作成されたブランチ（`origin/1st-draft` など）に切り替える
5. 書き上がったら PR を作成する（タイトル例: `[1st-draft] 第1章〜第3章初稿提出`）

補足：

- 次稿の執筆は前稿の PR クローズと**並行して**進めてよい（クローズを待つ必要はない）
- 前稿の PR で適用した Suggestion は次稿ブランチへ自動で merge される。次稿の執筆を再開するときは `Fetch origin`（`git pull`）で取り込む
- commit はこまめに（1日1回以上）。push すればバックアップにもなる
- 稿が進むにつれて、レビューの観点は「構成 → 内容・論理展開 → 文章品質・詳細」へと深まっていく

### 提出前のセルフチェック

PR を作成する前に、毎回次の3点を確認してください。

1. **コンパイルが通る** — LaTeX の構文エラーを解消し、PDF が生成できる状態にする
2. **textlint の指摘に対応済み** — VS Code の「問題」タブで日本語校正の指摘を確認する
3. **印刷して推敲した** — 画面だけでなく紙で読み直す（章ごとの印刷推敲を推奨）

参考文献を使う場合は BibTeX 形式を適切に使ってください。

## 6. 概要を執筆する（卒業論文・修士論文の場合）

論文本体がある程度完成すると、**教員から概要執筆開始の指示**があります。指示があるまで始めないでください。

- 概要は専用ブランチで添削を受ける：`gaiyou-1st`（日本語概要 `gaiyou.tex`）/ `abstract-1st`（英文概要 `abstract.tex`）
- 論文本体と同じく「PR 作成 → レビュー → 対応 → 自分でクローズ」のサイクルで進める（次の概要ブランチも自動作成される）

ブランチの作り方など詳細は [sotsuron-template の WRITING-GUIDE.md](https://github.com/smkwlab/sotsuron-template/blob/main/WRITING-GUIDE.md) の「概要の執筆」を参照してください。

## 7. 最終提出

教員から「提出 OK」の許可が出たら、**教員の指示に従って**提出版のコミットにタグを付与します。`final-*` 形式のタグが付与されると、最終提出処理（main への提出 PR の自動作成とリリース作成）が自動で実行されます。提出 PR のマージは教員が行います。

タグの名前と付け方の手順は使用中のリポジトリの README を参照してください（卒業論文・修士論文の例: [sotsuron-template README の「論文提出について」](https://github.com/smkwlab/sotsuron-template/blob/main/README.md#-論文提出について)）。概要完成後の手順は教員から口頭で説明されます。

## 8. してはいけないこと

以下の操作はワークフローを壊すので**禁止**です。

- ❌ draft ブランチから `main` への直接マージ（PR は必ず「クローズ」する）
- ❌ フォースプッシュ（`git push --force`）
- ❌ ブランチの削除
- ❌ 教員の指示より前の概要執筆・タグ付与

## 9. よくあるつまずき

- **PR をいつクローズすべきか分からない** — 教員の添削を確認し、対応が完了したタイミングでクローズする。次稿の執筆前にクローズしておく必要はない（並行作業できる）
- **ブランチが切り替えられない** — 未 commit の変更が残っていないか確認する。commit してから切り替える
- **自動作成されたはずの次稿ブランチが見えない** — GitHub Desktop で `Fetch origin` してからブランチ一覧を開き直す
- **「Sync review suggestions from ...」という PR が自動で作られた** — 前稿で適用した Suggestion を次稿へ自動で取り込めなかった（同じ箇所を両方の稿で編集した）合図。その PR の説明に従い「Resolve conflicts」ボタンで残したい文に編集すれば、あとは自動で処理される
- **PDF が生成されない** — VS Code の「問題」タブでコンパイルエラーの内容を確認する

解決しないときは担当教員に相談してください（smkwlab では smkwlabML でも質問できます）。

## 10. 参考リンク

- **使用中のリポジトリの README** — テンプレートの使い方・環境構築・提出手順（卒業論文・修士論文の例: [sotsuron-template の README](https://github.com/smkwlab/sotsuron-template/blob/main/README.md)）
- [sotsuron-template の WRITING-GUIDE.md](https://github.com/smkwlab/sotsuron-template/blob/main/WRITING-GUIDE.md) — GitHub Desktop の詳細操作・トラブルシューティング・FAQ（卒業論文・修士論文）
- [PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md) — 添削ルールの正典（ブランチ命名・自動化の仕様）
