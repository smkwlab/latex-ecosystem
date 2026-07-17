# マルチ org 展開ガイド

> 🌐 English version: [MULTI-ORG-DEPLOYMENT.md](MULTI-ORG-DEPLOYMENT.md)

LaTeX 卒論エコシステムを `smkwlab` 以外の GitHub org に展開する方法を説明します。

自動化の中核は org スコープになっており、学生向けのエントリポイントも `smkwlab`
を既定値とするパラメータ化がされているため、フォークは少数のつまみを設定するだけ
で自分自身を再ホームできます。このガイドは、新しい org が用意しなければならないもの、
自動化が消費する正確なリソースとシークレット、そして org ↔ レジストリの関係がどう
解決されるかを文書化します。

## アーキテクチャ: org ↔ レジストリの関係はどう解決されるか

org とレジストリの関係は、中央の設定にはいっさい保存されていません。
コンポーネントごとに、3 つの異なるレイヤーで解決されます。

1. **GitHub Actions（自動化の中核）** — `github.repository_owner` から動的に
   導出されます。レジストリリポジトリは既定で
   `<org>/thesis-student-registry` という規約に従い、org/repo 変数
   `REGISTRY_REPO` で上書きできます
   (`student-repo-management/.github/workflows/student-repo-management.yml`)。
   ローカル設定はいっさい関与しません。
