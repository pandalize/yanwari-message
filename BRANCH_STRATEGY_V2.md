# やんわり伝言 - ブランチ戦略 v2.0
## Web版・Flutter版並行開発対応

**更新日**: 2025年8月9日  
**対象**: やんわり伝言プロジェクト（Web版Vue.js + Flutter版iOS/Android）

## 🎯 新戦略の目的

1. **プラットフォーム別並行開発**: Web版とFlutter版の効率的な並行開発
2. **責任の明確化**: フロントエンド技術別の責任範囲明確化
3. **統合の簡素化**: 最終的な統合・デプロイプロセスの最適化
4. **コンフリクト最小化**: 交差開発によるマージコンフリクト防止

---

## 🏗️ メインブランチ構成

### **Tier 1: 本番・統合ブランチ**
```
main                 # 本番デプロイ用（Web・Mobile統合版）
└── develop         # 全体統合ブランチ（安定版集約）
```

### **Tier 2: プラットフォーム別統合ブランチ**
```
develop-web         # Web版専用統合ブランチ（Vue.js + フロントエンド）
develop-mobile      # Flutter版専用統合ブランチ（iOS/Android）
```

### **Tier 3: 機能開発ブランチ**
```
feature/web-[機能名]      # Web版専用機能（例: web-inbox-redesign）
feature/mobile-[機能名]   # Flutter版専用機能（例: mobile-push-notifications）
feature/shared-[機能名]   # 共通機能（例: shared-api-auth-v2）
hotfix/[修正内容]        # 緊急修正（例: hotfix-login-bug）
```

---

## 🔄 開発ワークフロー

### **標準的な機能開発フロー**

#### **Web版機能開発**
```bash
# 1. Web版機能ブランチ作成
git checkout develop-web
git pull origin develop-web
git checkout -b feature/web-notification-system

# 2. 機能開発・テスト
# （frontend/, backend/handlers/, backend/models/の変更）

# 3. develop-webに統合
git checkout develop-web
git merge feature/web-notification-system
git push origin develop-web

# 4. 定期的にdevelopに統合（週1回）
git checkout develop
git merge develop-web
```

#### **Flutter版機能開発**
```bash
# 1. Flutter版機能ブランチ作成
git checkout develop-mobile
git pull origin develop-mobile
git checkout -b feature/mobile-message-compose

# 2. 機能開発・テスト
# （mobile/, backend/（必要時）の変更）

# 3. develop-mobileに統合
git checkout develop-mobile
git merge feature/mobile-message-compose
git push origin develop-mobile

# 4. 定期的にdevelopに統合（週1回）
git checkout develop
git merge develop-mobile
```

#### **共通バックエンド開発**
```bash
# 1. 共通機能ブランチ作成
git checkout develop
git pull origin develop
git checkout -b feature/shared-real-time-notifications

# 2. バックエンドAPI・データベース変更
# （backend/, 設定ファイル変更）

# 3. developに直接統合
git checkout develop
git merge feature/shared-real-time-notifications
```

---

## 📁 ファイル責任範囲

### **Web版専用ファイル (`develop-web`)**
```
frontend/               # Vue.jsアプリケーション全体
├── src/components/     # Webコンポーネント
├── src/views/         # Web画面
├── src/stores/        # Web状態管理（Pinia）
├── src/services/      # WebAPI呼び出しサービス
└── package.json       # Web依存関係

# Web版固有のバックエンド拡張
backend/handlers/web_*  # Web専用APIハンドラー（必要時）
```

### **Flutter版専用ファイル (`develop-mobile`)**
```
mobile/                 # Flutterアプリケーション全体
├── lib/screens/       # Flutter画面
├── lib/models/        # Flutterデータモデル
├── lib/services/      # Flutter API・認証サービス
├── android/           # Android固有設定
├── ios/              # iOS固有設定
└── pubspec.yaml      # Flutter依存関係

# Flutter版固有のバックエンド拡張
backend/handlers/mobile_*  # Mobile専用APIハンドラー（必要時）
```

### **共通ファイル (`develop`)**
```
backend/                # 共通バックエンドAPI
├── handlers/          # 共通APIハンドラー
├── models/           # データベースモデル
├── services/         # 共通ビジネスロジック
├── database/         # DB接続・スキーマ
└── config/          # 設定・環境変数

# 共通設定
.env.example           # 環境変数テンプレート
README.md             # プロジェクト公式文書
CLAUDE.md            # AI開発者向けガイド
```

---

## 🚦 統合・リリースフロー

### **週次統合（毎週金曜日）**
```bash
# 1. プラットフォーム別統合をdevelopに統合
git checkout develop

# Web版統合
git merge develop-web

# Flutter版統合  
git merge develop-mobile

# 統合テスト実行
npm run test
cd mobile && flutter test

# 統合成功時にpush
git push origin develop
```

### **本番リリース（月次）**
```bash
# 1. developからmainにマージ
git checkout main
git merge develop

# 2. リリースタグ作成
git tag -a v1.2.0 -m "やんわり伝言 v1.2.0: Web版UI改善 + Flutter版iOS対応"

# 3. 本番デプロイ
git push origin main --tags
```

