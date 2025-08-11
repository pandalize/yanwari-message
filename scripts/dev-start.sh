#!/bin/bash

# やんわり伝言 開発環境起動スクリプト
# シンプル化版 - 新コマンド体系に対応

set -e

# カラー出力
RED='[0;31m'
GREEN='[0;32m'
YELLOW='[1;33m'
BLUE='[0;34m'
NC='[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 起動モード選択
show_menu() {
    echo -e "${BLUE}🔥 やんわり伝言 開発環境${NC}"
    echo "=================================="
    echo ""
    echo "起動モードを選択してください:"
    echo ""
    echo "  ${GREEN}1)${NC} Firebase付きで起動 (推奨)"
    echo "     - Firebase認証エミュレーター込み"
    echo "     - フル機能テスト可能"
    echo ""
    echo "  ${YELLOW}2)${NC} ローカルのみで起動"
    echo "     - Firebase認証なし"
    echo "     - APIテストのみ"
    echo ""
    echo "  ${BLUE}3)${NC} 環境リセット後に起動"
    echo "     - DB初期化 + サンプルデータ"
    echo "     - Firebase付きで起動"
    echo ""
    echo "  ${RED}0)${NC} キャンセル"
    echo ""
}

main() {
    # 依存関係チェック
    if ! command -v node >/dev/null 2>&1; then
        log_error "Node.js がインストールされていません"
        exit 1
    fi
    
    if ! command -v go >/dev/null 2>&1; then
        log_error "Go がインストールされていません"  
        exit 1
    fi
    
    # 引数で起動モードが指定されている場合
    if [ "$1" = "firebase" ] || [ "$1" = "1" ]; then
        npm run dev:firebase
        exit 0
    elif [ "$1" = "local" ] || [ "$1" = "2" ]; then
        npm run dev:local
        exit 0
    elif [ "$1" = "reset" ] || [ "$1" = "3" ]; then
        npm run reset && npm run dev:firebase
        exit 0
    fi
    
    # インタラクティブモード
    show_menu
    
    while true; do
        read -p "選択してください [1-3, 0]: " choice
        
        case $choice in
            1)
                log_info "Firebase付き開発環境を起動中..."
                npm run dev:firebase
                break
                ;;
            2)
                log_info "ローカル開発環境を起動中..."
                npm run dev:local
                break
                ;;
            3)
                log_info "環境リセット後にFirebase付き開発環境を起動中..."
                npm run reset && npm run dev:firebase
                break
                ;;
            0)
                log_info "キャンセルしました"
                exit 0
                ;;
            *)
                log_warning "無効な選択です。1-3または0を入力してください。"
                ;;
        esac
    done
}

main "$@"