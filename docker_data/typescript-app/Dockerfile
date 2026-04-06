# ベースとなるイメージ
FROM node:20-slim

# コンテナ内の作業ディレクトリ
WORKDIR /app

# ソースコードはボリュームで同期するため、最小限の設定
# 開発用ツール（nodemonなど）をインストール
RUN npm install -g typescript ts-node nodemon

# 3000番ポートを公開
EXPOSE 3000

# ソースの変更を監視して自動起動するコマンド
CMD ["nodemon", "--watch", "src/**/*.ts", "--exec", "ts-node", "src/index.ts"]