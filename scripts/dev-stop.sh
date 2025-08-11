#!/bin/bash

# やんわり伝言 開発環境停止スクリプト

set -e

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ポート設定
FRONTEND_PORT=5173
BACKEND_PORT=8080
FIREBASE_EMULATOR_PORT=9099

# ポート開放関数
kill_port() {
    local port=$1
    local service_name=$2
    
    if lsof -ti:$port >/dev/null 2>&1; then
        log_warning "ポート $port ($service_name) を停止中..."
        lsof -ti:$port | xargs kill -9 2>/dev/null || true
        sleep 1
        
        if ! lsof -ti:$port >/dev/null 2>&1; then
            log_success "ポート $port ($service_name) を停止しました"
        else
            log_error "ポート $port ($service_name) の停止に失敗しました"
        fi
    else
        log_info "ポート $port ($service_name) は既に停止しています"
    fi
}

# メイン処理
main() {
    log_info "🛑 やんわり伝言 開発環境を停止中..."
    log_info ""
    
    # Firebase Emulator停止
    log_info "🔥 Firebase Emulator 停止"
    pkill -f "firebase emulators" 2>/dev/null || true
    
    # 各ポート停止
    log_info "📍 ポート停止処理"
    kill_port $FRONTEND_PORT "フロントエンド"
    kill_port $BACKEND_PORT "バックエンド" 
    kill_port $FIREBASE_EMULATOR_PORT "Firebase Emulator"
    
    # Go プロセス停止（念のため）
    pkill -f "go run main.go" 2>/dev/null || true
    
    # Node.js開発サーバー停止（念のため）
    pkill -f "vite" 2>/dev/null || true
    
    log_info ""
    log_success "🎉 すべてのサービスを停止しました"
}

# スクリプト実行
main "$@"