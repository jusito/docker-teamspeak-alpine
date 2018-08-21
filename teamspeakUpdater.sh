#!/bin/sh
set -e

dir_above_serverdir=$(echo "$TS_PATH" | sed 's/\(.*\)\//\1/')
lastWorkingArchive="/tmp/lastWorking.tar.bz2"
#workfile
server_tar="/tmp/${TS_DIR_NAME}.tar.bz2"
#start script
startscript_name="ts3server_minimal_runscript.sh"
startscript="${TS_PATH}/${startscript_name}"

#1 param = target file
#downloads the newest teamspeak server to given target file
#if the file exists after executing this, the file has a valid checksum
#sh + busybox compatible
downloadAndCheckNewest() {
	#store target file name
	targetTar=$1
	#get substring containing checksum and link to newest file
	current=$(wget -q -O - "https://www.teamspeak.com/en/downloads" | tr '\n' ' ' | grep -Eo 'SHA256:\s*[^<]+<[^>]+>[^<]*<[^>]+>[^<]*<[^>]+>[^"]+"[^"]+"[^"]+"[^"]+teamspeak3-server_linux_amd64[^"]+"')
	#extract current link
	currentLink=$(echo "$current" | grep -Eo 'http[^"]+')
	#extract current checksum
	currentSha=$(echo "$current" |  grep -Eo 'SHA256: ([^<]+)' | grep -Eo '[a-f0-9]{64}')
	
	#download server files
	wget -q -O "${targetTar}" "$currentLink"
	#calculate sha of download
	fileSha=$(sha256sum "${targetTar}" | grep -Eo '^\S+')
	
	#if not file exists
	if [ ! -e "${targetTar}" ]; then
		echo '[error] could not find server file localy'

	#if checksum is incorrect
	elif [ "$fileSha" != "$currentSha" ]; then
		echo '[error] SHA256 invalid of downloaded file'
		rm -f "${targetTar}"
		
	#if file is valid
	else
		echo 'downloaded newest file'
	fi
}

#param 1 = parent dir of teamspeak logs
#backup current log dir inclusive old backups
#deletes logs after this
backupLogs() {
	
	cd "$1"
	
	#if logs existing => backup
	if [ -e "logs" ]; then
		#if an logs archive already exists => include it in backup
		if [ -e "logs.tar" ]; then
			#if an temporary logs archive exists => remove it
			if [ -e "logs.temp.tar" ]; then
				rm "logs.temp.tar"
			fi
			
			#create backup
			tar -cf "logs.temp.tar" "logs" "logs.tar"
			
			#remove files we have a backup of
			rm -rf "logs"
			rm "logs.tar"
			mv -f "logs.temp.tar" "logs.tar"
			
		#if no logs archive already exists => just backup logs
		else
			#create backup
			tar -cf "logs.tar" "logs"
			
			#remove files we have a backup of
			rm -rf "logs"
		fi
	else
		echo "directory logs doesn't exist, skipped log clear"
	fi	
}

#removes and creates "/tmp/${TS_DIR_NAME}"
initTempdir() {
	# check if there is an last workdir => if so remove it
	cd "/tmp/"
	if [ -e "${TS_DIR_NAME}" ]; then
		rm -rf "${TS_DIR_NAME}"
	fi
	mkdir "/tmp/${TS_DIR_NAME}"	
}

#oaram 1 = filename in teamspeak dir
#copies given file to current dir (forced)
copyFileToMe() {
	file="$1"
	if [ -e "${TS_PATH}/${file}" ]; then
		cp -fv "${TS_PATH}/${file}" "${file}"
	else
		echo "${file} doesn't exist"
	fi
}

#if param1 = 0
#archives the current server tar
#WIP
#archiveServerFiles() {
#	exitCode=$1
#	
#	#check exit code if 0 => archive server files because looks like its working
#	if [ "$exitCode" == "0" ]; then
#		echo "exit code valid => I archiv current server files"
#		cp -vf "$server_tar" "$lastWorkingArchive"
#	else
#		echo "exit code invalid => I dont archiv current server files"
#	fi
#	rm "$server_tar"
#}

echo "looking for latest version"
# find latest version and download it
downloadAndCheckNewest "${server_tar}"

echo "installing Teamspeak server"

#checking if last working server files are needed
if [ ! -e "$server_tar" ] && [ -e "$lastWorkingArchive" ]; then
	echo 'because no new valid version could be found, using old one'
	cp -vf "$lastWorkingArchive" "$server_tar"
fi

#if server file exists (and is valid)
if [ -e "${server_tar}" ]; then
	#init "/tmp/${TS_DIR_NAME}"
	initTempdir
	
	#archive current valid version
	cp -vf "$server_tar" "$lastWorkingArchive"
	
	#=> backup teamspeak logs
	backupLogs "${TS_PATH}"

	# extract new version into temp dir
	echo "extracting new version"
	cd "/tmp/${TS_DIR_NAME}"
	tar -xvf "${server_tar}" #can't replace --overwrite right now
	
	#cd into created dir
	temp_server_dirname=$(ls -F | grep / | head -n 1)
	cd "$temp_server_dirname"
	
	#copy persistent files to new version (only files which are part of default server files)
	echo "copy needed files from installation to new version"
	copyFileToMe "licensekey.dat"
	copyFileToMe "query_ip_blacklist.txt"
	copyFileToMe "query_ip_whitelist.txt"
	copyFileToMe "serverkey.dat"
	copyFileToMe "ts3server.ini"
	copyFileToMe "ts3server.sqlitedb"
	
	# move all files to installation #old: /tmp/${temp_server_dirname}
	echo "moving new files to installation"
	cp -rf * "${TS_PATH}"
	
	# clear workdir
	echo "cleanup"
	rm -rf "/tmp/${TS_DIR_NAME}"
	rm "$server_tar"
	
	#=> start the server
	cd "$TS_PATH"
	chown -R "$TS_USER" "$TS_PATH"
	chmod -R u=rwx,go= "$TS_PATH"
	chmod u=rwx,go= "${startscript_name}"
	
	#register SIGTERM trap => exit teamspeak server securely
	trap 'pkill -15 ts3server' SIGTERM
	
	#start teamspeak server and wait until its closed
	"./$startscript_name" "$@" &
	wait "$!"
	
	#todo if exit code of ts = 0 => archive server files (because working) else not
fi