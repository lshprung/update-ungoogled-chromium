#!/bin/bash

# Shell script to update ungoogled-chromium Portable Linux 64-bit to the latest version
# $1            -> Wrapper symlink location
# $2 (optional) -> Install location
# Return Values:
	# 0 -> failed
	# 1 -> success, installed new version
	# 2 -> success, did not install new version

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

# Function to determine path to install to
# $1 -> LOCATION or LINK target
# Return Values:
	# 0 -> failed, should print_help and exit after returning
	# 1 -> success
get_install_path() {
	if [ -n "$1" ]; then
		if [ ! -e "$1" ]; then
			echo "Error: $1 does not exist"
			return 0
		fi
		if [ ! -w "$1" ]; then
			echo "Error: cannot write to $1; insufficient permissions"
			return 0
		fi

		echo "$1"
		return 1
	fi

	return 0
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

# Check installed version number (if exists and link is valid)
if [ -h "$1" ] && [ "$(readlink -f "$1" | grep -E -o "[/][^/]*$")" == "/chrome-wrapper" ]; then

	# If the symlink exists, ensure I can write to it
	if [ ! -w "$1" ]; then
		echo "Error: Cannot write to $1"
		print_help
		exit 0
	fi

	MY_VERSION=$($1 --version | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")

	# Compare versions to determine if an update is necessary
	$(get_absolute_path "compare_versions.sh") "$VERSION" "$MY_VERSION"
	if [ $? -eq 0 ]; then
		echo "ungoogled-chromium $MY_VERSION is up to date"
		exit 2
	fi

	echo -n "Upgrade ungoogled-chromium to $VERSION? [Y/n] "
	read -r INPUT
	if [ "$INPUT" == "n" ]; then
		exit 2
	fi

	# Get old install location for deletion later
	OLD_INSTALL=$(get_install_path "$(readlink -f "$1" | sed 's/[/][^/]*$//g')")

	# Get install path
	INSTALL_TO=$(get_install_path "$(echo "$2" | sed 's/[/]*$//g')")
	if [ $? -eq 0 ]; then
		INSTALL_TO=$(get_install_path "$(readlink -f "$1" | sed 's/[/][^/]*[/][^/]*$//g')")
		if [ $? -eq 0 ]; then
			print_help
			exit 0
		fi
	fi

else
	# First time installation
	if [ -z "$2" ]; then
		echo "Error: Missing LOCATION argument"
		print_help
		exit 0
	fi

	# If a file exists already (that is not a symlink to ungoogled-chromium), then exit
	if [ -e "$1" ]; then
		echo "Error: $1 already exists"
		print_help
		exit 0
	fi

	# Check that a file can be created in this directory
	touch "$1"
	if [ ! $? -eq 0 ] || [ ! -w "$1" ]; then
		echo "Error: Cannot write to $1"
		print_help
		exit 0
	else
		rm "$1"
	fi

	# Check install path argument
	INSTALL_TO=$(get_install_path "$(echo "$2" | sed 's/[/]*$//g')")
	if [ $? -eq 0 ]; then
		print_help
		exit 0
	fi

	echo -n "Install ungoogled-chromium $VERSION to $INSTALL_TO/? [Y/n] "
	read -r INPUT
	if [ "$INPUT" == "n" ]; then
		exit 2
	fi
fi

# Get the realpath of INSTALL_TO
INSTALL_TO=$(realpath "$INSTALL_TO")

# Download tar file to /tmp
echo "Downloading ungoogled-chromium $VERSION"
DOWNLOAD_URL=$(curl -s "$URL" | grep -E -o "href=\".*tar\.xz\"" | cut -d '"' -f 2)
TAR_FILE="ungoogled-chromium_${VERSION}_linux.tar.xz"
wget --quiet -O "/tmp/$TAR_FILE" "$DOWNLOAD_URL"
if [ ! -r "/tmp/$TAR_FILE" ]; then
	echo "Error: Issue downloading ungoogled-chromium $VERSION from $DOWNLOAD_URL"
	exit 0
fi

# Check hash
echo "Checking MD5 hash"
HASH=$(curl -s "$URL" | grep "MD5" | sed 's/<[^<>]*>//g;s/[ ]//g' | cut -d ':' -f 2)
if [ "$HASH" != "$(md5sum "/tmp/$TAR_FILE" | cut -d ' ' -f 1)" ]; then
	echo "Error: MD5 checksum failed"
	rm "/tmp/$TAR_FILE"
	exit 0
fi

# Extract to INSTALL_TO and get parent directory name from archive
echo "Extracting to $INSTALL_TO/"
tar -xf "/tmp/$TAR_FILE" --directory "$INSTALL_TO/" 
PARENT_DIR=$(tar -tvf "/tmp/$TAR_FILE" | head -n 1 | cut -d ' ' -f 6 | cut -d '/' -f 1)

# Create symlink
echo "Creating symlink $1"
ln -fns "$INSTALL_TO/$PARENT_DIR/chrome-wrapper" "$1"

# Cleanup
echo "Removing /tmp/$TAR_FILE"
rm "/tmp/$TAR_FILE"
echo "$OLD_INSTALL" | grep -q "ungoogled-chromium"
if [ "$?" -eq 0 ] && [ -w "$OLD_INSTALL" ]; then
	echo "Removing $OLD_INSTALL"
	rm -r "$OLD_INSTALL"
fi
