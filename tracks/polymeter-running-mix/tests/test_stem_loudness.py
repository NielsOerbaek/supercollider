import stem_loudness

SUMMARY = """
[Parsed_ebur128_0 @ 0x55] Summary:

  Integrated loudness:
    I:         -18.4 LUFS
    Threshold: -28.6 LUFS

  Loudness range:
    LRA:         6.2 LU
"""


def test_parse_integrated_loudness():
    assert stem_loudness.parse_ebur128(SUMMARY) == -18.4


def test_suggested_gain_hits_the_target():
    assert stem_loudness.suggest_gain(measured=-18.4, target=-21.0) == -2.6
