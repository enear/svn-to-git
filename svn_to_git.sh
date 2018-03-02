#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m'

# Checks the number of arguments.
#
# Arguments:
# 1 = Expected number of arguments
# 2 = Expected number of arguments
function _check_arguments () {
	# Number of arguments
	local expected_nargs=$1
	local actual_nargs=$2

	# Checks arguments
	if [[ ${expected_nargs} -ne ${actual_nargs} ]]; then
		printf "${RED}Wrong number of arguments${NC}\n"
		return 1
	fi
}

# Clones a Subversion repo.
# 
# Arguments:
# 1 = Svn root URL
# 2 = Project relative path
# 3 = Authors File
# 4 = Project name (which will be the output directory)
function clone_repo () {
	# Checks arguments
	_check_arguments 4 $# || return $?

	# Subversion root URL
	local root_url="$1"
	# Project relative path
	local repo_path="$2"
	# Authors file
	local authors_file="$3"
	# Project name
	local output_dir="$4"

	git svn clone "${root_url}/${repo_path}" \
		--quiet \
		--authors-file="${authors_file}" \
		--stdlayout \
		-s "${output_dir}"

	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Clone success${NC}\n"
		return 0
	else
		printf "${RED}Clone failed${NC}\n"
		return 1
	fi
}

# Deletes a remote reference.
#
# Arguments:
# 1 = Git repository directory
# 1 = Remote reference (e.g., origin/trunk, origin/mytag)
function delete_remote_ref () {
	# Checks arguments
	_check_arguments 2 $# || return $?

	# Git repository directory
	local git_dir="$1"
	# Remote reference
	local remote_ref="$2"

	# Deletes the remote reference
	git -C "${git_dir}" branch --quiet -D -r "${remote_ref}"
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Remote reference deleted: %s${NC}\n" "$remote_ref"
		return 0
	else
		printf "${RED}Failed to delete remote reference: %s${NC}\n" "$remote_ref" 
		return 1
	fi
}

# Deletes a trunk reference.
#
# When Git clones a Subversion repo a remote reference is created for the
# trunk branch. This remote reference is unnecessary and can be safely deleted.
#
# Arguments:
# 1 = Git repository directory
function delete_trunk_ref () {
	# Checks arguments
	_check_arguments 1 $# || return $?

	# Git repository directory
	local git_dir="$1"

	# Deletes the trunk remote reference
	delete_remote_ref "${git_dir}" "origin/trunk"
}

# Checks if a tag remote reference tag is valid.
#
# When Git clones a Subversion repo a remote reference is created for each
# tag. In Subversion a tag is a branch with an additional commit but in Git a
# tag is just a reference to a commit. A valid tag remote reference must have
# no differences between the tag commit and the previous commit.
#
# Arguments:
# 1 = Git repository directory
# 2 = Tag remote reference
function validate_tag () {
	# Checks arguments
	_check_arguments 2 $# || return $?

	# Git repository directory
	local git_dir="$1"
	# Remote reference
	local remote_ref="$2"

	# Checks if tag commit is equal to the previous commit
	git -C "${git_dir}" diff --quiet "$remote_ref" "$remote_ref"~1
	if [[ $? -eq 0 ]]; then
		return 0
	else
		printf "${RED}Abnormal tag: %s${NC}\n" "$t"
		return 1
	fi
}

# Creates a tag based on a remote reference.
# 
# When Git clones a Subversion repo a remote reference is created for each
# tag. In Subversion a tag is a branch with an additional commit but in Git a
# tag is just a reference to a commit. The Git tag will be the previous commit
# which should be equal to tag commit. The tag remote reference commit can be
# deleted afterwards.
#
# Arguments:
# 1 = Git repository directory
# 2 = Tag remote reference
function create_tag () {
	# Checks arguments
	_check_arguments 2 $# || return $?

	# Git repository directory
	local git_dir="$1"
	# Remote reference
	local remote_ref="$2"

	# The tag name derived from remote reference
	tag_name="${remote_ref/origin\/tags\/}"

	# Creates a lightweigth tag
	git -C "${git_dir}" tag "${tag_name}" "$remote_ref"~1
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Tag successfully created: %s${NC}\n" "$tag_name"
		return 0
	else
		printf "${RED}Failed to create tag: %s${NC}\n" "$tag_name"
		return 1
	fi
}

# Creates valid tags based on Subversion remote references and deletes the
# remote references afterwards.
#
# Arguments:
# 1 = Git repository directory
function create_tags () {
	# Check arguments
	_check_arguments 1 $# || return $?

	# Git repository directory
	local git_dir="$1"

	# For each tag remote reference
	for t in $(git -C "${git_dir}" for-each-ref --format='%(refname:short)' refs/remotes/origin/tags); do
		validate_tag "${git_dir}" "$t" &&
		create_tag "${git_dir}" "$t" &&
		delete_remote_ref "${git_dir}" "$t"
	done
}

