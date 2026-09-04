# SuperCollider tracks

One directory per track under `tracks/`, each self-contained:

```
tracks/<name>/
  <name>.scd        the live player — open in scide, Ctrl+Enter to play, Ctrl+. to stop
  <name>-graph.scd  the synth graph (single source of truth — edit sounds/patterns here)
  render.scd        offline renderer (writes render.wav; keep its bpm/length
                    constants in sync with the graph)
  track.conf        mp3 metadata (title / artist / album / comment)
  SESSION-LOG.md    transparency log: the human/AI conversation that made
                    the track, with the human's direction quoted verbatim
  renders/          timestamped mp3s
```

These tracks are made in collaboration with Claude (Anthropic's Claude
Fable 5, via Claude Code): musical direction by the human, code by the
model. Each track's `SESSION-LOG.md` records exactly what that direction
was.

## Rendering

```
./make_mp3.sh tracks/<name>
```

Renders offline (no audio hardware needed), normalizes to −16 LUFS with a
flat gain, tags it from `track.conf`, and drops a timestamped mp3 in
`tracks/<name>/renders/`. With no argument it renders `tracks/polymeter`.

## Toolchain & requirements

Everything runs headless — no DAW, no sound card needed for rendering.

- **SuperCollider** (`sudo apt install supercollider`) — `sclang` runs the
  render script; `scsynth -N` (non-realtime mode, invoked via
  `Score.recordNRT`) renders the synth graph sample-accurately to
  `render.wav`, faster than real time. `scide` is the editor for live
  playback. Developed against 3.13.
- **ffmpeg** (`sudo apt install ffmpeg`) — two jobs: measures integrated
  loudness with the `ebur128` filter, then transcodes WAV → mp3
  (`libmp3lame`, VBR `-q:a 2`) applying one flat `volume` gain to hit
  −16 LUFS (no dynamic processing) with an `alimiter` safety, and writes
  the ID3 tags from `track.conf`.
- **python3** — one line of arithmetic in the gain calculation.
- **bash** — `make_mp3.sh` glues the above together.

Pipeline per render:

```
<name>-graph.scd ──(sclang render.scd, scsynth NRT)──> render.wav
render.wav ──(ffmpeg ebur128: measure LUFS)──> gain
render.wav ──(ffmpeg: volume + limiter + lame + tags)──> renders/<name>_<stamp>.mp3
```

Live playback needs working audio (JACK/PipeWire) — on a desktop Ubuntu
with PipeWire, opening `<name>.scd` in `scide` and pressing Ctrl+Enter
just works. Graphs seed their random UGens (`RandSeed`), so offline
renders are bit-for-bit reproducible; note that editing a graph's
structure reshuffles which random stream each UGen draws, so wandering
LFO paths differ between code versions even with the same seed.

## Tracks

- **polymeter** — drums in 5/4, bass in 7/4, arpeggio in 9/8, clap in 4/4,
  all in just intonation on E; after Thor Magnusson's *Drummer* (2006).
- **polymeter-2** — 12/8 glitch groove at 170: syncopated kit into a
  half-time jungle drop, fat slide bass, FM-pluck motif, blips in 5/8,
  a distorted strummed-guitar wall, and a bitcrush disintegration arc;
  just intonation on E.
- **polymeter-3** — a rhythmicon at 170: nine plucky voices, voice n
  playing n hits per bar on the first n harmonics of E, entering one by
  one and leaving FIFO; stated twice — first locked to the downbeat,
  then with rates floored to powers of two so the patterns phase.
