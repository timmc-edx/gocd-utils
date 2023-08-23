#!/bin/bash
# Given a job instance identifier, retrieve the job's output.
#
# Usage: $0 <job_instance>
#
# A job instance looks like: pipeline_name/pipeline_counter/stage_name/stage_counter/job_name
#
# Requires environment variables GOCD_SERVER and GOCD_TOKEN

set -eu -o pipefail

job_instance="$1"

# Basic check for reasonable path names so we can use this safely on
# the filesystem; expand this as needed.
if [[ ! "$job_instance" =~ ^([a-zA-Z0-9_-]+/){4}[a-zA-Z0-9_-]+$ ]]; then
    echo >&2 "Malformed job instance"
    exit 1
fi

function call_gocd {
    url="$1"
    curl -sS -H "Authorization: bearer $GOCD_TOKEN" -H "Accept: application/vnd.go.cd.v1+json" -- "$url"
}

call_gocd "${GOCD_SERVER}/go/files/${job_instance}/cruise-output/console.log"
