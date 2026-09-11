"""Report each stem's integrated loudness against its target.

Usage: python3 stem_loudness.py [timeline.json] [stems/] [--write]
  --write sets each part's gainDb to (targetLufs - measured) in timeline.json
"""
import json
import re
import subprocess
import sys
from pathlib import Path


def parse_ebur128(stderr):
    summary = stderr[stderr.rindex("Summary:"):]
    return float(re.search(r"I:\s*(-?[\d.]+)\s*LUFS", summary).group(1))


def integrated_lufs(path):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path),
                        "-af", "ebur128", "-f", "null", "-"], capture_output=True, text=True)
    return parse_ebur128(r.stderr)


def suggest_gain(measured, target):
    return round(target - measured, 1)


def main(argv):
    write = "--write" in argv
    args = [a for a in argv[1:] if a != "--write"]
    tl_path = Path(args[0] if args else "timeline.json")
    stem_dir = Path(args[1] if len(args) > 1 else "stems")
    tl = json.loads(tl_path.read_text())
    ok = True
    print(f"{'stem':6s} {'measured':>9s} {'gainDb':>7s} {'in mix':>8s} {'target':>7s}")
    for p in tl["parts"]:
        m = integrated_lufs(stem_dir / f"{p['name']}.wav")
        if write:
            p["gainDb"] = suggest_gain(m, p["targetLufs"])
        eff = m + p["gainDb"]
        good = abs(eff - p["targetLufs"]) <= 1.5
        ok &= good
        print(f"{p['name']:6s} {m:8.1f}  {p['gainDb']:+6.1f} {eff:7.1f}  {p['targetLufs']:6.1f}"
              f"  {'ok' if good else 'OFF TARGET'}")
    if write:
        tl_path.write_text(json.dumps(tl, indent=2) + "\n")
        print(f"wrote gainDb values to {tl_path}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
