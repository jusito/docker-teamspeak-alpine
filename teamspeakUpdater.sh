#!/bin/bash
set -e

website="http://dl.4players.de/ts/releases/"
versions=$(curl -s "$website" | grep -Po "(?<=>)(\d+(?:\.\d+)+/)(?=<)" | sort -t "." -k 1,1nr -k 2,2nr -k 3,3nr -k 4,4nr)
downloaded=false
server_tar="/tmp/${TS_DIR_NAME}.tar.bz2"
dir_above_serverdir=$(echo "$TS_PATH" | grep -Po "^(.+)(?=/)")
prefered_version="$1"
startscript_name="ts3server_minimal_runscript.sh"
startscript="${TS_PATH}/${startscript_name}"

downloadVersion() {
	current="${website}${1}"
	current_file=$(curl -s "$current" | grep -Po "(?i)(?<=\")teamspeak3-server_linux_amd64[^\"]+?\.tar\.bz2" | sort -r | head --lines=1 -)
	
	# if a server version is found ...
	if [ "$(echo "$current_file" | wc -m)" != "1" ]; then
		echo "found server version: $current_file"
		# ... download it
		curl -s -o "${server_tar}" "${current}${current_file}"
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
			fi
		fi
	done
fi

echo "installing teamspeak version ${version}"
files_backup=("licensekey.dat" "query_ip_blacklist.txt" "query_ip_whitelist.txt" "serverkey.dat" "ts3server.ini" "ts3server.sqlitedb")
if $downloaded ;then
	#remove last logs and 
	cd "${TS_PATH}"
	if [ -e "logs" ]; then
		if [ -e "logs.tar" ]; then
			if [ -e "logs.temp.tar" ]; then
				rm "logs.temp.tar"
			fi
			tar --remove-files -cf "logs.temp.tar" "logs" "logs.tar"
			mv -f "logs.temp.tar" "logs.tar"
		else
			tar --remove-files -cf "logs.tar" "logs"
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
	tar --overwrite -xf "${server_tar}"
	
	# go into it
	temp_server_dirname=`ls -F | grep / | head --lines=1`
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
chmod -R =700 "$TS_PATH"

teamspeak_params=("$@")
unset 'teamspeak_params[0]'

exec "./${startscript_name}" "$teamspeak_params"
