import json
import numpy as np
import pytest
import audio
import assemble


def click_stem(path, start, length):
    """A stem with a one-sample click on each of its own eighths, as a
    SuperCollider Impulse clock started at sample 0 would produce."""
    n = audio.eighth_to_sample(start + length) - audio.eighth_to_sample(start)
    x = np.zeros((n, 2), np.float32)
    k = np.arange(0, length, dtype=np.int64)
    pos = np.floor(k * 48000 * 60 / 340).astype(np.int64)   # a clock's own ticks
    x[pos] = 0.5
    audio.write_wav_float(path, x, 48000)


def timeline(parts):
    return {"sampleRate": 48000, "eighthNum": 60, "eighthDen": 340, "parts": parts}


def part(name, start, length, **kw):
    p = {"name": name, "start": start, "length": length,
         "gainDb": 0, "fadeIn": 0, "fadeOut": 0, "targetLufs": -16}
    p.update(kw)
    return p


def test_clicks_from_every_stem_land_on_the_global_grid(tmp_path):
    parts = [part("a", 0, 1488), part("b", 1360, 400)]
    for p in parts:
        click_stem(tmp_path / f"{p['name']}.wav", p["start"], p["length"])
    out = assemble.assemble(timeline(parts), tmp_path)
    hits = np.flatnonzero(np.abs(out[:, 0]) > 0.25)
    grid = audio.eighth_to_sample(np.arange(0, 1760, dtype=np.int64))
    nearest = np.abs(hits[:, None] - grid[None, :]).min(axis=1)
    assert nearest.max() <= 1


def test_overlap_sums(tmp_path):
    parts = [part("a", 0, 1488), part("b", 1360, 400)]
    for p in parts:
        click_stem(tmp_path / f"{p['name']}.wav", p["start"], p["length"])
    out = assemble.assemble(timeline(parts), tmp_path)
    s = audio.eighth_to_sample(1400)
    window = out[s - 2:s + 3, 0]
    assert window.max() >= 0.99          # both stems clicked on this eighth


def test_length_is_the_end_of_the_last_part(tmp_path):
    parts = [part("a", 0, 100), part("b", 60, 100)]
    for p in parts:
        click_stem(tmp_path / f"{p['name']}.wav", p["start"], p["length"])
    out = assemble.assemble(timeline(parts), tmp_path)
    assert len(out) == audio.eighth_to_sample(160)


def test_gain_and_equal_power_fade_out(tmp_path):
    n = audio.eighth_to_sample(64)
    audio.write_wav_float(tmp_path / "a.wav", np.ones((n, 2), np.float32), 48000)
    out = assemble.assemble(timeline([part("a", 0, 64, gainDb=-6, fadeOut=16)]), tmp_path)
    g = 10 ** (-6 / 20)
    assert abs(out[0, 0] - g) < 1e-5
    fo = audio.eighth_to_sample(16)
    mid = n - fo + fo // 2
    assert abs(out[mid, 0] - g * np.cos(np.pi / 4)) < 2e-3
    assert abs(out[-1, 0]) < 1e-5


def test_stem_longer_than_its_length_is_truncated(tmp_path):
    n = audio.eighth_to_sample(80)
    audio.write_wav_float(tmp_path / "a.wav", np.ones((n, 2), np.float32), 48000)
    out = assemble.assemble(timeline([part("a", 0, 64)]), tmp_path)
    assert len(out) == audio.eighth_to_sample(64)


def test_short_stem_is_padded_with_a_warning(tmp_path):
    n = audio.eighth_to_sample(32)
    audio.write_wav_float(tmp_path / "a.wav", np.ones((n, 2), np.float32), 48000)
    with pytest.warns(UserWarning, match="shorter"):
        out = assemble.assemble(timeline([part("a", 0, 64)]), tmp_path)
    assert len(out) == audio.eighth_to_sample(64)
    assert out[-1, 0] == 0


def test_cli_writes_a_float_wav(tmp_path):
    import subprocess, sys
    from conftest import TRACK
    click_stem(tmp_path / "a.wav", 0, 64)
    (tmp_path / "t.json").write_text(json.dumps(timeline([part("a", 0, 64)])))
    r = subprocess.run([sys.executable, str(TRACK / "assemble.py"), str(tmp_path / "t.json"),
                        str(tmp_path), str(tmp_path / "out.wav")], capture_output=True, text=True)
    assert r.returncode == 0, r.stderr
    y, sr = audio.read_wav(tmp_path / "out.wav")
    assert sr == 48000 and len(y) == audio.eighth_to_sample(64)
