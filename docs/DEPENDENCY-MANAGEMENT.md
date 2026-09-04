# 依存管理基盤（Renovate 一本化）

開発インフラリポジトリとドキュメントテンプレートの依存関係更新は Renovate に一元化しています（Dependabot は不使用）。
本書はその方針と設定の所在をまとめたものです。

手動でのイメージ再ビルドとテンプレートへの伝播は [RELEASE-OPERATIONS.md](RELEASE-OPERATIONS.md) を参照してください。
学生リポジトリには Renovate を導入しておらず、draft PR サイクルとは無関係です。

## 原則

> **Renovate が確認し、Renovate がマージする。**
> **GitHub のブランチ保護は「人手マージの床」であって「自動マージの条件」ではない。**

| # | 原則 |
|---|---|
| 1 | 自動マージ対象は minor / patch / digest / lockFileMaintenance のみ。major は常に人間がレビューする |
| 2 | マージの実行主体は Renovate bot。判定条件は「その PR の全 check run が完了していて、失敗が 1 つも無いこと」で、リポジトリ設定に依存しない |
| 3 | `platformAutomerge` は org 既定 false。ブランチ保護が CI 全体を過不足なく表現できていると確認できたリポジトリだけが opt-in する。opt-in しているリポジトリは無い |
| 4 | required status checks は「床」として設定する。Renovate は全 check を見るのでリストの完全性を維持する義務はない。役割は人手マージ時の赤 PR 混入阻止と、`allow_auto_merge` 誤有効化時の被害限定 |
| 5 | 流量はスケジュールだけで律する。`prHourlyLimit` / `prConcurrentLimit` による絞りは設けない |
| 6 | 自動マージが到達するのは `main` まで。配布（Docker イメージタグ push、`v1` 付け替え、release 作成）は必ず人間の明示操作 |

原則 2 の背景: GitHub の auto-merge は「ブランチ保護の要件が充足された時点」でマージするため、required status checks が空のリポジトリでは CI 完了前にマージされる。
Renovate 自前の automerge は PR の全 check run が出揃うのを待つため、リポジトリ設定が何であっても安全。
skip されたジョブは success と同じく通過扱いになる（後述の required status checks と同じ扱い）。

原則 6 が自動マージを許容できる構造的根拠。
**`v1` を動かす前に `git log v1..main` を確認する**こと。
自動マージで積み上がった更新が、無関係な修正のついでに全学生リポジトリへ配布されるのを防ぐ。

## preset の構成

共有 preset は `smkwlab/.github` のリポジトリ直下に置き、移動タグ `v1` 経由で参照する。

| preset | 参照名 | 内容 |
|---|---|---|
| `default.json` | `github>smkwlab/.github` | org 共通。`platformAutomerge: false`、`automergeStrategy: "squash"`、patch/digest/pinDigest を個別 PR で自動マージ、`osvVulnerabilityAlerts: true`、`renovate-config` manager の無効化 |
| `github-actions.json` | `:github-actions` | actions の minor/patch/digest をグループ `github actions` にまとめて自動マージ |
| `npm.json` | `:npm` | npm の minor/patch/digest/lockFileMaintenance をグループ `npm dependencies` にまとめて自動マージ |
| `elixir.json` | `:elixir` | default + `:github-actions` を extends。mix(hex) の minor まで自動マージ（org 全体の patch/digest 限定方針に対する意図的な例外） |
| `latex.json` | `:latex` | default + `:github-actions` + `:npm` を extends。スケジュール・流量・pin 方針と `lockFileMaintenance` を担当 |
| `template.json` | `:template` | `:latex` を extends。テンプレート専用に、共有ワークフロー参照の digest 固定だけを外す |

major はどの preset でも自動マージ対象外。

各リポジトリの参照先:

