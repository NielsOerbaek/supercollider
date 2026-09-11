// render-part.scd — offline render of one part of the running mix.
// Usage: sclang render-part.scd <part> <seconds> [graph.scd] [out.wav]
//   defaults: run-<part>.scd next to this file, written to stems/<part>.wav
// The synth definition and the synth start share one bundle at score time 0,
// so the stem's sample 0 is the part's grid zero — which is what lets
// assemble.py lock every part to the global grid by arithmetic alone.
(
var args = thisProcess.argv;
var dir = thisProcess.nowExecutingPath.dirname;
var part = args[0];
var seconds = args[1].asFloat;
var graph = if(args.size > 2) { args[2] } { dir +/+ "run-" ++ part ++ ".scd" };
var out = if(args.size > 3) { args[3] } { dir +/+ "stems" +/+ part ++ ".wav" };
var def = graph.load.asSynthDef(name: ("run_" ++ part).asSymbol);
var score = Score([
	[0.0, [\d_recv, def.asBytes], [\s_new, def.name, 1000, 0, 0]],
	[seconds, [\c_set, 0, 0]]
]);
File.mkdir(out.dirname);
score.recordNRT(
	oscFilePath: out.splitext[0] ++ ".osc",
	outputFilePath: out,
	sampleRate: 48000,
	headerFormat: "WAV",
	sampleFormat: "int16",
	options: ServerOptions.new.numOutputBusChannels_(2),
	duration: seconds,
	action: { "NRT_DONE".postln; 0.exit }
);
)
