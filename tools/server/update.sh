#!/usr/bin/env bash
# Pull the newest commits and publish what changed: the page and each track are
# copied out of the repo into the Caddy web root. Nothing else in the web root
# is touched — the podcast files and feed.xml live there too.
set -euo pipefail
base=/opt/mix.raakode.dk
cd "$base/repo"
git fetch -q --depth 50 origin main
before=$(git rev-parse --short HEAD)
git merge -q --ff-only origin/main
after=$(git rev-parse --short HEAD)
mkdir -p "$base/public/tracks"
shopt -s nullglob
copied=0
for mp3 in tracks/*/latest.mp3; do
	name=$(basename "$(dirname "$mp3")")
	dest="$base/public/tracks/$name.mp3"
	if ! cmp -s "$mp3" "$dest"; then cp -f "$mp3" "$dest"; copied=$((copied+1)); fi
done
if [ -f site/index.html ]; then cp -f site/index.html "$base/public/index.html"; fi
if [ "$before" = "$after" ]; then
	echo "already up to date at $after ($copied file(s) refreshed)"
else
	echo "pulled $before -> $after: $(git log -1 --format=%s) ($copied track(s) updated)"
fi
