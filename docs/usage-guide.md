# 📖 使用方法ガイド - アジャイル GitHub スイート

## 🎯 概要

「アジャイル GitHub スイート」は、**複数のプロジェクト・リポジトリで使える汎用アジャイル管理ツール**です。各プロジェクトで独立してセットアップし、チーム固有のアジャイル開発を支援します。

## 🚀 セットアップ方法

### 📋 前提条件

- GitHub CLI (`gh`) がインストール・認証済み
- Git がインストール済み
- Python 3.x がインストール済み（ローカル開発用）

### 🛠️ 方法1: ワンクリックセットアップ（推奨）

```bash
# 1. このリポジトリをクローン
git clone https://github.com/pandalize/agile.git
cd agile

# 2. あなたのプロジェクト用にセットアップ
./scripts/setup-enhanced.sh -r your-org/your-project -s "Sprint 1" -d 14
```

#### セットアップオプション
```bash
./scripts/setup-enhanced.sh [OPTIONS]

オプション:
  -r, --repo REPO        対象GitHubリポジトリ (owner/repo形式) [必須]
  -s, --sprint NAME      スプリント名 (デフォルト: Sprint 1)
  -d, --days DAYS        スプリント期間(日) (デフォルト: 14)
  -l, --labels FILE      カスタムラベルJSONファイル
  --skip-labels          ラベル作成をスキップ
  --skip-milestone       マイルストーン作成をスキップ  
  --skip-issues          サンプル課題作成をスキップ
  --dry-run             実際の変更なしで実行内容確認
  -v, --verbose         詳細ログ出力
```

### 🔧 方法2: 手動セットアップ

<details>
<summary>📋 手動セットアップ手順（クリックして展開）</summary>

#### ステップ1: リポジトリ準備
```bash
# 1. agileリポジトリをクローン
git clone https://github.com/pandalize/agile.git your-project-agile
cd your-project-agile

# 2. リモートURLを変更（あなたのプロジェクト用）
git remote set-url origin https://github.com/your-org/your-project.git

# 3. プロジェクト固有の設定
# docs/assets/js/utils.js を編集
```

#### ステップ2: GitHub設定
```bash
# ラベル作成
gh label create "priority/high" --color "d73a4a" --repo your-org/your-project
gh label create "priority/medium" --color "fbca04" --repo your-org/your-project
gh label create "priority/low" --color "0e8a16" --repo your-org/your-project

gh label create "type/feature" --color "a2eeef" --repo your-org/your-project
gh label create "type/bug" --color "d73a4a" --repo your-org/your-project
gh label create "type/task" --color "7057ff" --repo your-org/your-project

gh label create "estimate/1" --color "c5f015" --repo your-org/your-project
gh label create "estimate/2" --color "c5f015" --repo your-org/your-project
gh label create "estimate/3" --color "c5f015" --repo your-org/your-project
gh label create "estimate/5" --color "c5f015" --repo your-org/your-project
gh label create "estimate/8" --color "c5f015" --repo your-org/your-project

# マイルストーン作成
gh milestone create "Sprint 1" --due-date "2025-09-01" --repo your-org/your-project
```

#### ステップ3: GitHub Pages有効化
1. リポジトリの Settings → Pages
2. Source: Deploy from a branch
3. Branch: main, Folder: /docs
4. Save

</details>

## 🌟 複数プロジェクトでの活用方法

### パターン1: プロジェクト個別管理

各プロジェクトに独立してセットアップ：

```bash
# プロジェクトA
./scripts/setup-enhanced.sh -r company/project-alpha -s "Alpha Sprint 1" -d 10

# プロジェクトB  
./scripts/setup-enhanced.sh -r company/project-beta -s "Beta Sprint 1" -d 14

# プロジェクトC
./scripts/setup-enhanced.sh -r company/project-gamma -s "Gamma Sprint 1" -d 7
```

### パターン2: チーム統合管理

複数プロジェクトを一元管理：

```bash
# メインダッシュボードリポジトリを作成
gh repo create your-org/agile-dashboard --public

# 各プロジェクトのメトリクスを統合（将来機能）
```

### パターン3: 部署横断展開

```bash
# 開発部
./scripts/setup-enhanced.sh -r company/dev-team -s "Dev Sprint 1" -d 14

# デザイン部
./scripts/setup-enhanced.sh -r company/design-team -s "Design Sprint 1" -d 7  

# QA部
./scripts/setup-enhanced.sh -r company/qa-team -s "QA Sprint 1" -d 10
```

## 📊 利用可能な機能

### 1. 📈 バーンダウンチャート
- **URL**: `https://your-org.github.io/your-project/burndown/`
- **機能**: スプリント進捗の可視化、ベロシティ計算、完了予測
- **更新**: GitHub Actionsで毎平日朝9時自動更新

