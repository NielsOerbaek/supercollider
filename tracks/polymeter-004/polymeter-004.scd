// polymeter-004.scd — 15/4 at 170: a Karplus-Strong bassline hearing the bar
// as 5+5+5 against a four-on-the-floor kit hearing the same 15 quarters as
// 3+3+3+3+3.
//
// The synth graph lives in polymeter-004-graph.scd (shared with render.scd,
// the offline renderer) — edit sounds and structure THERE.
//
// Usage: cursor inside the paren block, Ctrl+Enter. Ctrl+. stops.

(
var dir = thisProcess.nowExecutingPath.notNil.if(
	{ thisProcess.nowExecutingPath.dirname },
	{ "~/Documents/repos/supercollider/tracks/polymeter-004".standardizePath });
s.waitForBoot({
	(dir +/+ "polymeter-004-graph.scd").load.play;
});
)
