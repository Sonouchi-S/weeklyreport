# ベースとなるイメージ
FROM python:3.11-slim

# GUIおよびMariaDB接続に必要なシステムライブラリをインストール
RUN apt-get update && apt-get install -y \
    python3-tk \
    libx11-6 \
    gcc \
    libmariadb-dev \
    && rm -rf /var/lib/apt/lists/*

# コンテナ内の作業ディレクトリ
WORKDIR /app

# 必要なライブラリのインストール
RUN pip install mariadb mysql-connector-python

# 実行コマンド
CMD ["python", "src/main.py"]