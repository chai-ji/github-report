#!/bin/bash
set -euo pipefail

# https://cli.github.com/manual/gh_api
# https://docs.github.com/en/rest/users?apiVersion=2022-11-28
# https://docs.github.com/en/rest/repos?apiVersion=2022-11-28
# https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-contributors
# https://docs.github.com/en/rest/commits/commits?apiVersion=2022-11-28
# https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28
# https://github.com/cli/cli/issues/8984

# https://github.com/nf-core

ORG="$1"
OUTPUT_DIR=output
OUTPUT_FILE="${OUTPUT_DIR}/${ORG}.tsv"

# TODO: better output handling
mkdir -p "$OUTPUT_DIR"
> "${OUTPUT_FILE}"

get_last_commit () {
    local org="$1"
    local repo="$2"
    local contributor="$3"

    # this sometimes fails with errors like this;
    # Invalid search query "author:an-altosian repo:nf-core/scrnaseq".
    # Search text is required when searching commits. Searches that use qualifiers only are not allowed. Were you searching for something else?

    # ^^ this is because some people have their activity on GitHub set to Private

    local LAST_COMMIT="$(gh search commits --author "$contributor" --repo "${ORG}/${repo}" --sort committer-date --order desc --json commit --jq '.[].commit.committer.date' --limit 1 || echo "NA")"

    echo "$LAST_COMMIT"
}

# get list of all repos in the Org
# REPOS=$(gh api "orgs/${ORG}/repos" --jq '.[].full_name')
# TODO: how to search >1000?
# REPOS="$(gh search repos --limit 1000 --owner "${ORG}" --json name,updatedAt --jq '.[] | [.name, .updatedAt] | @tsv' )"
REPOS="$(gh repo list nextflow-io --limit 100000 --json name,updatedAt --jq '.[] | [.name, .updatedAt] | @tsv')"

while read -r repo updatedAt; do
    echo "org: $ORG, repo: $repo updatedAt: $updatedAt"

    CONTRIBUTORS="$(gh api repos/${ORG}/${repo}/contributors --jq '.[] | [.login,.contributions] | @tsv')"

    while read -r contributor contributions; do
    LAST_COMMIT="$(get_last_commit "${ORG}" "${repo}" "$contributor")"

    paste \
    <(echo "$ORG") \
    <(echo "$repo") \
    <(echo "$updatedAt") \
    <(echo "$contributor") \
    <(echo "$contributions") \
    <(echo "$LAST_COMMIT") \
    >> "${OUTPUT_FILE}"

    sleep 2 # beware of API rate limits !

    done < <(echo "$CONTRIBUTORS")
done < <(echo "$REPOS")

