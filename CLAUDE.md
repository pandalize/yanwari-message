# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

やんわり伝言サービス - AIを使って気まずい用件を優しく伝えるサービス

### 基本フロー
1. ユーザーがメッセージ入力
2. AI が3つのトーン（優しめ、建設的、カジュアル）に変換
3. 最適なトーンを選択
4. AI がメッセージを分析して最適な送信時間を提案
5. 配信時間を決定して送信予約
6. 受信者に指定時間に配信

## 技術スタック

- **バックエンド**: Go 1.23+ + Gin + Firebase認証 + MongoDB Atlas
- **フロントエンド**: Vue 3 + TypeScript + Vite + Pinia
- **モバイル**: Flutter (iOS/Android)
- **AI**: Anthropic Claude API

## 開発コマンド

```bash
# セットアップ
npm run install:all
npm run setup:env

# 開発サーバー起動
npm run dev              # Web + Backend同時起動
./yanwari-start          # 全環境起動（Web・Mobile・Backend）

# 個別起動
npm run dev:backend      # Go サーバー :8080
npm run dev:frontend     # Vue 開発サーバー :5173
cd mobile && flutter run # Flutter モバイルアプリ

# テスト・品質チェック
npm run test
npm run lint
```

## ブランチ戦略

### メインブランチ
- **main** - 本番環境（プロダクション）
- **develop** - 統合開発ブランチ（Web・Mobile共通）

### 機能開発ブランチ
- **feature/web-[機能名]** - Web版専用機能（Vue.js）
- **feature/mobile-[機能名]** - モバイル版専用機能（Flutter）
- **feature/shared-[機能名]** - 共通機能（バックエンドAPI・DB・認証等）

### 開発フロー
```bash
# 機能開発例
git checkout develop
git pull origin develop
git checkout -b feature/web-new-ui        # Web版機能
git checkout -b feature/mobile-new-screen # Mobile版機能  
git checkout -b feature/shared-new-api    # 共通機能

# 開発完了後
git push origin feature/xxx
# PR作成: feature/xxx → develop
# develop → main（リリース時）
```

## 運用ルール

1. **日本語コメント必須**
2. **Firebase認証**: 全APIで認証必須
3. **品質チェック**: 実装後は `npm run lint` と `npm run test` を実行

## 完了済み機能

- ✅ Firebase認証システム
- ✅ メッセージ作成・AIトーン変換  
- ✅ スケジュール・時間提案機能
- ✅ 友達申請システム
- ✅ メッセージ評価システム
- ✅ Flutter iOSアプリ

## ブランチ統合計画

### 現在の課題
現在3つのdevelopブランチが分散：
- `develop` - 基本ブランチ
- `develop-mobile` - モバイル開発用（AI改善含む）  
- `develop-web` - Web開発用

### 統合提案
**1つの`develop`に統一** → 開発効率向上・コードベース統一

```bash
# 統合手順
git checkout develop
git pull origin develop
git merge develop-mobile --no-ff
git merge develop-web --no-ff
git push origin develop

# 古いブランチ削除
git push origin --delete develop-mobile develop-web
```

### 統合後の利点
- Web・Mobile共通のコードベース
- AI改善機能の全プラットフォーム共有
- 重複開発の削減・レビュー効率化