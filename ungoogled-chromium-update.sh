#!/bin/bash

# Shell script to install the latest version of ungoogled-chromium over the version on the machine if an update is available (using atom feed). User can specify a subgrouping (default is AppImage)

# path for downloading ungoogled-chromium and comparing version numbers (FIXME WIP)
UG_PATH="$HOME/Applications/ungoogled-chromium"

# URL for atom feed
ATOM_URL="https://raw.githubusercontent.com/ungoogled-software/ungoogled-chromium-binaries/master/feed.xml"

PARSED_XML=$(curl -s $ATOM_URL | xml2)

# Get table of available platforms, with versions, and URLs on the following line
PLATFORM_TABLE=$(echo "$PARSED_XML" | grep -E '(/feed/entry/title=)|(/feed/entry/link/@href=)' | sed 's/^.*=//g')

# echo "$PARSED_XML"
echo "$PLATFORM_TABLE"


# Function to check if $1 is higher version than $2
# $1 -> remote version (example: 91.0.4472.164-1.1)
# $2 -> local version (example: 91.0.4472.114-1
# Return value:
# 	0 -> $1 <= $2 (no need to update)
# 	1 -> $1 >  $2 (update available)
compare_version() {
	# Break into arrays
	local IFS='.'
	read -ra V1 <<< "$1"
	read -ra V2 <<< "$2"

	# for val in "${V1[@]}"; do
	# 	echo "$val"
	# done
	# echo ${#V1[@]}
	# for val in "${V2[@]}"; do
	# 	echo "$val"
	# done
	# echo ${#V2[@]}

	# Determine shorter array (for the loop)
	local LENGTH=${#V1[@]}
	if [ ${#V1[@]} -gt ${#V2[@]} ]; then
		local LENGTH=${#V2[@]}
	fi

	echo "$LENGTH"
}

compare_version "91.0.4472.164-1.1" "91.0.4472.114-1"
