# docker-teamspeak-alpine

##Features:
- alpine linux + glibc + ca-certs only
- always newest version on restart
- always SHA256 checked
- last valid version backup/restore [auto]
- tar logs on every restart
- persistent: blacklist, whitelist, ts3server.ini, ts3server.sqlitedb, ...
- docker run arguments are passed directly to ts3server

##WIP:
- backup a valid and verified version only if teamspeak server runs successful
- Simple handling of multiple servers?

##Example 1
Run container with teamspeak auto-update:
```
docker run -dti --name "teamspeak_server" -p 9987:9987/udp -p 30033:30033 -p 10011:10011 \
--volume="teamspeak_server:/home/teamspeak3-server:rw" \
"jusito/docker-teamspeak-alpine:latest"
```

##Example 2
For example, use your given ini with auto-update:
```
docker run -dti --name "teamspeak_server" -p 9987:9987/udp -p 30033:30033 -p 10011:10011 \
--volume="teamspeak_server:/home/teamspeak3-server:rw" \
"jusito/docker-teamspeak-alpine:latest" "inifile=ts3server.ini"
```

##Example 3
Setting serveradmin password & ini:
```
docker run -dti --name "teamspeak_server" -p 9987:9987/udp -p 30033:30033 -p 10011:10011 \
--volume="teamspeak_server:/home/teamspeak3-server:rw" \
"jusito/docker-teamspeak-alpine:latest" "serveradmin_password=123" "inifile=ts3server.ini"
```