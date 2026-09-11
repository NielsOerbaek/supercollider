import os
import subprocess
import numpy as np
import audio
from conftest import TRACK


def test_stem_sample_zero_is_grid_zero(tmp_path):
    graph = tmp_path / "grid.scd"
    graph.write_text("{ (Impulse.ar(170 / 60 * 2) * 0.8) ! 2 }\n")
    out = tmp_path / "grid.wav"
    r = subprocess.run(["sclang", str(TRACK / "render-part.scd"), "gridtest", "2.0",
                        str(graph), str(out)], capture_output=True, text=True, timeout=180,
                       env={**os.environ, "QT_QPA_PLATFORM": "offscreen"})
    assert "NRT_DONE" in r.stdout, r.stdout[-2000:]
    x, sr = audio.read_wav(out)
    assert sr == 48000 and x.shape[1] == 2
    hits = np.flatnonzero(x[:, 0] > 0.4)
    assert hits[0] == 0                                    # grid zero is sample 0
    exact = np.arange(1, 10) * 48000 * 60 / 340
    assert np.all(np.abs(hits[1:10] - exact) <= 1.0)       # the clock is the grid
