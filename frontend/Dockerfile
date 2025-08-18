# マルチステージビルドでVue.jsアプリケーションを最適化
FROM node:20-alpine AS builder

# 作業ディレクトリを設定
WORKDIR /app

# package.jsonとpackage-lock.jsonをコピー
COPY package*.json ./

# 依存関係をインストール
RUN npm ci --only=production && npm cache clean --force

# ソースコードをコピー
COPY . .

# アプリケーションをビルド
RUN npm run build

# 本番用のNginxイメージ
FROM nginx:alpine

# カスタムNginx設定をコピー
COPY nginx.conf /etc/nginx/nginx.conf

# ビルドしたファイルをNginxの公開ディレクトリにコピー
COPY --from=builder /app/dist /usr/share/nginx/html

# ポートを公開
EXPOSE 80

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Nginxを起動
CMD ["nginx", "-g", "daemon off;"]