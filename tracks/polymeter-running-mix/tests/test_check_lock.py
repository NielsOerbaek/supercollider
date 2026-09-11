import numpy as np
import audio
import check_lock

SR = 48000


def burst_stem(start_eighth, seconds, offset_ms=0.0, drift_ms=0.0, tuplets=False, seed=0):
    """Noise-burst hits on every global eighth inside the stem, optionally
    shifted by a constant offset and by a drift growing linearly to drift_ms."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    x = rng.standard_normal(n) * 0.002                         # a noise floor
    s0 = audio.eighth_to_sample(start_eighth)
    m = np.arange(start_eighth + 1, start_eighth + int(seconds * 340 / 60) - 1, dtype=np.int64)
    pos = audio.eighth_to_sample(m) - s0
    pos = pos + np.round((offset_ms + drift_ms * pos / n) * SR / 1000).astype(np.int64)
    burst = rng.standard_normal(48) * np.exp(-np.arange(48) / 10)
    for p in pos[(pos >= 0) & (pos < n - 48)]:
        x[p:p + 48] += burst
        if tuplets:                                            # a triplet hit a third later
            q = p + int(8470.6 / 3)
            if q < n - 48:
                x[q:q + 48] += burst * 0.7
    return x


def test_on_grid_stem_passes():
    x = burst_stem(1360, 60)
    rep = check_lock.stem_report(x, SR, 1360)
    res = check_lock.evaluate(rep)
    assert res["ok"], res
    assert abs(res["median_ms"]) < 0.5
    assert abs(res["drift_ms"]) < 0.2


def test_tuplets_and_noise_do_not_move_the_grid():
    res = check_lock.evaluate(check_lock.stem_report(burst_stem(4696, 60, tuplets=True), SR, 4696))
    assert res["ok"], res
    assert abs(res["median_ms"]) < 0.5


def test_constant_attack_offset_is_fine():
    res = check_lock.evaluate(check_lock.stem_report(burst_stem(0, 60, offset_ms=3.0), SR, 0))
    assert res["ok"], res
    assert abs(res["median_ms"] - 3.0) < 0.5


def test_drift_fails():
    res = check_lock.evaluate(check_lock.stem_report(burst_stem(0, 60, drift_ms=2.5), SR, 0))
    assert not res["ok"]
    assert res["drift_ms"] > 1.5


def test_stem_off_the_grid_fails():
    res = check_lock.evaluate(check_lock.stem_report(burst_stem(0, 60, offset_ms=50.0), SR, 0))
    assert not res["ok"]
