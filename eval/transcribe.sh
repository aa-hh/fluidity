#!/bin/sh
# Run each speech model over the test clips with FluidAudio's CLI.
#
# Usage: sh eval/transcribe.sh [data dir] [models...]
#   defaults: /Volumes/Space/fluidity-data, v2 v3
#   models: any fluidaudiocli --model-version (v2, v3, ultra, ...), nemotron-en,
#   nemotron-ml (language detected), whisper-turbo (needs whisperkit-cli;
#   WHISPERKIT_MODELS sets where its model is downloaded).
# Needs FLUIDAUDIO_CLI, or fluidaudiocli built in ~/Projects/FluidAudio.
# Writes test/transcripts/<model>/<id>.json (full CLI output) and <id>.txt.
# Clips already transcribed are skipped, so a stopped run can resume.
set -eu

data=${1:-/Volumes/Space/fluidity-data}
[ "$#" -gt 0 ] && shift
models=${*:-v2 v3}
cli=${FLUIDAUDIO_CLI:-$HOME/Projects/FluidAudio/.build/release/fluidaudiocli}

test_dir="$data/test"
for model in $models; do
    out="$test_dir/transcripts/$model"
    mkdir -p "$out"
    if [ "$model" = whisper-turbo ]; then
        # One call over the whole folder so the model loads once. One worker:
        # more join a long clip's pieces out of order.
        whisperkit-cli transcribe --model large-v3-v20240930_turbo \
            ${WHISPERKIT_MODELS:+--download-model-path "$WHISPERKIT_MODELS"} \
            --audio-folder "$test_dir" --concurrent-worker-count 1 --report --report-path "$out" > /dev/null 2>&1 || true
        python3 -I -c 'import json,sys,os
for l in open(sys.argv[1]):
    r = json.loads(l); rep = os.path.join(sys.argv[2], os.path.splitext(r["wav"])[0] + ".json")
    if os.path.exists(rep): open(os.path.join(sys.argv[2], r["id"] + ".txt"), "w").write(json.load(open(rep))["text"].strip() + "\n")' \
            "$test_dir/clips.jsonl" "$out"
        echo "$model: $(ls "$out"/*.txt 2>/dev/null | wc -l | tr -d ' ') clips transcribed"
        continue
    fi
    [ -x "$cli" ] || { echo "transcribe.sh: no fluidaudiocli at $cli" >&2; exit 1; }
    python3 -I -c 'import json,sys
for l in open(sys.argv[1]): r=json.loads(l); print(r["id"], r["wav"])' "$test_dir/clips.jsonl" |
    while read -r id wav; do
        [ -s "$out/$id.txt" ] && continue
        case $model in
        nemotron-en|nemotron-ml)
            # Streaming models print the transcript to the log, no JSON; 1120 ms chunks.
            if [ "$model" = nemotron-en ]; then set -- nemotron-transcribe --chunk 1120
            else set -- nemotron-multilingual-transcribe --chunk-ms 1120 --language auto; fi
            "$cli" "$@" --input "$test_dir/$wav" 2>&1 | sed -n 's/.*Transcript:  //p' > "$out/$id.txt" ;;
        *)
            "$cli" transcribe "$test_dir/$wav" --model-version "$model" --output-json "$out/$id.json" > /dev/null 2>&1 \
                && python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))["text"])' "$out/$id.json" > "$out/$id.txt" ;;
        esac
        [ -s "$out/$id.txt" ] || { rm -f "$out/$id.txt"; echo "transcribe.sh: $model failed on $wav" >&2; }
    done
    echo "$model: $(ls "$out"/*.txt 2>/dev/null | wc -l | tr -d ' ') clips transcribed"
done
