import sys
from pathlib import Path

TRACK = Path(__file__).resolve().parents[1]
REPO = TRACK.parents[1]
sys.path.insert(0, str(TRACK))
