#!/usr/bin/env bash
# deploy-mix.sh — publish the newest render of every track to mix.raakode.dk.
#
# Builds site/index.html from the tracks' own metadata, then uploads it and
# each tracks/<name>/latest.mp3 to the Caddy web root on the box. Nothing else
# in that directory is touched: the podcast files and feed.xml live there too.
set -euo pipefail
cd "$(dirname "$0")/.."

host=${MIX_HOST:-box}
root=/opt/mix.raakode.dk/public

python3 tools/build_site.py

ssh "$host" "mkdir -p $root/tracks"
for mp3 in tracks/*/latest.mp3; do
	name=$(basename "$(dirname "$mp3")")
	echo "uploading $name"
	scp -q "$mp3" "$host:$root/tracks/$name.mp3"
done
scp -q site/index.html "$host:$root/index.html"

echo "published to https://mix.raakode.dk/"
