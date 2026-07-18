# 教員向け添削ワークフローガイド

> **本書の位置づけ**: 初期設定・スクリプト・提出プロセス管理・セキュリティは本書が正典です。
> 日常のレビュー操作（コメント・Suggestion・複数教員レビュー）は [PR-REVIEW-GUIDE.md](PR-REVIEW-GUIDE.md)、初回の全体像は [TEACHER-ONBOARDING.md](TEACHER-ONBOARDING.md) を参照してください。
>
> 本ガイド中の org 名・URL・コマンド例・連絡先は **smkwlab organization での運用を例**に記述しています。他の org に展開した環境では、自 org の値に読み替えてください（展開方法は [MULTI-ORG-DEPLOYMENT.md](MULTI-ORG-DEPLOYMENT.md)）。

## 概要

このガイドは、GitHub を使った論文添削ワークフローの教員向け運用・管理ガイドです。
draft 連鎖型のワークフローにより、各稿の差分レビューを効率的に実施できます。

## ワークフロー概要

### ブランチ構成

```
main (最終成果物)
 ├─ 0th-draft (目次案)
 ├─ 1st-draft (0th-draftベース) ← 差分明確
 ├─ 2nd-draft (1st-draftベース) ← 差分明確
 ├─ 3rd-draft (2nd-draftベース) ← 差分明確
 └─ abstract-1st, abstract-2nd, … (概要用)
```

各 draft PR は直前の draft をベースにするため、直前版からの差分だけが表示されます。
次稿ブランチは PR 作成時に GitHub Actions が自動作成します（create-next-draft）。

> **旧構成についての補足**: 2025年10月以前に作成されたリポジトリには
> `initial` / `review-branch` と「レビュー用 PR」が存在しますが、この仕組みは
> 廃止されました（sotsuron-template #74）。現行のリポジトリには存在しません。

### レビューの使い分け

| コメントの種類 | 場所 |
| ------------ | ----------- |
| 目次案への指摘 | 0th-draft PR |
| 直前版からの変更点 | 各版のPR (1st-draft等) |
| 論文全体の構成・章を跨ぐ整合性 | その時点の最新の draft PR |
| 全体を通した確認 | 各 PR で自動ビルドされる PDF アーティファクト |

## 初期設定

### リポジトリ作成（学生自身で実行）

学生は以下のDockerベースのワンライナーでリポジトリを作成します：

```bash
# 学生が実行するコマンド（Homebrewスタイル・論文リポジトリの例）
bash <(curl -fsSL https://repo-setup.smkwlab.net) thesis
```

> 上記 URL は **smkwlab デプロイの**エントリポイントです。他の org に展開した環境では、fork 設定済みの**自 org の `setup.sh`**（[MULTI-ORG-DEPLOYMENT.md](MULTI-ORG-DEPLOYMENT.md) の fork 設定表を参照）を学生に案内してください。
> **注意**: smkwlab の URL のままでは smkwlab の既定値でリポジトリが作成されます。

**自動実行される内容**：
1. GitHub認証（ブラウザ経由）
2. リポジトリ作成（テンプレートから）
3. LaTeX devcontainer追加 (aldc)
4. 0th-draft ブランチ作成
5. 学生レジストリへの登録と `main` ブランチ保護の自動設定
6. レビュアー（教員）の自動アサイン

### 教員側の設定作業

学生のリポジトリ作成後、必要に応じて以下を設定：

1. **mainブランチ保護設定**（通常は自動設定される。失敗時のみ手動）
   ```bash
   # 教員用ブランチ保護ツール（student-repo-management リポジトリの scripts/ にある）
   ./scripts/setup-branch-protection.sh k21rs001-sotsuron k21rs002-sotsuron
   
   # 個別設定
   ./scripts/setup-branch-protection.sh k21rs001-sotsuron
   ```

2. **Collaboratorの追加**（必要時）
   ```bash
   gh api repos/smkwlab/{repo-name}/collaborators/{username} \
     --method PUT \
     --field permission=write
   ```

## 日常的な添削作業

日々のレビュー操作の詳細な手順（差分の見方・コメント・Suggestion・レビュー送信）は
[PR-REVIEW-GUIDE.md](PR-REVIEW-GUIDE.md) が正典です。ここでは運用上の要点のみまとめます。

### 1. 学生からPRが来たとき

- **差分レビュー（各版のPR）**: 直前版からの変更点をレビューします。
  操作手順は [PR-REVIEW-GUIDE.md](PR-REVIEW-GUIDE.md) の「基本的な添削手順」を参照。
