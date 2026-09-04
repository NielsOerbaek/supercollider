#!/usr/bin/env bash
# Render a track to a loudness-normalized, tagged, timestamped mp3.
#
# Usage: ./make_mp3.sh [tracks/<name>]     (default: tracks/polymeter)
#
# A track directory needs:
#   render.scd   — offline renderer; must write render.wav next to itself
#   track.conf   — optional mp3 metadata (title/artist/album/comment)
# Output lands in <track>/renders/<name>_<timestamp>.mp3
set -euo pipefail
cd "$(dirname "$0")"

track="${1:-tracks/polymeter}"
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
mkdir -p "$track/renders"
out="$track/renders/${name}_${stamp}.mp3"
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
