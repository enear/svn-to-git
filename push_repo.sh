#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m'

function create_repo () {
	local bitbucket_host="$1"
	local username="$2"
	local repo_name="$3"

	printf "Creating a BitBucket repository\n"

	curl -n -H "Content-Type: application/json" \
	  -d "{\"name\": \"${repo_name}\", \"public\": true}" \
	  "http://${bitbucket_host}/rest/api/1.0/projects/~${username}/repos"
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Repository created${NC}\n"
		return 0
	else
		printf "${RED}Failed to create repository${NC}\n"
		return 1
	fi
}

function init_origin () {
	local bitbucket_host="$1"
	local username="$2"
	local repo_name="$3"
	local repos_dir="$4"

	git -C "${repos_dir}/${repo_name}" remote add origin \
		"http://${username}@${bitbucket_host}/scm/~${username}/${repo_name}.git"
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Origin initialized${NC}\n"
		return 0
	else
		printf "${RED}Origin initialization failed${NC}\n"
		return 1
	fi
}

function push_code () {
	local username="$1"
	local repo_name="$2"
	local repos_dir="$3"

	git -C "${repos_dir}/${repo_name}" push origin --all
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Pushed every branch${NC}\n"
	else
		printf "${RED}Failed to push every branch${NC}\n"
		return 1
	fi

	git -C "${repos_dir}/${repo_name}" push origin --tags
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Pushed tags${NC}\n"
	else
		printf "${RED}Failed to push tags${NC}\n"
		return 1
	fi

	return 0
}

if [[ $# -ne 4 ]]; then
	printf "Usage: push_repo.sh <bitbucket_host> <username> <repo_name> <repos_dir>\n"
	exit 1
fi

bitbucket_host="$1"
username="$2"
repo_name="$3"
repos_dir="$4"

create_repo "${bitbucket_host}" "${username}" "${repo_name}" &&
init_origin "${bitbucket_host}" "${username}" "${repo_name}" "${repos_dir}" &&
push_code "${username}" "${repo_name}" "${repos_dir}"
