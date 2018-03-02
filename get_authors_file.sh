#!/bin/sh

if [[ $# -ne 2 ]]; then
	printf "Usage: get_authors_file.sh <svn_url> <output_file>\n"
	exit 1
fi

# Subversion URL
svn_url="$1"
# Output file
output_file="$2"

# Getting the user list
svn log --xml --quiet "${svn_url}" | grep author | sort -u | \
	perl -pe 's/.*>(.*?)<.*/$1 = /' >> "${output_file}"