### 2. 👥 チームダッシュボード
- **URL**: `https://your-org.github.io/your-project/team-dashboard/`
- **機能**: チームメトリクス、アクティブ課題、パフォーマンス指標
- **更新**: 5分間隔で自動更新

### 3. 📋 Issue管理システム
- **User Story テンプレート**: 機能開発用
- **Bug Report テンプレート**: バグ修正用
- **Task テンプレート**: 技術作業用

### 4. 🏷️ ラベルシステム
```
優先度: priority/high, priority/medium, priority/low
種類: type/feature, type/bug, type/task, type/epic
見積り: estimate/1, estimate/2, estimate/3, estimate/5, estimate/8
状態: status/backlog, status/todo, status/in-progress, status/review, status/done
```

### 5. 🤖 自動化機能
- **バーンダウンデータ収集**: 平日朝9時
- **チームメトリクス収集**: 朝8時・夕方6時
- **Discord通知連携**: 進捗通知（オプション）

## ⚙️ カスタマイズ方法

### 🎨 プロジェクト固有のブランディング

#### 1. プロジェクト名・説明の変更
```html
<!-- docs/index.html -->
<title>Your Project - アジャイルダッシュボード</title>
<h1>🚀 Your Project スイート</h1>
<p>Your Project Team の完全なアジャイル開発管理システム</p>
```

#### 2. リポジトリ情報の更新
```javascript
// docs/assets/js/utils.js
const REPO_OWNER = 'your-org';
const REPO_NAME = 'your-project';
```

#### 3. カラーテーマのカスタマイズ
```css
/* docs/assets/css/common.css */
:root {
    --color-primary: #your-brand-color;
    --color-success: #your-success-color;
    /* ... */
}
```

### 📝 Issue テンプレートのカスタマイズ

```yaml
# .github/ISSUE_TEMPLATE/custom-story.yml
name: "カスタム User Story"
description: "プロジェクト固有のUser Story作成"
body:
  - type: textarea
    attributes:
      label: "プロジェクト固有の項目"
      description: "あなたのプロジェクトに特化した項目を追加"
```

### 🔧 GitHub Actions のカスタマイズ

```yaml
# .github/workflows/custom-metrics.yml
name: Custom Project Metrics
on:
  schedule:
    - cron: '0 9 * * 1-5'  # プロジェクト固有のスケジュール
```

## 🚀 運用ベストプラクティス

### 📋 セットアップ後のチェックリスト

- [ ] GitHub Pages が正常に表示される
- [ ] バーンダウンチャートにアクセス可能
- [ ] チームダッシュボードが機能する
- [ ] Issue テンプレートが利用可能
- [ ] ラベルが正しく設定されている
- [ ] GitHub Actions が動作している

### 🏃‍♂️ 日常運用フロー

#### Sprint Planning
1. 新しいマイルストーンを作成
2. バックログからIssueを選定
3. Story Point を見積もり
4. スプリントゴールを設定

#### Daily Standup  
1. プロジェクトボードを確認
2. Issue ステータスを更新
3. ブロッカーを特定・解決

#### Sprint Review & Retrospective
1. バーンダウンチャートで進捗分析
2. ベロシティを測定
3. 改善アクションを決定

### 📊 メトリクス監視

定期的に確認すべき指標：

- **スプリント計画精度**: 80%以上目標
- **ベロシティ安定性**: ±20%以内の変動
- **バーンダウン健全性**: 理想線±10%以内
- **Issue完了率**: 95%以上

## 🔗 関連ドキュメント

- [📊 Project Status & Strategy](../project-status-and-strategy.md)
- [🔧 Setup Guide](../setup-guide.md)  
- [⚖️ Tool Comparison](../agile-tools-comparison.md)
- [📋 GitHub Projects Best Practices](https://docs.github.com/en/issues/planning-and-tracking-with-projects)

## ❓ トラブルシューティング

### よくある問題と解決方法

#### Q: GitHub Pages が表示されない
**A**: Settings → Pages で設定を確認し、数分待ってから再アクセス

#### Q: バーンダウンチャートにデータが表示されない  
**A**: GitHub Actions が実行されているか確認、手動でワークフローをトリガー

#### Q: ラベルが重複している
**A**: 既存ラベルを削除してから setup スクリプトを再実行

#### Q: 複数プロジェクトでの管理が煩雑
**A**: 今後のEnterprise機能で統合管理ダッシュボードを提供予定

## 🆘 サポート

- **Issue報告**: [GitHub Issues](https://github.com/pandalize/agile/issues)
- **機能要望**: [GitHub Discussions](https://github.com/pandalize/agile/discussions)
- **コミュニティ**: [Discord Server](#) (準備中)

---

**🌟 この使用方法ガイドで、あなたのプロジェクトも効率的なアジャイル開発が実現できます！**