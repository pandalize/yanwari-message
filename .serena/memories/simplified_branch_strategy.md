# 簡素化ブランチ戦略

## 最終的なブランチ構成

### メインブランチ
- **main** - 本番環境（プロダクション）
- **develop** - 統合開発ブランチ（Web・Mobile・API全て）

### 機能開発ブランチ
- **feature/web-[機能名]** - Web版専用機能（Vue.js）
- **feature/mobile-[機能名]** - モバイル版専用機能（Flutter）
- **feature/shared-[機能名]** - 共通機能（バックエンドAPI・DB・認証等）

## 削除された複雑性

### 以前の複雑な構成（削除済み）
- ~~develop-mobile~~ - 削除
- ~~develop-web~~ - 削除

### 現在のシンプル構成
- **develop単一ブランチ** - すべての開発を統合

## 利点

### 開発効率最大化
- 単一コードベースでの開発
- 機能の一貫性確保
- 開発・レビュー効率の最大化
- 複雑性の排除

### 実装の簡素さ
- ブランチ管理の複雑さ排除
- 統合作業の簡素化
- 開発者の認知負荷軽減

## 開発フロー

```bash
# 基本フロー
git checkout develop
git pull origin develop
git checkout -b feature/web-new-feature   # または mobile/shared
# 開発作業
git push origin feature/web-new-feature
# PR作成: feature/* → develop
```

## 現在の状況
CLAUDE.mdに反映済み：
- 複雑な統合計画の記載削除
- シンプルな単一develop構成に更新
- 開発効率重視の構成として確定