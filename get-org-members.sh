#!/bin/bash
set -euo pipefail

# https://cli.github.com/manual/gh_api
# https://docs.github.com/en/rest/users?apiVersion=2022-11-28
# https://docs.github.com/en/rest/repos?apiVersion=2022-11-28
# https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-contributors
# https://docs.github.com/en/rest/commits/commits?apiVersion=2022-11-28

# https://github.com/nf-core

ORG=nf-core
REPOS_LIST="${ORG}.repos.txt"

# get list of all repos in the Org
# REPOS=$(gh api "orgs/${ORG}/repos" --jq '.[].full_name')
# TODO: how to search >1000?
gh search repos --limit 1000 --owner "${ORG}" --json name,updatedAt --jq '.[] | [.name, .updatedAt] | @tsv' > "$REPOS_LIST"

# get list of all Contributors per repo
while read -r repo updatedAt; do
echo "${ORG} - ${repo}"
CONTRIBUTORS_LIST="${ORG}.${repo}.contributors.txt"
gh api repos/${ORG}/${repo}/contributors --jq '.[] | [.login,.contributions] | @tsv' > "$CONTRIBUTORS_LIST"
done < "$REPOS_LIST"





# gh search commits --author stevekm --owner "$ORG"


