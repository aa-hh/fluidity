#!/bin/sh
# Run each Parakeet model over the test clips with FluidAudio's CLI.
#
# Usage: sh eval/transcribe.sh [data dir] [models...]
#   defaults: /Volumes/Space/fluidity-data, v2 v3
# Needs FLUIDAUDIO_CLI, or fluidaudiocli built in ~/Projects/FluidAudio.
# Writes test/transcripts/<model>/<id>.json (full CLI output) and <id>.txt.
# Clips already transcribed are skipped, so a stopped run can resume.
set -eu

data=${1:-/Volumes/Space/fluidity-data}
[ "$#" -gt 0 ] && shift
models=${*:-v2 v3}
cli=${FLUIDAUDIO_CLI:-$HOME/Projects/FluidAudio/.build/release/fluidaudiocli}
[ -x "$cli" ] || { echo "transcribe.sh: no fluidaudiocli at $cli" >&2; exit 1; }

test_dir="$data/test"
for model in $models; do
    out="$test_dir/transcripts/$model"
    mkdir -p "$out"
    python3 -I -c 'import json,sys
for l in open(sys.argv[1]): r=json.loads(l); print(r["id"], r["wav"])' "$test_dir/clips.jsonl" |
    while read -r id wav; do
        [ -s "$out/$id.txt" ] && continue
        "$cli" transcribe "$test_dir/$wav" --model-version "$model" --output-json "$out/$id.json" > /dev/null 2>&1 \
            || { echo "transcribe.sh: $model failed on $wav" >&2; continue; }
        python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))["text"])' "$out/$id.json" > "$out/$id.txt"
    done
    echo "$model: $(ls "$out"/*.txt 2>/dev/null | wc -l | tr -d ' ') clips transcribed"
done
