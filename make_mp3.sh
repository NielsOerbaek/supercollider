#!/usr/bin/env bash
# Render a track to a loudness-normalized, tagged, timestamped mp3.
#
# Usage: ./make_mp3.sh [tracks/<name>]     (default: tracks/polymeter-001)
#
# A track directory needs:
#   render.sh    — optional; if present and executable it is used instead of
#                  render.scd, and must leave render.wav in the track directory
#   render.scd   — offline renderer; must write render.wav next to itself
#   track.conf   — optional mp3 metadata (title/artist/album/comment)
# Output lands in <track>/renders/<name>_<timestamp>_<commit>.mp3
set -euo pipefail
cd "$(dirname "$0")"

track="${1:-tracks/polymeter-001}"
track="${track%/}"
name=$(basename "$track")
# a track renders either through its own render.sh (which must leave
# render.wav in the track directory) or through render.scd
if [ -x "$track/render.sh" ]; then
	renderer="$track/render.sh"
elif [ -f "$track/render.scd" ]; then
	renderer=""
else
	echo "error: no render.sh or render.scd in $track" >&2; exit 1
fi

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

if [ -n "$renderer" ]; then
	"$renderer"
else
	QT_QPA_PLATFORM=offscreen sclang "$track/render.scd"
fi

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
