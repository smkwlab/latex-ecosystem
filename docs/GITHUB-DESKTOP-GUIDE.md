# GitHub Desktop 操作ガイド

draft PR サイクルで執筆するときの GitHub Desktop とブラウザの操作手順をまとめたガイドです。
卒業論文・修士論文、情報科学演習レポート、学会ポスター、汎用 LaTeX 文書のどれでも操作は同じなので、使用中のテンプレートを問わず本書を参照してください。

Git の詳しい知識は必要ありません。
GitHub Desktop の操作とブラウザでの PR 操作だけで、執筆から提出まで完了できます。

- **何を書くか・どの段階で何を提出するか** → [STUDENT-WORKFLOW.md](STUDENT-WORKFLOW.md)（プロセスの流れとルール）
- **どう操作するか** → 本書
- **エディタ・ビルド・品質チェック**（LaTeX Workshop、textlint、HTML 検証など） → 使用中のテンプレートの README

> 本ガイド中の org 名・URL は **smkwlab organization での運用を例**に記述しています。
> 所属する研究室の運用が異なる場合は、担当教員の指示に従ってください。

## 準備

- **GitHub Desktop** をインストールし、GitHub アカウントでサインインしておく
- **Docker Desktop** と **VS Code**（Dev Containers 拡張機能）をインストールしておく

リポジトリの作り方は使用中のテンプレートの README を参照してください。

## 1. リポジトリをクローンする

1. 自分のリポジトリのページをブラウザで開く
2. `Code` ボタンをクリック
3. `Open with GitHub Desktop` をクリック
4. 保存場所を確認して `Clone` ボタンをクリック

クローンできたら、GitHub Desktop の `Open in Visual Studio Code` で編集を始められます。
VS Code で「Dev Containers: Reopen in Container」を実行すると、執筆環境が自動で構築されます。

## 2. ブランチを切り替える

### 最初の稿（`0th-draft`）

GitHub Desktop の `Current Branch` が `0th-draft` になっていることを確認します。
`main` になっている場合は `0th-draft` に切り替えてください。

### 自動作成された次稿ブランチ

PR を作成すると次稿ブランチが自動で作られます。
手元に取り込むには次の操作をします。

1. GitHub Desktop で `Fetch origin` をクリック
2. `Current Branch` をクリックしてブランチ一覧を表示
3. **`origin/` で始まるブランチ**（例: `origin/1st-draft`）を選択
4. 「Create a new branch」と表示されるので `Create branch` をクリック

一覧に出てこないときは、もう一度 `Fetch origin` してから開き直してください。

### ブランチを自分で作る場合

概要用ブランチなど、自動作成されないブランチを作るときの操作です。

1. **分岐元のブランチに切り替えておく**（ここから枝分かれします）
2. GitHub Desktop で `Current Branch` → `New Branch`
3. ブランチ名を入力して `Create branch`
4. `Publish branch` をクリックしてリモートに反映

## 3. 編集して commit & push

1. VS Code でファイルを編集して保存する
2. GitHub Desktop の `Changes` タブに変更ファイルが表示される
3. 左下の `Summary` に変更内容を短く書く（例: `第2章を追記`）
4. `Commit to <ブランチ名>` をクリック
5. `Push origin` をクリックしてリモートに反映

commit はこまめに（1日1回以上）行ってください。
push しておけばバックアップにもなります。

## 4. Pull Request を作成する

書き上がったら PR を作成して添削を依頼します。

1. GitHub Desktop で `Create Pull Request` をクリック（ブラウザが開きます）
2. **base を前稿ブランチに変更する** — ここが最重要です
   - 画面上部の `base:` が既定ブランチ（`main`）のままになっているので、**前の稿のブランチ**に変更する
   - 例: `base: 0th-draft` ← `compare: 1st-draft`、`base: 1st-draft` ← `compare: 2nd-draft`
   - 前の稿がない最初の `0th-draft` の PR だけ `base: main` のままでよい
3. `Title` に現在のブランチ名を書く（例: `1st-draft`）
4. 変更点・工夫した点・質問があれば説明欄に書く
5. `Create pull request` をクリック

