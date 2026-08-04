# 依存管理基盤（Renovate 一本化）

開発インフラリポジトリとドキュメントテンプレートの依存関係更新は Renovate に一元化しています（Dependabot は不使用）。本書はその方針と設定の所在をまとめたものです。

手動でのイメージ再ビルドとテンプレートへの伝播は [RELEASE-OPERATIONS.md](RELEASE-OPERATIONS.md) を参照してください。学生リポジトリには Renovate を導入しておらず、draft PR サイクルとは無関係です。

## 原則

> **Renovate が確認し、Renovate がマージする。GitHub のブランチ保護は「人手マージの床」であって「自動マージの条件」ではない。**

| # | 原則 |
|---|---|
| 1 | 自動マージ対象は minor / patch / digest / lockFileMaintenance のみ。major は常に人間がレビューする |
| 2 | マージの実行主体は Renovate bot。判定条件は「その PR の全 check run が完了していて、失敗が 1 つも無いこと」で、リポジトリ設定に依存しない |
| 3 | `platformAutomerge` は org 既定 false。ブランチ保護が CI 全体を過不足なく表現できていると確認できたリポジトリだけが opt-in する。opt-in しているリポジトリは無い |
| 4 | required status checks は「床」として設定する。Renovate は全 check を見るのでリストの完全性を維持する義務はない。役割は人手マージ時の赤 PR 混入阻止と、`allow_auto_merge` 誤有効化時の被害限定 |
| 5 | 流量はスケジュールだけで律する。`prHourlyLimit` / `prConcurrentLimit` による絞りは設けない |
| 6 | 自動マージが到達するのは `main` まで。配布（Docker イメージタグ push、`v1` 付け替え、release 作成）は必ず人間の明示操作 |

原則 2 の背景: GitHub の auto-merge は「ブランチ保護の要件が充足された時点」でマージするため、required status checks が空のリポジトリでは CI 完了前にマージされる。Renovate 自前の automerge は PR の全 check run が出揃うのを待つため、リポジトリ設定が何であっても安全。skip されたジョブは success と同じく通過扱いになる（後述の required status checks と同じ扱い）。

原則 6 が自動マージを許容できる構造的根拠。**`v1` を動かす前に `git log v1..main` を確認する**こと。自動マージで積み上がった更新が、無関係な修正のついでに全学生リポジトリへ配布されるのを防ぐ。

## preset の構成

共有 preset は `smkwlab/.github` のリポジトリ直下に置き、移動タグ `v1` 経由で参照する。

| preset | 参照名 | 内容 |
|---|---|---|
| `default.json` | `github>smkwlab/.github` | org 共通。`platformAutomerge: false`、`automergeStrategy: "squash"`、patch/digest/pinDigest を個別 PR で自動マージ、`osvVulnerabilityAlerts: true` |
| `github-actions.json` | `:github-actions` | actions の minor/patch/digest をグループ `github actions` にまとめて自動マージ |
| `npm.json` | `:npm` | npm の minor/patch/digest/lockFileMaintenance をグループ `npm dependencies` にまとめて自動マージ |
| `elixir.json` | `:elixir` | default + `:github-actions` を extends。mix(hex) の minor まで自動マージ（org 全体の patch/digest 限定方針に対する意図的な例外） |
| `latex.json` | `:latex` | default + `:github-actions` + `:npm` を extends。スケジュール・流量・pin 方針と `lockFileMaintenance` を担当 |
| `template.json` | `:template` | `:latex` を extends。テンプレート専用に、共有ワークフロー参照の digest 固定だけを外す |

major はどの preset でも自動マージ対象外。

各リポジトリの参照先:

| リポジトリ | 参照 |
|---|---|
| texlive-ja-textlint / latex-environment / latex-release-action / ai-academic-paper-reviewer / student-repo-management | `:latex#v1` |
| sotsuron-template / sotsuron-report-template / ise-report-template / wr-template / latex-template / poster-template | `:template#v1` |
| tenbin_dns / tdig / tenbin_ex / tenbin_cache / elixir_dnstap | `:elixir#v1` |
| .github | `default` + `:github-actions`（`enabledManagers` は github-actions のみ） |

