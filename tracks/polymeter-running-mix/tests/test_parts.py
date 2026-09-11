"""Acceptance tests for each part's stem: length, no clipping, beat lock,
and a few measurable facts about its sections (spec, "Parts").

Section facts are band levels over ranges of the part's own bars. The
thresholds are deliberately loose: they catch a section that is missing or
in the wrong place, not a mix preference."""
import json
import numpy as np
import pytest
import audio
import check_lock
from conftest import TRACK

_TIMELINE = json.loads((TRACK / "timeline.json").read_text())
TL = {p["name"]: p for p in _TIMELINE["parts"]}
LATENCY = _TIMELINE.get("latencySamples", 0)


def stem(part):
    x, sr = audio.read_wav(TRACK / "stems" / f"{part}.wav")
    return x.mean(axis=1), sr


def level(part, e8_from, e8_to, lo=0.0, hi=None, side=False):
    """Band level of a span of eighths. side=True measures L-R instead of
    L+R: sources mixed in mono (drums, bass, pink wash) cancel there."""
    x, sr = audio.read_wav(TRACK / "stems" / f"{part}.wav")
    sig = (x[:, 0] - x[:, 1]) / 2 if side else x.mean(axis=1)
    a, b = audio.eighth_to_sample(e8_from), audio.eighth_to_sample(e8_to)
    return audio.band_rms_db(sig[a:b], sr, lo, hi)


@pytest.mark.parametrize("part", list(TL))
def test_stem_length_and_no_clipping(part):
    mono, sr = stem(part)
    x, _ = audio.read_wav(TRACK / "stems" / f"{part}.wav")
    want = audio.eighth_to_sample(TL[part]["length"])
    assert abs(len(x) - want) <= sr // 10                      # within 0.1 s
    assert int((np.abs(x) >= 0.999).sum()) == 0


@pytest.mark.parametrize("part", [n for n, p in TL.items() if p.get("lockCheck", "fold") == "fold"])
def test_stem_beat_lock(part):
    mono, sr = stem(part)
    res = check_lock.evaluate(check_lock.stem_report(mono[LATENCY:], sr, TL[part]["start"]))
    assert res["ok"], res


# ---- 003a (4/4, bar = 8 eighths) ----
# The build is measured above 300 Hz: voice 1's drone pluck (41-164 Hz, with a
# sub-octave sine) carries most of the energy, so eight lighter, higher voices
# arriving on top barely move the full-band level (+0.5..1.6 dB measured).
# The duo comparison stays full-band.
def test_003a_builds_then_thins_to_the_duo():
    alone = level("003a", 0, 11 * 8, lo=300)            # voice 1 alone
    full_hi = level("003a", 100 * 8, 126 * 8, lo=300)   # all nine
    full = level("003a", 100 * 8, 126 * 8)
    duo = level("003a", 156 * 8, 168 * 8)               # glass + tick
    assert full_hi - alone >= 10
    assert full - duo >= 6


# ---- 003b (4/4) ----
def test_003b_phasing_hold_then_duo():
    alone = level("003b", 0, 7 * 8, lo=300)
    full_hi = level("003b", 70 * 8, 110 * 8, lo=300)
    full = level("003b", 70 * 8, 110 * 8)
    duo = level("003b", 140 * 8, 150 * 8)
    assert full_hi - alone >= 10
    assert full - duo >= 6


# ---- 001 (eighths) ----
def test_001_cycle3_breakdown_is_drums_and_bass():
    # the arp and the harmonies are the only stereo content in 001 (drums,
    # bass and pink wash are mono), so the side channel is them alone; skip
    # the first ~7 s of the breakdown so their reverb tails have gone
    before = level("001", 1100, 1260, side=True)
    breakdown = level("001", 1300, 1400, side=True)
    assert before - breakdown >= 10


def test_001_ends_on_the_arp_tail():
    full = level("001", 1900, 2040, hi=150)      # before the 12 s outro fade
    tail = level("001", 2150, 2240, hi=150)
    assert full - tail >= 15


# ---- 002 (12/8, bar = 12 eighths) ----
def test_002_break_drops_the_kit():
    # glitch clicks and the crushers keep some top end in the break, so the
    # margin is modest; a missing break would show ~0 dB
    drop = level("002", 112 * 12, 120 * 12, lo=6000)
    brk = level("002", 121 * 12, 127 * 12, lo=6000)
    assert drop - brk >= 4


def test_002_second_drop_returns():
    brk = level("002", 121 * 12, 127 * 12, lo=6000)
    b2 = level("002", 140 * 12, 180 * 12, lo=6000)
    assert b2 - brk >= 4


# ---- 004 (15/4, bar = 30 eighths) ----
def test_004_drop_removes_the_kit():
    # the driven clap and the dirt arc's crush trace keep some top end in
    # the drop; a kit that failed to cut would show ~0 dB
    kit = level("004", 31 * 30, 43 * 30, lo=6000)
    drop = level("004", 44 * 30, 50 * 30, lo=6000)
    assert kit - drop >= 4


def test_004_outro_drops_the_low_end():
    build = level("004", 85 * 30, 91 * 30, hi=120)
    outro = level("004", 91 * 30 + 15, 93 * 30, hi=120)
    assert build - outro >= 10


def test_003_voice_clocks_do_not_drift(tmp_path):
    """003a/003b are skipped by the grid fold (their attacks change as voices
    come and go), so test the clocks their voices actually run on: Impulse at
    n hits per bar, over a full stem's length."""
    import os, subprocess
    graph = tmp_path / "clk.scd"
    graph.write_text("{ var barDur = 4 / (170/60); [Impulse.ar(3 / barDur), Impulse.ar(9 / barDur)] * 0.5 }\n")
    out = tmp_path / "clk.wav"
    r = subprocess.run(["sclang", str(TRACK / "render-part.scd"), "clk", "265.0", str(graph), str(out)],
                       capture_output=True, text=True, timeout=600,
                       env={**os.environ, "QT_QPA_PLATFORM": "offscreen"})
    assert "NRT_DONE" in r.stdout, r.stdout[-2000:]
    x, sr = audio.read_wav(out)
    bar = 4 / (170 / 60) * sr
    for ch, n in ((0, 3), (1, 9)):
        hits = np.flatnonzero(x[:, ch] > 0.25)
        err = hits - np.arange(len(hits)) * bar / n
        assert len(hits) > 100 and np.abs(err).max() <= 2.0, (n, err[-5:])