| リポジトリ | 参照 |
|---|---|
| texlive-ja-textlint / latex-environment / latex-release-action / ai-academic-paper-reviewer / student-repo-management / latex-ecosystem | `:latex#v1` |
| sotsuron-template / sotsuron-report-template / ise-report-template / wr-template / latex-template / poster-template | `:template#v1` |
| ecosystem-manager / registry-manager / thesis-monitor / elixir-tool-kit | `:elixir#v1` |
| .github | `default` + `:github-actions`（`enabledManagers` は github-actions のみ） |

テンプレートが `:latex` をそのまま参照しないのは、**テンプレートの内容が学生リポジトリへそのままコピーされる**ため。
`:latex` は github-actions の参照を digest 固定するが、学生リポジトリには Renovate が居ないので、固定された参照はそこで永久に凍結する。
これは[参照方式](#参照方式)の層 3 が守っている性質にあたる。
サードパーティ action は SHA 固定のままにしている。
学生リポジトリではこれも凍結するため、脆弱性が見つかっても古いまま残るというトレードオフを受け入れている。
固定を外せば凍結は避けられるが、可変タグを学生リポジトリに配ることになり、そちらの危険の方が大きい。

学生リポジトリ自体は Renovate の対象外で、生成時に `.github/renovate.json` を削除する（`dependabot.yml` と同じ扱い）。

aldc と thesis-student-registry も対象外。
ワークフローが共有ワークフローを移動タグで呼ぶだけで、Renovate が更新できる依存を 1 つも持たない。

`.github` は `:latex` を extends していない。
preset の変更で latex 系だけを対象にすると `.github` が漏れるため、org 全体に効かせたい設定は `default.json` に置く。

`default.json` は `renovate-config` manager を無効化している。
この manager は preset 参照そのものを依存関係として読み取り、移動タグ `v1` を固定タグへ書き換える PR を出すため、配布経路が黙って壊れる。
実際に student-repo-management は誰も pin する判断をしないまま 3 回書き換わった。

無効化を共通の土台に置いているのは、preset ごとに事情が違っても**意図として同じ 1 箇所に表明する**ため。
`elixir.json` は `enabledManagers` の allow-list に `renovate-config` を含めないことで結果的に守られていたが、これは「mix と github-actions を見る」ために書かれた設定の副作用であり、allow-list に manager を足せば黙って保護が外れる。

## 参照方式

action・再利用ワークフロー・preset をどう参照するかは、**その参照を更新する主体が居るか**で決まる。
参照先が第三者のものか自組織のものか、では決まらない。
ただし共有ワークフローだけは例外で、更新主体の有無にかかわらず移動タグで参照する（理由は[後述](#共有ワークフローは-renovate-が居る側も移動タグで見る)）。

| 層 | 参照方式 | 例 | 更新主体 |
|---|---|---|---|
| サードパーティ action | SHA pin + バージョンコメント | `actions/checkout@3d3c42e5… # v7.0.1` | Renovate |
| 開発インフラ間 | 固定バージョンタグ | `smkwlab/ai-academic-paper-reviewer@v1.10` | Renovate |
| 共有ワークフローへの参照（全消費者） | 移動タグ | `smkwlab/.github/.github/workflows/ai-review.yml@v1` | 無し |
| Renovate preset | 移動タグ | `github>smkwlab/.github:latex#v1` | 無し |

### Renovate が居る側は固定する

pin を上げる主体が居るので、固定しても更新が止まらない。
固定する利点は、いつどのコードに変わったかが commit として残り、変更のたびにレビューの機会が生じること。

サードパーティだけ SHA まで固定するのは、タグを force-push できる主体と、それをレビューして merge する主体が別だから。
自組織のコードでは両者が同じなので、可読性を取ってバージョンタグにする。

**固定タグは、タグが切られて初めて Renovate が上げられる。**
リリース発行が止まれば更新の連鎖全体が止まり、しかも何も壊れないので気付かない。
固定タグで参照される側は、リリース発行を人の記憶に依存させないこと。

### Renovate が居ない側は移動タグ 1 本だけを見る

学生リポジトリには Renovate を導入していない。
しかも年度ごとに増え続け、過年度分も残る。
参照を固定すると、共有ワークフローを直すたびに全リポジトリへの伝播が必要になり、その手間はリポジトリ数に比例して伸び続ける。
移動タグはこの規模に更新を届ける唯一の手段である。

引き換えに 2 つの危険を受け入れている。

- 同じ ref でも、GitHub Actions の tarball キャッシュが古い内容を配ることがある
- 消費者はレビューの機会なしに新しいコードを受け取る

受容できるのは配布が人間の明示操作だからで（原則 6）、**`v1` を動かす前に `git log v1..main` を確認する**ことが対価にあたる。

#### 配布の手順

`v1` の付け替えと `vX.Y.Z` の新規発行は 1 組で行う。
`v1` だけを動かすと、その時点で何が配られたのかを後から指せる名前が残らない。
非破壊な変更のときだけ行うという条件は [smkwlab/.github の README](https://github.com/smkwlab/.github#readme) にある。

```bash
# 1. 何が配られるかを確認する（原則 6 の対価。オープン PR の有無も見る）
git fetch --tags --force && git log v1..main
gh pr list -R smkwlab/.github --state open

# 2. v1 を動かし、同じコミットに vX.Y.Z を切る
gh api -X PATCH /repos/smkwlab/.github/git/refs/tags/v1 -f sha=<main-HEAD> -F force=true
git tag -a v1.<N>.0 <main-HEAD> -m "chore(release): v1.<N>.0 - <要旨>" && git push origin v1.<N>.0

# 3. 配布された実体を確認する（push の成功は内容の確認にならない）
gh api /repos/smkwlab/.github/contents/latex.json?ref=v1 --jq '.content' | base64 -d
```

3 を省かないこと。
ローカルの push が成功したことと、狙った内容が `v1` に乗ったことは別である。
確認すべきは主要な設定値そのもので、タグの SHA が一致していることではない。

さらに確実を期すなら、配布後に消費者側で 1 本走らせる。
再利用ワークフローの re-run は元コミット時点のタグ解決を再利用するため、古い内容のまま緑になることがある。
`workflow_dispatch` を持つ caller があれば、それが最短の実走確認になる。

`vX.Y.Z` を切り忘れたことに後から気付いた場合は、遡って切らずに次の版へ畳む。
タグメッセージに、その版が前回の配布分も内包している旨を書けば、`vX.Y.Z` を辿って全配布を追える状態に戻せる。
実例は `v1.44.0`（`5f6ffc5` の #165 / #166 分を内包）。

複数のセッションや担当者が同じ `v1` を動かしうる場合、気付いた側が配布して事後に一報する運用でよい。
force-move は `main` の HEAD に合わせるだけなので冪等で、衝突しない。
事故になるのは相手の未マージ分を巻き込むときだけで、それは 1 の確認で防げる。

### 移動タグを見る側は開発インフラ層を直接参照しない

Renovate が居ない消費者が固定タグを直接参照すると、pin を上げる手段が無いため永久に更新されない。
参照先が動かないだけで壊れはしないので、誰も気付かない。

共有ワークフローを 1 枚挟むこと。
その内側の pin は Renovate が居る側で管理され、移動タグ経由で全消費者に届く。

### 共有ワークフローは Renovate が居る側も移動タグで見る

インフラリポジトリにも Renovate は居るが、共有ワークフローへの参照は固定しない。
固定しても「変更のたびにレビューの機会が生じる」という利点が得られないためである。

`v1` を動かした時点で、更新は学生リポジトリとテンプレートに届く。
固定している側の pin を Renovate が上げるのはその後なので、**固定は「最初に気付く」ではなく「最後に気付く」を意味する**。
移動タグに揃えると全消費者へ同時に届き、CI を持つリポジトリが壊れを即座に検出する。

`:latex` は `smkwlab/.github` への参照だけ `pinDigests` を無効にしてこれを保証する。
同じリポジトリ内のサードパーティ action は固定したままで、そちらは更新主体が居て下流の消費者も居ないため、固定の根拠がそのまま成立する。

### 新しい action を足すとき

1. 第三者のものなら SHA pin + バージョンコメント
2. 自組織のもので参照元に Renovate が居るなら固定バージョンタグ。
   参照先がリリースを自動発行することを確認する
3. 参照元が学生リポジトリやテンプレートなら直接参照しない。
   共有ワークフローに包む
4. 共有ワークフロー自体は誰から見ても `@v1`

## 流量

| preset | 窓 | 上限 |
|---|---|---|
| `:latex` | 金曜・土曜の終日（Asia/Tokyo） | なし |
| `:elixir` | 日曜・月曜の終日（Asia/Tokyo） | 既定 |

窓が 2 日間あるのは、**schedule が Renovate を起動しないため**。
schedule は走っているジョブに対して「今動いてよいか」を答える許可フィルタでしかなく、ジョブを起こす力を持たない。
Mend のジョブ間隔は 4 時間なので、窓がそれより狭いと 2 回のジョブの隙間に丸ごと収まりうる。
そうなったリポジトリは、ジョブが毎回正常に完走していても更新が 1 つも作られない。

幅は出る量を決めていない。
上限が無制限なので、窓に入った最初のジョブが溜まっていた分を作り切り、後続のジョブには作るものが残らない。
幅が買っているのは、そもそも 1 回でも窓の中にジョブが入る確実性である。

2 つの preset で日をずらしているのは、同時実行枠が org 単位で 1〜2 しか無いため。
窓が重なると、両ファミリの PR 作成と、それが起動する CI が同じタイミングに集中する。

`:latex` で上限を設けないのは、major が自動マージ対象外でレビューまで PR として残るため。
上限があると major が枠を占有し、自動マージされる minor/patch の車線まで塞がる。

lock ファイルの再生成（`lockFileMaintenance`）も同じ窓で回す。
この設定は独自のスケジュールを持ち、トップレベルの `schedule` では上書きされないため、preset 側で窓を明示している。
書かなければ Renovate 既定の月曜 4:00 前になり、週の更新が 2 つの波に割れる。

窓の外で更新を取り込みたい場合は、Dependency Dashboard の該当項目にチェックを入れると即座に PR が作られる。

### 脆弱性は窓を待たない

`vulnerabilityAlerts` は既定でスケジュールを迂回し、検知次第すぐ PR を作る（`prCreation: "immediate"`、コミットメッセージ接尾辞 `[SECURITY]`）。
routine 更新を週 1 回に絞っても、セキュリティ修正だけは窓を待たない。

この経路の情報源は **osv.dev** である（`osvVulnerabilityAlerts: true`）。
GitHub の Dependabot alerts ではないため、**リポジトリ設定の有効・無効に検知が左右されない**。
原則 2 と同じ考え方を検知側にも適用したもので、新しいリポジトリが既定値次第で無検知になる事態を防ぐ。

Dependabot 自身の自動 PR（`automated-security-fixes`）は全リポジトリで無効のまま維持する。
依存更新は Renovate に一元化する方針を、セキュリティ修正でも崩さない。

推移的依存の advisory は直接依存を上げても解消しない。
依存ツリーの残りは書き換わらないためで、`lockFileMaintenance` はこれを定期的に洗い流す役割も持つ。

## required status checks

自動マージの条件ではなく、人手マージの床。
`enforce_admins: false` は全リポジトリ共通（CI が壊れた緊急時に管理者が明示的に突破できる。Renovate App はブランチ保護をバイパスしないため bot 側は必ずゲートされる）。
`strict: false`（up-to-date 要求なし）は、保護を設定している全リポジトリで共通。

| リポジトリ | contexts |
|---|---|
| texlive-ja-textlint | `changes`, `build-alpine`, `build-debian`, `build-debian-arm64` |
| latex-environment | `build-and-release-pdf` |
| latex-release-action | `yaml-lint`, `test-build` |
| ai-academic-paper-reviewer | `test` |
| student-repo-management | `Validate YAML files` |
| .github | `actionlint` |
| ecosystem-manager / registry-manager / thesis-monitor / elixir-tool-kit | 未設定 |

elixir 系に設定する場合の contexts は `ci / Code Quality` と `ci / All checks` の 2 つ。
どちらも共有ワークフロー `elixir-ci.yml` のジョブなので、リポジトリごとに違う名前になることはない。

`strict`（マージ前に main を取り込むことの要求）は latex 系では false にしている。
1 本マージするたびに全 PR が rebase と再ビルドになるためで、流量が少なければこの費用は発生しない。
true で得られるのは、個別には緑でも組み合わせると壊れる PR の検出で、これを防ぐ仕組みは他に無い。
流量の少ないリポジトリでは true を選ぶ余地がある。

### マトリクスは集約ジョブ 1 つで受ける

`ci / All checks` は `elixir-ci.yml` の `gate` ジョブで、`quality` と `test` の結果を集約するだけのジョブ。
テストマトリクスのジョブ名は `Test on OTP 27.3.4.4 / Elixir 1.17.3` のように**版を含む**ため、直接 required にすると版を上げるたびに全リポジトリの保護設定を編集することになる。

集約ジョブには `if: always()` が要る。
これが無いと依存ジョブの失敗時に**集約ジョブ自体が skip され**、後述のとおり skip は通過扱いなので、止めるべきときに限って緑になる。
`skipped` を成功と見なさないのも同じ理由で、走らなかったジョブは何も保証していない。

`review / review`（AI レビュー）は required にしない。
Renovate と Dependabot の PR ではジョブごと skip され、レビュー内容の合否も表さない。

required に指定してよいのは、**その PR で必ず check run が生成されるジョブ**に限る。

- job レベルの `if:` で skip されたジョブは `conclusion=skipped` の check run が生成され、required でも通過扱いになる。
  指定してよい
- workflow レベルの `paths:` / `branches:` フィルタで発火しなかった workflow は check run 自体が生成されず、永久 pending になる。
  指定してはいけない
- context 名はジョブ id とは限らない。
  ジョブに `name:` があればそちらが context 名になる
- action が生成する check run（reviewdog など）は action の差し替えで名前が変わる。
  指定しない

## 不変条件

変更する場合は本書も更新すること。

- `allow_auto_merge` は全リポジトリで無効。
  GitHub の auto-merge はブランチ保護の要件が満たされた時点でマージするため、required に入っていない check（`review / review` など）を待たない。
  マージは Renovate 自前の automerge に任せる
- `platformAutomerge` は org 既定 false で、opt-in しているリポジトリは無い。
  opt-in する場合は、ブランチ保護が自リポジトリの CI 全体を表現できていることを確認する
- `enforce_admins: false` は全リポジトリ共通。
  `strict: false` も保護を設定している全リポジトリで共通
- テストマトリクスは集約ジョブ 1 つで required にする。
  集約ジョブから `if: always()` を外さないこと（skip は通過扱いになるため、外すと止めるべきときに緑になる）
- 自動マージが到達するのは `main` まで。
  配布は人間の明示操作
- 参照方式は [参照方式](#参照方式) の 4 層に従う。
  とくに、移動タグを見る消費者は開発インフラ層を直接参照しない
- preset 参照は移動タグに保つ。
  `renovate-config` manager の無効化を外すなら、固定タグへ書き換えられないことを別の手段で保証すること
- 脆弱性の検知はリポジトリ設定に依存させない。
  `osvVulnerabilityAlerts` を無効に戻すなら、Dependabot alerts が全リポジトリで有効であることを別の手段で保証すること
- 共有ワークフローへの参照は全消費者で `@v1`。
  `pinDigests` の無効化を外すなら、`v1` の付け替えが固定側にも同時に届くことを別の手段で保証すること
- テンプレートは `:template` を参照する。
  `:latex` に切り替えるなら、共有ワークフロー参照が digest 固定されて学生リポジトリで凍結しないことを別の手段で保証すること
- 学生リポジトリに依存更新の設定を残さない。
  生成時に `dependabot.yml` と `renovate.json` を削除する