- **論文全体に関わる指摘**: その時点の最新の draft PR にコメントします。
  全体を通して読む場合は、各 PR で自動ビルドされる PDF アーティファクトを利用します。

### 2. Suggestion対応フロー

Suggestion 提示後は学生の適用と Re-request review を待ち、確認後に承認コメントします。
**教員はPRをマージしません。学生が自分でクローズします。**
適用された Suggestion は次稿ブランチへも自動で merge されます（`sync-next-draft.yml`）。
コンフリクト時は前稿→次稿の同期 PR が自動作成され、学生がブラウザで解決します。
詳細フローは [PR-REVIEW-GUIDE.md](PR-REVIEW-GUIDE.md) の「Suggestion対応フロー」を参照。

### 3. 並行作業時のサポート

学生が並行作業をしている場合のサポート手順：

#### 学生向け指示

```
学生への標準的な指示：
「1st-draft PR提出後、すぐに次稿執筆を開始できます。
2nd-draftブランチは自動作成されているので、以下の手順で進めてください：
1. GitHub Desktop で Fetch origin をクリック
2. Current Branch → origin/2nd-draft を選択してブランチ作成
3. 次稿執筆開始
4. 前稿の添削対応完了後、自分でPRをクローズしてください」
```

#### 注意事項

```
PRをマージしない運用のメリット：
- 競合解決不要：PRをマージしないため競合は発生しません
- 並行作業自由：いつでも次稿執筆開始可能
- シンプル操作：学生の複雑なGit操作は不要
- 完全履歴：全PRが保持され、完全な変遷記録となります
```

## スクリプト活用

