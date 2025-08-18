# マルチステージビルドでVue.jsアプリケーションを最適化
FROM node:20-alpine AS builder

# 作業ディレクトリを設定
WORKDIR /app

# package.jsonとpackage-lock.jsonをコピー
COPY package*.json ./

# 依存関係をインストール（ビルド時はdevDependenciesも必要）
RUN npm ci && npm cache clean --force

# ソースコードをコピー
COPY . .

# アプリケーションをビルド（型チェックをスキップ）
RUN npm run build-only

# 本番用のNginxイメージ
FROM nginx:alpine

# ビルドしたファイルをNginxの公開ディレクトリにコピー
COPY --from=builder /app/dist /usr/share/nginx/html

# カスタムNginx設定をコピー（ローカルからコピー）
COPY nginx.conf /etc/nginx/nginx.conf

# ポートを公開
EXPOSE 80

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Nginxを起動
CMD ["nginx", "-g", "daemon off;"]