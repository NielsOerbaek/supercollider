# SuperCollider tracks

One directory per track under `tracks/`, each self-contained:

```
tracks/<name>/
  <name>.scd        the live player — open in scide, Ctrl+Enter to play, Ctrl+. to stop
  <name>-graph.scd  the synth graph (single source of truth — edit sounds/patterns here)
  render.scd        offline renderer (writes render.wav; keep its bpm/length
                    constants in sync with the graph)
  track.conf        mp3 metadata (title / artist / album / comment)
  renders/          timestamped mp3s
```

## Rendering

```
./make_mp3.sh tracks/<name>
```

Renders offline (no audio hardware needed), normalizes to −16 LUFS with a
flat gain, tags it from `track.conf`, and drops a timestamped mp3 in
`tracks/<name>/renders/`. With no argument it renders `tracks/polymeter`.

Requires `supercollider` and `ffmpeg` (both via apt).

## Tracks

- **polymeter** — drums in 5/4, bass in 7/4, arpeggio in 9/8, clap in 4/4,
  all in just intonation on E; after Thor Magnusson's *Drummer* (2006).
