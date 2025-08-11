#!/bin/bash

# 安全な環境変数ファイルセットアップスクリプト

ENV_FILE="backend/.env"
EXAMPLE_FILE="backend/.env.example"

echo "🔧 環境変数ファイルセットアップ開始..."

# .env.exampleの存在確認
if [ ! -f "$EXAMPLE_FILE" ]; then
    echo "❌ $EXAMPLE_FILE が見つかりません"
    exit 1
fi

# .envファイルの処理
if [ -f "$ENV_FILE" ]; then
    echo "⚠️  $ENV_FILE が既に存在します"
    echo ""
    echo "📋 現在の設定:"
    echo "  MONGODB_URI: $(grep MONGODB_URI $ENV_FILE | cut -d= -f2 | head -c 50)..."
    echo "  FIREBASE_PROJECT_ID: $(grep FIREBASE_PROJECT_ID $ENV_FILE | cut -d= -f2)"
    echo ""
    
    # バックアップ作成の提案
    while true; do
        read -p "🔄 上書きしますか？(バックアップを作成) [y/N]: " choice
        case $choice in
            [Yy]* )
                BACKUP_FILE="${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
                cp "$ENV_FILE" "$BACKUP_FILE"
                echo "💾 バックアップ作成: $BACKUP_FILE"
                cp "$EXAMPLE_FILE" "$ENV_FILE"
                echo "✅ $ENV_FILE を更新しました（要設定）"
                break
                ;;
            [Nn]* | "" )
                echo "⏭️  $ENV_FILE をそのまま使用します"
                break
                ;;
            * )
                echo "❓ y または n を入力してください"
                ;;
        esac
    done
else
    cp "$EXAMPLE_FILE" "$ENV_FILE"
    echo "✅ $ENV_FILE を作成しました"
fi

echo ""
echo "📝 次のステップ:"
echo "1. $ENV_FILE を編集してください"
echo "2. MONGODB_URI を正しい値に設定してください"
echo "3. 他の必要な環境変数を設定してください"