テンプレートが `:latex` をそのまま参照しないのは、**テンプレートの内容が学生リポジトリへそのままコピーされる**ため。`:latex` は github-actions の参照を digest 固定するが、学生リポジトリには Renovate が居ないので、固定された参照はそこで永久に凍結する。これは[参照方式](#参照方式)の層 3 が守っている性質にあたる。サードパーティ action は SHA 固定のままにしている。学生リポジトリではこれも凍結するため、脆弱性が見つかっても古いまま残るというトレードオフを受け入れている。固定を外せば凍結は避けられるが、可変タグを学生リポジトリに配ることになり、そちらの危険の方が大きい。

学生リポジトリ自体は Renovate の対象外で、生成時に `.github/renovate.json` を削除する（`dependabot.yml` と同じ扱い）。

`.github` は `:latex` を extends していない。preset の変更で latex 系だけを対象にすると `.github` が漏れるため、org 全体に効かせたい設定は `default.json` に置く。

`latex.json` は `renovate-config` manager を無効化している。この manager は preset 参照そのものを依存関係として読み取り、移動タグ `v1` を固定タグへ書き換える PR を出すため、原則 6 の配布経路が黙って壊れる。

## 参照方式

action・再利用ワークフロー・preset をどう参照するかは、**その参照を更新する主体が居るか**で決まる。参照先が第三者のものか自組織のものか、では決まらない。

| 層 | 参照方式 | 例 | 更新主体 |
|---|---|---|---|
| サードパーティ action | SHA pin + バージョンコメント | `actions/checkout@3d3c42e5… # v7.0.1` | Renovate |
| 開発インフラ間 | 固定バージョンタグ | `smkwlab/ai-academic-paper-reviewer@v1.10` | Renovate |
| 学生リポジトリ・テンプレート → 共有ワークフロー | 移動タグ | `smkwlab/.github/.github/workflows/ai-review.yml@v1` | 無し |
| Renovate preset | 移動タグ | `github>smkwlab/.github:latex#v1` | 無し |

### Renovate が居る側は固定する

pin を上げる主体が居るので、固定しても更新が止まらない。固定する利点は、いつどのコードに変わったかが commit として残り、変更のたびにレビューの機会が生じること。

サードパーティだけ SHA まで固定するのは、タグを force-push できる主体と、それをレビューして merge する主体が別だから。自組織のコードでは両者が同じなので、可読性を取ってバージョンタグにする。

**固定タグは、タグが切られて初めて Renovate が上げられる。** リリース発行が止まれば更新の連鎖全体が止まり、しかも何も壊れないので気付かない。固定タグで参照される側は、リリース発行を人の記憶に依存させないこと。

### Renovate が居ない側は移動タグ 1 本だけを見る

学生リポジトリには Renovate を導入していない。しかも年度ごとに増え続け、過年度分も残る。参照を固定すると、共有ワークフローを直すたびに全リポジトリへの伝播が必要になり、その手間はリポジトリ数に比例して伸び続ける。移動タグはこの規模に更新を届ける唯一の手段である。

引き換えに 2 つの危険を受け入れている。

- 同じ ref でも、GitHub Actions の tarball キャッシュが古い内容を配ることがある
- 消費者はレビューの機会なしに新しいコードを受け取る

受容できるのは配布が人間の明示操作だからで（原則 6）、**`v1` を動かす前に `git log v1..main` を確認する**ことが対価にあたる。

### 移動タグを見る側は開発インフラ層を直接参照しない

Renovate が居ない消費者が固定タグを直接参照すると、pin を上げる手段が無いため永久に更新されない。参照先が動かないだけで壊れはしないので、誰も気付かない。

共有ワークフローを 1 枚挟むこと。その内側の pin は Renovate が居る側で管理され、移動タグ経由で全消費者に届く。

### 新しい action を足すとき

1. 第三者のものなら SHA pin + バージョンコメント
2. 自組織のもので参照元に Renovate が居るなら固定バージョンタグ。参照先がリリースを自動発行することを確認する
3. 参照元が学生リポジトリやテンプレートなら直接参照しない。共有ワークフローに包み `@v1` で呼ぶ

## 流量

| preset | 窓 | 上限 |
|---|---|---|
| `:latex` | 日曜 21:00 以降（Asia/Tokyo） | なし |
| `:elixir` | 月曜 6:00 前 | 既定 |

`:latex` で上限を設けないのは、major が自動マージ対象外でレビューまで PR として残るため。上限があると major が枠を占有し、自動マージされる minor/patch の車線まで塞がる。

lock ファイルの再生成（`lockFileMaintenance`）も同じ窓で回す。この設定は独自のスケジュールを持ち、トップレベルの `schedule` では上書きされないため、preset 側で窓を明示している。書かなければ Renovate 既定の月曜 4:00 前になり、週の更新が 2 つの波に割れる。

窓の外で更新を取り込みたい場合は、Dependency Dashboard の該当項目にチェックを入れると即座に PR が作られる。

### 脆弱性は窓を待たない

`vulnerabilityAlerts` は既定でスケジュールを迂回し、検知次第すぐ PR を作る（`prCreation: "immediate"`、コミットメッセージ接尾辞 `[SECURITY]`）。routine 更新を週 1 回に絞っても、セキュリティ修正だけは窓を待たない。

この経路の情報源は **osv.dev** である（`osvVulnerabilityAlerts: true`）。GitHub の Dependabot alerts ではないため、**リポジトリ設定の有効・無効に検知が左右されない**。原則 2 と同じ考え方を検知側にも適用したもので、新しいリポジトリが既定値次第で無検知になる事態を防ぐ。

Dependabot 自身の自動 PR（`automated-security-fixes`）は全リポジトリで無効のまま維持する。依存更新は Renovate に一元化する方針を、セキュリティ修正でも崩さない。

推移的依存の advisory は直接依存を上げても解消しない。依存ツリーの残りは書き換わらないためで、`lockFileMaintenance` はこれを定期的に洗い流す役割も持つ。

## required status checks

自動マージの条件ではなく、人手マージの床。`strict: false`（up-to-date 要求なし）、`enforce_admins: false`（CI が壊れた緊急時に管理者が明示的に突破できる。Renovate App はブランチ保護をバイパスしないため bot 側は必ずゲートされる）。

| リポジトリ | contexts |
|---|---|
| texlive-ja-textlint | `changes`, `build-alpine`, `build-debian`, `build-debian-arm64` |
| latex-environment | `build-and-release-pdf` |
| latex-release-action | `yaml-lint`, `test-build` |
| ai-academic-paper-reviewer | `test` |
| student-repo-management | `Validate YAML files` |
| .github | `actionlint` |

`review / review`（AI レビュー）は required にしない。Renovate と Dependabot の PR ではジョブごと skip され、レビュー内容の合否も表さない。

required に指定してよいのは、**その PR で必ず check run が生成されるジョブ**に限る。

- job レベルの `if:` で skip されたジョブは `conclusion=skipped` の check run が生成され、required でも通過扱いになる。指定してよい
- workflow レベルの `paths:` / `branches:` フィルタで発火しなかった workflow は check run 自体が生成されず、永久 pending になる。指定してはいけない
- context 名はジョブ id とは限らない。ジョブに `name:` があればそちらが context 名になる
- action が生成する check run（reviewdog など）は action の差し替えで名前が変わる。指定しない

## 不変条件

変更する場合は本書も更新すること。

- `allow_auto_merge` は上記 required status checks の表にある 6 リポジトリ（`:latex#v1` を参照する 5 つと `.github`）で無効
- `platformAutomerge` は org 既定 false で、opt-in しているリポジトリは無い。opt-in する場合は、ブランチ保護が自リポジトリの CI 全体を表現できていることを確認する
- required status checks は `strict: false` / `enforce_admins: false`
- 自動マージが到達するのは `main` まで。配布は人間の明示操作
- 参照方式は [参照方式](#参照方式) の 4 層に従う。とくに、移動タグを見る消費者は開発インフラ層を直接参照しない
- 脆弱性の検知はリポジトリ設定に依存させない。`osvVulnerabilityAlerts` を無効に戻すなら、Dependabot alerts が全リポジトリで有効であることを別の手段で保証すること
- テンプレートは `:template` を参照する。`:latex` に切り替えるなら、共有ワークフロー参照が digest 固定されて学生リポジトリで凍結しないことを別の手段で保証すること
- 学生リポジトリに依存更新の設定を残さない。生成時に `dependabot.yml` と `renovate.json` を削除する
