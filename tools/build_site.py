#!/usr/bin/env python3
"""Build site/index.html — the page behind mix.raakode.dk.

One entry per track that has a latest.mp3, with its title and description from
track.conf, its length and size from the file, and the commit the render came
from. Run it through tools/deploy-mix.sh, which also uploads the audio.
"""
import re
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ORDER = ["polymeter-running-mix"]          # these go last; everything else by name


def conf(track):
    out = {}
    p = track / "track.conf"
    if p.exists():
        for line in p.read_text().splitlines():
            m = re.match(r'(\w+)="(.*)"\s*$', line.strip())
            if m:
                out[m.group(1)] = m.group(2)
    return out


def duration(mp3):
    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                        "-of", "csv=p=0", str(mp3)], capture_output=True, text=True)
    secs = float(r.stdout.strip())
    return f"{int(secs // 60)}:{int(secs % 60):02d}"


def commit(track):
    r = subprocess.run(["git", "-C", str(REPO), "log", "-1", "--format=%h %ad",
                        "--date=format:%-d %b %Y", "--", str(track)],
                       capture_output=True, text=True)
    return r.stdout.strip()


def tracks():
    found = [t for t in sorted((REPO / "tracks").iterdir()) if (t / "latest.mp3").exists()]
    return sorted(found, key=lambda t: (t.name in ORDER, t.name))


def build():
    rows = []
    for t in tracks():
        c = conf(t)
        mp3 = t / "latest.mp3"
        rows.append(f"""    <article class="track">
      <header>
        <h2>{c.get('title', t.name)}</h2>
        <p class="meta">{duration(mp3)} &middot; {mp3.stat().st_size / 1048576:.0f} MB &middot; {commit(t)}</p>
      </header>
      <p class="desc">{c.get('comment', '')}</p>
      <audio controls preload="none" src="tracks/{t.name}.mp3"></audio>
    </article>""")
    html = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Polymeter — latest renders</title>
<style>
  :root {{ color-scheme: dark; --bg:#12100f; --fg:#ece6df; --dim:#8d857c; --line:#2b2724; --accent:#d8a657; }}
  * {{ box-sizing: border-box; }}
  body {{ margin:0; background:var(--bg); color:var(--fg); padding-block:3rem;
         padding-inline:max(1rem, calc(50vw - 24rem));
         font:16px/1.6 "Iosevka", ui-monospace, SFMono-Regular, Menlo, monospace; }}
  h1 {{ font-size:1.5rem; letter-spacing:.06em; margin:0 0 .25rem; }}
  .lede {{ color:var(--dim); margin:0 0 2.5rem; max-width:34rem; }}
  .track {{ border-top:1px solid var(--line); padding:1.5rem 0; }}
  .track h2 {{ font-size:1.05rem; margin:0; font-weight:600; }}
  .meta {{ color:var(--dim); font-size:.8rem; margin:.15rem 0 0; }}
  .desc {{ color:var(--fg); opacity:.85; margin:.75rem 0 1rem; max-width:38rem; }}
  audio {{ width:100%; height:2.5rem; }}
  footer {{ border-top:1px solid var(--line); margin-top:2rem; padding-top:1rem;
            color:var(--dim); font-size:.8rem; }}
  a {{ color:var(--accent); }}
</style>
</head>
<body>
  <h1>Polymeter</h1>
  <p class="lede">Latest render of each track. Everything runs at quarter = 170 in just
  intonation on E, written in SuperCollider.</p>
{chr(10).join(rows)}
  <footer>Rendered offline from the track graphs; each entry names the commit it came from.</footer>
</body>
</html>
"""
    (REPO / "site").mkdir(exist_ok=True)
    (REPO / "site" / "index.html").write_text(html)
    print(f"built site/index.html with {len(rows)} tracks")


if __name__ == "__main__":
    build()
