#!/bin/bash

# Shell script to update ungoogled-chromium Portable Linux 64-bit to the latest version
# $1 (optional) -> Wrapper symlink location (ungoogled-chromium by default)
# $2 (optional) -> Install location
# Return Values:
	# 0 -> failed
	# 1 -> success, installed new version
	# 2 -> success, did not install new version

# If first time installing: user must specify a symlink location and an installation directory
# If checking for updates: user must pass a symlink for ungoogled-chromium (this is typically just the command name if a symlink is part of the path)
	# Use the symlink target to determine installation directory

# URL for atom feed
ATOM_URL="https://raw.githubusercontent.com/ungoogled-software/ungoogled-chromium-binaries/master/feed.xml"

# Default platform to install/update
DEFAULT_PLATFORM="Portable Linux 64-bit"
PLATFORM="$DEFAULT_PLATFORM"

# Array of supported platforms
# TODO add support for other platforms
declare -A SUPPORTED_PLATFORMS
SUPPORTED_PLATFORMS["Portable Linux 64-bit"]=1

# Should the user be prompted if a new version is available
PROMPT=1


# Print help message
print_help() {
	echo "Usage: $0 [OPTION]... [LINK] [LOCATION]"
	echo
	echo "$0 is a bash script that can help to automate installation and updating of ungoogled-chromium"
	echo "LINK is the path or desired path for a symlink pointing to the ungoogled-chromium executable. If LINK is not specified, it will be set to ungoogled-chromium by default"
	echo "LOCATION is the desired install location for ungoogled-chromium. It does not need to be specified unless installing ungoogled-chromium for the first time"
	echo
	echo "  -h, --help			Print this help message"
	echo "  -p, --platform PLATFORM	Specify platform to target. Set to $DEFAULT_PLATFORM by default"
	echo "  -y, --yes 			Automatic yes for all prompts"
}

# Function to compare ungoogled-chromium version numbers
# $1 -> up-to-date version number (from atom feed)
# $2 -> currently installed version number
# Return Values:
	# 0 -> installed version is up-to-date
	# 1 -> installed version can be upgraded
compare_versions() {
	# Break into arrays
	local IFS='.'
	read -ra V1 <<< "$1"
	read -ra V2 <<< "$2"

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

# Function to determine path to install to (and to perform sanity checks on that path)
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


# Read flags
while [ $# -gt 0 ]; do
	case "$1" in
		-- )
			shift
			break
			;;
		-h | --help )
			print_help
			exit
			;;
		-p | --platform )
			PLATFORM="$2"
			shift
			shift
			;;
		-y | --yes )
			PROMPT=0
			shift
			;;
		* )
			break
			;;
	esac
done

# Set LINK argument (with a default value)
LINK="ungoogled-chromium"
if [ -n "$1" ]; then
	LINK="$1"
fi

# Set LOCATION argument
if [ -n "$2" ]; then
	LOCATION="$2"
fi

# Fetch info, break and store into variables
PARSED_XML=$(curl -s $ATOM_URL | xml2)

if [ ! $? -eq 0 ]; then
	echo "Error: Could not parse atom URL $ATOM_URL"
	exit 0
fi

# Get table of available platforms, with versions, and URLs on the following line
PLATFORM_TABLE=$(echo "$PARSED_XML" | grep -E '(/feed/entry/title=)|(/feed/entry/link/@href=)' | sed 's/^.*=//g')

# Get platform information matching PLATFORM, handle any ambiguity by prompting for a selection (PLATFORM+SELECT)
LINE_NUMBER=$(echo "$PLATFORM_TABLE" | grep -i -n "$PLATFORM" | cut -d ':' -f 1)
while read -r line; do
	# Ignore invalid LINE_NUMBER
	# Ignore links
	if [[ ! "$line" =~ [0-9]+ || "$(echo "$PLATFORM_TABLE" | sed -n "$line,$((line))p")" =~ ^https.* ]]; then
		continue
	fi
	# Check that this platform is supported
	if [ "${SUPPORTED_PLATFORMS["$(echo "$PLATFORM_TABLE" | sed -n "$line,$((line))p" | cut -d ':' -f 1)"]}" = '1' ]; then
		FULL_INFO="$(echo -e "$FULL_INFO\n$(echo "$PLATFORM_TABLE" | sed -n "$line,$((line))p")\t$(echo "$PLATFORM_TABLE" | sed -n "$((line+1)),$((line+1))p")")"
	fi
done < <(echo "$LINE_NUMBER")
FULL_INFO="$(echo "$FULL_INFO" | sed -n '2,$p')"
PLATFORM_SELECT=1

FULL_INFO_LINES="$(echo "$FULL_INFO" | wc -l)"
#echo "$FULL_INFO"
#echo "$FULL_INFO_LINES"
if [ -z "$FULL_INFO" ]; then
	# PLATFORM was not found in PLATFORM_TABLE
	echo "Error: No supported platforms match \"$PLATFORM\""
	echo "For a list of supported platforms, see the README"
	print_help
	exit 0
