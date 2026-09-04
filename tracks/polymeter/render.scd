// render.scd — offline (non-realtime) render of the piece to a WAV.
// Loads the shared synth graph from polymeter-graph.scd, so edits there
// are picked up automatically. Run with:  sclang render.scd
// (make_mp3.sh wraps this and transcodes to a timestamped mp3.)
//
// KEEP IN SYNC with the graph: `bpm` and `outro` below must match the
// graph's tempo and outro length — they determine the render duration.
(
var bpm = 170;
var outro = 22;
var intro = 5;
var trackEnd = (1040 * (60 / bpm / 2)) + outro + intro; // intro + 1040-eighth arc + outro
var duration = trackEnd.roundUp + 3;            // small guard for the reverb tail

var dir = thisProcess.nowExecutingPath.notNil.if(
	{ thisProcess.nowExecutingPath.dirname },
	{ "~/Documents/repos/supercollider/tracks/polymeter".standardizePath });
var func = (dir +/+ "polymeter-graph.scd").load;
var def = func.asSynthDef(name: \polyrender);
var score = Score([
	[0.0, [\d_recv, def.asBytes]],
	[0.05, [\s_new, \polyrender, 1000, 0, 0]],
	[duration, [\c_set, 0, 0]]
]);
score.recordNRT(
	oscFilePath: dir +/+ "nrt.osc",
	outputFilePath: dir +/+ "render.wav",
	sampleRate: 48000,
	headerFormat: "WAV",
	sampleFormat: "int16",
	options: ServerOptions.new.numOutputBusChannels_(2),
	duration: duration,
	action: { "NRT_DONE".postln; 0.exit }
);
)
