# Alice ログイン問題の修正 (2025年8月11日)

## 問題の概要
- Alice でログインできないが Bob でログインできる
- Firebase Emulator と MongoDB の Firebase UID 不一致が原因

## 根本原因
1. **Firebase Emulator**: `test_firebase_uid_001`
2. **MongoDB (古いデータ)**: `42KXtAePGIhXdeClVDJcEf1Qpz63`
3. **フィールド名不一致**: `firebase_uid` (snake_case) vs `firebaseUid` (camelCase)

## 修正内容
1. **db-seed.cjs**: `firebase_uid` → `firebaseUid` に変更
2. **test-firebase-integration.cjs**: Charlie ユーザー追加
3. **MongoDBデータ更新**: Alice の firebaseUid を `test_firebase_uid_001` に修正
4. **check-alice-user.cjs**: UID確認・修正スクリプト作成

## ログイン情報
- **Alice**: alice@yanwari.com / testpassword123
- **Bob**: bob@yanwari.com / testpassword123  
- **Charlie**: charlie@yanwari.com / testpassword123

## 実行コマンド
```bash
# Firebase Emulator ユーザー作成
npm run test:firebase-integration

# Alice の Firebase UID 修正（必要時）
node backend/scripts/check-alice-user.cjs
```