# dev

## Purpose

Developer tooling that keeps running on this Mac after the session that set it
up: launchd jobs, with their install scripts and one purge script.

## Rules

- **Every job's label starts `rillo.dev.`** so `purge.sh` finds and removes it.
- **A new job is added to nothing else:** `purge.sh` removes by label prefix,
  so it needs no edit when a job is added.

## Map

- `cloud-sync.plist.template` → launchd job running `eval/cloud_sync.py` every three hours.
- `install-cloud-sync.sh` → fills in the template and loads the job.
- `purge.sh` → unloads and deletes every `rillo.dev.*` job.
