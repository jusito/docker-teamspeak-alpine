# docker-teamspeak-alpine

Run container with teamspeak auto-update:
```
docker run -dti --name "teamspeak_server" -p 9987:9987/udp -p 30033:30033 -p 10011:10011 \
--volume="teamspeak_server:/home/teamspeak3-server:rw" \
"jusito/docker-teamspeak-alpine:latest"
```

Run container with pinned teamspeak version "3.0.13.8/":
```
docker run -dti --name "teamspeak_server" -p 9987:9987/udp -p 30033:30033 -p 10011:10011 \
--volume="teamspeak_server:/home/teamspeak3-server:rw" \
"jusito/docker-teamspeak-alpine:latest" "3.0.13.8/"
```
See: http://dl.4players.de/ts/releases/

If you have own arguments for the teamspeak server you can add it to run, but keep in mind that the first is always for pinned version.

For example, use your given ini with auto-update:
```
docker run -dti --name "teamspeak_server" -p 9987:9987/udp -p 30033:30033 -p 10011:10011 \
--volume="teamspeak_server:/home/teamspeak3-server:rw" \
"jusito/docker-teamspeak-alpine:latest" "" "inifile=ts3server.ini"
```

Use your own ini with pinned version:
```
docker run -dti --name "teamspeak_server" -p 9987:9987/udp -p 30033:30033 -p 10011:10011 \
--volume="teamspeak_server:/home/teamspeak3-server:rw" \
"jusito/docker-teamspeak-alpine:latest" "3.0.13.8/" "inifile=ts3server.ini"
```