# Subversion to Git

Utility scripts to convert a Subversion repository to a Git repository.

## Requirements

These scripts require the following software to be installed:

 * Bash
 * Git
 * Git Flow
 * Curl

## Authors file

In Subversion commits are identified by username but in Git users are
identified by email. To have correct author information a translation table is
required.

To get all users names from Subversion execute the following command:

```bash
$ ./get_authors_file.sh <svn_url> <output_file>
```

This will return a file were the keys are the Subversion usernames and the
values are empty. For example:

```
john.doe =
jane.doe =
john.smith =
```

The value should be the Git user name and email. For example:

```
john.doe = John Doe <john.doe@mail.com>
jane.doe = Jane Doe <jane.doe@mail.com>
john.smith = John Smith <john.smith@mail.com>
```

All values must be set before proceeding.

## Convert one repository

To convert a Subversion repository to a Git repository execute the following
command:

```bash
$ svn_to_git.sh <root_url> <repo_path> <authors_file> <output_dir>
```

The arguments are detailed bellow:

 * Root URL: The Subversion root URL (e.g., http://svn.apache.org/repos/asf)
 * Repository Path: The Subversion repository path (e.g., subversion, xml/axkit)
 * Output Directory: The directory were the Git repository is output

This command will clone the Subversion repository, create branches and tags,
clean up Subversion metadata, initialize Git Flow and optimize the repository.

### Clone project

Git provides tool to clone Subversion repositories. The conversion script
executes the following command:

```bash
$ git svn clone <root_url>/<repository_path> \
    --authors-file=<authors_file>
    --std-layout -s <output_dir>
```

The command clones a Subversion repository assuming a standard directory
structure (`trunk`, `branches` and `tags`). The commit information will be
based in the authors file.

### Delete trunk remote reference

The Subversion the `trunk` branch is equivalent to Git `master` branch. Cloning
a Subversion repository leaves an unnecessary remote reference to `trunk`. The
tool simply removes the reference:

```bash
git branch -D -r "origin/trunk"
```

### Tags

Cloning a Subversion repository also creates remote references to tags. The tag
remote references can be found by executing:

```bash
git for-each-ref --format='%(refname:short)' refs/remotes/origin/tags
```

Which may result in the following output:

```
origin/tags/v1.0
origin/tags/v2.2
```

In Subversion a tag is created by copying a branch (e.g., `trunk`,
`branches/feature1`) to the tags folder. This results in an additional commit.
In Git a tag is simply a reference to a commit. Based on this, a valid tag is a
commit without differences compared to the previous commit:

```bash
git diff --quiet "$remote_ref" "$remote_ref"~1
```

The above command returns zero if there are no differences between the two
commits, making the tag valid.

The tool creates a lightweight tag of the previous commit if the tag is valid
and deletes the tag remote reference.

```bash
# Removes the 'origin/tags/' part
tag_name="${remote_ref/origin\/tags\/}"

# Creates a lightweight tag of the previous commit of the tag remote reference
git tag "${tag_name}" <remote_ref>~1

# Deletes the remote reference
git branch -D -r <remote_ref>
```

Note that invalid tags are ignored. These should be handled manually.

### Branches

Cloning a Subversion repository creates remote references to branches. The
branch remote references, excluding trunk, can be found by executing:

```bash
git for-each-ref --format='%(refname:short)' refs/remotes/origin \
    | grep -v 'origin/trunk' | grep -v 'origin/tags'
```

For example, the result could be:

```
origin/feature1
origin/feature2
```

For each branch remote reference, the tool creates a branch and removes de
remote reference:

```bash
# Removes the 'origin/' part
branch_name=${remote_ref/origin\//}

# Creates a branch
git branch ${branch_name}" <remote_ref>

# Deletes de remote reference
git branch -D -r <remote_ref>
```

### Import ignore

Git has a tool to import Subversion ignore properties. The Subversion ignore
properties are imported as follows:

```bash
# Import svn ignore
git svn show-ignore > " .gitignore"

# Commit
git add ".gitignore"
git commit -m "Add ignore"
```

### Remove Subversion Metadata

At this point any Subversion metadata is not required and can be safely
deleted. The Subversion metadata is removed as follows:

```bash
# Removes Subversion configuration
git config --remove-section "svn"
git config --remove-section "svn-remote.svn"

# Removes Subversion metadata
rm -r .git/svn"
```

### Git Flow

Git Flow is an extension that provides high level operations for Vincent
Driessen's branching model. Git Flow is initialized as follows:

```bash
# Creates the develop branch
git branch develop

# Initializes Git Flow
git flow init -d
```

### Repository Optimization

After everything is done the repository should be optimized. Optimization is
acheived by executing:

```bash
git gc
```

## Convert multiple repositories

Too convert multiple Subversion projects from the same root URL first create a
file with the repository paths. For example:

```
main/project1
main/project2
utils/project3
```

This file can be input to the following script:

```bash
$ ./multi_svn_to_git.sh <root_url> <authors_file> <repo_paths_file> <repos_output_dir>
```

The arguments are detailed bellow:

 * Root URL: The Subversion root URL (e.g., http://svn.apache.org/repos/asf)
 * Authors file: Subversion to Git username translation file
 * Repository Paths File: The Subversion repository paths file
 * Output Directory: The directory to output the converted Git repositories

In Subversion projects are structured as a filesystem but in Git each project
should be stored in it's own repository. For that reason the name of the Git
output repository is the Subversion path with slashes replaced by dashes (e.g.,
`master/project1 => master-project1`).

For each Subversion clone a log file is output in the projects output
directory. This log is colored and can be viewed with a regular unix tool:

```
less -r <log_file>
```

## Push repository

After the convertion from Subversion to Git and checking everything is correct,
the code can be pushed to host service. The next sections show how to to this
with Bitbucket.

### Password configuration

The scripts require Git and Curl non interactive password authentication. To
configure curl add the `~/.netrc` with the following content:

```
machine <host> login <username> password <password>
```

For example:

machine mybitbucket.com username joedoe password mypassword

In Git one option is to store passwords and login once:

```bash
git config credential.helper store
```

After the repositories are pushed you may want to delete these configurations.

### Create and push Bitbucket repository

To create a Bitbucket repository and push all branches and tags, based on local
repository, execute the following command:

```bash
$ ./push_repo.sh <bitbucket_host> <username> <repo_name> <repos_dir>
```

For example:

```bash
$ ./push_repo.sh mybitbucket.com joedoe test repos
```

Would execute the following steps:

 * Create a public empty `test` repository owned by user `joedoe` hosted in
   `mybitbucket.com`
 * Set the origin of the local `test` repository, in the `repos` directory, as
   the newly created Bitbucket repository
 * Push all branches and tags to origin

This script assumes the local repository does not have origin set and that the
Bitbucket repository does not exist.

To execute the previous script for multiple repositories, run the following
command:

```bash
$ ./multi_push_repo.sh <bitbucket_host> <username> <repos_dir>
```

For example:

```bash
$ ./multi_push_repo.sh mybitbucket.com joedoe repos
```

Would execute the `push_repo` command for each repository found in the `repos`
directory. Additionally a log file is created in the `repos` directory for each
execution.

### Delete a Bitbucket repo

If something went wrong you may want to delete all the Bitbucket repositories
and unset the origin of the local Git repositories. To do that for a single
repository execute:

```bash
$ ./delete_repo.sh <bitbucket_host> <username> <repo_name> <repos_dir>
```

For example:

```bash
$ ./delete_repo.sh mybitbucket.com joedoe test repos
```

Would execute the following steps:

 * Delete the `test` repository owned by user `joedoe` hosted in
   `mybitbucket.com`
 * Unset the origin of the local `test` repository in the `repos` directory

This script assumes the local repository does not have origin set and that the
Bitbucket repository does not exist.

You can also execute the same script for multiple repositories:

```bash
$ ./_multi_delete_repo.sh mybitbucket.com joedoe repos
```

For example:

```bash
$ ./multi_push_repo.sh mybitbucket.com joedoe repos
```

Would the `delete_repo` command for each repository found in the `repos`
directory. Like the multiple push command, a log file is created in the `repos`
directory for each execution.
