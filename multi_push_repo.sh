#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m'

function push_repo () {
	bitbucket_host="$1"
	username="$2"
	repo_name="$3"
	repos_dir="$4"

	./push_repo.sh "${bitbucket_host}" "${username}" \
		"${repo_name}" "${repos_dir}" \
		&> "${repos_dir}/push-${repo_name}.log"
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Push ${repo_name} success${NC}\n" "$remote_ref"
		return 0
	else
		printf "${RED}Push ${repo_name} failed${NC}\n" "$remote_ref" 
		return 1
	fi
}

function push_repos () {
	bitbucket_host="$1"
	username="$2"
	repos_dir="$3"

	for d in "${repos_dir}"/*; do
		if [[ -d "$d" ]]; then
			repo_name="${d##*/}"
			push_repo "${bitbucket_host}" "${username}" \
				"${repo_name}" "${repos_dir}"
		fi
	done
}

if [[ $# -ne 3 ]]; then
	printf "Usage: multi_push_repo.sh <bitbucket_host> <username> <repos_dir>\n"
	exit 1
fi

bitbucket_host="$1"
username="$2"
repos_dir="$3"

push_repos "${bitbucket_host}" "${username}" "${repos_dir}"
