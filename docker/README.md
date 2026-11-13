# OpenEDA Docker for RISC-V Day Tokyo 2026 Autumn

Ubuntu 24.04ベースのDockerイメージです。
KLayout / xschem / ngspice / Magic / Netgen + gf180mcuD PDK が入っています。

## ビルド

```bash
cd docker
docker build -t openeda-risc-v-day .
```

amd64向け
```bash
docker build --platform linux/amd64 -t openeda-risc-v-day:amd64 .
```

## 起動

```bash
docker run -d --name openeda -p 5901:5901 \
  -v "$(pwd)/work:/home/ishi-kai/work" \
  openeda-risc-v-day
```

amd64 イメージのとき:

```bash
docker run -d --platform linux/amd64 --name openeda -p 5901:5901 \
  -v "$(pwd)/work:/home/ishi-kai/work" \
  openeda-risc-v-day:amd64
```

## Mac の画面共有から接続

コンテナの VNC はディスプレイ `:1`、ポート 5901 です。画面共有（Screen Sharing.app）はポートを省略すると 5900 に繋ぐので、番号まで指定します。

1. 「画面共有」を開く
2. 接続先は `localhost:5901`
3. パスワードは `ishi-kai`

ターミナルから開く場合:

```bash
open vnc://localhost:5901
```

5901 が使用中のときは、`docker run` の `-p` の左側だけ変えます。`-p 5902:5901` なら、接続先は `localhost:5902` です。
