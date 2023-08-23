#!/bin/bash
# Fetch job outputs and print jobs that failed and have output matching the regex.
#
# Job outputs are cached in the `output_base_dir` under a folder tree
# matching job instance names.
#
# JSON containing the job_instance, job_run data, and output_path are
# sent to stdout as JSONL; progress information is sent to stderr.
#
# Prep:
#
# - export GOCD_TOKEN and GOCD_SERVER
# - Run ./gocd-history.sh and direct the output to some history.jsonl file
#
# Usage:
#
#   $0 <history.jsonl> <output_base_dir> <perl_regex>

set -eu -o pipefail

job_history_jsonl="$1"
output_base="$2"
regex="$3"

function call_gocd {
    url="$1"
    curl -sS -H "Authorization: bearer $GOCD_TOKEN" -H "Accept: application/vnd.go.cd.v1+json" -- "$url"
}

function job_json_to_instance_id {
    jq -r '"\(.pipeline_name)/\(.pipeline_counter)/\(.stage_name)/\(.stage_counter)/\(.name)"'
}

output_relpath="cruise-output/console.log"

cat -- "$job_history_jsonl" | while IFS= read -r job_line; do
    if [[ "$(echo "$job_line" | jq -r '.result')" != "Failed" ]]; then
        continue
    fi

    job_instance=$(echo "$job_line" | job_json_to_instance_id)
    echo >&2 "Found failed job: $job_instance"

    output_file="$output_base/$job_instance/$output_relpath"
    if [[ -f "$output_file" ]]; then
        echo >&2 "Already have cached output"
        output="$(cat -- "$output_file")"
    else
        echo >&2 "Fetching job output"
        mkdir -p -- "$(dirname -- "$output_file")"
        output="$(call_gocd "${GOCD_SERVER}/go/files/${job_instance}/${output_relpath}")"
        echo "$output" > "$output_file" || {
            echo >&2 "Failed to fetch properly; deleting output file"
            rm -rf -- "$output_file"
        }
    fi

    matching_lines="$(echo "$output" | grep -o -P -e "$regex" || true)"
    if [[ -n "$matching_lines" ]]; then
        echo >&2 "Matched!"
        jq --null-input -c \
           --arg job_instance "$job_instance" \
           --argjson job_run "$job_line" \
           --arg output_path "$output_file" \
           '{$job_instance, $job_run, $output_path}'
    fi
done
echo >&2 "Finished."
