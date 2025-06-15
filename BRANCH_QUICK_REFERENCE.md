# ブランチ操作クイックリファレンス

## 作成済みブランチ一覧

### メインブランチ
- `main` - 本番環境用（保護設定）
- `develop` - 開発統合用

### 機能ブランチ
- `feature/auth-system` - F-01: 認証システム（BE Lead担当）
- `feature/message-drafts` - F-02: 下書き・トーン変換（BE+FE協力）
- `feature/schedule-system` - F-03: 送信スケジュール（BE Lead担当）
- `feature/history-management` - F-04: 履歴管理（FE+BE協力）
- `feature/frontend-ui` - UI/UX基盤（FE Lead担当）
- `feature/infrastructure` - インフラ・CI/CD（DevOps担当）

## よく使うGitコマンド

### ブランチ切り替え
```bash
# 機能ブランチに切り替え
git checkout feature/auth-system

# developブランチに切り替え
git checkout develop
```

### 最新の変更を取得
```bash
# リモートの最新情報を取得
git fetch origin

# developブランチの最新を取り込み
git checkout develop
git pull origin develop

# 機能ブランチにdevelopの変更をマージ
git checkout feature/auth-system
git merge develop
```

### 作業の保存・共有
```bash
# 変更をコミット
git add .
git commit -m "feat: 認証API実装"

# リモートにプッシュ
git push origin feature/auth-system
```

### プルリクエスト作成
1. 機能ブランチで作業完了
2. GitHubでPR作成（`feature/xxx` → `develop`）
3. コードレビュー実施
4. マージ実行

## 注意事項

⚠️ **重要**: 直接`main`ブランチにプッシュしないでください
✅ **推奨**: 必ず`develop`経由でマージしてください
🔄 **定期実行**: `develop`の変更を定期的に機能ブランチに取り込んでください

## トラブルシューティング

### コンフリクトが発生した場合
```bash
# developの最新を取得
git checkout develop
git pull origin develop

# 機能ブランチでマージ
git checkout feature/your-feature
git merge develop

# コンフリクト解決後
git add .
git commit -m "resolve: developとのコンフリクト解決"
```

### 間違ったブランチで作業してしまった場合
```bash
# 変更を一時保存
git stash

# 正しいブランチに切り替え
git checkout feature/correct-branch

# 変更を復元
git stash pop
```

## 連絡先

質問や問題がある場合は、チームメンバーに相談してください。

---
作成日: 2025年6月15日