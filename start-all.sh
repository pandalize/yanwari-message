#!/bin/bash

# やんわり伝言 - 全環境起動スクリプト
# このスクリプトは、バックエンド、フロントエンド、モバイルアプリを一括で起動します

# 色付き出力用の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# プロジェクトルートディレクトリ
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Flutter パスの設定
export PATH="$PATH:/Users/fujinoyuki/development/flutter/bin"

echo -e "${BLUE}🚀 やんわり伝言 - 全環境起動開始${NC}"
echo "=================================="

# 1. バックエンドサーバーの起動
echo -e "\n${GREEN}1. バックエンドサーバー起動中...${NC}"
cd "$PROJECT_ROOT/backend"

# 既存のバックエンドプロセスを確認
if lsof -i :8080 > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  ポート8080は既に使用中です${NC}"
    echo "既存のバックエンドサーバーを使用します"
else
    # 新しいターミナルでバックエンドを起動
    osascript -e "tell app \"Terminal\" to do script \"cd '$PROJECT_ROOT/backend' && go run main.go\""
    echo "バックエンドサーバーを新しいターミナルで起動しました"
    echo "起動待機中..."
    sleep 5
fi

# バックエンドの起動確認
echo -n "バックエンドサーバーの起動を確認中"
for i in {1..10}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo -e "\n${GREEN}✅ バックエンドサーバー起動完了 (http://localhost:8080)${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# 2. フロントエンドサーバーの起動
echo -e "\n${GREEN}2. フロントエンドサーバー起動中...${NC}"
cd "$PROJECT_ROOT/frontend"

# 既存のフロントエンドプロセスを確認
if lsof -i :5173 > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  ポート5173は既に使用中です${NC}"
    echo "既存のフロントエンドサーバーを使用します"
else
    # 新しいターミナルでフロントエンドを起動
    osascript -e "tell app \"Terminal\" to do script \"cd '$PROJECT_ROOT/frontend' && npm run dev\""
    echo "フロントエンドサーバーを新しいターミナルで起動しました"
    echo "起動待機中..."
    sleep 5
fi

# 3. iOSシミュレーターの起動
echo -e "\n${GREEN}3. iOSシミュレーター起動中...${NC}"

# 利用可能なiPhoneシミュレーターを探す
SIMULATOR_ID=$(xcrun simctl list devices | grep -E "iPhone 1[4-6]" | grep -v "unavailable" | head -1 | grep -oE "[A-F0-9-]{36}")

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${RED}❌ iPhoneシミュレーターが見つかりません${NC}"
else
    # シミュレーターの状態を確認
    SIMULATOR_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -oE "\(.*\)" | tr -d "()")
    
    if [ "$SIMULATOR_STATE" = "Booted" ]; then
        echo -e "${YELLOW}⚠️  シミュレーターは既に起動しています${NC}"
    else
        xcrun simctl boot "$SIMULATOR_ID"
        echo "シミュレーターを起動しました"
        # Simulator.appを開く
        open -a Simulator
        sleep 3
    fi
    
    echo -e "${GREEN}✅ iOSシミュレーター起動完了${NC}"
fi

# 4. Flutterアプリの起動
echo -e "\n${GREEN}4. Flutterモバイルアプリ起動中...${NC}"
cd "$PROJECT_ROOT/mobile"

# 依存関係の確認
if [ ! -d "ios/Pods" ]; then
    echo "依存関係をインストール中..."
    flutter pub get
fi

# Flutterアプリを起動
if [ -n "$SIMULATOR_ID" ]; then
    # 新しいターミナルでFlutterを起動
    osascript -e "tell app \"Terminal\" to do script \"cd '$PROJECT_ROOT/mobile' && export PATH='\$PATH:/Users/fujinoyuki/development/flutter/bin' && flutter run -d $SIMULATOR_ID\""
    echo "Flutterアプリを新しいターミナルで起動しました"
else
    echo -e "${YELLOW}⚠️  シミュレーターが利用できないため、Webブラウザで起動します${NC}"
    osascript -e "tell app \"Terminal\" to do script \"cd '$PROJECT_ROOT/mobile' && export PATH='\$PATH:/Users/fujinoyuki/development/flutter/bin' && flutter run -d chrome --web-port 3000\""
fi

# 5. 起動完了サマリー
echo -e "\n${BLUE}=================================="
echo -e "🎉 やんわり伝言 - 全環境起動完了！"
echo -e "==================================${NC}"
echo
echo -e "${GREEN}アクセス可能なURL:${NC}"
echo -e "  📡 バックエンドAPI: ${BLUE}http://localhost:8080${NC}"
echo -e "  🖥️  フロントエンド: ${BLUE}http://localhost:5173${NC}"
echo -e "  📱 モバイル(Web版): ${BLUE}http://localhost:3000${NC}"
echo
echo -e "${YELLOW}ヒント:${NC}"
echo -e "  • 各ターミナルウィンドウでログを確認できます"
echo -e "  • Ctrl+C で各サービスを停止できます"
echo -e "  • Flutter Hot Reload: 'r' キーを押す"
echo
echo -e "${GREEN}Happy Coding! 🚀${NC}"

# ヘルスチェックURL
echo -e "\n${BLUE}動作確認用コマンド:${NC}"
echo "  curl http://localhost:8080/health  # バックエンドヘルスチェック"
echo "  open http://localhost:5173         # フロントエンドを開く"