// render.scd — offline (non-realtime) render of polymeter-2 to render.wav.
// Loads the shared synth graph. Run via:  ./make_mp3.sh tracks/polymeter-2
//
// KEEP IN SYNC with the graph: `bpm` and `bars` must match its tempo and
// total length — they determine the render duration.
(
var bpm = 170;
var bars = 92;                                    // 76 full-mix + 16 outro bars of 12/8
var duration = ((bars * 12 * (60 / bpm / 2)) + 3).roundUp;

var dir = thisProcess.nowExecutingPath.notNil.if(
	{ thisProcess.nowExecutingPath.dirname },
	{ "~/Documents/repos/supercollider/tracks/polymeter-2".standardizePath });
var func = (dir +/+ "polymeter-2-graph.scd").load;
var def = func.asSynthDef(name: \poly2render);
var score = Score([
	[0.0, [\d_recv, def.asBytes]],
	[0.05, [\s_new, \poly2render, 1000, 0, 0]],
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