教員用スクリプトは [student-repo-management リポジトリの scripts/](https://github.com/smkwlab/student-repo-management/tree/main/scripts) にあります。

### setup-branch-protection.sh（教員用）

```bash
# 複数リポジトリのブランチ保護設定
./scripts/setup-branch-protection.sh k21rs001-sotsuron k21rs002-sotsuron k21gjk01-thesis

# 個別リポジトリの設定
./scripts/setup-branch-protection.sh k21rs001-sotsuron

# 機能:
# - mainブランチ保護（PR必須、1承認必要）
# - GitHub Actions自動マージ許可
# - final-*タグ時の自動マージ対応
```

## 複数人レビューの運用方法

役割分担（主指導・副指導・外部）、順次/並行/段階的レビューの各パターン、CODEOWNERS や必要承認数の
GitHub 設定、通知管理、レビュー遅延時の対応は、[PR-REVIEW-GUIDE.md](PR-REVIEW-GUIDE.md) の
「複数教員での添削」を参照してください。教員間で意見が相違した場合は PR 上で協議し、学生には統一見解を提示します。

## 効率的な添削のコツ

Suggestion の効果的な使用、優先順位付け、週次の推奨スケジュールは、
[PR-REVIEW-GUIDE.md](PR-REVIEW-GUIDE.md) の「効率的な添削のコツ」を参照してください。

## トラブルシューティング

### よくある問題と対処法

#### 1. 学生のブランチ作成ミス

```bash
# 正しいベースブランチを指定してブランチ作成支援
git checkout {correct-base-branch}
git checkout -b {new-branch-name}
git push -u origin {new-branch-name}
```

#### 2. aldc実行ファイルの残留

```bash
# 一時ファイルの削除
find . -name "*-aldc" -type f -delete
```

## セキュリティとベストプラクティス

### 1. リポジトリアクセス管理

- プライベートリポジトリの確認
- 必要最小限のCollaborator設定
- 定期的なアクセス権限見直し

### 2. ブランチ保護

```bash
# main ブランチ保護設定例
gh api repos/smkwlab/{repo}/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":[]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1}'
```

### 3. バックアップ

```bash
# 重要な節目でのバックアップ
git tag v1.0-{student-id}-submit
git push origin v1.0-{student-id}-submit
```

## 提出プロセス管理

論文提出は **2段階のプロセス** で管理します：

### 第1段階: 論文提出許可

#### 1. 論文本体の完成度判定

```bash
# 学生の論文内容を確認
# 最新の draft PR と PDF アーティファクトで全体チェック
# 各版PRで変更内容チェック
```

#### 2. 提出許可の指示

論文本体が提出レベルに達したと判断した場合：

```
学生への指示例：
「論文本体の内容が提出レベルに達しました。
現在のドラフトに submit タグを作成し、概要の執筆を開始してください。」
```

#### 3. submit タグの確認

```bash
# 学生が作成したsubmitタグを確認
git tag -l "*submit*"
git show submit

# この段階ではmainブランチにマージされません
```

### 第2段階: 概要執筆・添削

#### 1. 概要執筆の指導

```bash
# 概要用ブランチの確認
git branch -r | grep abstract

# 概要PRのレビュー
gh pr list --label abstract
```

#### 2. 概要完成の判定

概要の内容が適切になったタイミングで、口頭で最終段階に進むことを伝えます。

### 第3段階: 最終版完成・自動マージ（口頭指示）

#### 1. 最終版判定後の指示

概要完成後、論文の最終改善を経て最終版と判定した場合：

```
学生への指示例（口頭）：
「最終版として問題ありません。final-2nd タグを作成してください。」
```

#### 2. final tag による提出 PR の自動作成

学生が `final-*` タグを作成すると、GitHub Actions（auto-final-merge.yml）が
**タグの付いたブランチ → main の提出 PR**（タイトル "Final Submission: final-*"）を
自動作成します。同時に、タグ push に対して latex-build が最終版 PDF 付きの
GitHub Release を作成します。

#### 3. 提出 PR の確認・マージ

```bash
# PR内容を確認・承認のうえ、教員がマージ
gh pr review {pr-number} --approve --body "最終版として承認します。"
# マージ方式はリポジトリ設定に従う（merge が許可されていなければ --squash 等に読み替え）
gh pr merge {pr-number} --merge
```

#### 4. 提出完了の確認

```bash
# final tagの確認
git tag -l "final-*"
git show final-2nd

# GitHub Release の確認
gh release list

# main ブランチにマージされたことを確認
gh pr list --state merged --base main
```

### 段階別タグの意味

- **submit タグ**: 論文本体の提出許可版（mainにマージされない）
- **final タグ**: 最終完成版（main への提出 PR を自動作成・教員がマージ、GitHub Release作成）

### トラブル時の対応

```bash
# ワークフロー実行状況の確認
gh run list --workflow="Auto Final Merge"

# ワークフロー失敗時の手動マージ
gh pr merge {pr-number} --merge
gh release create final-2nd --title "Final Submission: final-2nd"

# リポジトリアーカイブ（任意）
gh repo archive smkwlab/{student-repo}
```

## その他

### GitHub Actions設定

- PDF自動生成の確認
- Reviewer自動アサインの確認
- **次稿ブランチ自動作成の確認**（create-next-draft.yml）
- **suggestion 次稿自動反映の確認**（sync-next-draft.yml）
- 必要に応じてworkflow調整

### 学生指導のポイント

- GitHub Desktopの基本操作支援
- ブランチ概念の簡単な説明
- commit頻度の指導
- 印刷推敲の重要性
- **概要執筆の指示タイミング**: 
  - 論文本体の骨格が固まった段階（推奨：3rd-draft以降）
  - 大きな構成変更の可能性が低くなった時点
  - 学生に指示：「概要執筆を開始してください」
- **abstract-1stブランチ**: 学生が手動作成（**その時点の最新稿ベース**）
- **abstract-2nd以降**: 自動作成時に最新稿ブランチから作成
  - 例：7th-draftが最新なら、abstract-2ndは7th-draftベース
  - 利点：常に最新の論文本体を含むため、整合性が保たれる
- **自動作成ブランチの切り替え**: 
  - GitHub Desktopでは `origin/xxx-draft` として表示
  - 学生には「originが付いているブランチを選択」と指導

### 概要執筆指示の例

#### 指示のタイミング例
```
5th-draftをレビューした結果、論文の基本構成が固まったと判断した場合：

学生への指示例：
「論文本体の構成が固まりましたので、概要の執筆を開始してください。
現在の最新稿をベースにabstract-1stブランチを作成し、gaiyou.texの執筆を進めてください。
概要では、研究の背景・目的・手法・結果・結論を400字程度でまとめてください。」
```

#### 判断基準
- ✅ 章立てが確定している
- ✅ 主要な実験・検証が完了している  
- ✅ 結論の方向性が固まっている
- ❌ まだ大きな構成変更の可能性がある

質問がある場合は管理者へ共有し（smkwlab では smkwlabML）、ノウハウを蓄積していきましょう。

## 関連ドキュメント

- [TEACHER-ONBOARDING.md](TEACHER-ONBOARDING.md): 初めての教員向けオンボーディング（最初の1時間で読む文書）
- [PR-REVIEW-GUIDE.md](PR-REVIEW-GUIDE.md): 日常のレビュー操作の正典（コメント・Suggestion・複数教員レビュー）
- [PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md): エコシステム全体の添削ルールの正典
