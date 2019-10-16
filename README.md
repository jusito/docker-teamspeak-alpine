# docker-teamspeak-alpine
Important: [Build Status](Failed), dependency is missing
[![](https://images.microbadger.com/badges/image/jusito/docker-teamspeak-alpine.svg)](https://microbadger.com/images/jusito/docker-teamspeak-alpine "Get your own image badge on microbadger.com")

## Features:
- base image(130+ stars) + this automatic build
- alpine linux + glibc + ca-certs + ts3server = lowest size possible
- always newest version on restart
- always SHA256 checked
- if download on restart fails => last valid version is used
- tar logs on every restart (inclusive last logs.tar) and clears Logs/*
- persistent: blacklist, whitelist, ts3server.ini, ts3server.sqlitedb, ...
- docker run arguments are passed directly to ts3server

## Example 1 - Simple setup, persistent data
Run container with teamspeak auto-update:
```
docker run -dti --name "teamspeak_server" -p 9987:9987/udp -p 30033:30033 -p 10011:10011 \
--volume="teamspeak_server:/home/teamspeak3-server:rw" \
"jusito/docker-teamspeak-alpine:latest"
```

## Example 2 - Use your config file
Create docker volume and copy your ini in, in this example its ts3server.ini.
Use your given ini with auto-update:
```
docker run -dti --name "teamspeak_server" -p 9987:9987/udp -p 30033:30033 -p 10011:10011 \
--volume="teamspeak_server:/home/teamspeak3-server:rw" \
"jusito/docker-teamspeak-alpine:latest" "inifile=ts3server.ini"
```

## Example 3 - Set serveradmin password & use your ini
Create docker volume and copy your ini in, in this example its ts3server.ini.
Setting serveradmin password & ini:
```
docker run -dti --name "teamspeak_server" -p 9987:9987/udp -p 30033:30033 -p 10011:10011 \
--volume="teamspeak_server:/home/teamspeak3-server:rw" \
"jusito/docker-teamspeak-alpine:latest" "serveradmin_password=123" "inifile=ts3server.ini"
```

## Hints
- On ubuntu docker volumes are default at: /var/lib/docker/volumes/*NAME*/
- if you want to use your files, create the volume and copy elements in, owner should be 10002:10002 and rw
- for multiple virtual servers you just need to expose one port more f.e. 9987/udp & 9988/udp
- Ports: http://www.teamspeak.de/faq/index.php?solution_id=1032

## Teamspeak 3 server parameters
- the parameters are listed with default value
- default_voice_port=9987, for first virtual server, second using this + 1, aso.
- voice_ip=0.0.0.0, default listen port = listen on every ip
- create_default_virtualserver=1, create virtual server if no valid instance exists (instances > 32 port and no valid license are invalid)
- machine_id=
- filetransfer_port=30033
- filetransfer_ip=0.0.0.0
- query_port=10011
- query_ip=0.0.0.0
- clear_database=0, 1 means the database is cleared on every restart
- logpath=logs/, dont change it please
- logpath=ts3db_sqlite3
- dbpluginparameter=
- dbsqlpath=sql/
- dbsqlcreatepath=create_sqlite/
- licensepath=, empty means installation dir = root of volume
- createinifile=0, on 1 creates an ini file with given configuration
- inifile=, ini used for server
- query_ip_whitelist=query_ip_whitelist.txt

## ToDo
- add health check -> calculate & check hash