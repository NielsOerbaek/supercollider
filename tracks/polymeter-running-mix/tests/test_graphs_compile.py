import os
import subprocess
import pytest
from conftest import TRACK

PARTS = ["003a", "001", "003b", "002", "004"]


@pytest.mark.parametrize("part", PARTS)
def test_graph_compiles(part, tmp_path):
    script = tmp_path / "compile.scd"
    script.write_text(
        f'var d = "{TRACK / ("run-" + part + ".scd")}".load.asSynthDef(name: \\c{part});\n'
        '("COMPILE_OK " ++ d.children.size).postln; 0.exit;\n')
    r = subprocess.run(["sclang", str(script)], capture_output=True, text=True, timeout=120,
                       env={**os.environ, "QT_QPA_PLATFORM": "offscreen"})
    assert "COMPILE_OK" in r.stdout, r.stdout[-3000:]
