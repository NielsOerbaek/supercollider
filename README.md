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
`tracks/<name>/renders/`.

A track may instead provide an executable `render.sh`, which `make_mp3.sh`
runs in place of `render.scd`; it must leave `render.wav` in the track
directory. polymeter-running-mix uses this to render its parts as stems
(cached, in parallel) and assemble them. The filename carries the short commit hash the
render was built from, suffixed `-dirty` if the working tree had uncommitted
changes — so commit before rendering if you want the mp3 to be traceable. With no argument it renders `tracks/polymeter-001`.

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

- **polymeter-001** — drums in 5/4, bass in 7/4, arpeggio in 9/8, clap in 4/4,
  all in just intonation on E; after Thor Magnusson's *Drummer* (2006).
- **polymeter-002** — 12/8 glitch groove at 170: syncopated kit into a
  half-time jungle drop, fat slide bass, FM-pluck motif, blips in 5/8,
  a distorted strummed-guitar wall, and a bitcrush disintegration arc;
  just intonation on E.
- **polymeter-003** — a rhythmicon at 170: nine plucky voices, voice n
  playing n hits per bar on the first n harmonics of E, entering one by
  one and leaving FIFO; stated twice — first locked to the downbeat,
  then with rates floored to powers of two so the patterns phase.
- **polymeter-004** — 15/4 at 170: one 15-quarter bar heard two ways at
  once. The bass (polymeter-003's Karplus-Strong pluck, dropped to E1)
  carves it 5+5+5, accenting 1, 2-and and 3-and of each cell with ghost
  notes in the tail; the bitcrushed polymeter-002 kit puts a kick on every
  quarter, hat accents every third, and a backbeat every second — beats 2
  4 6 8 10 12 14, plus 15 to stop an even pattern flipping in an odd bar.
  Four groupings at once: 1, 2, 3 and 5 against a 15-cycle. polymeter-003's
  deep pluck pins beat 1 and 7-and, and two of its lighter voices arp on
  top in 6 and 8 steps — the 6 locking to the drum groups, the 8 rotating
  against the bar and coming round every fourth. All of it E minor
  pentatonic in just intonation, resolving nowhere.
- **polymeter-running-mix** — 30 minutes at 170 for running: 003's first
  section slowed into a warm-up, 001 run for three cycles, 003's second
  section as an interlude with a long phasing hold, 002 stretched with a
  second drop, and 004 stretched to 95 bars, handing over through a 12/8
  against 15/4 crossover. Each part is a forked graph rendered as a stem and
  placed on one sample-exact eighth-note grid, so the beat never moves.