# Creates branch based on a remote reference.
#
# When Git clones a Subversion repo a remote reference is created for each
# branch. A Git branch is created based on the remote reference. After creating
# the branch the remote reference can be deleted.
#
# Arguments:
# 1 = Git repository directory
# 2 = Branch remote reference
function create_branch () {
	# Check arguments
	_check_arguments 2 $# || return $?

	# Git repository directory
	local git_dir="$1"
	# Branch remote reference
	local branch_ref="$2"

	# Removes the "origin/" part
	branch_name=${b/origin\//}

	# Creates a branch based on the remote reference
	git -C "${git_dir}" branch --quiet "${branch_name}" "${branch_ref}"
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Branch created: %s${NC}\n" "$branch_name"
		return 0
	else
		printf "${RED}Failed to delete remote reference: %s${NC}\n" "$remote_ref"
		return 1
	fi
}

# Creates branches based on Subversion remote references and deletes the remote
# references afterwards.
#
# Arguments:
# 1 = Git repository directory
function create_branches () {
	# Check arguments
	_check_arguments 1 $# || return $?

	# Git repository directory
	local git_dir="$1"

	# For each remote reference except trunk and tags
	for b in $(git -C "${git_dir}"  for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -v 'origin/trunk' | grep -v 'origin/tags'); do
		create_branch "${git_dir}" "$b" &&
		delete_remote_ref "${git_dir}" "$b"
	done
}

# Imports Subversion ignore
#
# Arguments:
# 1 = Git repository directory
function import_ignore () {
	# Check arguments
	_check_arguments 1 $# || return $?

	# Git repository directory
	local git_dir="$1"

	# Creates the Git ignore fiel
	git -C "${git_dir}" svn show-ignore > "$git_dir/.gitignore"
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Exported ignore${NC}\n"
	else
		printf "${RED}Failed to export ignore${NC}\n"
		return 1
	fi

	# Add Git ignore
	git -C "${git_dir}" add ".gitignore"
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Added ignore${NC}\n"
	else
		printf "${RED}Failed to add ignore${NC}\n"
		return 1
	fi

	# Commit Git ignore
	git -C "${git_dir}" commit -m "Add ignore"
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Committed ignore${NC}\n"
	else
		printf "${RED}Failed to commit ignore${NC}\n"
		return 1
	fi

	return 0
}

# Removes Subversion configuration and data
#
# Arguments:
# 1 = Git repository directory
function remove_svn_config () {
	# Check arguments
	_check_arguments 1 $# || return $?

	# Git repository directory
	local git_dir="$1"

	# Removes Subversion section
	git -C "${git_dir}" config --remove-section "svn"
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Removed the Subversion section${NC}\n"
	else
		printf "${RED}Failed to remove the Subversion section${NC}\n"
		return 1
	fi

	# Removes Subversion remote section
	git -C "${git_dir}" config --remove-section "svn-remote.svn"
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Removed the Subversion remote section${NC}\n"
	else
		printf "${RED}Failed to remove the Subversion remote section${NC}\n"
		return 1
	fi

	# Remove Subversion metadata
	rm -r "${git_dir}/.git/svn"
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Removed the Subversion metadata${NC}\n"
	else
		printf "${RED}Failed to remove the Subversion metadata${NC}\n"
		return 1
	fi

	return 0
}

# Creates a development branch.
#
# Arguments:
# 1 = Git repository directory
function create_dev_branch () {
	# Check arguments
	_check_arguments 1 $# || return $?

	# Git repository directory
	local git_dir="$1"

	git -C "${git_dir}" branch --quiet develop
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Development branch created${NC}\n"
		return 0
	else
		printf "${RED}Failed to create development branch${NC}\n"
		return 1
	fi
}

# Initializes Git Flow
#
# Arguments:
# 1 = Git repository directory
function init_git_flow() {
	# Check arguments
	_check_arguments 1 $# || return $?

	# Git repository directory
	local git_dir="$1"

	git -C "${git_dir}" flow init -d
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Git Flow successfully initialized${NC}\n"
		return 0
	else
		printf "${RED}Failed to initialize Git Flow${NC}\n"
		return 1
	fi
}

# Optimizes the repository
#
# Arguments:
# 1 = Git repository directory
function optimize_repo () {
	# Check arguments
	_check_arguments 1 $# || return $?

	# Git repository directory
	local git_dir="$1"

	git -C "${git_dir}" gc
	if [[ $? -eq 0 ]]; then
		printf "${GREEN}Optimization successful${NC}\n"
		return 0
	else
		printf "${RED}Failed to optimize${NC}\n"
		return 1
	fi
}

# Subversion root URL
root_url="$1"
# Project relative path
repo_path="$2"
# Authors file
authors_file="$3"
# Project name
output_dir="$4"

if [[ $# -ne 4 ]]; then
	printf "Usage: svn_to_git.sh <root_url> <repo_path> <authors_file> <output_dir>\n"
	exit 1
fi

clone_repo "${root_url}" "${repo_path}" "${authors_file}" "${output_dir}" &&
delete_trunk_ref "${output_dir}" &&
create_tags "${output_dir}" &&
create_branches "${output_dir}" &&
import_ignore "${output_dir}"
create_dev_branch "${output_dir}" &&
init_git_flow "${output_dir}" &&
remove_svn_config "${output_dir}" &&
optimize_repo "${output_dir}"
