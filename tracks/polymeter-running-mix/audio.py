"""Shared audio helpers for the running mix: grid math, WAV I/O, band levels.

The global grid is the eighth note at quarter = 170: 60/340 s. Every sample
position on it is rounded from the exact rational value, never accumulated,
so placement error is at most half a sample anywhere in the piece.
"""
import struct
from pathlib import Path

import numpy as np

SR = 48000
E8_NUM, E8_DEN = 60, 340


def eighth_to_sample(n, sr=SR, num=E8_NUM, den=E8_DEN):
    """Nearest sample to global eighth n (int, or numpy int64 array)."""
    return (2 * n * sr * num + den) // (2 * den)


def eighth_seconds(n, num=E8_NUM, den=E8_DEN):
    return n * num / den


def read_wav(path):
    """Read a 16-bit PCM or 32-bit float WAV -> (float32 frames x channels, sr)."""
    data = Path(path).read_bytes()
    if data[:4] != b"RIFF" or data[8:12] != b"WAVE":
        raise ValueError(f"{path}: not a RIFF/WAVE file")
    pos, fmt, pcm = 12, None, None
    while pos + 8 <= len(data):
        cid = data[pos:pos + 4]
        size = int.from_bytes(data[pos + 4:pos + 8], "little")
        body = data[pos + 8:pos + 8 + size]
        if cid == b"fmt ":
            tag, ch, sr = struct.unpack("<HHI", body[:8])
            bits = struct.unpack("<H", body[14:16])[0]
            if tag == 0xFFFE:                       # WAVE_FORMAT_EXTENSIBLE
                tag = struct.unpack("<H", body[24:26])[0]
            fmt = (tag, ch, sr, bits)
        elif cid == b"data":
            pcm = body
        pos += 8 + size + (size & 1)
    if fmt is None or pcm is None:
        raise ValueError(f"{path}: missing fmt or data chunk")
    tag, ch, sr, bits = fmt
    if tag == 1 and bits == 16:
        a = np.frombuffer(pcm, "<i2").astype(np.float32) / 32768.0
    elif tag == 3 and bits == 32:
        a = np.frombuffer(pcm, "<f4").astype(np.float32)
    else:
        raise ValueError(f"{path}: unsupported WAV format tag {tag}, {bits} bits")
    return a.reshape(-1, ch), sr


def write_wav_float(path, data, sr):
    """Write frames x channels float data as a 32-bit float WAV."""
    data = np.ascontiguousarray(data, dtype="<f4")
    frames, ch = data.shape
    payload = data.tobytes()
    fmt = struct.pack("<HHIIHH", 3, ch, sr, sr * ch * 4, ch * 4, 32)
    with open(path, "wb") as f:
        f.write(b"RIFF" + struct.pack("<I", 4 + 8 + len(fmt) + 8 + len(payload)) + b"WAVE")
        f.write(b"fmt " + struct.pack("<I", len(fmt)) + fmt)
        f.write(b"data" + struct.pack("<I", len(payload)) + payload)


def band_rms_db(mono, sr, lo=0.0, hi=None):
    """Mean-square power of the part of `mono` between lo and hi Hz, in dB."""
    mono = np.asarray(mono, dtype=np.float64)
    spec = np.fft.rfft(mono)
    freqs = np.fft.rfftfreq(len(mono), 1 / sr)
    hi = sr / 2 if hi is None else hi
    band = (freqs >= lo) & (freqs < hi)
    power = 2 * np.sum(np.abs(spec[band]) ** 2) / len(mono) ** 2
    return 10 * np.log10(power + 1e-20)
