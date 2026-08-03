# 依存管理基盤（Renovate 一本化）

開発インフラリポジトリの依存関係更新は Renovate に一元化しています（Dependabot は不使用）。本書はその方針と設定の所在をまとめたものです。

手動でのイメージ再ビルドとテンプレートへの伝播は [RELEASE-OPERATIONS.md](RELEASE-OPERATIONS.md) を参照してください。学生リポジトリには Renovate を導入しておらず、draft PR サイクルとは無関係です。

## 原則

> **Renovate が確認し、Renovate がマージする。GitHub のブランチ保護は「人手マージの床」であって「自動マージの条件」ではない。**

| # | 原則 |
|---|---|
| 1 | 自動マージ対象は minor / patch / digest / lockFileMaintenance のみ。major は常に人間がレビューする |
| 2 | マージの実行主体は Renovate bot。判定条件は「その PR の全 check run が green」で、リポジトリ設定に依存しない |
| 3 | `platformAutomerge` は org 既定 false。ブランチ保護が CI 全体を過不足なく表現できていると確認できたリポジトリだけが opt-in する |
| 4 | required status checks は「床」として設定する。Renovate は全 check を見るのでリストの完全性を維持する義務はない。役割は人手マージ時の赤 PR 混入阻止と、`allow_auto_merge` 誤有効化時の被害限定 |
| 5 | 流量はスケジュールだけで律する。`prHourlyLimit` / `prConcurrentLimit` による絞りは設けない |
| 6 | 自動マージが到達するのは `main` まで。配布（Docker イメージタグ push、`v1` 付け替え、release 作成）は必ず人間の明示操作 |

原則 2 の背景: GitHub の auto-merge は「ブランチ保護の要件が充足された時点」でマージするため、required status checks が空のリポジトリでは CI 完了前にマージされる。Renovate 自前の automerge は PR の全 check run が green になるのを待つため、リポジトリ設定が何であっても安全。

原則 6 が自動マージを許容できる構造的根拠。**`v1` を動かす前に `git log v1..main` を確認する**こと。自動マージで積み上がった更新が、無関係な修正のついでに全学生リポジトリへ配布されるのを防ぐ。

## preset の構成

共有 preset は `smkwlab/.github` のリポジトリ直下に置き、移動タグ `v1` 経由で参照する。

| preset | 参照名 | 内容 |
|---|---|---|
| `default.json` | `github>smkwlab/.github` | org 共通。`platformAutomerge: false`、`automergeStrategy: "squash"`、patch/digest/pinDigest を個別 PR で自動マージ |
| `github-actions.json` | `:github-actions` | actions の minor/patch/digest をグループ `github actions` にまとめて自動マージ |
| `npm.json` | `:npm` | npm の minor/patch/digest/lockFileMaintenance をグループ `npm dependencies` にまとめて自動マージ |
| `elixir.json` | `:elixir` | default + `:github-actions` を extends。mix(hex) の minor まで自動マージ（org 全体の patch/digest 限定方針に対する意図的な例外） |
| `latex.json` | `:latex` | default + `:github-actions` + `:npm` を extends。スケジュール・流量・pin 方針を担当 |

major はどの preset でも自動マージ対象外。

各リポジトリの参照先:

| リポジトリ | 参照 |
|---|---|
| texlive-ja-textlint / latex-environment / latex-release-action / ai-academic-paper-reviewer / student-repo-management | `:latex#v1` |
| tenbin_dns / tdig / tenbin_ex / tenbin_cache / elixir_dnstap | `:elixir#v1` |
| .github | `default` + `:github-actions`（`enabledManagers` は github-actions のみ） |

`.github` は `:latex` を extends していない。preset の変更で latex 系だけを対象にすると `.github` が漏れるため、org 全体に効かせたい設定は `default.json` に置く。

`latex.json` は `renovate-config` manager を無効化している。この manager は preset 参照そのものを依存関係として読み取り、移動タグ `v1` を固定タグへ書き換える PR を出すため、原則 6 の配布経路が黙って壊れる。

## 流量

| preset | 窓 | 上限 |
|---|---|---|
| `:latex` | 月曜 11:00 以降（Asia/Tokyo） | なし |
| `:elixir` | 月曜 6:00 前 | 既定 |

`:latex` で上限を設けないのは、major が自動マージ対象外でレビューまで PR として残るため。上限があると major が枠を占有し、自動マージされる minor/patch の車線まで塞がる。

窓の外で更新を取り込みたい場合は、Dependency Dashboard の該当項目にチェックを入れると即座に PR が作られる。

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

- `allow_auto_merge` は latex 系 6 リポジトリで無効
- `platformAutomerge` は org 既定 false。opt-in するリポジトリは、ブランチ保護が自リポジトリの CI 全体を表現できていることを確認する
- required status checks は `strict: false` / `enforce_admins: false`
- 自動マージが到達するのは `main` まで。配布は人間の明示操作
- 共有 preset は移動タグ `v1` で参照する（固定タグに pin しない）
