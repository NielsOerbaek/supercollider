// polymeter-002.scd — 12/8 glitch groove, blips in 5/8, moving delays; JI on E
//
// The synth graph lives in polymeter-002-graph.scd (shared with render.scd,
// the offline renderer) — edit sounds, patterns, and arrangement THERE.
//
// Usage: put the cursor inside the paren block and press Ctrl+Enter.
// Ctrl+. (period) stops everything.

(
var dir = thisProcess.nowExecutingPath.notNil.if(
	{ thisProcess.nowExecutingPath.dirname },
	{ "~/Documents/repos/supercollider/tracks/polymeter-002".standardizePath });
s.waitForBoot({
	(dir +/+ "polymeter-002-graph.scd").load.play;
});
)
