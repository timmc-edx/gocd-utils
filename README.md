# GOCD Utilities

A few shell scripts for working with the GoCD API.

API reference: https://api.gocd.org/

## Querying jobs by log output

1. Export environment variables `GOCD_TOKEN` (a personal token
   generated in the GoCD UI) and `GOCD_SERVER` (`https://domain`)
2. Retrieve the run history for the job:
   ```
   ./job-history.sh mypipeline/mystage/myjob > ~/cached/gocd/myjob-history.jsonl
   ```
3. Fetch job log contents and identify the ones with a certain pattern in the logs:
   ```
   ./job-identify-matching-output.sh ~/cached/gocd/myjob-history.jsonl \
       ~/cached/gocd/artifacts 'some-[0-9]+-pattern' \
       > ~/cached/gocd/myjob-matched.jsonl
   ```

This data will allow you to build a histogram of when these failures are occurring:

```
cat ~/cached/gocd/myjob-matched.jsonl | while IFS= read -r json; do
    seconds=$(echo "$json" | jq .job_run.scheduled_date | head -c-4)
    date -d @$seconds --utc +"%Y-%m"
done | sort | uniq -c

      1 2023-01
      6 2023-02
      2 2023-03
      2 2023-04
```
