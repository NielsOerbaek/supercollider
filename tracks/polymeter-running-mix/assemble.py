"""Assemble the running mix: place every stem on the global eighth grid.

A stem's sample 0 is its part's grid zero (render-part.scd starts each synth
at score time 0), so placing it at the sample of its start eighth locks its
whole internal clock to the global grid. Stems are cut to their timeline
length, gained, faded (equal power) and summed in float32 — the sum may
exceed full scale; make_mp3.sh's gain and limiter deal with that.

Usage: python3 assemble.py [timeline.json] [stems/] [render.wav]
"""
import json
import sys
import warnings
from pathlib import Path

import numpy as np

from audio import eighth_to_sample, read_wav, write_wav_float


def assemble(timeline, stem_dir):
    sr = timeline["sampleRate"]
    num, den = timeline["eighthNum"], timeline["eighthDen"]
    at = lambda n: eighth_to_sample(n, sr, num, den)
    parts = timeline["parts"]
    out = np.zeros((max(at(p["start"] + p["length"]) for p in parts), 2), np.float32)
    for p in parts:
        stem, stem_sr = read_wav(Path(stem_dir) / f"{p['name']}.wav")
        if stem_sr != sr:
            raise ValueError(f"stem {p['name']}: {stem_sr} Hz, expected {sr}")
        if stem.shape[1] == 1:
            stem = np.repeat(stem, 2, axis=1)
        s0, s1 = at(p["start"]), at(p["start"] + p["length"])
        n = s1 - s0
        if len(stem) < n:
            warnings.warn(f"stem {p['name']} is shorter than its timeline length "
                          f"({len(stem)} < {n} samples); padding with silence")
            stem = np.vstack([stem, np.zeros((n - len(stem), 2), np.float32)])
        seg = stem[:n].copy()
        seg *= np.float32(10 ** (p.get("gainDb", 0) / 20))
        fi = at(p.get("fadeIn", 0))
        if fi:
            seg[:fi] *= np.sin(0.5 * np.pi * np.arange(fi) / fi).astype(np.float32)[:, None]
        fo = at(p.get("fadeOut", 0))
        if fo:
            seg[n - fo:] *= np.cos(0.5 * np.pi * np.linspace(0, 1, fo)).astype(np.float32)[:, None]
        out[s0:s1] += seg
    return out


def main(argv):
    tl_path = Path(argv[1] if len(argv) > 1 else "timeline.json")
    stem_dir = Path(argv[2] if len(argv) > 2 else "stems")
    out_path = Path(argv[3] if len(argv) > 3 else "render.wav")
    timeline = json.loads(tl_path.read_text())
    mix = assemble(timeline, stem_dir)
    write_wav_float(out_path, mix, timeline["sampleRate"])
    secs = len(mix) / timeline["sampleRate"]
    print(f"assembled {len(timeline['parts'])} stems -> {out_path} "
          f"({int(secs // 60)}:{secs % 60:04.1f}, peak {np.abs(mix).max():.3f})")


if __name__ == "__main__":
    main(sys.argv)
