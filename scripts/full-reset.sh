#!/bin/bash

echo "🔄 完全リセット開始..."

# プロセス停止
echo "🛑 既存プロセスを停止中..."
pkill -f 'firebase emulators' 2>/dev/null || true
pkill -f 'go run' 2>/dev/null || true  
pkill -f 'vite' 2>/dev/null || true
pkill -f 'concurrently' 2>/dev/null || true

sleep 3

# データベースリセット
echo "🗄️ データベース初期化中..."
npm run db:reset

# サンプルデータ投入
echo "📊 サンプルデータ投入中..."
npm run db:seed

echo "✅ リセット完了！"
echo ""
echo "🚀 次のコマンドで開発を開始してください:"
echo "  npm run dev:firebase  # Firebase付きで起動"
echo "  npm run dev:local     # ローカルのみで起動"