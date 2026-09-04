// polymeter-3.scd — a rhythmicon: nine plucks, voice n playing n hits per
// bar on the first n harmonics of E2, entering one by one 8 bars apart.
//
// The synth graph lives in polymeter-3-graph.scd (shared with render.scd,
// the offline renderer) — edit sounds and structure THERE.
//
// Usage: cursor inside the paren block, Ctrl+Enter. Ctrl+. stops.

(
var dir = thisProcess.nowExecutingPath.notNil.if(
	{ thisProcess.nowExecutingPath.dirname },
	{ "~/Documents/repos/supercollider/tracks/polymeter-3".standardizePath });
s.waitForBoot({
	(dir +/+ "polymeter-3-graph.scd").load.play;
});
)