elif [ "$FULL_INFO_LINES" -gt 1 ]; then
	# PLATFORM matched multiple platforms; prompt the user which to use
	if [ "$PROMPT" -eq 1 ]; then
		echo "Multiple platforms match \"$PLATFORM\". Select from the list below"
		for i in $(seq 1 $FULL_INFO_LINES); do
			echo "($i) $(echo "$FULL_INFO" | sed -n "$i,$((i))p" | cut -f 1)"
		done
		echo
		echo -n "Which platform? (default: 1) "
		read -r INPUT
		if [ "$INPUT" -lt 1 ] || [ "$INPUT" -gt "$FULL_INFO_LINES" ]; then
			echo "Invalid platform number. Defaulting to $PLATFORM_SELECT"
		else
			PLATFORM_SELECT="$INPUT"
		fi
	fi
fi

FULL_INFO="$(echo "$FULL_INFO" | sed -n "$PLATFORM_SELECT,$((PLATFORM_SELECT))p")"
echo "Targeting $(echo "$FULL_INFO" | cut -f 1)"

NAME="$(echo "$FULL_INFO" | cut -f 1 | cut -d ':' -f 1)"
VERSION="$(echo "$FULL_INFO" | cut -f 1 | cut -d ':' -f 2 | sed 's/^[ ]*//g' | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"
URL="$(echo "$FULL_INFO" | cut -f 2)"

# Handle if LINK is in PATH by getting the absolute path with which
if [ ! -e "$LINK" ] && [ -e "$(which "$LINK")" ]; then
	LINK=$(which "$LINK")
fi

# Check installed version number (if exists and link is valid)
if [ -h "$LINK" ] && [ "$(readlink -f "$LINK" | grep -E -o "[/][^/]*$")" == "/chrome-wrapper" ]; then

	# To make things easier, get absolute path of LINK
	LINK="$(realpath -s "$LINK")"

	# If the symlink exists, ensure I can write to it
	if [ ! -w "$LINK" ]; then
		echo "Error: Cannot write to $LINK"
		print_help
		exit 0
	fi

	MY_VERSION=$($LINK --version | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")

	# Compare versions to determine if an update is necessary
	compare_versions "$VERSION" "$MY_VERSION"
	if [ $? -eq 0 ]; then
		echo "ungoogled-chromium $MY_VERSION is up to date"
		exit 2
	fi

	if [ $PROMPT = 1 ]; then
		echo -n "Upgrade ungoogled-chromium to $VERSION? [Y/n] "
		read -r INPUT
		if [ "$INPUT" == "n" ]; then
			exit 2
		fi
	fi

	# Get old install location for deletion later
	OLD_INSTALL=$(get_install_path "$(readlink -f "$LINK" | sed 's/[/][^/]*$//g')")

	# Get install path
	INSTALL_TO=$(get_install_path "$(echo "$LOCATION" | sed 's/[/]*$//g')")
	if [ $? -eq 0 ]; then
		INSTALL_TO=$(get_install_path "$(readlink -f "$LINK" | sed 's/[/][^/]*[/][^/]*$//g')")
		if [ $? -eq 0 ]; then
			print_help
			exit 0
		fi
	fi

else
	# First time installation
	if [ -z "$LOCATION" ]; then
		echo "Error: Missing LOCATION argument"
		print_help
		exit 0
	fi

	# If a file exists already (that is not a symlink to ungoogled-chromium), then exit
	if [ -e "$LINK" ]; then
		echo "Error: $LINK already exists"
		print_help
		exit 0
	fi

	# Check that a file can be created in this directory
	touch "$LINK"
	if [ ! $? -eq 0 ] || [ ! -w "$LINK" ]; then
		echo "Error: Cannot write to $LINK"
		print_help
		exit 0
	else
		rm "$LINK"
	fi

	# Check install path argument
	INSTALL_TO=$(get_install_path "$(echo "$LOCATION" | sed 's/[/]*$//g')")
	if [ $? -eq 0 ]; then
		print_help
		exit 0
	fi

	if [ $PROMPT = 1 ]; then
		echo -n "Install ungoogled-chromium $VERSION to $INSTALL_TO/? [Y/n] "
		read -r INPUT
		if [ "$INPUT" == "n" ]; then
			exit 2
		fi
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
echo "Creating symlink $LINK"
ln -fns "$INSTALL_TO/$PARENT_DIR/chrome-wrapper" "$LINK"

# Cleanup
echo "Removing /tmp/$TAR_FILE"
rm "/tmp/$TAR_FILE"
echo "$OLD_INSTALL" | grep -q "ungoogled-chromium"
if [ "$?" -eq 0 ] && [ -w "$OLD_INSTALL" ]; then
	echo "Removing $OLD_INSTALL"
	rm -r "$OLD_INSTALL"
fi
