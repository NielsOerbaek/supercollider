// render.scd — offline (non-realtime) render of polymeter-3 to render.wav.
// Loads the shared synth graph. Run via:  ./make_mp3.sh tracks/polymeter-3
//
// KEEP IN SYNC with the graph: `bpm` and `bars` must match its tempo and
// total length — they determine the render duration.
(
var bpm = 170;
var bars = 208;                                   // 4/4 bars (graph total)
var duration = ((bars * 4 * (60 / bpm)) + 3).roundUp;

var dir = thisProcess.nowExecutingPath.notNil.if(
	{ thisProcess.nowExecutingPath.dirname },
	{ "~/Documents/repos/supercollider/tracks/polymeter-3".standardizePath });
var func = (dir +/+ "polymeter-3-graph.scd").load;
var def = func.asSynthDef(name: \poly3render);
var score = Score([
	[0.0, [\d_recv, def.asBytes]],
	[0.05, [\s_new, \poly3render, 1000, 0, 0]],
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
