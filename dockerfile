FROM frolvlad/alpine-glibc:alpine-3.6

EXPOSE 9987/udp 10011 30033

ENV TS_DIR_NAME="teamspeak3-server"
ENV TS_PATH="/home/${TS_DIR_NAME}" \
	TS_GROUP_ID=10002 \
	TS_USER_ID=10002 \
	TS_USER=teamspeak \
	LD_LIBRARY_PATH=".:$LD_LIBRARY_PATH"

COPY ["teamspeakUpdater.sh", "/home/teamspeakUpdater.sh" ]
	
RUN apk add --no-cache bash=4.3.48-r1 bzip2=1.0.6-r5 coreutils=8.27-r0 curl=7.55.0-r0 grep=3.0-r0 tar=1.29-r1 && \
	addgroup -g "${TS_GROUP_ID}" "${TS_USER}" && \
	adduser -h "${TS_PATH}" -g "" -s "/bin/false" -G "${TS_USER}" -D -u "${TS_USER_ID}" "${TS_USER}" && \
	chown "$TS_USER" "/home/teamspeakUpdater.sh" && \
	chmod -R =500 "/home/teamspeakUpdater.sh" && \
	chown "$TS_USER" "$TS_PATH" && \
	chmod -R =700 "$TS_PATH" && \
	apk del --quiet --no-cache --progress --purge && \
	rm -rf /var/cache/apk/*

VOLUME "$TS_PATH"
	
USER "$TS_USER_ID:$TS_GROUP_ID"
	
ENTRYPOINT "./home/teamspeakUpdater.sh"