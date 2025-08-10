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

# 開発
npm run dev                # 全て起動
./yanwari-start           # 統合起動スクリプト

# 品質チェック
npm run lint              # リント
npm run test              # テスト
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

## 現在のブランチ
- **現在**: `fix/message-rating-system`
- **メイン**: `main`
- **開発**: `develop`