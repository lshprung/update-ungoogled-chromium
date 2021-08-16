#!/bin/bash

# Shell script to install the latest version of ungoogled-chromium over the version on the machine if an update is available (using atom feed). User can specify a subgrouping (default is AppImage)

# path for downloading ungoogled-chromium and comparing version numbers (FIXME WIP)
# TODO write function to search through user's path for ungoogled-chromium
UG_PATH="$HOME/Applications/appimage/ungoogled-chromium_87.0.4280.141-1.1_linux.AppImage"

# Set default platform to look for new version from
DEFAULT_PLATFORM="AppImage"

# URL for atom feed
ATOM_URL="https://raw.githubusercontent.com/ungoogled-software/ungoogled-chromium-binaries/master/feed.xml"

PARSED_XML=$(curl -s $ATOM_URL | xml2)

# Get table of available platforms, with versions, and URLs on the following line
PLATFORM_TABLE=$(echo "$PARSED_XML" | grep -E '(/feed/entry/title=)|(/feed/entry/link/@href=)' | sed 's/^.*=//g')

# echo "$PARSED_XML"
echo "$PLATFORM_TABLE"


# Function to print a message that the currently installed ungoogled-chromium is up to date
nothing_to_do() {
	echo "$UG_PATH is up to date"
}

# Function to check if $1 is higher version than $2
# $1 -> remote version (example: 91.0.4472.164)
# $2 -> local version (example: 91.0.4472.114)
# Return value:
# 	0 -> $1 <= $2 (no need to update)
# 	1 -> $1 >  $2 (update available)
compare_version() {
	echo "$1"
	echo "$2"

	# Break into arrays
	local IFS='.'
	read -ra V1 <<< "$1"
	read -ra V2 <<< "$2"

	for val in "${V1[@]}"; do
		echo "$val"
	done
	echo ${#V1[@]}
	for val in "${V2[@]}"; do
		echo "$val"
	done
	echo ${#V2[@]}

	# Determine shorter array (for the loop)
	local LENGTH=${#V1[@]}

	for (( i = 0 ; i < LENGTH ; i++ )); do
		if [ "${V1[$i]}" -gt "${V2[$i]}" ]; then
			return 1
		elif [ "${V1[$i]}" -lt "${V2[$i]}" ]; then
			return 0
		fi
	done

	return 0
}


# DEBUG
#compare_version "91.0.4472.164" "91.0.4472.114"

# Determine local version if ungoogled-chromium is installed
if [ -x "$UG_PATH" ]; then
	VERSION=$($UG_PATH --version | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")
	echo "$VERSION"
fi

# If ungoogled-chromium is installed on the machine, check if there is a newer version
LATEST=$(echo "$PLATFORM_TABLE" | grep "$DEFAULT_PLATFORM")
# TODO handle ambiguous DEFAULT_PLATFORM
# TODO handle if unknown DEFAULT_PLATFORM

if [ -n "$VERSION" ]; then

	compare_version "$(echo "$LATEST" | head -n 1 | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")" "$VERSION" 
	if [ $? -eq 0 ]; then
		nothing_to_do
		exit
	else
		echo "Gotta update!"
	fi
fi
