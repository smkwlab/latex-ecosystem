# LaTeX 論文執筆環境エコシステム

本ドキュメントは、九州産業大学 理工学部 下川研究室の論文執筆環境エコシステムのアーキテクチャと管理方針を記述する。

## リポジトリ概要

### コアインフラ
- **texlive-ja-textlint**: 日本語 LaTeX コンパイルと textlint のための Docker イメージ
- **latex-environment**: devcontainer を備えた汎用 LaTeX 開発環境テンプレート
- **latex-release-action**: LaTeX の自動コンパイルとリリース作成のための GitHub Action

### テンプレートとツール
- **sotsuron-template**: 統合論文テンプレート(学部の卒業論文 + 大学院の修士論文)
- **ise-report-template**: HTML/textlint による品質管理を備えた情報科学演習レポートテンプレート
- **wr-template**: 週間報告テンプレート
- **latex-template**: 基本 LaTeX テンプレート
- **sotsuron-report-template**: 論文執筆練習用レポートテンプレート
- **poster-template**: 学会発表用ポスターテンプレート(A0 サイズ)

### 管理と自動化
- **student-repo-management**: 論文指導のための管理ツールとドキュメント
- **thesis-student-registry**: 学生リポジトリのレジストリデータ(private、データ専用)
- **registry-manager**: レジストリデータ管理ツール(Elixir escript)
- **thesis-monitor**: 学生リポジトリ監視ツール(Elixir escript)
- **ecosystem-manager**: エコシステムワークスペースの横断ステータスツール(Elixir escript)
- **ai-academic-paper-reviewer**: org 標準の AI レビューワークフローで使う自動レビュー GitHub Action。`ACADEMIC`(論文)と `CODE`(コード)の両レビューモードを持ち、エコシステム唯一の AI レビューアである
- **ai-reviewer**(legacy): `toshi0806/ai-reviewer` にある単機能コードレビュー Action(`Nasubikun/ai-reviewer` のフォーク)。`ai-academic-paper-reviewer`(`CODE` モード)に置き換えられ、移行後のワークフローでは未使用。参照用にのみ残している
- **aldc**: リポジトリに LaTeX devcontainer を追加するコマンドラインツール

> **エコシステム対象外**: ローカルワークスペースにこれらと並んで存在しうる他のリポジトリ
> (`split-sentences`、`ise-report` など)は論文執筆環境エコシステムの一部ではなく、
> ここでは管理しない。

## 依存関係マトリクス

```
┌─────────────────────────────────────────────────────────────┐
│                    Dependency Flow                         │
└─────────────────────────────────────────────────────────────┘

texlive-ja-textlint (Docker Base)
    ↓
latex-environment (DevContainer Template)
    ↓
├── sotsuron-template (Student Templates)
├── ise-report-template (HTML-based quality-focused)
├── wr-template
├── latex-template
├── sotsuron-report-template
└── poster-template

Supporting Infrastructure:
├── latex-release-action → (Used by templates)
├── ai-academic-paper-reviewer → (AI review for thesis repos & code review, ACADEMIC/CODE modes)
├── aldc → latex-environment (release branch)
├── student-repo-management → (Management workflows)
├── thesis-student-registry → (Student repository registry data, private)
├── registry-manager → thesis-student-registry (writes registry data)
├── thesis-monitor → thesis-student-registry (reads registry data)
└── ecosystem-manager → (reads status of all ecosystem repos)
```

## バージョン互換性

| コンポーネント | 現行バージョン | 互換対象 | 更新頻度 |
|-----------|----------------|-----------------|------------------|
| texlive-ja-textlint | 2026a | TeXLive 2026 | 年次(TeXLive リリース) |
| latex-environment | release ブランチ | texlive-ja-textlint:2026a | 自動(main へのマージ時) |
| sotsuron-template | 最新 | aldc 経由で自動更新 | 手動更新不要 |
| ise-report-template | 最新 | aldc 経由で自動更新 | 手動更新不要 |
| latex-template | 最新 | aldc 経由で自動更新 | 手動更新不要 |
| wr-template | 最新 | aldc 経由で自動更新 | 手動更新不要 |
| sotsuron-report-template | 最新 | aldc 経由で自動更新 | 手動更新不要 |
| poster-template | 最新 | aldc 経由で自動更新 | 手動更新不要 |
| latex-release-action | v3.3.0 | 全テンプレート | 機能ごと |
| aldc | 最新 | latex-environment:release | 更新不要 |
| ecosystem-manager | 最新 | Elixir ~> 1.17 (OTP 27+) | 機能ごと |

