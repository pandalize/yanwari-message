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

# 本番用の軽量イメージ
FROM alpine:latest

# セキュリティとタイムゾーン設定
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/

# ビルドしたバイナリをコピー
COPY --from=builder /app/main .

# 設定ファイルをコピー
COPY --from=builder /app/config ./config

# 環境変数でポートを設定
ENV PORT=8080
ENV GIN_MODE=release

# ポートを公開
EXPOSE 8080

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# アプリケーションを実行
CMD ["./main"]