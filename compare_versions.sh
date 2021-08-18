#!/bin/bash

# Bash script to compare ungoogled-chromium version numbers
# $1 -> up-to-date version number (from atom feed)
# $2 -> currently installed version number
# Return Values:
	# 0 -> installed version is up-to-date
	# 1 -> installed version can be upgraded


# Break into arrays
IFS='.'
read -ra V1 <<< "$1"
read -ra V2 <<< "$2"

# DEBUG
for val in "${V1[@]}"; do
	echo "$val"
done
echo ${#V1[@]}
for val in "${V2[@]}"; do
	echo "$val"
done
echo ${#V2[@]}

# Determine shorter array (for the loop)
LENGTH=${#V1[@]}

for (( i = 0 ; i < LENGTH ; i++ )); do
	if [ "${V1[$i]}" -gt "${V2[$i]}" ]; then
		exit 1
	elif [ "${V1[$i]}" -lt "${V2[$i]}" ]; then
		exit 0
	fi
done

exit 0