## 自動更新チェーン

```
1. texlive-ja-textlint の更新（手動でタグ作成）
   ↓
2. latex-environment が自動検出して PR を作成
   ↓
3. PR を手動レビューして main へマージ
   ↓
4. latex-environment の release ブランチが自動更新
   （main へのマージ時に update-release-branch workflow が実行）
   ↓
5. aldc は更新された release ブランチを自動的に利用
   ↓
6. 新規の学生リポジトリには自動的に最新環境が入る
   ↓
7. テンプレート側の手動更新は不要（aldc 連携）
```

## 管理原則

### 1. **疎結合 (Loose Coupling)**
- 各リポジトリは独立性を保つ
- コンポーネント間のインターフェースを明確にする
- ハードな依存関係は最小限にする

### 2. **漸進的拡張 (Progressive Enhancement)**
- コア機能はオプションのコンポーネントなしでも動作する
- 追加機能はその上にきれいに重なる
- 依存先が使えないときは段階的に機能を縮退する

### 3. **学生第一の設計**
- シンプルなセットアップ(Docker とワンライナー)
- セルフサービスでのリポジトリ作成
- 環境の自動構成

### 4. **教員ワークフローとの統合**
- GitHub に組み込まれたレビューシステム
- 自動化された suggestion ワークフロー
- 受理された suggestion は後続 draft ブランチへ自動伝播する
- 手作業の介入は最小限にする

### 5. **org 単位のデプロイメント**

エコシステムは **GitHub organization 単位**で運用する。1 つの org が 1 つの
デプロイメント単位であり、レジストリデータリポジトリ・学生リポジトリ・
自動化を自ら保持する。ツールはコードとして配布され、デプロイメントの
アイデンティティはコードではなく org に宿る。

- **規約による所在 (Location by convention)**: レジストリデータリポジトリは
  `<org>/thesis-student-registry` である。org は常に実行時コンテキストから
  導出する — GitHub Actions では `github.repository_owner`、create-repo
  スクリプトでは `ORGANIZATION`、ツール設定では `github_org`。
  コードに実効デフォルトとしての org 名リテラル — すなわち実行時に実際に
  フォールバック先となる値 — を含めてはならない。テストフィクスチャ、
  ドキュメントのサンプル、および(実行時コンテキストが存在しない場合の)
  明示されたローカル専用フォールバックのリテラルは許容する。
- **設定による逸脱 (Deviation by configuration)**: 規約から外れる
  デプロイメントは、デプロイメントごとに上書きする — 自動化には org レベルの
  Actions 変数 `REGISTRY_REPO`、CLI にはツールごとの上書き
  (`--registry-repo` フラグ / 環境変数 / ローカル設定)。
  変数を空文字列に設定すると上書きは無効になる(規約にフォールバックする)。
- **フォーククリーン保証 (Fork-clean guarantee)**: ツールリポジトリを別 org に
  clone またはフォークしたとき、**配布コードを編集せずに**動作しなければ
  ならない。したがって、デプロイメントのアイデンティティをツールリポジトリに
  コミットすることは許されない(フォークの分岐を強いるため)。
- ローカルのツール設定(`~/.config/registry-manager/config.yml`、
  `~/.config/thesis-monitor/config.yml`)は、この決定のローカルな記録と
  マシン固有の詳細である。org コンテキストが真実の源であることは変わらない。
  共有語彙は後述の「ツール設定規約」を参照。

