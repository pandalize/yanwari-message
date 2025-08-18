# マルチステージビルドでGoアプリケーションを最適化
FROM golang:1.23-alpine AS builder

# 必要なパッケージをインストール
RUN apk add --no-cache git ca-certificates tzdata

# 作業ディレクトリを設定
WORKDIR /app

# go.modとgo.sumをコピーして依存関係をダウンロード
COPY go.mod go.sum ./
RUN go mod download

# ソースコードをコピー
COPY . .

# アプリケーションをビルド（静的バイナリ）
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# 開発環境用にGoも含めたイメージ
FROM golang:1.23-alpine

# 必要なパッケージをインストール（開発環境用）
RUN apk add --no-cache git ca-certificates tzdata wget

# 作業ディレクトリを設定
WORKDIR /app

# go.modとgo.sumをコピーして依存関係をダウンロード
COPY go.mod go.sum ./
RUN go mod download

# ソースコードをコピー
COPY . .

# 開発環境用にビルド（デバッグ情報付き）
RUN go build -o main .

# 環境変数はdocker-compose.ymlで設定

# ポートを公開
EXPOSE 8080

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# 開発環境用：ホットリロードでアプリケーションを実行
CMD ["go", "run", "."]