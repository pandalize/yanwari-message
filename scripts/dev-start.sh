#!/bin/bash

# やんわり伝言 開発環境起動スクリプト
# ポート管理・Firebase Emulator統合・環境変数設定を含む

set -e  # エラー時に停止

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

# ポート使用状況確認関数
check_port() {
    local port=$1
    local service_name=$2
    
    if lsof -ti:$port >/dev/null 2>&1; then
        log_warning "ポート $port ($service_name) が使用中です"
        return 1
    else
        log_info "ポート $port ($service_name) は使用可能です"
        return 0
    fi
}

# ポート開放関数
kill_port() {
    local port=$1
    local service_name=$2
    
    log_warning "ポート $port ($service_name) を開放中..."
    lsof -ti:$port | xargs kill -9 2>/dev/null || true
    sleep 1
    
    if ! lsof -ti:$port >/dev/null 2>&1; then
        log_success "ポート $port ($service_name) を開放しました"
    else
        log_error "ポート $port ($service_name) の開放に失敗しました"
        return 1
    fi
}

# Firebase Emulator状況確認
check_firebase_emulator() {
    if ps aux | grep -v grep | grep "firebase emulators" >/dev/null 2>&1; then
        log_info "Firebase Emulator は既に起動中です"
        return 0
    else
        log_info "Firebase Emulator は起動していません"
        return 1
    fi
}

# Firebase Emulator停止
stop_firebase_emulator() {
    log_warning "Firebase Emulator を停止中..."
    pkill -f "firebase emulators" 2>/dev/null || true
    sleep 2
    log_success "Firebase Emulator を停止しました"
}

# メイン処理
main() {
    log_info "🔥 やんわり伝言 開発環境を起動中..."
    log_info ""
    
    # 1. ポート状況確認と開放
    log_info "📍 Step 1: ポート状況確認"
    
    # フロントエンドポートチェック
    if ! check_port $FRONTEND_PORT "フロントエンド"; then
        kill_port $FRONTEND_PORT "フロントエンド"
    fi
    
    # バックエンドポートチェック
    if ! check_port $BACKEND_PORT "バックエンド"; then
        kill_port $BACKEND_PORT "バックエンド"
    fi
    
    # Firebase Emulatorポートチェック
    if ! check_port $FIREBASE_EMULATOR_PORT "Firebase Emulator"; then
        kill_port $FIREBASE_EMULATOR_PORT "Firebase Emulator"
    fi
    
    log_info ""
    
    # 2. Firebase Emulator確認・停止
    log_info "🔥 Step 2: Firebase Emulator 管理"
    
    if check_firebase_emulator; then
        stop_firebase_emulator
    fi
    
    log_info ""
    
    # 3. 環境変数確認
    log_info "⚙️  Step 3: 環境変数確認"
    
    if [ ! -f "backend/.env" ]; then
        log_warning "backend/.env が見つかりません。.env.example からコピーします"
        cp backend/.env.example backend/.env 2>/dev/null || log_error "backend/.env.example が見つかりません"
    else
        log_success "backend/.env が存在します"
    fi
    
    log_info ""
    
    # 4. 依存関係チェック
    log_info "📦 Step 4: 依存関係確認"
    
    # Node.js / npm チェック
    if ! command -v node >/dev/null 2>&1; then
        log_error "Node.js がインストールされていません"
        exit 1
    fi
    
    if ! command -v npm >/dev/null 2>&1; then
        log_error "npm がインストールされていません"
        exit 1
    fi
    
    # Go チェック
    if ! command -v go >/dev/null 2>&1; then
        log_error "Go がインストールされていません"
        exit 1
    fi
    
    # Firebase CLI チェック
    if ! command -v firebase >/dev/null 2>&1; then
        log_error "Firebase CLI がインストールされていません"
        log_info "インストール: npm install -g firebase-tools"
        exit 1
    fi
    
    log_success "すべての依存関係が確認できました"
    log_info ""
    
    # 5. concurrently パッケージ確認
    log_info "🔧 Step 5: 必要パッケージ確認"
    
    if [ ! -d "node_modules" ] || [ ! -d "node_modules/concurrently" ]; then
        log_warning "concurrently がインストールされていません。インストール中..."
        npm install
    fi
    
    log_success "パッケージ確認完了"
    log_info ""
    
    # 6. 開発サーバー起動
    log_info "🚀 Step 6: 開発サーバー起動"
    log_info ""
    log_success "以下のサービスを起動します:"
    log_info "  - Firebase Emulator: http://localhost:$FIREBASE_EMULATOR_PORT"
    log_info "  - バックエンド: http://localhost:$BACKEND_PORT" 
    log_info "  - フロントエンド: http://localhost:$FRONTEND_PORT"
    log_info ""
    log_warning "停止するには Ctrl+C を押してください"
    log_info ""
    
    # 環境変数をエクスポート
    export PORT=$BACKEND_PORT
    export FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:$FIREBASE_EMULATOR_PORT
    
    # 起動コマンド実行
    npx concurrently \
        --prefix-colors "blue,green,yellow" \
        --names "🔥FIREBASE,⚙️ BACKEND,🌐FRONTEND" \
        "firebase emulators:start --only auth" \
        "cd backend && FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:$FIREBASE_EMULATOR_PORT PORT=$BACKEND_PORT go run main.go" \
        "cd frontend && npm run dev -- --port=$FRONTEND_PORT --host=localhost"
}

# スクリプト実行
main "$@"