**デプロイメントのアイデンティティと共有インフラの区別。** 上記の org スコープの
規則が対象とするのは*デプロイメントのアイデンティティ* — レジストリデータ、
学生リポジトリ、名簿、通知先 — である。これとは別の第二のカテゴリが
*共有インフラ*である: すべてのデプロイメントが利用する再利用可能な GitHub
Actions ワークフロー(`smkwlab/.github`)、composite action
(`smkwlab/latex-release-action`、`smkwlab/ai-academic-paper-reviewer`)、
DevContainer イメージ(`ghcr.io/smkwlab/texlive-ja-textlint`)。これらは
**public な共有サービスとして公開**され、リテラルで参照する。GitHub Actions の
`uses:`/`container:` 参照には式を書けない — `${{ github.repository_owner }}` は
そこでは解決されないため、ワークフローが「自 org の」コピーを動的に指すことは
できない。この区別は意図的である: デプロイメントのアイデンティティをコード
リテラルにしてはならない(前節)が、*共有インフラへのリテラル参照*は
デプロイメントのアイデンティティではない — それは共有サービスのアドレスで
あり、org 固有の値は Actions の secrets と variables を通じて注入され、共有
ワークフローに焼き込まれることはない。この依存を断ちたい org はインフラを
フォークして参照を書き換えてもよいが、既定かつ推奨の姿勢は共有利用である。
具体的な参照戦略は [docs/MULTI-ORG-DEPLOYMENT.md](docs/MULTI-ORG-DEPLOYMENT.md)
を参照。

## テンプレートの特化

### 文書フォーマットの焦点
- **sotsuron-template**: 高度な組版を備えた LaTeX ベースの学術論文
- **ise-report-template**: Web アクセシビリティと品質自動化を備えた HTML ベースのレポート
- **wr-template**: 構造化された週間進捗報告
- **latex-template**: 汎用学術文書のための最小構成 LaTeX
- **poster-template**: tikzposter と LuaLaTeX による A0 サイズの学術ポスター

### 品質管理のアプローチ
- **ise-report-template**: 包括的な品質パイプライン(HTML5 検証、アクセシビリティチェック、日本語 textlint)
- **sotsuron-template**: 引用管理を含む学術的文章の標準
- **wr-template**: 一貫したフォーマットによる構造化された進捗管理
- **latex-template**: 基本的な LaTeX 品質保証
- **poster-template**: 視覚デザイン検証付きの自動 PDF 生成

### 想定読者
- **ise-report-template**: 情報科学演習の学生(HTML 習熟度の育成)
- **sotsuron-template**: 学部・大学院の論文執筆学生(研究文書の作成)
- **wr-template**: 研究室の学生と教員(進捗管理)
- **latex-template**: 一般の学術ユーザ(基本的な LaTeX 用途)
- **poster-template**: 学会・シンポジウムで発表する研究者

## リポジトリ横断の標準

### 用語: 学生リポジトリレジストリ

エコシステムでは、学生リポジトリの台帳を一貫して **「registry(レジストリ)」** と呼ぶ:

- **Registry**: 学生リポジトリの台帳。レジストリデータリポジトリ内の
  `data/registry.json` として実体化される(2026-07 に `repositories.json` から
  改名。旧名はもう読まれない — 後方互換フォールバックは公開前にすべて廃止、
  2026-07)。`thesis-monitor` は GitHub contents API 経由で読む(ローカル
  チェックアウト不要)。ドキュメントでは「registry (data)」と表記し、
  「student data」「学生リポジトリ一覧」「リポジトリ一覧」などの場当たり的な
  同義語を同じ対象に使わない。
- **レジストリデータリポジトリ**: `thesis-student-registry`(private、データ専用)。
  テスト用の対応リポジトリ: `thesis-student-registry-test`(命名規則:
  `<production-name>-test`)。
- **ツール命名**: prefix = ツールが操作する対象、suffix = 役割
  (読み = *monitor*、書き = *manager*)。よって `registry-manager` は
  レジストリを書き、`thesis-monitor` はレジストリを索引として読み、学生の
  論文リポジトリを監視する。prefix の非対称は意図的である — 2 つのツールは
  異なる対象を操作している。
- **データフィールド**: レジストリが管理するタイムスタンプは `registry_`
  prefix を持つ(`registry_created_at`、`registry_updated_at`)。素の
  `created_at`/`updated_at` はレガシーフィールドである(移行状況は
  registry-manager のデータ構造仕様を参照)。
