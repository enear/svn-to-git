#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m'

function delete_repo () {
	local bitbucket_host="$1"
	local username="$2"
	local repo_name="$3"

	printf "Deleting a BitBucket repository\n"

	curl -X DELETE -n \
	  "http://${bitbucket_host}/rest/api/1.0/projects/~${username}/repos/${repo_name}"
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Repository deleted${NC}\n"
		return 0
	else
		printf "${RED}Failed to delete the repository${NC}\n"
		return 1
	fi
}

function delete_origin () {
	local repo_name="$1"
	local repos_dir="$2"

	printf "Deleting origin\n"

	git -C "${repos_dir}/${repo_name}" remote rm origin
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Origin deleted${NC}\n"
		return 0
	else
		printf "${RED}Origin deletion failed${NC}\n"
		return 1
	fi
}

if [[ $# -ne 4 ]]; then
	printf "Usage: delete_repo.sh <bitbucket_host> <username> <repo_name> <repos_dir>\n"
	exit 1
fi

bitbucket_host="$1"
username="$2"
repo_name="$3"
repos_dir="$4"

delete_repo "${bitbucket_host}" "${username}" "${repo_name}" &&
delete_origin "${repo_name}" "${repos_dir}"
