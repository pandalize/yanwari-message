#!/bin/bash

echo "🔍 MongoDB メッセージコレクション調査スクリプト"
echo "================================================"

# 現在のディレクトリを確認
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📁 作業ディレクトリ: $BACKEND_DIR"

# .envファイルを読み込み
if [ -f "$BACKEND_DIR/.env" ]; then
    echo "🔧 環境変数を読み込み中..."
    set -a
    source "$BACKEND_DIR/.env"
    set +a
    echo "✅ 環境変数読み込み完了"
else
    echo "❌ エラー: .envファイルが見つかりません ($BACKEND_DIR/.env)"
    exit 1
fi

# MONGODB_URIが設定されているか確認
if [ -z "$MONGODB_URI" ]; then
    echo "❌ エラー: MONGODB_URI環境変数が設定されていません"
    exit 1
fi

echo "🔗 MongoDB URI: ${MONGODB_URI:0:30}..."

# Go 調査スクリプトを実行
echo "🚀 調査開始..."
echo ""

cd "$SCRIPT_DIR"
go run message_investigation.go

echo ""
echo "✅ 調査完了"