# 統一ブランチ戦略

## 現在の課題
現在3つのdevelopブランチが存在し、開発が分散している：
- develop        # 基本ブランチ
- develop-mobile # モバイル開発用（AI改善含む）
- develop-web    # Web開発用

## 統一ブランチ戦略

### メインブランチ構成
- **main** - 本番環境（プロダクション）
- **develop** - 統合開発ブランチ（Web・Mobile共通）

### 機能開発ブランチ
- **feature/web-[機能名]** - Web版専用機能
- **feature/mobile-[機能名]** - モバイル版専用機能
- **feature/shared-[機能名]** - 共通機能（バックエンドAPI・DB・認証等）

## 統合の利点

### 開発効率向上
- すべての開発者が同じコードベースで作業
- AI改善機能がWeb版・モバイル版で共有
- 重複開発の削減
- コードレビューの効率化

### コードベース統一
- バックエンドAPIの共通化
- 共通コンポーネント・ユーティリティの再利用
- 統一されたテスト・CI/CD環境
- 設定・環境変数の一元管理

## 統合手順

### Step 1: develop-mobile統合
```bash
git checkout develop
git pull origin develop
git merge develop-mobile --no-ff -m "統合: develop-mobileをdevelopにマージ"
```

### Step 2: develop-web統合
```bash
git merge develop-web --no-ff -m "統合: develop-webをdevelopにマージ"
```

### Step 3: 古いブランチ削除
```bash
# リモートブランチ削除
git push origin --delete develop-mobile
git push origin --delete develop-web

# ローカルブランチ削除
git branch -D develop-mobile
git branch -D develop-web
```

### Step 4: 統合developをプッシュ
```bash
git push origin develop
```

## 新しいワークフロー

### 日常的な開発フロー
```bash
# Web版機能開発
git checkout develop
git pull origin develop
git checkout -b feature/web-new-feature
# 開発作業
git push origin feature/web-new-feature
# PR: feature/web-new-feature → develop

# モバイル版機能開発
git checkout develop
git pull origin develop  
git checkout -b feature/mobile-new-feature
# 開発作業
git push origin feature/mobile-new-feature
# PR: feature/mobile-new-feature → develop

# 共通機能開発
git checkout develop
git pull origin develop
git checkout -b feature/shared-new-api
# 開発作業
git push origin feature/shared-new-api
# PR: feature/shared-new-api → develop
```

### リリースフロー
```bash
# 定期的にdevelopの安定版をmainにマージ
git checkout main
git pull origin main
git merge develop --no-ff -m "リリース: v1.x.x"
git tag v1.x.x
git push origin main --tags
```

## ブランチ命名規則

### 機能ブランチ
- `feature/web-ui-redesign` - Web版UI改善
- `feature/web-notification-system` - Web版通知機能
- `feature/mobile-push-notification` - モバイルプッシュ通知
- `feature/mobile-offline-mode` - モバイルオフライン機能
- `feature/shared-api-v2` - 共通API v2
- `feature/shared-real-time-sync` - 共通リアルタイム同期

### その他ブランチ
- `bugfix/web-login-issue` - Web版バグ修正
- `bugfix/mobile-crash-fix` - モバイル版バグ修正
- `hotfix/security-patch` - 緊急セキュリティ修正
- `release/v1.0.0` - リリース準備

## 統合後の開発環境

### 共通開発環境
- バックエンド: `http://localhost:8080` (Go + Gin)
- Web: `http://localhost:5173` (Vue 3)
- モバイル: Flutter + Hot Reload

### 統合スクリプト
```bash
# 全環境起動
./yanwari-start

# 個別起動
npm run dev:backend   # バックエンドのみ
npm run dev:frontend  # Webのみ
cd mobile && flutter run  # モバイルのみ
```

## 期待される効果

### 短期的効果（1-2週間）
- 開発者間の認識統一
- 重複作業の削減
- レビュー効率向上

### 中長期的効果（1-3ヶ月）
- 開発速度の大幅向上
- バグ削減・品質向上
- 機能の一貫性確保
- デプロイ・リリースの簡素化