# コーディング規約・スタイルガイド

## 必須ルール
1. **日本語コメント必須**: すべてのコメントは日本語で記述
2. **段階的思考**: 複雑な実装前は `/thinkharder` または `/think` を使用
3. **コード品質**: 実装後は必ず `npm run lint` と `npm run test` を実行
4. **セキュリティ重視**: 認証・APIキー・パスワード関連は慎重に扱う

## Go バックエンド規約
- **構造**: 機能別ハンドラー構成（handlers/auth.go, handlers/messages.go等）
- **命名**: 関数・構造体・変数名に日本語コメント必須
- **認証**: Firebase認証ミドルウェア使用
- **エラーハンドリング**: 適切なHTTPステータスコード、日本語エラーメッセージ
- **データベース**: MongoDB操作はservice層経由
- **依存性注入**: ハンドラーはサービス層を受け取る構造

## Vue.js フロントエンド規約
- **コンポーネント**: PascalCase命名、日本語コメント推奨
- **ファイル構成**: 機能別ディレクトリ構成
- **状態管理**: Pinia使用、stores/配下に機能別ストア
- **ルーティング**: router/index.ts、認証ガード必須
- **API呼び出し**: services/配下のサービス層経由
- **型定義**: TypeScript活用、日本語説明コメント

## TypeScript規約
- **型定義**: 型には日本語での説明コメント
- **strict**: 厳密なTypeScript設定
- **interface**: APIレスポンス等はinterface定義

## Flutter (モバイル) 規約
- **命名**: snake_case（Dart標準）
- **画面**: screens/配下、機能別ファイル分割
- **サービス**: services/配下、APIアクセス層
- **状態管理**: Provider または Riverpod使用予定

## ファイル・ディレクトリ構成
```
backend/
  handlers/     # APIハンドラー（機能別分割）
  models/       # データモデル・サービス層
  middleware/   # 認証等のミドルウェア
  services/     # 外部API連携（Firebase等）
  database/     # DB接続管理

frontend/src/
  components/   # 機能別コンポーネント
  views/        # ページコンポーネント
  stores/       # Pinia状態管理
  services/     # API呼び出しサービス層
  router/       # ルーティング設定

mobile/lib/
  screens/      # 画面コンポーネント
  services/     # APIサービス層
  models/       # データモデル
```

## セキュリティ・認証規約
- **Firebase認証**: 全APIエンドポイントで認証必須
- **JWT削除**: Firebase移行により従来のJWT認証は廃止
- **環境変数**: 機密情報は.env管理、.env.example提供
- **API キー**: ANTHROPIC_API_KEY等は環境変数で管理