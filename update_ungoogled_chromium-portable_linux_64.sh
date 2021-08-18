#!/bin/bash

# Shell script to update ungoogled-chromium Portable Linux 64-bit to the latest version
# $1            -> Wrapper symlink location
# $2 (optional) -> Install location

# If first time installing: user must specify a symlink location and an installation directory
# If checking for updates: user must pass a symlink for ungoogled-chromium (this is typically just the command name if a symlink is part of the path)
	# Use the symlink target to determine installation directory

PLATFORM="Portable Linux 64-bit"


# Print help message
print_help() {
	echo "Usage: $0 LINK [LOCATION]"
	echo
	echo "LINK is the path for a symlink pointing to the ungoogled-chromium executable"
	echo "LOCATION is the desired install location for ungoogled-chromium. It does not need to be specified unless installing ungoogled-chromium for the first time"
}

# Function to determine absolute path of helper scripts
# $1 -> script name
get_absolute_path() {
	echo "$(dirname "$(which "$1")")/$1"
}


# Exit if $1 does not exist
if [ -z "$1" ]; then
	echo "Error: too few arguments"
	print_help
	exit 0
fi

# Fetch info, break and store into variables
FULL_INFO=$($(get_absolute_path "fetch_info.sh") "$PLATFORM")

if [ $? -eq 0 ]; then
	echo "Error: Could not get latest version info"
	exit 0
fi

NAME=$(echo "$FULL_INFO" | head -n 1 | cut -d ':' -f 1)
VERSION=$(echo "$FULL_INFO" | head -n 1 | cut -d ':' -f 2 | sed 's/^[ ]*//g' | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")
URL=$(echo "$FULL_INFO" | sed -n "2p")

echo "$NAME"
echo "$VERSION"
echo "$URL"

# Check installed version number (if exists)
if [ -h "$1" ]; then
	MY_VERSION=$($1 --version | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")
	echo "$MY_VERSION"

	# Compare versions to determine if an update is necessary
fi