base を前稿ブランチにすると、差分がその稿で書き直した部分だけになり、教員が変更点を追いやすくなります。
base が `main` のままだと前の稿の内容まで差分に出てしまいます。

> 作成後に base を間違えたことに気づいた場合は、PR ページのタイトル横の `Edit` から base を変更できます。

## 5. 添削を確認して対応する

添削コメントは、自分が作成した PR のページに付きます。

### コメントへの対応

指摘に応じてファイルを修正し、[3. 編集して commit & push](#3-編集して-commit--push) と同じ手順で反映します。
同じ PR に対する push は自動で反映されるので、PR を作り直す必要はありません。

### Suggestion（修正提案）の適用

教員が具体的な修正案を提示することがあります。
ブラウザ上で適用できます。

1. suggestion の右上の `Apply suggestion` をクリック
2. 複数あるときは `Add suggestion to batch` で選び、まとめて適用できる
3. `Commit suggestions` をクリックして反映

適用した修正は、執筆中の次稿ブランチへも自動で取り込まれます（同じ箇所を次稿でも編集していた場合を除く）。
次稿の作業を再開するときは GitHub Desktop で `Fetch origin` してから `Pull origin` で手元に取り込んでください。

取り込めなかったときは同期 PR が自動作成されるので、下の「7.「Sync review suggestions from ...」という PR が来たら」を参照してください。

### 再レビューの依頼

対応が終わったことを教員に伝えるには、PR ページ右側の `Reviewers` セクションで教員名の横の 🔄 アイコン（`Re-request review`）をクリックします。
教員が一度レビューしていないと表示されません。

## 6. PR をクローズして次稿へ進む

添削への対応が完了したら、**自分で PR をクローズ**します（マージはしません）。

1. PR ページを開く
2. ページ下部の `Close pull request` ボタンをクリック

次稿の執筆は、前稿の PR クローズを待たずに並行して進められます。
詳しいルールは [STUDENT-WORKFLOW.md](STUDENT-WORKFLOW.md) を参照してください。

## 7. 「Sync review suggestions from ...」という PR が来たら

適用した suggestion を次稿ブランチへ自動で取り込めなかったときに、システムが自動で作成する PR です（同じ箇所を前稿と次稿の両方で編集した場合に起きます）。
ブラウザだけで解決できます。

1. その PR のページを開く
2. `Resolve conflicts` ボタンをクリック
3. `<<<<<<<`、`=======`、`>>>>>>>` の行ごと削除し、残したい文章だけの状態に編集する
4. `Mark as resolved` → `Commit merge` をクリック

解決すると同期は自動で再開し、この PR も自動的に処理されます。
うまくいかないときは自己判断で操作を続けず、担当教員に相談してください。

## 8. タグを付ける

提出時など、特定のコミットに目印（タグ）を付けるよう指示されることがあります。

1. GitHub Desktop の `History` で対象のコミットを右クリック
2. `Create Tag...` をクリック
3. `Name` に指示されたタグ名を入力
4. `Create Tag` → `Push origin` でリモートに反映

どのタグをいつ付けるかはテンプレートごとに違います。
使用中のテンプレートの README と教員の指示に従ってください。

## よくある質問

### Q: 自動作成されたはずのブランチが GitHub Desktop に出てこない

`Fetch origin` を実行してから `Current Branch` の一覧を開き直してください。
それでも見つからない場合は自動作成に失敗している可能性があるので、教員に相談してください。

### Q: ブランチを切り替えられない

未 commit の変更が残っていると切り替えられないことがあります。
commit してから切り替えてください。

### Q: commit の内容を間違えた

新しい commit で修正してください。
履歴を書き換える操作（force push など）は禁止です。

### Q: PR の差分に前の稿の内容まで出てしまう

base が `main` のままになっています。
PR ページのタイトル横の `Edit` から base を前稿ブランチに変更してください。

### Q: `Re-request review` ボタンが見つからない

PR が Open の状態で、かつ教員が一度レビューしている必要があります。

### Q: コンフリクト（競合）の解決がうまくいかない

無理に操作を続けず、教員に相談してください。
一緒に解決方法を確認します。

## 困ったときは

解決しないときは担当教員に相談してください（smkwlab では smkwlabML でも質問できます）。
他の学生も同じところでつまずいている可能性があります。
