# 起動

```
docker run -d --name openeda -p 5901:5901 -v $(pwd)/work:/home/ishi-kai/work openeda-risc-v-day
```

起動に成功すると Screen Sharing.app から localhost:5901 に接続できる

ログ確認
```
docker exec -it openeda cat /home/ishi-kai/.vnc/e0125b71ec59:1.log
```
