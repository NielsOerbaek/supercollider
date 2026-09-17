#!/usr/bin/env python3
"""Build site/index.html — the page behind mix.raakode.dk.

One entry per track that has a latest.mp3, with its title and description from
track.conf, its length and size from the file, and the commit the render came
from. Run it through tools/deploy-mix.sh, which also uploads the audio.
"""
import json
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



TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Polymeter — latest renders</title>
<style>
  :root { color-scheme: dark; --bg:#12100f; --panel:#1a1715; --fg:#ece6df; --dim:#8d857c;
          --line:#2b2724; --accent:#d8a657; }
  * { box-sizing: border-box; }
  body { margin:0; background:var(--bg); color:var(--fg); padding-block:2.5rem 9rem;
         padding-inline:max(1rem, calc(50vw - 25rem));
         font:16px/1.6 ui-monospace, SFMono-Regular, Menlo, monospace; }
  header.top { display:flex; align-items:flex-start; justify-content:space-between; gap:1rem;
               flex-wrap:wrap; margin-bottom:2rem; }
  h1 { font-size:1.5rem; letter-spacing:.06em; margin:0 0 .25rem; }
  .lede { color:var(--dim); margin:0; max-width:32rem; font-size:.9rem; }
  .pull { display:flex; align-items:center; gap:.6rem; }
  button { font:inherit; color:inherit; background:var(--panel); border:1px solid var(--line);
           border-radius:.4rem; padding:.45rem .8rem; cursor:pointer; }
  button:hover { border-color:var(--accent); }
  button:disabled { opacity:.5; cursor:default; }
  #pull-status { color:var(--dim); font-size:.8rem; }
  ul.tracks { list-style:none; margin:0; padding:0; }
  li.track { display:flex; gap:1rem; align-items:flex-start; padding:1.1rem 0;
             border-top:1px solid var(--line); }
  li.track.playing h2 { color:var(--accent); }
  .play { flex:none; width:2.6rem; height:2.6rem; border-radius:50%; display:grid;
          place-items:center; padding:0; }
  .ico { width:0; height:0; border-left:.7rem solid currentColor;
         border-block:.45rem solid transparent; margin-left:.2rem; }
  li.track.playing .ico { border:0; width:.65rem; height:.7rem; margin:0;
         border-left:.22rem solid currentColor; border-right:.22rem solid currentColor; }
  .info { min-width:0; }
  h2 { font-size:1rem; margin:0; font-weight:600; }
  .desc { margin:.2rem 0 0; font-size:.85rem; opacity:.8; }
  .meta { margin:.2rem 0 0; color:var(--dim); font-size:.75rem; }
  footer.player { position:fixed; inset:auto 0 0 0; background:var(--panel);
                  border-top:1px solid var(--line); padding:.7rem max(1rem, calc(50vw - 25rem)); }
  .bar { display:flex; align-items:center; gap:.8rem; }
  .now { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;
         font-size:.85rem; }
  .times { color:var(--dim); font-size:.75rem; font-variant-numeric:tabular-nums; }
  input[type=range] { -webkit-appearance:none; appearance:none; background:transparent;
                      width:100%; height:1.1rem; cursor:pointer; }
  input[type=range]::-webkit-slider-runnable-track { height:.28rem; border-radius:.2rem;
      background:linear-gradient(var(--accent),var(--accent)) 0/var(--pct,0%) 100% no-repeat, var(--line); }
  input[type=range]::-moz-range-track { height:.28rem; border-radius:.2rem;
      background:linear-gradient(var(--accent),var(--accent)) 0/var(--pct,0%) 100% no-repeat, var(--line); }
  input[type=range]::-webkit-slider-thumb { -webkit-appearance:none; width:.8rem; height:.8rem;
      border-radius:50%; background:var(--accent); margin-top:-.26rem; }
  input[type=range]::-moz-range-thumb { width:.8rem; height:.8rem; border:0; border-radius:50%;
      background:var(--accent); }
  #vol { width:6rem; flex:none; }
  @media (max-width:34rem) { #vol { display:none; } }
</style>
</head>
<body>
  <header class="top">
    <div>
      <h1>Polymeter</h1>
      <p class="lede">Latest render of each track. Everything runs at quarter = 170 in just
      intonation on E, written in SuperCollider.</p>
    </div>
    <div class="pull">
      <button id="pull">git pull</button>
      <span id="pull-status"></span>
    </div>
  </header>

  <ul class="tracks">
__ROWS__
  </ul>

  <footer class="player">
    <div class="bar">
      <button id="prev" aria-label="Previous">&#9664;&#9664;</button>
      <button id="toggle" aria-label="Play">&#9654;</button>
      <button id="next" aria-label="Next">&#9654;&#9654;</button>
      <span class="now" id="now">Nothing playing</span>
      <span class="times"><span id="cur">0:00</span> / <span id="dur">0:00</span></span>
      <input id="vol" type="range" min="0" max="1" step="0.01" value="1" aria-label="Volume">
    </div>
    <input id="seek" type="range" min="0" max="1000" value="0" aria-label="Seek">
  </footer>

<script>
const PLAYLIST = __PLAYLIST__;
const audio = new Audio();
audio.preload = "none";
let current = -1;

const $ = (id) => document.getElementById(id);
const fmt = (s) => isFinite(s) ? `${Math.floor(s/60)}:${String(Math.floor(s%60)).padStart(2,"0")}` : "0:00";
const rows = [...document.querySelectorAll("li.track")];

function paint() {
  rows.forEach((r, i) => r.classList.toggle("playing", i === current && !audio.paused));
  $("toggle").innerHTML = audio.paused ? "&#9654;" : "&#10074;&#10074;";
  $("now").textContent = current < 0 ? "Nothing playing" : PLAYLIST[current].title;
}

function load(i, play = true) {
  if (i < 0 || i >= PLAYLIST.length) return;
  if (i !== current) {
    current = i;
    audio.src = PLAYLIST[i].src;
  }
  if (play) audio.play().catch(() => {});
  paint();
}

rows.forEach((row) => {
  const i = Number(row.dataset.i);
  const hit = () => (i === current && !audio.paused) ? audio.pause() : load(i);
  row.querySelector(".play").addEventListener("click", hit);
  row.querySelector(".info").addEventListener("click", hit);
});

$("toggle").addEventListener("click", () => {
  if (current < 0) return load(0);
  audio.paused ? audio.play() : audio.pause();
});
$("prev").addEventListener("click", () => audio.currentTime > 3 ? (audio.currentTime = 0) : load(current - 1));
$("next").addEventListener("click", () => load(current + 1));
audio.addEventListener("ended", () => load(current + 1));
["play", "pause"].forEach((e) => audio.addEventListener(e, paint));

audio.addEventListener("timeupdate", () => {
  $("cur").textContent = fmt(audio.currentTime);
  $("dur").textContent = fmt(audio.duration);
  const pct = audio.duration ? (audio.currentTime / audio.duration) * 1000 : 0;
  $("seek").value = pct;
  $("seek").style.setProperty("--pct", (pct / 10) + "%");
});
$("seek").addEventListener("input", (e) => {
  if (audio.duration) audio.currentTime = (e.target.value / 1000) * audio.duration;
});
$("vol").addEventListener("input", (e) => { audio.volume = Number(e.target.value); });
$("vol").style.setProperty("--pct", "100%");

document.addEventListener("keydown", (e) => {
  if (e.target.tagName === "INPUT") return;
  if (e.code === "Space") { e.preventDefault(); $("toggle").click(); }
  if (e.code === "ArrowRight") audio.currentTime += 10;
  if (e.code === "ArrowLeft") audio.currentTime -= 10;
});

// the git pull button: POST to the endpoint Caddy password-protects. Browsers
// do not show the auth dialog for fetch, so a 401 falls back to opening the
// endpoint in a tab, where they do.
$("pull").addEventListener("click", async () => {
  const btn = $("pull"), status = $("pull-status");
  btn.disabled = true; status.textContent = "pulling…";
  try {
    const r = await fetch("/api/pull", { method: "POST", credentials: "include" });
    if (r.status === 401) { status.textContent = "sign in…"; window.open("/api/pull", "_blank"); }
    else {
      const text = (await r.text()).trim();
      status.textContent = text.split("\n").pop().slice(0, 80);
      if (r.ok) setTimeout(() => location.reload(), 1200);
    }
  } catch (err) {
    status.textContent = "failed: " + err.message;
  } finally {
    btn.disabled = false;
  }
});
</script>
</body>
</html>
"""


def build():
    items, rows = [], []
    for i, t in enumerate(tracks()):
        c = conf(t)
        mp3 = t / "latest.mp3"
        title = c.get("title", t.name)
        items.append({"src": f"tracks/{t.name}.mp3", "title": title})
        rows.append(f"""    <li class="track" data-i="{i}">
      <button class="play" aria-label="Play {title}"><span class="ico"></span></button>
      <div class="info">
        <h2>{title}</h2>
        <p class="desc">{c.get('comment', '')}</p>
        <p class="meta">{duration(mp3)} &middot; {mp3.stat().st_size / 1048576:.0f} MB &middot; {commit(t)}</p>
      </div>
    </li>""")
    playlist = json.dumps(items, indent=2)
    html = TEMPLATE.replace("__ROWS__", "\n".join(rows)).replace("__PLAYLIST__", playlist)
    (REPO / "site").mkdir(exist_ok=True)
    (REPO / "site" / "index.html").write_text(html)
    print(f"built site/index.html with {len(rows)} tracks")


if __name__ == "__main__":
    build()
