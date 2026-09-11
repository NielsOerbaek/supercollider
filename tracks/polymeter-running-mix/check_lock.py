"""Beat-lock check for the running mix's stems.

For each 20 s window of a stem, fold its onset envelope onto the global
eighth grid: sum the envelope at every grid point shifted by a trial lag,
for lags from -5 to +15 ms, and keep the lag that scores highest. Hits that
sit on the grid (plus their attack) pile up at one lag; sixteenths, triplets
and noise spread out. A locked stem keeps the same lag from its first window
to its last. Drift is the fitted change of that lag across the stem.

Parts marked "lockCheck": "clock" in timeline.json are skipped: 003's
rhythmicon voices change attack character as they enter and leave (a 1.8 s
sine bloom early, 1 ms glass ticks late), which moves the fold's peak without
any timing change. Their clocks are tested directly instead
(tests/test_parts.py::test_003_voice_clocks_do_not_drift).

Usage: python3 check_lock.py [timeline.json] [stems/]   (exit 1 on failure)
"""
import json
import sys
from pathlib import Path

import numpy as np

from audio import eighth_to_sample, read_wav


def onset_envelope(mono):
    """Rectified first difference, smoothed over 0.5 ms: jumps at transients."""
    d = np.abs(np.diff(mono, prepend=mono[:1])).astype(np.float64)
    k = 24
    c = np.concatenate([[0.0], np.cumsum(d)])
    env = (c[k:] - c[:-k]) / k
    return np.concatenate([env, np.zeros(k - 1)])


def window_lag(env, sr, start_eighth, a, b, num=60, den=340):
    lags = np.arange(-int(0.005 * sr), int(0.015 * sr) + 1)
    s0 = eighth_to_sample(start_eighth, sr, num, den)
    per = sr * num / den
    m = np.arange(int(np.ceil((s0 + a) / per)) + 1, int((s0 + b) / per) - 1, dtype=np.int64)
    if len(m) < 8:
        return 0.0, 0.0
    g = eighth_to_sample(m, sr, num, den) - s0
    idx = g[:, None] + lags[None, :]
    idx = idx[(idx.min(axis=1) >= 0) & (idx.max(axis=1) < len(env))]
    if len(idx) < 8:
        return 0.0, 0.0
    score = env[idx].sum(axis=0)
    best = int(np.argmax(score))
    return lags[best] * 1000.0 / sr, float(score[best] / (np.median(score) + 1e-12))


def stem_report(mono, sr, start_eighth, window_s=20.0):
    env = onset_envelope(mono)
    w = int(window_s * sr)
    rows = []
    for a in range(0, len(env) - w + 1, w):
        lag, clarity = window_lag(env, sr, start_eighth, a, a + w)
        rows.append(((a + w / 2) / sr, lag, clarity))
    return rows


def evaluate(report, drift_tol_ms=1.0, lag_range_ms=(-1.0, 6.0), min_clarity=1.5, min_windows=3):
    clear = [(t, lag) for t, lag, c in report if c >= min_clarity]
    res = {"ok": False, "drift_ms": 0.0, "median_ms": 0.0, "n_clear": len(clear), "reason": ""}
    if len(clear) < min_windows:
        res["reason"] = f"only {len(clear)} windows with a clear grid (need {min_windows})"
        return res
    t = np.array([c[0] for c in clear])
    lag = np.array([c[1] for c in clear])
    slope = np.polyfit(t, lag, 1)[0]
    res["drift_ms"] = float(slope * (t[-1] - t[0]))
    res["median_ms"] = float(np.median(lag))
    if abs(res["drift_ms"]) > drift_tol_ms:
        res["reason"] = f"drift {res['drift_ms']:+.2f} ms across the stem"
    elif not (lag_range_ms[0] <= res["median_ms"] <= lag_range_ms[1]):
        res["reason"] = f"median lag {res['median_ms']:+.2f} ms is off the grid"
    else:
        res["ok"] = True
    return res


def main(argv):
    tl = json.loads(Path(argv[1] if len(argv) > 1 else "timeline.json").read_text())
    stem_dir = Path(argv[2] if len(argv) > 2 else "stems")
    all_ok = True
    print(f"{'stem':6s} {'windows':>8s} {'median lag':>11s} {'drift':>8s}  result")
    for p in tl["parts"]:
        if p.get("lockCheck", "fold") == "clock":
            print(f"{p['name']:6s} {'-':>8s} {'-':>11s} {'-':>8s}  SKIP: clock-verified by test")
            continue
        x, sr = read_wav(stem_dir / f"{p['name']}.wav")
        # trim the graphs' shared Limiter latency, exactly as assemble.py does
        mono = x.mean(axis=1)[tl.get("latencySamples", 0):]
        res = evaluate(stem_report(mono, sr, p["start"]))
        all_ok &= res["ok"]
        print(f"{p['name']:6s} {res['n_clear']:8d} {res['median_ms']:+10.2f}ms "
              f"{res['drift_ms']:+7.2f}ms  {'PASS' if res['ok'] else 'FAIL: ' + res['reason']}")
    print("beat lock: " + ("PASS" if all_ok else "FAIL"))
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
