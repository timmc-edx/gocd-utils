#!/bin/bash
# Fetches job run history.
#
# Usage: $0 "my_pipeline/some_stage/the_job"
#
# Prints JSONL of jobs to stdout (in some order), and progress information
# to stderr.
#
# Requires environment variables GOCD_SERVER and GOCD_TOKEN

set -eu -o pipefail

job_ident="$1"

function call_gocd {
    url="$1"
    curl -sS -H "Authorization: bearer $GOCD_TOKEN" -H "Accept: application/vnd.go.cd.v1+json" -- "$url"
}

history_url="${GOCD_SERVER}/go/api/jobs/${job_ident}/history?"
while true; do
    output=$(call_gocd "$history_url&page_size=100")

    echo >&2 "Found $(echo "$output" | jq '.jobs|length' -c) jobs"
    echo "$output" | jq '.jobs[]' -c

    history_url="$(echo "$output" | jq '._links.next.href' -r)"
    if [[ "$history_url" = "null" ]]; then
        echo >&2 "No more history"
        break
    else
        echo >&2 "Fetching next page: $history_url"
    fi
    sleep 3
done
