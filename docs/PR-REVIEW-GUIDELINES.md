# Pull Request ベース添削ガイドライン

本ドキュメントは、九州産業大学情報科学部におけるLaTeX論文執筆エコシステムでのPull Requestベースの添削ルールと運用方針を定義します。

## 📋 目次

- [基本概念](#基本概念)
- [添削フロー](#添削フロー)
- [自動化システム](#自動化システム)
- [学生向けルール](#学生向けルール)
- [教員向けルール](#教員向けルール)
- [管理者向け機能](#管理者向け機能)
- [技術仕様](#技術仕様)

## 基本概念

### 段階的執筆アプローチ

本エコシステムは**段階的な文書改善プロセス**を採用し、学生の学習効果と教員の指導効率を最大化します。

```
アウトライン → 初稿 → 改稿 → 最終稿
     ↓         ↓      ↓       ↓
   構造確認   内容指導  詳細指導  最終確認
```

### Pull Request中心の設計

- **透明性**: 全ての変更と指導過程が記録される
- **段階性**: 各段階での適切なフィードバック
- **協働性**: 学生・教員・システムの協働による品質向上

## 添削フロー

### 1. 標準的な進行段階

#### 第0段階：アウトライン作成
- **ブランチ**: `0th-draft`
- **目的**: 全体構成の確認
- **内容**: 章立て、見出し構造のみ
- **レビュー観点**: 論理構成、研究範囲、構造的妥当性

#### 第1段階：初稿執筆
- **ブランチ**: `1st-draft` (自動作成)
- **目的**: 基本的な文章化
- **内容**: 各章の基本的な文章を追加
- **レビュー観点**: 内容の妥当性、論理展開、表現方法

#### 第2段階：改稿
- **ブランチ**: `2nd-draft` (自動作成)
- **目的**: 詳細化と精密化
- **内容**: より詳細な説明、図表の追加、参考文献
- **レビュー観点**: 詳細な内容、文章品質、学術的妥当性

#### 継続段階
- **3rd-draft, 4th-draft...**: 必要に応じて継続
- **最終提出**: `final-*` タグによる提出確定

### 2. 特殊なブランチパターン

#### 概要専用ブランチ
- **abstract-1st, abstract-2nd**: 英文概要
- **gaiyou-1st, gaiyou-2nd**: 日本語概要
- **用途**: 概要の独立した添削プロセス

## 自動化システム

### 1. ブランチ保護機能

#### A. Draft Merge Prevention
**ファイル**: `.github/workflows/prevent-draft-merge.yml`

```yaml
# 保護対象パターン
protected_patterns:
  - "0th-draft"
  - "*-draft"
  - "abstract-*"
  - "gaiyou-*"
```

**目的**: 添削プロセスを経ない直接マージを防止

#### B. Branch Protection Rules
**設定内容**:
- ✅ 1つ以上の承認レビューが必要
- ✅ 新コミット時に古いレビューを無効化  
- ✅ フォースプッシュとブランチ削除を禁止
- ✅ 対象ブランチ: `main`, `review-branch`

### 2. 次稿ブランチ自動作成

**ファイル**: `.github/workflows/create-next-draft.yml`

**動作例**:
```
1st-draft PR作成 → 2nd-draft ブランチ自動生成
2nd-draft PR作成 → 3rd-draft ブランチ自動生成
```

**効果**:
- 学生は常に次の段階に進める
- ブランチ管理の手間を削減

### 3. 最終提出処理

**ファイル**: `.github/workflows/auto-final-merge.yml`

**トリガー**: `final-*` タグの付与  
**処理**:
1. 承認済みPRの検索
2. 自動マージ実行
3. リリース作成

## 学生向けルール

### 1. 基本作業フロー

#### Step 1: ブランチ確認
```bash
# 現在のブランチ確認
git branch -a

# 作業ブランチに切り替え
git checkout 0th-draft  # または指定されたブランチ
```

#### Step 2: 段階的執筆
1. **アウトライン段階**: 章立てと見出し構造のみ
2. **初稿段階**: 基本的な文章を追加
3. **改稿段階**: 詳細化と精密化

#### Step 3: Pull Request作成
```markdown
# PRタイトル例
[0th-draft] 論文アウトライン提出
[1st-draft] 第1章〜第3章初稿提出
[2nd-draft] 全章改稿版提出
```

#### Step 4: レビュー対応
1. 教員からのレビューコメントを確認
2. 指摘事項を修正
3. **重要**: レビュー対応完了後は自分でPRをクローズ
4. 次のdraftブランチで執筆を継続

### 2. 品質管理遵守

#### LaTeX文書 (論文)
- **textlint**: 日本語校正ルールの遵守
- **コンパイル確認**: LaTeX構文エラーの解消
- **参考文献**: BibTeX形式の適切な使用

#### HTML文書 (ISEレポート)
- **W3C準拠**: 標準HTML構文の遵守
- **アクセシビリティ**: 画像alt属性、見出し構造
- **CSS**: 適切なスタイル設計

### 3. 禁止事項

- ❌ draftブランチからmainへの直接マージ
- ❌ レビュー前の完成版コミット
- ❌ フォースプッシュ (`git push --force`)
- ❌ ブランチの強制削除

## 教員向けルール

### 1. レビュー方針

#### 段階別レビュー観点

| 段階 | 主要観点 | 具体的内容 |
|------|----------|------------|
| 0th-draft | 構造・範囲 | 章立て、研究範囲、論理構成 |
| 1st-draft | 内容・展開 | 論理展開、内容妥当性、表現方法 |
| 2nd-draft+ | 詳細・品質 | 文章品質、学術的厳密性、完成度 |

#### レビューの段階的深化
```
浅い ←→ 深い
構造 → 内容 → 表現 → 詳細
```

### 2. レビューコメント作成

#### A. ファイル内コメント
- **場所**: 該当行に直接コメント
- **内容**: 具体的な修正指示
- **例**:
  ```
  + この文章は主語が不明確です。「誰が」を明示してください。
  + 図1の参照が不適切です。文中で適切に説明してください。
  ```

#### B. 総合コメント
- **場所**: PRの総合コメント欄
- **内容**: 全体的なフィードバック
- **例**:
  ```markdown
  ## 全体評価
  論理構成は改善されましたが、以下の点で更なる改善が必要です：
  
  ### 良い点
  - 第2章の関連研究整理が適切
  - 図表の配置が改善された
  
  ### 改善点
  - 結論部分の論理展開を強化
  - 参考文献の形式統一
  ```

### 3. レビュー承認基準

#### 承認条件
- ✅ 該当段階の学習目標を達成
- ✅ 重大な構造的・内容的問題が解決
- ✅ 次段階への準備が整った

#### 承認タイミング
- **段階完了時**: その段階の目標達成時に承認
- **継続指導**: 承認後も次段階で継続的指導

## 管理者向け機能

### 1. 自動リポジトリ管理

#### A. Issue処理ワークフロー
**トリガー**: 「📋 リポジトリ登録依頼」Issue作成  
**処理内容**:
1. 学生リポジトリの自動登録
2. ブランチ保護設定の適用
3. thesis-student-registryの更新
4. Issue自動クローズ

#### B. レジストリ管理
```bash
# 進捗監視
./registry-manager status

# 保護状況確認  
./registry-manager status --show-protection
```

### 2. 品質管理システム

#### A. 自動チェック項目
- **構文チェック**: LaTeX/HTML/CSS
- **校正チェック**: textlint日本語校正
- **標準準拠**: W3C validation
- **アクセシビリティ**: WAVE検証

#### B. エラー対応
```bash
# 品質問題の確認
gh pr checks <PR番号>

# エラーログの確認
gh run view <run-id> --log
```

## 技術仕様

### 1. ブランチ命名規則

#### 標準パターン
- `0th-draft`: アウトライン段階
- `1st-draft`, `2nd-draft`, `3rd-draft...`: 執筆段階
- `abstract-1st`, `abstract-2nd`: 英文概要
- `gaiyou-1st`, `gaiyou-2nd`: 日本語概要

#### 特殊パターン
- `final-submission`: 最終提出
- `review-branch`: 特別レビュー用

### 2. ワークフロー設定

#### A. 必須ワークフロー
```yaml
# .github/workflows/必須ファイル
- prevent-draft-merge.yml     # draft保護
- create-next-draft.yml       # 次稿自動作成
- auto-final-merge.yml        # 最終提出処理
```

#### B. 品質管理ワークフロー
```yaml
# LaTeX系
- textlint.yml               # 日本語校正
- latex-compile.yml          # コンパイル確認

# HTML系 (ISE)
- html-validation.yml        # W3C準拠チェック
- accessibility-check.yml    # アクセシビリティ
```

### 3. 権限設定

#### Repository Settings
```yaml
branches:
  main:
    protection_rules:
      required_reviews: 1
      dismiss_stale_reviews: true
      prevent_force_push: true
      prevent_deletions: true
  review-branch:
    protection_rules:
      required_reviews: 1
      dismiss_stale_reviews: true
```

---

## 📚 関連リソース

### ドキュメント
- [エコシステム全体構成](CLAUDE-ARCHITECTURE.md)
- [ワークフロー詳細](CLAUDE-WORKFLOWS.md)
- [学生向け使用方法](../sotsuron-template/README.md)

### 完成レポート例
- [学生作品例1](http://www-st.is.kyusan-u.ac.jp/~k22rs044/semi3a/)
- [学生作品例2](http://www-st.is.kyusan-u.ac.jp/~k22rs120/semi3a/)
- [学生作品例3](http://www-st.is.kyusan-u.ac.jp/~k22rs004/semi3a/)

### 管理ツール
- [registry-manager](../thesis-student-registry/registry_manager_v3/)
- [thesis-management-tools](../thesis-management-tools/)

---

*このドキュメントは本エコシステムの運用に関わる全ての関係者（学生・教員・管理者）を対象としています。*  
*最終更新: 2025-07-05*