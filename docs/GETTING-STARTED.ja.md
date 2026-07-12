# エコシステム運用はじめの一歩

> 🌐 English version: [GETTING-STARTED.md](GETTING-STARTED.md)

LaTeX 卒論エコシステムの運用を引き継ぐ（または新しく始める）ための手順を、順を追って説明するガイドです。
詳細はリンク先のドキュメントに任せ、本ガイドは「どの手順を、どの順番で」だけを示します。

## 1. 対象読者

このエコシステムを**運用**しようとしている人 — 学生リポジトリの作成、
PR ベースの添削フロー、学生レジストリの管理を担う人 — が対象です。
論文を*書く*だけ、*添削する*だけの場合は
[ドキュメントガイド](README.md) を参照してください。

## 2. 前提条件

- 対象 GitHub org の **admin 権限**
- **GitHub CLI (`gh`)**（認証済み: `gh auth login`）
- **Docker**（学生リポジトリ作成はコンテナ内で実行されます）
- **Elixir/Mix** — 開発用ワークスペースを構築する場合、または
  `ecosystem-manager` / `registry-manager` / `thesis-monitor` を使う場合のみ

ツールのインストール詳細は
[SETUP-AND-RELEASE.ja.md](SETUP-AND-RELEASE.ja.md) の「前提条件」を参照。

## 3. Path A: 対象 org が構築済みの場合

対象の organization で既に本エコシステムが運用されている場合（例:
元々のデプロイである `smkwlab`）、必要なのはローカルのワークスペースだけです。

```bash
# ワンライナーでワークスペース構築（全コンポーネントリポジトリを clone）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/latex-ecosystem/main/setup.sh)"

# ecosystem manager のビルド（初回のみ）
cd latex-ecosystem-dev   # setup.sh が既定で作成するディレクトリ（既存チェックアウト内で実行した場合は作成されない）
(cd ecosystem_manager && mix escript.build)

# 動作確認: 全リポジトリの状態表示
./ecosystem_manager/ecosystem-manager status
```

セットアップの変種（カスタム配置、手動 clone）は
[SETUP-AND-RELEASE.ja.md](SETUP-AND-RELEASE.ja.md) を参照。

続けて [最初の学生リポジトリ](#5-最初の学生リポジトリ) へ。

## 4. Path B: 新しい org に展開する

新しい org でプロビジョニングが必要なのは、要点だけ挙げると:

- **GitHub App** 1つ（リポジトリ自動化の認証情報）
- private な**レジストリリポジトリ** 1つ（`<org>/thesis-student-registry`）
- org 内にコピーした**文書テンプレート**
- 少数の **secrets / variables**

正確な権限、secrets の一覧表、fork の設定、検証チェックリストまで、すべて
[MULTI-ORG-DEPLOYMENT.ja.md](MULTI-ORG-DEPLOYMENT.ja.md) にあります。
最後まで実施してから、ここに戻ってきてください。

## 5. 最初の学生リポジトリ

作成方法は2通り:

1. **学生自身が実行（通常経路）** —
   [student-repo-management/create-repo/setup.sh](https://github.com/smkwlab/student-repo-management/blob/main/create-repo/setup.sh)
   のワンライナーを学生に実行してもらう:

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/student-repo-management/main/create-repo/setup.sh)" bash thesis
   ```

   > 上記 URL は **smkwlab デプロイの**エントリポイントです。それ以外のデプロイでは、
   > **自 org のフォーク**の `setup.sh`（[MULTI-ORG-DEPLOYMENT.ja.md](MULTI-ORG-DEPLOYMENT.ja.md)
   > の fork 設定表に従って設定済みのもの）を学生に実行させてください — smkwlab の
   > URL のままでは smkwlab の既定値でリポジトリが作成されてしまいます。

2. **登録 Issue 経由** — org の `student-repo-management` に
   リポジトリ作成依頼 Issue を作成すると、あとは GitHub Actions が処理します。

作成後の確認:

- 新しいリポジトリに**ブランチ保護**が適用されていること
- `data/registry.json` に登録されていること:

  ```bash
  ./thesis-monitor/thesis-monitor status
  ```

どちらかの確認に失敗した場合は、自動化のセットアップガイド
[GITHUB-ACTIONS-SETUP.md](https://github.com/smkwlab/student-repo-management/blob/main/docs/GITHUB-ACTIONS-SETUP.md)
を参照してください。

## 6. 教員と学生のオンボーディング

- **教員** →
  [TEACHER-ONBOARDING.md](TEACHER-ONBOARDING.md)
- **学生** → 各学生リポジトリに生成される README、および
  [STUDENT-WORKFLOW.md](STUDENT-WORKFLOW.md)

## 7. 日常運用（Day-2 operations）

- **定常的な管理**（状態確認、リポジトリ横断の調整、リリース）→
  [MANAGEMENT-WORKFLOWS.ja.md](MANAGEMENT-WORKFLOWS.ja.md) と
  [SETUP-AND-RELEASE.ja.md](SETUP-AND-RELEASE.ja.md)
- **学生の進捗監視** →
  [thesis-monitor](https://github.com/smkwlab/thesis-monitor)
  （`thesis-monitor status`）
- **添削ルールの正典** →
  [PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md)
