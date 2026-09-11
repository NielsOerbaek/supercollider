import json
import numpy as np
import assemble
import audio
from conftest import TRACK


def test_mix_length_and_loudness_targets():
    tl = json.loads((TRACK / "timeline.json").read_text())
    mix = assemble.assemble(tl, TRACK / "stems")
    secs = len(mix) / tl["sampleRate"]
    assert abs(secs - 1797.53) <= 5.0
    import stem_loudness
    for p in tl["parts"]:
        m = stem_loudness.integrated_lufs(TRACK / "stems" / f"{p['name']}.wav")
        assert abs(m + p["gainDb"] - p["targetLufs"]) <= 1.5, p["name"]
