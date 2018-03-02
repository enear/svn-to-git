#!/bin/bash

# Converts a set Subversion repositories to Git
#
# Subversions repositories can be structured hierarchically but Git
# repositories cannot. For that reason the name of the resulting Git
# repositories is the Subversion path with slashes replaced with dashes (e.g.,
# master/project => master-project)

RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m'

if [[ $# -ne 4 ]]; then
	printf "Usage: multi_svn_to_git.sh <root_url> <authors_file> <repos_paths_file> <repos_output_dir>\n"
	exit 1
fi

# Subversion root URL
root_url="${1}"
# Authors file
authors_file="${2}"
# Project relative paths file
repos_paths_file="${3}"
# Output directory
repos_output_dir="${4}"

# Checks if the repository output directory already exists
if [[ -e ${repos_output_dir} ]]; then
	printf "Projects output directory already exists\n"
	exit 1
fi

# Creates the repository output directory
mkdir ${repos_output_dir}
if [[ $? -ne 0 ]]; then
	printf "Failed to create repos output directory\n"
	exit 1
fi

# For each repository path
while read repo_path; do
	# Project name
	# 
	# This will be the Subversion path with slashes replaced with dashes
	# (e.g., master/project => master-project)
	repo_name="${repo_path//\//-}"

	# Project dir
	repo_output_dir="${repos_output_dir}/${repo_name}"

	# Log file
	log_file="${repos_output_dir}/${repo_name}.log"

	./svn_to_git.sh "${root_url}" "${repo_path}" "${authors_file}" "${repo_output_dir}" &> ${log_file}
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Finished: %s${NC}\n" "${repo_output_dir}"
	else
		printf "${RED}Failed: %s${NC}\n" "${repo_output_dir}"
	fi
done < "${repos_paths_file}"
