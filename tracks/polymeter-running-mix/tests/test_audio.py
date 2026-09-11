import numpy as np
import audio


def test_eighth_to_sample_exact_points():
    assert audio.eighth_to_sample(0) == 0
    assert audio.eighth_to_sample(17) == 144000          # 17 eighths = exactly 3 s
    assert audio.eighth_to_sample(1) == 8471              # 8470.588... rounds up
    assert audio.eighth_to_sample(10186) == 86281412


def test_eighth_to_sample_never_drifts():
    for n in range(0, 10200, 7):
        exact = n * 48000 * 60 / 340
        assert abs(audio.eighth_to_sample(n) - exact) <= 0.5


def test_eighth_to_sample_vectorised():
    n = np.arange(0, 100, dtype=np.int64)
    assert list(audio.eighth_to_sample(n)) == [audio.eighth_to_sample(int(k)) for k in n]


def test_float_wav_roundtrip(tmp_path):
    x = (np.random.default_rng(1).standard_normal((4800, 2)) * 0.3).astype(np.float32)
    p = tmp_path / "x.wav"
    audio.write_wav_float(p, x, 48000)
    y, sr = audio.read_wav(p)
    assert sr == 48000 and y.shape == x.shape
    assert np.array_equal(x, y)


def test_read_int16_wav(tmp_path):
    import wave
    p = tmp_path / "i.wav"
    frames = np.array([[0, 16384], [-32768, 32767]], dtype="<i2")
    with wave.open(str(p), "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(48000)
        w.writeframes(frames.tobytes())
    y, sr = audio.read_wav(p)
    assert sr == 48000
    assert np.allclose(y, [[0, 0.5], [-1.0, 32767 / 32768]])


def test_band_rms_of_a_sine():
    sr = 48000
    t = np.arange(sr) / sr
    x = np.sin(2 * np.pi * 1000 * t)
    assert abs(audio.band_rms_db(x, sr, 500, 2000) - (-3.01)) < 0.05
    assert audio.band_rms_db(x, sr, 3000, 6000) < -60
