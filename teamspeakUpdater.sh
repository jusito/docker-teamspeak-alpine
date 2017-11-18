#!/bin/bash
set -e

sleep 3s #bash=4.3.48-r1 bzip2=1.0.6-r5 coreutils=8.27-r0 curl=7.56.1-r0 grep=3.0-r0 tar=1.29-r1

website="http://dl.4players.de/ts/releases/"
versions=$(wget -q -O - "$website" | grep -Eo '>3\.[.0-9]+/<' | grep -Eo '[.0-9]+/' | sort -t "." -k 1,1nr -k 2,2nr -k 3,3nr -k 4,4nr)
downloaded=false
server_tar="/tmp/${TS_DIR_NAME}.tar.bz2"
dir_above_serverdir=$(echo "$TS_PATH" | sed 's/\(.*\)\//\1/')
prefered_version="$1"
teamspeak_params=("$@")
startscript_name="ts3server_minimal_runscript.sh"
startscript="${TS_PATH}/${startscript_name}"
#http://dl.4players.de/ts/releases/3.0.13.8/
#busybox wget -O - "http://dl.4players.de/ts/releases/3.0.13.8/" | busybox grep -Eo 'teamspeak3-server_linux_amd64[^"]+\.tar\.bz2' | busybox sort -r | busybox head -n 1

downloadVersion() {
	current="${website}${1}"
	current_file=$(wget -q -O - "$current" | grep -Eo 'teamspeak3-server_linux_amd64[^"]+\.tar\.bz2' | sort -r | head -n 1)
	
	# if a server version is found ...
	if [ "$(echo "$current_file" | busybox wc -m)" != "1" ]; then
		echo "found server version: $current_file"
		# ... download it
		wget -q -O "${server_tar}" "${current}${current_file}"
	fi
}

echo "looking if a version is prefered"
# try at first prefered_version
if [ -n "$prefered_version" ]; then
	echo "searching for given prefered_version"
	downloadVersion "${prefered_version}"
	if [ -e "${server_tar}" ]; then
		downloaded=true
	else
		echo "couldn't find prefered server version, switching to latest"
	fi
fi

#if prefered version not given or failed
if ! $downloaded ;then
	echo "looking for latest version"
	# find latest version and download it
	# not every version has a server version, so we need first to find the latest version
	for version in $versions
	do
		if ! $downloaded ;then
			downloadVersion "${version}"
			if [ -e "${server_tar}" ]; then
				downloaded=true
				downloadedVersion="$version"
			fi
		fi
	done
fi

echo "installing teamspeak version ${downloadedVersion}"
files_backup=("licensekey.dat" "query_ip_blacklist.txt" "query_ip_whitelist.txt" "serverkey.dat" "ts3server.ini" "ts3server.sqlitedb")
if $downloaded ;then
	#remove last logs and 
	cd "${TS_PATH}"
	if [ -e "logs" ]; then
		if [ -e "logs.tar" ]; then
			if [ -e "logs.temp.tar" ]; then
				rm "logs.temp.tar"
			fi
			#tar --remove-files -cf "logs.temp.tar" "logs" "logs.tar"
			tar -cf "logs.temp.tar" "logs" "logs.tar"
			rm -rf "logs"
			rm "logs.tar"
			mv -f "logs.temp.tar" "logs.tar"
		else
			#tar --remove-files -cf "logs.tar" "logs"
			tar -cf "logs.tar" "logs"
			rm -rf "logs"
		fi
	else
		echo "directory logs doesn't exist, skipped log clear"
	fi

	#tar downloaded to install_dir with overwrite
	cd "/tmp/"
	# check if there is an last workdir
	if [ -e "${TS_DIR_NAME}" ] && [ -n "${TS_DIR_NAME}" ]; then
		rm -rf "${TS_DIR_NAME}"
	fi
	
	echo "extracting new version"
	# exctract new version
	tar --overwrite -xf "${server_tar}" #can't replace --overwrite right now
	
	# go into it
	#temp_server_dirname=$(ls -F | grep / | head --lines=1)
	temp_server_dirname=$(ls -F | grep / | head -n 1)
	cd "$temp_server_dirname"
	
	echo "copy needed files from installation to new version"
	#copy own files into
	for file in ${files_backup[@]}
	do
		if [ -e "${TS_PATH}/${file}" ]; then
			cp -fv "${TS_PATH}/${file}" "${file}"
		else
			echo "${file} doesn't exist"
		fi
	done
	
	echo "removing old version of ${startscript}"
	# remove minimal script, maybe its not in it anymore, but if we want to call it
	if [ -e "${startscript}" ]; then
		rm "${startscript}"
	fi
	
	echo "moving new files to installation"
	# move all files to installation #old: /tmp/${temp_server_dirname}
	cp -rf * "${TS_PATH}"
	
	echo "cleanup"
	# clear workdir
	rm -rf "/tmp/${TS_DIR_NAME}"
fi

# start the server
cd "$TS_PATH"
chown -R "$TS_USER" "$TS_PATH"
chmod -R u=rwx,go= "$TS_PATH"
chmod u=rwx,go= "${startscript_name}"

exec "./${startscript_name}" "${teamspeak_params[@]}"
