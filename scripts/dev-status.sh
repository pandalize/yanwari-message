#!/bin/bash

echo "🔍 開発環境ステータス確認"
echo "=================================="

# ポート使用状況
echo "📡 ポート使用状況:"
PORTS_IN_USE=$(lsof -i:5173,8080,9099 2>/dev/null)
if [ -z "$PORTS_IN_USE" ]; then
    echo "  ❌ 使用中のポートはありません"
else
    echo "$PORTS_IN_USE" | head -1
    echo "$PORTS_IN_USE" | grep -v COMMAND
fi

echo ""

# Firebase Emulator状態
echo "🔥 Firebase Emulator:"
FIREBASE_PROC=$(ps aux | grep firebase | grep -v grep)
if [ -z "$FIREBASE_PROC" ]; then
    echo "  ❌ 起動していません"
else
    echo "  ✅ 起動中"
fi

echo ""

# Go Backend状態  
echo "🟢 Go Backend:"
GO_PROC=$(ps aux | grep 'go run' | grep -v grep)
if [ -z "$GO_PROC" ]; then
    echo "  ❌ 起動していません"
else
    echo "  ✅ 起動中"
fi

echo ""

# Vue Frontend状態
echo "⚡ Vue Frontend:"
VITE_PROC=$(ps aux | grep vite | grep -v grep)
if [ -z "$VITE_PROC" ]; then
    echo "  ❌ 起動していません"  
else
    echo "  ✅ 起動中"
fi

echo ""
echo "🔗 サービスURL:"
echo "  Frontend: http://localhost:5173"
echo "  Backend:  http://localhost:8080"
echo "  Firebase: http://localhost:4000"
echo "  Swagger:  http://localhost:8080/swagger/index.html"