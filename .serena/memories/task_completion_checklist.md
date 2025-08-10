# タスク完了時のチェックリスト

## 必須実行項目

### 1. コード品質チェック
```bash
# リント・フォーマットチェック
npm run lint
npm run format

# 型チェック（フロントエンド）
cd frontend && npm run type-check
```

### 2. テスト実行
```bash
# ユニットテスト実行
npm run test:backend   # Go テスト
npm run test:frontend  # Vitest テスト

# 必要に応じてE2Eテスト
npm run test:e2e
```

### 3. 動作確認
```bash
# 開発サーバー起動して動作確認
npm run dev
# または
./yanwari-start

# API動作確認（必要に応じて）
curl http://localhost:8080/health
```

### 4. Git・ブランチ管理
```bash
# 変更をコミット
git add .
git commit -m "feat: [機能の説明]"

# developブランチの最新変更を取り込み
git fetch origin
git merge origin/develop  # コンフリクト解決

# リモートにプッシュ
git push origin feature/[ブランチ名]
```

## 機能別チェック項目

### バックエンド実装時
- [ ] Firebase認証ミドルウェア適用確認
- [ ] MongoDB接続・CRUD操作動作確認
- [ ] エラーハンドリング実装確認
- [ ] API_TEST_COMMANDS.md のコマンドで動作テスト
- [ ] 日本語コメント記述確認

### フロントエンド実装時
- [ ] 認証ガード動作確認
- [ ] レスポンシブデザイン確認
- [ ] エラーメッセージ表示確認
- [ ] ローディング状態表示確認
- [ ] TypeScript型エラー解消確認

### Firebase認証関連
- [ ] Firebase認証トークン検証動作確認
- [ ] 認証エラー時の適切な処理確認
- [ ] ログアウト処理動作確認

## セキュリティチェック
- [ ] 認証必須APIの認証チェック動作確認
- [ ] 他ユーザーのデータアクセス不可確認
- [ ] 機密情報のログ出力無し確認
- [ ] 環境変数の適切な管理確認

## ドキュメント更新
- [ ] CLAUDE.md の現在の実装状況更新
- [ ] API_TEST_COMMANDS.md の新規APIコマンド追加
- [ ] 必要に応じてREADME.md更新

## 完了前最終確認
- [ ] 他の機能に影響を与えていないか確認
- [ ] developブランチにマージ可能な状態か確認
- [ ] プルリクエスト作成準備完了