---

## 🛠️ 既存ブランチ整理計画

### **統合対象ブランチ**
```
# Web版関連を develop-web に統合
feature/ui-design-improvement    → develop-web
feature/ui-responsive-improvement → develop-web
feature/inbox-ui-redesign       → develop-web

# Flutter版関連を develop-mobile に統合
feature/flutter-mobile-app      → develop-mobile（既に統合済み）

# 共通バックエンド関連を develop に統合
feature/auth-phase1-implementation → develop
feature/friend-request-system      → develop（既に統合済み）
feature/ai-tone-transform          → develop

# 非アクティブブランチ削除対象
feature/auth-system               # 古いJWT認証（Firebase移行済み）
feature/message-delivery          # 未実装・空ブランチ
feature/setting-page              # 重複（settings-pageが正）
```

### **新規作成ブランチ**
```bash
# プラットフォーム専用統合ブランチ
git checkout -b develop-web origin/develop
git checkout -b develop-mobile origin/develop

# 今後の機能開発用
git checkout -b feature/web-real-time-notifications develop-web
git checkout -b feature/mobile-push-system develop-mobile
git checkout -b feature/shared-analytics develop
```

---

## 📋 開発者向けクイックリファレンス

### **Web版開発者**
```bash
# 日常的な作業
git checkout develop-web          # Web統合ブランチに切り替え
git pull origin develop-web       # 最新取得
git checkout -b feature/web-xxx   # 新機能ブランチ作成

# 作業完了時
git push origin feature/web-xxx   # プッシュ
# GitHubでPR作成: feature/web-xxx → develop-web
```

### **Flutter版開発者**
```bash
# 日常的な作業
git checkout develop-mobile        # Flutter統合ブランチに切り替え
git pull origin develop-mobile     # 最新取得
git checkout -b feature/mobile-xxx # 新機能ブランチ作成

# 作業完了時
git push origin feature/mobile-xxx # プッシュ
# GitHubでPR作成: feature/mobile-xxx → develop-mobile
```

### **バックエンド開発者**
```bash
# 日常的な作業
git checkout develop              # 共通開発ブランチ
git pull origin develop          # 最新取得
git checkout -b feature/shared-xxx # 共通機能ブランチ作成

# 作業完了時
git push origin feature/shared-xxx # プッシュ
# GitHubでPR作成: feature/shared-xxx → develop
```

---

## 🔍 CI/CD・テスト戦略

### **ブランチ別CI設定**
```yaml
# develop-web: Web版専用テスト
- Web Unit Test (Vitest)
- Web E2E Test (Playwright) 
- Web Build Test
- API Integration Test

# develop-mobile: Flutter版専用テスト
- Flutter Unit Test
- Flutter Integration Test
- iOS Build Test
- Android Build Test
- API Integration Test

# develop: 統合テスト
- Full Stack E2E Test
- Cross Platform Test
- Database Migration Test
- Performance Test
```

---

## ⚡ 緊急修正（Hotfix）プロセス

```bash
# 1. 本番問題発見時
git checkout main
git pull origin main
git checkout -b hotfix/critical-login-bug

# 2. 修正・テスト
# 最小限の修正実装

# 3. main・developの両方に適用
git checkout main
git merge hotfix/critical-login-bug
git push origin main

git checkout develop
git merge hotfix/critical-login-bug
git push origin develop

# 4. プラットフォーム別ブランチにも反映
git checkout develop-web
git merge develop

git checkout develop-mobile  
git merge develop
```

---

## 📊 効果・メリット

### **開発効率の向上**
- ✅ **並行開発**: Web・Flutter開発者が独立して作業可能
- ✅ **コンフリクト削減**: プラットフォーム専用ファイル分離
- ✅ **責任明確化**: 各開発者の担当範囲が明確

### **品質管理の強化**
- ✅ **段階的統合**: プラットフォーム別 → 全体統合の2段階
- ✅ **テスト最適化**: プラットフォーム固有のテスト実行
- ✅ **デプロイ安全性**: 統合テスト後の本番デプロイ

### **保守性の向上**
- ✅ **ブランチ整理**: 不要ブランチ削除・アクティブブランチ明確化
- ✅ **履歴追跡**: プラットフォーム別の変更履歴管理
- ✅ **ロールバック**: 問題発生時の影響範囲限定

---

## 🎯 移行スケジュール

### **Phase 1: ブランチ準備（1週間）**
- develop-web, develop-mobile ブランチ作成
- 既存機能ブランチの統合・整理
- CI/CD設定更新

### **Phase 2: 開発フロー移行（2週間）**
- 新しいワークフローでの開発開始
- 開発者への移行ガイド共有
- 初期問題の解決・調整

### **Phase 3: 完全移行（1週間）**
- 旧ブランチの削除・アーカイブ
- 新戦略での最初の週次統合
- 移行完了の確認・文書化

---

**この戦略により、Web版とFlutter版の並行開発が効率化され、品質の高い統合デプロイが実現できます。**