2. **ローカル管理ツール** — ツールごとの設定ファイル
   (`~/.config/<tool>/config.yml`) から解決され、同じ規約の既定値を使います。
   [ローカルツールの設定](#local-tool-configuration)を参照。
3. **学生向けのエントリポイント** (`setup.sh`, `aldc`, テンプレートワークフロー) —
   `smkwlab` を既定値とする環境変数のつまみ (`DEFAULT_ORG`, `TEMPLATE_REPO`,
   `ALDC_URL`, …) でパラメータ化されています。フォークはこれらを設定して
   自分自身を再ホームします（[create-repo フォークの設定](#5-create-repo-fork-configuration)を参照）。
   テンプレートワークフローは設計上、依然として `smkwlab/.github` を
   リテラルで参照します（[共有インフラ](#shared-infrastructure-reference-strategy)を参照）。

## そのまま動くもの

以下のコンポーネントは *Organization-Scoped Deployment* 原則
(ECOSYSTEM.md) に従っており、コード変更は不要です。

- **リポジトリ作成パイプライン** (`student-repo-management`):
  `student-repo-management.yml`, `process-pending-issues.sh`,
  `setup-branch-protection.sh` は org を
  `github.repository_owner` / `GITHUB_REPOSITORY` から導出し、レジストリを
  `<org>/thesis-student-registry` として解決します。org をまたぐリクエストは
  明示的なガードで拒否されます。
- **レジストリ自動登録**: `data/registry.json` の更新は、解決されたレジストリ
  リポジトリを使って GitHub API 経由で行われます。認証には実行ごとに発行される
  GitHub App のインストールトークンを使い、PAT は使いません。
- **ecosystem-manager**: 完全に org 非依存です。org はワークスペースルートの
  `origin` リモートから導出され、リポジトリの自動検出はそのオーナーで
  フィルタリングされます。

<a id="prerequisites-in-the-new-organization"></a>
## 新しい org における前提条件

自動化は、1 つの GitHub App、1 つのレジストリリポジトリ、一連のテンプレート、
そして少数のシークレットと変数で駆動されます。学生をオンボーディングする前に、
以下のすべてを用意してください。（`student-repo-management.yml`,
`ai-code-review.yml`, `notify-ml-on-pr.yml`, `create-repo/*.sh` に対して
検証済み。）

> **org プランの要件。** 卒論リポジトリは **private** で作成され
> (`create-repo/main.sh` が `VISIBILITY="private"` を設定)、登録ワークフローが
> それらにブランチ保護を適用します。*private* リポジトリへのブランチ保護には
> 有料の GitHub プラン（Team または Enterprise）が必要です。**Free** プランでは
> 保護ステップが HTTP 403 (`Upgrade to GitHub Pro or make this repository public
> to enable this feature`) で失敗し、登録実行は失敗で終わります。学生を
> オンボーディングする前に、新しい org を private リポジトリへのブランチ保護を
> 許可するプランに置いてください。（2026-07-11 に Free テスト org で検証済み:
> 他のすべてのステップ — App トークン、レジストリ書き込み、issue クローズ —
> は成功し、private リポジトリへのブランチ保護呼び出しだけが拒否されました。）

### 1. リポジトリ

| リポジトリ | 目的 | 備考 |
|---|---|---|
| `<org>/thesis-student-registry` (private) | `data/registry.json` を保持 | `registry-manager init --org <org>` で初期化する（設定が既に存在する場合は `--force` を追加。[ローカルツールの設定](#local-tool-configuration)を参照）。非標準の名前を使う場合は後述の `REGISTRY_REPO` 変数が必要。 |
| `<org>/student-repo-management` | 登録ワークフローと `create-repo` スクリプトをホスト | フォーク/コピー。App シークレットと後述のフォーク設定を保持する。 |
| `<org>/sotsuron-template`, `<org>/wr-template`, `<org>/ise-report-template` | 学生用ドキュメントテンプレート | **org 内に存在する必要がある** — `create-repo` はこれらを `${ORGANIZATION}/<template>` として解決する。 |
| `<org>/latex-template`, `<org>/poster-template` | 汎用 LaTeX / ポスターテンプレート | 既定では `smkwlab/...`（共有）。`TEMPLATE_REPO` を自分のコピーに向ける場合にのみ org 内に必要。 |

### 2. GitHub App（`<org>/student-repo-management` 上）

`student-repo-management.yml` は `actions/create-github-app-token` を使い
`owner: <org>` で実行ごとのインストールトークンを発行するため、単一の App で
このリポジトリ、レジストリ、学生リポジトリに到達できます。

- **権限**: `contents: write`（レジストリのコミットとリポジトリ内容）、
  `administration: write`（ブランチ保護）、`issues: write`（登録 issue の
  クローズ）。
- **インストール**: org 全体が最もシンプル（`student-repo-management`、
  レジストリ、学生リポジトリをカバーする必要がある）。
- **`student-repo-management` 上のシークレット**: `APP_ID`, `APP_PRIVATE_KEY`。

### 3. Actions 変数（任意）

- `student-repo-management` 上の `REGISTRY_REPO` — レジストリリポジトリ名が
  `<org>/thesis-student-registry` から外れる場合にのみ設定する。

### 4. シークレット

各シークレットは、それを使うワークフローが動く場所に置きます。AI キーと ML の
設定については、すべての学生リポジトリが継承できるよう **org シークレット** を
推奨します。

| シークレット | 消費元 | 置き場所 | 必須? |
|---|---|---|---|
| `APP_ID`, `APP_PRIVATE_KEY` | 登録自動化 (`student-repo-management.yml`) | `student-repo-management` | **はい** — これがないと登録は実行できない |
| `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` | 学生リポジトリの `ai-review` / `claude-qa`、および `student-repo-management` 自身の `ai-code-review.yml` | org（学生リポジトリ）＋ `student-repo-management` | 任意 — AI ジョブは無い場合にクリーンにスキップする |
| `SMTP_SERVER`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM`, `LAB_ML_ADDRESS` | `notify-ml-on-pr` 再利用可能ワークフロー（sotsuron / ise / latex テンプレート、`secrets: inherit`） | org | このワークフローが要求 — **6 つすべて**。ML メールを省く場合は、代わりにテンプレートから `notify-ml-on-pr.yml` を削除する。 |

すべてのシークレット値はプレーンな文字列です（GitHub シークレットは常に
文字列）。`SMTP_PORT` は例えば `587` のように設定します。`notify-ml-on-pr` は
それをそのままメールアクションに渡すため、数値型は不要です。

<a id="5-create-repo-fork-configuration"></a>
### 5. create-repo フォークの設定

フォークした `create-repo` スクリプトは、org 固有の値すべてを既定で `smkwlab`
にします（`setup.sh` / `common-lib.sh` が読む環境変数）。新しい org は以下を
上書きします。

| 変数 | 既定値 | 設定する値 |
|---|---|---|
| `DEFAULT_ORG` | `smkwlab` | 自分の org（メンバーシップチェック、ターゲット org、tools オーナーを駆動する） |
| `TOOLS_REPO_OWNER` / `TOOLS_REPO_NAME` / `TOOLS_CLONE_URL` | `<DEFAULT_ORG>` / `student-repo-management` / 導出 | 自分のフォークの場所 |
| `TEMPLATE_REPO` | `smkwlab/latex-template`, `smkwlab/poster-template` | 自分のコピー — 任意のドキュメントタイプのテンプレートを上書きする（[#517](https://github.com/smkwlab/student-repo-management/issues/517)）。表示の既定値は latex/poster を駆動し、thesis/wr/ise は org から導出される |
| `ALDC_URL` | `…/smkwlab/aldc/main/aldc` | 自分の aldc コピー（または共有のものを使い続ける） |
| `AUTO_ASSIGN_REVIEWER` | `toshi0806` | 自分のレビュアーアカウント（既定は `toshi0806`。自動アサインは割当先が org 外ユーザーの場合のみスキップされる） |
| `SETUP_GIT_EMAIL_DOMAIN` | `smkwlab.github.io` | 自分のドメイン |

#### 学生へ案内するコマンド

smkwlab 向けのドキュメントは、学生に短縮 URL `https://repo-setup.smkwlab.net`
を案内しています。この短縮 URL は **smkwlab のフォークの `setup.sh` を配信する
専用のもの**なので、他の org ではそのまま使えません（smkwlab の既定でリポジトリが
作られてしまいます）。

自分の org では、案内するコマンドの短縮 URL 部分を、**自分のフォークの `setup.sh`
を指す raw URL** に差し替えてください。

```bash
# smkwlab のドキュメントに載っている形
bash <(curl -fsSL https://repo-setup.smkwlab.net) thesis

# 自分の org（例: your-org）向けに書き換えた形
bash <(curl -fsSL https://raw.githubusercontent.com/your-org/student-repo-management/v1/create-repo/setup.sh) thesis
```

`v1` は自分のフォークの最新安定版リリースを指す移動タグです（[RELEASE](https://github.com/smkwlab/student-repo-management/blob/main/docs/RELEASE.md)
のリリース運用に従ってタグを打ちます）。短縮 URL を独自に用意したい場合は、
smkwlab の [Pages ワークフロー](https://github.com/smkwlab/student-repo-management/blob/main/.github/workflows/pages.yml)
を参考に、自分の org で同様の配信を設定できます。

<a id="shared-infrastructure-reference-strategy"></a>
## 共有インフラ: 参照戦略

一部のインフラは、すべてのテンプレートから *リテラルに*（文字列中に `smkwlab/`
を含めて）参照されており、展開のアイデンティティとは異なり、これは動的化
**できません**。GitHub Actions の `uses:`/`container:` 参照には式を含められない
ため、`${{ github.repository_owner }}` はそこでは解決されません。したがって
ワークフローは「自分の org」の再利用可能ワークフローやアクションのコピーを
指すことができず、org は文字列が書かれた時点で固定されます。

**決定 (#105): これを公開された共有インフラとして扱う。** 以下は公開の共有
サービスとして提供されます。どの org も `smkwlab/...` を直接参照して利用し、
共有コードを編集する代わりに Actions のシークレットと変数を通じて自分の値を
注入します。

| 共有サービス | 参照元 | org ごとの入力 |
|---|---|---|
| `smkwlab/.github` の再利用可能ワークフロー (`.github/workflows/<name>.yml@v1`) | テンプレートの呼び出し元ワークフロー（draft-chain、ML 通知、AI レビュー、LaTeX ビルド、QA） | シークレット / `secrets: inherit` |
| `smkwlab/latex-release-action@v3` | `latex-build` / `latex-build-modified` 再利用可能ワークフロー | — |
| `smkwlab/ai-academic-paper-reviewer@v1` | `ai-review` 再利用可能ワークフロー | `ANTHROPIC_API_KEY` / `GEMINI_API_KEY` |
| `ghcr.io/smkwlab/texlive-ja-textlint` | `devcontainer.json`、ビルドワークフロー | — |

フォークではなく共有利用が既定である理由:

- 再利用可能ワークフローの **本体** は既に org 非依存です — org の導出は
  `github.repository_owner` を使い、org 固有の値（メーリングリストアドレス、
  SMTP、API キー）はハードコードではなくシークレットを通じて消費されます。
  上記の *アドレス* だけが `smkwlab` を持っています。
- `uses:` はテンプレート化できないため、フォークするということはすべての
  テンプレートのすべての呼び出し元を書き換え（7 ワークフロー × 5 テンプレート）、
  上流の変更のたびに再同期することを意味します。そのコストは独立性を買いますが、
  共有サービスを信頼する展開にとってはそれ以外に何ももたらしません。

**受け入れるトレードオフ。** 共有利用は、`smkwlab` org が公開されたままで
あることへの恒久的な依存を意味し、別の org のテンプレート PR はその org の
シークレットで smkwlab 所有の再利用可能コードを実行します（あらゆる公開
再利用可能ワークフローにとって通常の信頼モデル）。依存を断ち切る必要がある
org — 独立性、エアギャップ、または再利用可能ロジックそのものの org ごとの
カスタマイズのため — は、代わりにフォークすべきです。[フォークすべきとき](#when-to-fork)を
参照。

**対象外 — レガシーな `ai-reviewer.yml` 再利用可能ワークフロー。**
`smkwlab/.github` は `toshi0806/ai-reviewer`（個人アカウント）を固定した
レガシーな `ai-reviewer.yml` 再利用可能ワークフローも提供しています。これは
**展開経路の一部ではありません**: どのテンプレート
(`sotsuron` / `wr` / `ise-report` / `sotsuron-report` / `latex` / `poster`) も
それを参照せず、`scripts/callers/` はそれ用の呼び出し元を提供しないため、
新規作成されるリポジトリと新しい org の展開がそれを拾うことはありません —
現在の AI レビュー経路は `ai-review.yml`（→ `smkwlab/ai-academic-paper-reviewer`）
です。影響を受けるのは、まだそれを呼び出している既存のリポジトリだけです。
したがってその廃止（または org 所有のアクションへの向け直し）は、それらの
レガシーリポジトリのための smkwlab 内部のクリーンアップ項目であり、マルチ org
の懸念ではありません。

### DevContainer イメージのメンテナンス

`ghcr.io/smkwlab/texlive-ja-textlint` イメージ（TeXLive + textlint、TeXLive の年で
タグ付け、例: `2026a`）が既定の共有イメージです。公開 GHCR は匿名 pull を許可し、
`latex-environment` の `check-texlive-updates.yml` は新しいイメージが公開された
ときに `devcontainer.json` のタグを自動的に更新します。そのため、利用する org は
イメージのメンテナンスをいっさい必要としません。

イメージをフォークするのは、独立した更新頻度が欲しいとき、TeX パッケージを固定
またはパッチしたいとき、あるいはレジストリ / エアギャップのポリシーを満たしたい
ときだけです。ビルドパイプラインは公開時点で既に org 非依存です:
`texlive-ja-textlint` の `build-tag.yml` は `github.repository_owner` を通じて
`ghcr.io/<owner>/texlive-ja-textlint` に push するため、フォークはコード変更なしで
自分の名前空間に公開します（パッケージを公開にするか、pull 認証情報を用意する）。
フォークがその後 `ghcr.io/<org>/...` に向け直さなければならないもの:

- **`latex-environment` フォーク** — `devcontainer.json` の `image`、**および**
  `check-texlive-updates.yml` の `IMAGE=` 定数（自動更新が org のイメージを
  追跡するように）。`aldc` はこの devcontainer を注入するため、`aldc` も org の
  `latex-environment` に、aldc の `ALDC_REPOSITORY_OWNER` /
  `ALDC_REPOSITORY_NAME` 環境変数で向ける
  （[aldc#32](https://github.com/smkwlab/aldc/issues/32)）。
- **CI ビルドイメージ** — `latex-build-modified.yml` は
  `container: ghcr.io/smkwlab/texlive-ja-textlint:2026a` で *同じ* イメージと
  タグを固定します（PDF ビルドが開発環境を再現するよう、意図的に DevContainer に
  一致させている）。一方 `latex-build.yml` は `smkwlab/latex-release-action` を
  通じて間接的にイメージに到達します。どちらも `smkwlab/.github` にあるため、
  向け直すには `.github`（およびアクション）もフォークする必要があります —
  [フォークすべきとき](#when-to-fork)を参照。

<a id="when-to-fork"></a>
### フォークすべきとき

フォーク経路を選ぶのは、共有利用が受け入れられないとき（独立性の要件、または
再利用可能ロジックを org ごとに変える必要があるとき）だけです。その場合:

- `smkwlab/.github`, `latex-release-action`, `ai-academic-paper-reviewer`、
  そしてイメージパイプラインを org 内にコピーし、`uses:`/`container:` 参照を
  org に書き換えます。
- `smkwlab` を前提とする 2 つの配布側の継ぎ目に注意してください:
  `smkwlab/.github/scripts/callers/*.yml` の呼び出し元テンプレートは
  `smkwlab/.github` オーナーをハードコードしており（`@__REF__` バージョンのみが
  トークン化されている）、`scripts/distribute-workflow.sh` は `--org` フラグを
  持たず `ORG="smkwlab"` を既定にします。フォークのワークフローを保守可能に
  するには、どちらも org のパラメータ化が必要です。

<a id="local-tool-configuration"></a>
## ローカルツールの設定

新しい org のスタッフのマシンには、ツールごとの設定が必要です。**各ツールを
明示的に設定してください**: 両方の Elixir ツールに org の既定値はもうありません
— org は `registry_repo` のオーナーから導出され、未設定の場合は smkwlab に
暗黙のフォールバックをせず明示的にエラーになります。以下のとおり設定します。

- **registry-manager**: `~/.config/registry-manager/config.yml`

  ```yaml
  github_org: your-org
  registry_repo: your-org/thesis-student-registry   # 明示的に指定。すべてのレジストリ操作に必須
  ```

  または `registry-manager init --org your-org` で生成します。設定ファイルが
  既に存在する場合は **上書きされません** — `--force` を追加してください
  （コマンドはいずれの場合もレジストリリポジトリの作成/修復は行います）。
- **thesis-monitor**: `thesis-monitor init --org your-org` を実行します
  （`--org` フラグは `init` でのみ機能します。ランタイムコマンドは設定ファイルを
  読みます）。registry-manager と同様に、既存の設定を上書きするには `--force` が
  必要です。
- **学生名簿（任意）**: CSV を `~/.config/<your-org>/students.csv` に置きます —
  規約パスは `github_org` に自動的に従います。
- **ecosystem-manager**: org 設定は不要です。複数のワークスペースを使う場合は
  `~/.config/ecosystem-manager/config.exs` でワークスペースパスを設定します。

## 検証チェックリスト

org と設定を準備したあと:

1. org を設定した状態で（[ローカルツールの設定](#local-tool-configuration)を
   参照）、`registry-manager list` は新しい org のレジストリを読みます — そして
   設定が無い場合は、smkwlab にフォールバックせず明示的にエラーになるように
   なりました。
2. `thesis-monitor status` は新しい org のリポジトリのみを報告します（同じく
   設定が無ければ明示的にエラーになる保証）。
3. 学生にフォークから `setup.sh` を実行してもらう
   （[create-repo フォークの設定](#5-create-repo-fork-configuration)に従って
   設定したもの）か、org の `student-repo-management` に直接リポジトリ作成
   リクエストの issue を出してもらい、次を確認します: リポジトリが新しい org に
   作成されること、ブランチ保護が適用されること（有料プランが必要 —
   [前提条件](#prerequisites-in-the-new-organization)のプラン注記を参照）、
   そして新しい org のレジストリの `data/registry.json` にエントリが追加される
   こと。`setup.sh` はクリエータを対話的コンテナ (`docker run -it`) で実行する
   ため、実際のターミナルが必要です — ヘッドレス/自動化されたチェックでは、
   代わりに `create-repo/main.sh` を直接実行してください。例:
   `TARGET_ORG=<org> DOC_TYPE=thesis ./main.sh <student-id>`。
4. 作成された学生リポジトリでドラフト PR を開き、テンプレートワークフロー
   （ビルド、draft-chain、レビュー）が、欠けているシークレットや private な
   `smkwlab` リソースを参照することなく実行されることを確認します。
