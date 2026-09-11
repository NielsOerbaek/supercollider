import subprocess
from conftest import REPO


def test_make_mp3_uses_render_sh(tmp_path):
    track = tmp_path / "hooktest"
    track.mkdir()
    render = track / "render.sh"
    render.write_text(
        "#!/usr/bin/env bash\nset -e\ncd \"$(dirname \"$0\")\"\n"
        "ffmpeg -hide_banner -loglevel error -f lavfi -i sine=frequency=440:duration=2 "
        "-ac 2 -ar 48000 -y render.wav\n")
    render.chmod(0o755)
    r = subprocess.run([str(REPO / "make_mp3.sh"), str(track)],
                       capture_output=True, text=True, timeout=120)
    assert r.returncode == 0, r.stdout + r.stderr
    mp3s = list((track / "renders").glob("hooktest_*.mp3"))
    assert len(mp3s) == 1
    assert not (track / "render.wav").exists()