- **`repository_type` の語彙**: `sotsuron`(卒業論文)、`master`(修士論文)、
  `wr`、`ise`(格納値。`ise-report` はエイリアスとして受理)、`latex`
  (latex-template 由来、ブランチ管理 — 学会論文など)、`other`。
  `thesis` という語は repository_type では**ない**: それは別のレイヤに
  のみ存在する — `DOC_TYPE=thesis` の文書フロー、「全論文」フィルタ
  (`--type thesis` = sotsuron ∪ master)、および歴史的なリポジトリ名
  suffix(実際の修士論文は `*-master` と命名される)。
  決定記録: smkwlab/student-repo-management#471。
- **曖昧さ回避**: コンテナ / イメージの文脈(texlive-ja-textlint、devcontainer
  ドキュメント)での「registry」は **GitHub Container Registry (ghcr.io)** を
  意味し、無関係である。そこでは常に完全な名称で書くこと。

### ツール設定規約

2 つのレジストリツールは 1 つの設定スキームを共有する(2026-07 決定;
smkwlab/thesis-monitor#14/#16/#18/#20、registry-manager#16/#18/#21):

- **共有語彙** — 同じキーは両ツールで同じ意味を持つ:
  - `github_org`: デプロイメントの org(デフォルトなし — 未設定時は
    `registry_repo` の owner から導出し、それもなければ明示的なエラー;
    thesis-monitor#28 / registry-manager#45)
  - `registry_repo`: レジストリデータリポジトリ(`owner/repo`)
  - `csv_path`: 氏名解決用の学生名簿 CSV(オプション)
- **ファイル形式と場所**: `~/.config/<tool-name>/config.yml` の注釈付き YAML
  (`registry-manager` / `thesis-monitor`)。コメントは設計の一部である —
  生成される設定は規約どおりのデフォルトをコメント行として示し、実効値は
  常に実行時導出から得る。ドリフトしうる保存コピーからは決して得ない。
- **設定より規約 (Convention over configuration)**: 実行時に導出できる値は
  保存しない。**リーダー**(`thesis-monitor`)の `registry_repo` は
  `<github_org>/thesis-student-registry` がデフォルト。両ツールで `csv_path` は
  `~/.config/<github_org>/students.csv` が存在すればそれがデフォルト
  (存在しなければ氏名解決を単にスキップする — 警告なし、氏名は N/A 表示)。
  名簿 CSV 自体は**ローカル専用**である(個人情報を含む — いかなる
  リポジトリにもレジストリにもコミットしない)。
- **読みは org のみ、書きは明示**: `thesis-monitor`(リーダー)に必要なのは
  org だけである(`thesis-monitor init --org <org>` で設定を生成;
  `registry_repo` は規約から導出される) — それ以外の前提は `gh auth login`
  のみ。`registry-manager`(ライター)は明示的な `registry_repo` を要求する:
  書き込み先を規約から推測することは決してない。この非対称は安全のための
  設計である。どちらのツールもデフォルト org にフォールバックしない:
  org コンテキストの欠如は明示的なエラーである
  (thesis-monitor#28 / registry-manager#45)。
- **後方互換フォールバックなし**: 旧キー(`data_dir`、`data_repo`、
  `student_csv`、`registry_dir`)、旧ファイル名(`repositories.json`)、旧設定
  場所(`config.json`、`~/.thesis-monitor.yml`)は読まない。移行は改名 /
  書き換えであり、未移行マシンは実行可能な対処を示すメッセージとともに
  明示的に失敗する(公開前の決定、2026-07)。

### ファイル命名規約
- **CLAUDE.md**: プロジェクト固有の Claude Code 向け指示
- **README.md**: ユーザ向けドキュメント
- **CHANGELOG.md**: リリース履歴(該当する場合)
- **.devcontainer/**: VS Code 開発環境

### ブランチ戦略
- **main**: 開発と真実の源
- **release**: 利用者向けのクリーンなテンプレート(latex-environment のみ)
- **feature ブランチ**: 開発作業、PR ベースのワークフロー

### タグ戦略
- **セマンティックバージョニング**: v{MAJOR}.{MINOR}.{PATCH}
- **カレンダーバージョニング**: texlive-ja-textlint 用(例: 2025b)
- **協調リリース**: エコシステムの大規模更新時

## 開発ワークフロー

### インフラ変更の場合
1. ベースコンポーネント(texlive-ja-textlint)を更新する
2. latex-environment でテストする
3. テンプレートへ伝播させる
4. ドキュメントを更新する

### テンプレート変更の場合
1. テンプレートリポジトリで開発する
2. 現行環境でテストする
3. 論文種別をまたぐ互換性を確認する
4. 関連ドキュメントを更新する

### ツール開発の場合
1. 各ツールリポジトリで開発する
2. 複数のテンプレートに対してテストする
3. 連携ドキュメントを更新する
4. 自動化の機会を検討する

## 品質保証

### 自動テスト
- **texlive-ja-textlint**: マルチアーキテクチャビルド、LaTeX コンパイルテスト
- **latex-environment**: DevContainer 検証、拡張機能ロード
- **テンプレート**: サンプル文書のコンパイル、textlint 検証
  - **ise-report-template**: HTML5/CSS 品質検証、アクセシビリティチェック、日本語学術文章の標準
- **Actions**: サンプルリポジトリによる統合テスト
- **Elixir ツール**(ecosystem-manager、registry-manager、thesis-monitor): `smkwlab/.github` 経由の org 標準 Elixir CI(mix test、Credo、Dialyzer)

### 手動検証
- 学生ワークフローのエンドツーエンドテスト
- 教員レビュープロセスの検証
- クロスプラットフォーム互換性(Windows/macOS/Linux)
- 性能リグレッションテスト

## 緊急時の手順

### ロールバック戦略
1. **即時**: 問題のあるコンポーネントを前バージョンに戻す
2. **周知**: 関係リポジトリでステータスを更新する
3. **調査**: Issue トラッカーで根本原因を分析する
4. **予防**: 同種の問題を検出できるよう自動テストを更新する

### ホットフィックスプロセス
1. 最後の正常な状態から hotfix ブランチを作成する
2. 十分なテストとともに最小限の修正を適用する
3. レビュープロセスを迅速化する
4. 監視しながらデプロイする

## 監視とメトリクス

### 健全性指標
- 学生リポジトリ作成の成功率
- 環境セットアップの失敗率
- テンプレート全体でのコンパイル成功率
- レビューシステムの利用状況

### 性能メトリクス
- コンテナビルド時間
- リポジトリセットアップ所要時間
- 文書コンパイル速度
- Action 実行時間

## 今後のロードマップ

### 短期(3 か月)
- [ ] リポジトリ横断テストの実装
- [x] 依存関係更新の自動化強化(check-texlive-updates ワークフロー + 各リポジトリへの Renovate 導入)
- [ ] エラー報告と診断の改善

### 中期(6 か月)
- [ ] 多言語テンプレート対応
- [ ] AI レビュー機能の強化
- [ ] 学生の進捗分析

### 長期(12 か月)
- [ ] クラウドベースのコンパイルサービス
- [ ] リアルタイム共同編集機能
- [ ] 高度なテンプレートカスタマイズ

## コントリビューションガイドライン

### リポジトリ横断の変更
1. 影響するすべてのリポジトリに Issue を作成する
2. 中心となるトラッキング Issue で変更を調整する
3. 連携ポイントを十分にテストする
4. 必要に応じて本ドキュメントを更新する

### ドキュメント標準
- アーキテクチャ変更時は ECOSYSTEM.md を最新に保つ
- 各リポジトリの README.md を維持する
- 本エコシステムのドキュメントは日本語で管理する(コード・コマンド・固有名詞は原語のまま)
- 用語の定義は [docs/GLOSSARY.md](docs/GLOSSARY.md) を正とする
- 破壊的変更には移行ガイドを含める

## サポートと連絡先

- **主保守者**: Kyushu Sangyo University LaTeX Team
- **Issue トラッキング**: コンポーネント固有の問題は各リポジトリの Issue へ
- **エコシステムの問題**: 横断的な事項は latex-environment リポジトリを使う
- **緊急連絡**: 該当リポジトリに `urgent` ラベル付きの Issue を作成する

---

*Last Updated: 2026-07-18*  
*Document Version: 1.4(ドキュメントを日本語化)*
