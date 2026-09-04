// polymeter.scd — drums in 5/4, bass in 7/4, arpeggio in 9/8, just intonation on E
// drummer after Thor Magnusson's "Drummer" (2006)
//
// The eighth note is the shared pulse; the quarter is constant across all layers.
// Drum bar = 10 eighths (5/4), bass = 14 (7/4), arp = 9 (9/8), clap = 8 (4/4).
// Downbeats realign every LCM(10,14,9) = 630 eighths (~1:51 at quarter = 170).
//
// The synth graph lives in polymeter-graph.scd (shared with render.scd, the
// offline renderer) — edit sounds, patterns, and arrangement THERE.
//
// Usage: put the cursor inside the paren block and press Ctrl+Enter.
// Ctrl+. (period) stops everything.

(
var dir = thisProcess.nowExecutingPath.notNil.if(
	{ thisProcess.nowExecutingPath.dirname },
	{ "~/Documents/repos/supercollider/tracks/polymeter".standardizePath });
s.waitForBoot({
	(dir +/+ "polymeter-graph.scd").load.play;
});
)
