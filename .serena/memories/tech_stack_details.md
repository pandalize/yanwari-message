# 技術スタック詳細

## バックエンド (Go 1.23+)
- **フレームワーク**: Gin Web Framework
- **認証**: Firebase Authentication + Firebase Admin SDK
- **データベース**: MongoDB Atlas (接続管理、CRUD操作)
- **AI連携**: Anthropic Claude API
- **主要パッケージ**:
  - firebase.google.com/go/v4 v4.18.0
  - github.com/gin-gonic/gin v1.10.1
  - go.mongodb.org/mongo-driver v1.17.4
  - golang.org/x/crypto v0.40.0
  - gopkg.in/yaml.v3 v3.0.1

## フロントエンド (Vue 3)
- **フレームワーク**: Vue 3 + TypeScript
- **ビルドツール**: Vite 6.2.4
- **状態管理**: Pinia 3.0.1
- **ルーティング**: Vue Router 4.5.0
- **HTTP クライアント**: Axios 1.10.0
- **認証**: Firebase Web SDK 12.0.0

## モバイルアプリ (Flutter)
- **フレームワーク**: Flutter
- **対応プラットフォーム**: iOS, Android
- **認証**: Firebase Authentication
- **現在のアプリ状況**: iOSアプリ受信トレイ機能実装済み

## データベース (MongoDB)
- **プロバイダー**: MongoDB Atlas
- **接続管理**: connection pooling実装
- **コレクション**: users, messages, schedules, friend_requests, friendships, message_ratings

## AI・外部API
- **AI プロバイダー**: Anthropic Claude API
- **機能**: トーン変換（3種並行処理）、時間提案
- **設定**: YAML設定ファイルでプロンプト管理