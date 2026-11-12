# 起動

```
docker run -d --name openeda -p 5901:5901 -v $(pwd)/work:/home/ishi-kai/work openeda-risc-v-day
docker run -d --name openeda-amd64 -p 5902:5901 -v $(pwd)/work:/home/ishi-kai/work openeda-risc-v-day
```

起動に成功すると Screen Sharing.app から localhost:5901 に接続できる

シェルからログインも可能
```
docker exec -it openeda bash
```
