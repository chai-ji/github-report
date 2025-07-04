#!/bin/bash
set -euo pipefail

# https://cli.github.com/manual/gh_api
# https://docs.github.com/en/rest/users?apiVersion=2022-11-28
# https://docs.github.com/en/rest/repos?apiVersion=2022-11-28
# https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-contributors
# https://docs.github.com/en/rest/commits/commits?apiVersion=2022-11-28
# https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28

# https://github.com/nf-core

ORG=nf-core
OUTPUT_DIR=output
REPOS_LIST="${OUTPUT_DIR}/${ORG}.repos.txt"

# TODO: better output handling
mkdir -p "$OUTPUT_DIR"

# get list of all repos in the Org
# REPOS=$(gh api "orgs/${ORG}/repos" --jq '.[].full_name')
# TODO: how to search >1000?
gh search repos --limit 1000 --owner "${ORG}" --json name,updatedAt --jq '.[] | [.name, .updatedAt] | @tsv' > "$REPOS_LIST"


while read -r repo updatedAt; do

    echo "${ORG} - ${repo}"
    # get list of all Contributors per repo
    CONTRIBUTORS_LIST="${OUTPUT_DIR}/${ORG}.${repo}.contributors.txt"
    gh api repos/${ORG}/${repo}/contributors --jq '.[] | [.login,.contributions] | @tsv' > "$CONTRIBUTORS_LIST"
    sleep 5

    # get each contributor's last commit date to the repo
    CONTRIBUTORS="$(gh api repos/${ORG}/${repo}/contributors --jq '.[] | [.login] | @tsv')"
    for contributor in $CONTRIBUTORS; do
        paste <(echo "${contributor}") \
        <(echo "${ORG}/${repo}") \
        <(gh search commits --author "$contributor" --repo "${ORG}/${repo}" --sort committer-date --order desc --json commit --jq '.[].commit.committer.date' --limit 1) \
        >> "${OUTPUT_DIR}/user.${contributor}.txt"
        sleep 3
    done

done < "$REPOS_LIST"





