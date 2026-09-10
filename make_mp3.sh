#!/usr/bin/env bash
# Render a track to a loudness-normalized, tagged, timestamped mp3.
#
# Usage: ./make_mp3.sh [tracks/<name>]     (default: tracks/polymeter-001)
#
# A track directory needs:
#   render.scd   — offline renderer; must write render.wav next to itself
#   track.conf   — optional mp3 metadata (title/artist/album/comment)
# Output lands in <track>/renders/<name>_<timestamp>_<commit>.mp3
set -euo pipefail
cd "$(dirname "$0")"

track="${1:-tracks/polymeter-001}"
track="${track%/}"
name=$(basename "$track")
[ -f "$track/render.scd" ] || { echo "error: no render.scd in $track" >&2; exit 1; }

# metadata defaults; track.conf overrides any of them
title="$name"
artist=""
album="SuperCollider Sketches"
comment=""
[ -f "$track/track.conf" ] && source "$track/track.conf"

stamp=$(date +%Y%m%d-%H%M%S)
# tag every render with the commit it was built from, so an mp3 can always be
# traced back to exact source. A "-dirty" suffix means the working tree had
# uncommitted changes and the render does NOT correspond to that commit.
hash=$(git rev-parse --short HEAD 2>/dev/null || echo nogit)
git diff --quiet HEAD -- 2>/dev/null || hash="${hash}-dirty"
mkdir -p "$track/renders"
out="$track/renders/${name}_${stamp}_${hash}.mp3"
wav="$track/render.wav"

QT_QPA_PLATFORM=offscreen sclang "$track/render.scd"

# linear loudness normalization to -16 LUFS: measure integrated loudness,
# then apply one flat gain (no dynamic processing), with a safety limiter
measured=$(ffmpeg -hide_banner -i "$wav" -af ebur128 -f null - 2>&1 \
	| grep -A4 'Summary:' | awk '/I:/{print $2}')
gain=$(python3 -c "print(f'{-16 - (${measured}):.1f}')")
echo "measured ${measured} LUFS -> gain ${gain} dB"

ffmpeg -hide_banner -loglevel error -i "$wav" -codec:a libmp3lame -q:a 2 \
	-af "volume=${gain}dB,alimiter=limit=0.98:level=false" \
	-metadata title="$title" -metadata artist="$artist" -metadata album="$album" \
	-metadata date="$(date +%Y)" -metadata comment="$comment — render $stamp" "$out"
rm -f "$wav" "$track/nrt.osc"

echo "wrote $out"
