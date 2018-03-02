# Corehub Subversion to Git issues

Corehub in particular has some issues with the multiple Subversion repositories
to Git repositories script. These are detailed in this file.

## Trunk references with ID

Some remote references to trunk are followed by `@` and the Subversion ID.
Most probably these can be removed.

## Branches with ID

Some branches include the Subversion commit ID. To find the repositories with
odd branch names execute the following command:

```
$ grep -l "Branch.*@" *.log
```

Leaving the branches is not problematic but only one should exist. Since there
is no automatic way of knowing which one to choose, this must be fixed
manually.

## Abnormal tags

In Corehub not all tags have been correctly created. To find the repositories
with abnormal tags execute the following command:

```
$ grep -l "Abnormal" *.log
```

For example:

 * datacentre-config-builder

These must be handled manually. The next section details some of these issues.

### Dangling Tag Commits

Some tag commits do not belong to the master branch. These are called dangling
commits because they do not belong to any branch.

Some of these can be fixed by with a rebase because there are no branches. For
example:

 * common-corehub-adapter-common
 * common-corehub-logic-common

This will glue the tag with the master branch. A side effect is that empty
commits are removed (e.g., commits that only changed ignore properties).

Others are not so simple. There are branches that will not belong to the
rebased master branch:

 * common-corehub-parent

The branches must be manually glued to the rebased master branch.

Finally there are cases with multiple dangling tags. These must also be
manually and carefuly glued. For example:

 * common-vts

### Tags as branches

Some tags have been interpreted as being branches. For example:

```
A -- C -- D
     \--- B (tag: 1.0)
```

In the example above `B` is differente than `A` and `C`, as if the result
should have been:

```
A -- B (tag: 1.0) -- C -- D
```

But since it's not these must be rebased. One example of such project is:

 * datacentre-database-corehub-tds-database

## Non standard tag naming scheme

Most Git tags follow the pattern `vX.Y.Z`. For example:

```
v1.2.0
v1.3.0-RC1
v4.1.0
```

Or the same pattern without the 'v'. However CoreHub follows an inconsistent
pattern. Most projects follow the pattern `<project-name>-X.Y.Z" while others
follow `REL-X-Y-Z` with minor variations. It is possible to capture every tag
and fix it to follow the Git standard:

```
# Similar to semantic versioning (e.g., 1.1.0-RC1, 1.0_2, 1.0.1.0)
^.*-([0-9]+\.)+([0-9]+)([_-\.].+)?$

# Version with dashes (e.g., REL-1-1-0-RC1, REL-2-0-0)
REL-([0-9]+-)+[0-9](-.*)?
```

Such inconsistency however is not problematic and we can leave it as it is.

