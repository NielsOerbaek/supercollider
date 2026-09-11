#!/usr/bin/env bash
# render.sh — the running mix's renderer, called by make_mp3.sh.
# Renders every stem whose graph, renderer or length changed (in parallel),
# assembles them on the global grid into render.wav, then checks the lock.
# A stem is cached in stems/<part>.wav with a hash of its inputs beside it.
#
# Usage: ./render.sh              all stems, then assemble + checks
#        ./render.sh 003a 001     only these stems (if changed), then stop
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stems
want=("$@")

mapfile -t jobs < <(python3 -c '
import json
t = json.load(open("timeline.json"))
for p in t["parts"]:
    # render the Limiter latency on top, so the stem still covers its whole
    # length once assemble.py has trimmed that latency off the front
    secs = p["length"] * t["eighthNum"] / t["eighthDen"] + t.get("latencySamples", 0) / t["sampleRate"]
    print(p["name"], "%.6f" % secs)
')

pids=()
for job in "${jobs[@]}"; do
	read -r part secs <<<"$job"
	if [ "${#want[@]}" -gt 0 ] && [[ " ${want[*]} " != *" $part "* ]]; then
		continue
	fi
	hash="$(cat "run-$part.scd" render-part.scd | sha256sum | cut -d' ' -f1)-$secs"
	if [ -f "stems/$part.wav" ] && [ "$(cat "stems/$part.hash" 2>/dev/null)" = "$hash" ]; then
		echo "stem $part: up to date"
		continue
	fi
	echo "stem $part: rendering ${secs}s"
	(
		QT_QPA_PLATFORM=offscreen timeout 1800 sclang render-part.scd "$part" "$secs" \
			</dev/null >"stems/$part.log" 2>&1 || true
		if grep -q NRT_DONE "stems/$part.log"; then
			echo "$hash" >"stems/$part.hash"
		else
			rm -f "stems/$part.hash"
			echo "stem $part: FAILED (see stems/$part.log)" >&2
			exit 1
		fi
	) &
	pids+=($!)
done

fail=0
for pid in "${pids[@]}"; do wait "$pid" || fail=1; done
[ "$fail" = 0 ] || { echo "error: stem render failed" >&2; exit 1; }
[ "${#want[@]}" -gt 0 ] && exit 0

python3 assemble.py timeline.json stems render.wav
python3 stem_loudness.py timeline.json stems || echo "warning: a stem is off its loudness target" >&2
python3 check_lock.py timeline.json stems
