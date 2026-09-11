// run-003b.scd — the running mix's interlude: polymeter-003's second
// section. Forked from tracks/polymeter-003, which is untouched.
//
// The same nine voices and notes, but each voice's hit rate is floored to
// the nearest power of two while its pitch cycle keeps n notes — voice 3
// plays its 3 notes as half notes (a 1.5-bar pattern), voice 7 its 7 as
// quarters, voice 9 as eighths — so the odd voices phase against the
// barline. Voices enter every 8 bars (voice 9 at bar 64); all nine phase
// together over bars 64-112, a hold the original never had; then they
// leave first-in-first-out every 4 bars from bar 112. The duo plays on
// alone from bar 136, carries on under 002's opening from bar 152, and
// fades with this stem's end at bar 168.
//
// Grid zero is this synth's first sample; every clock and gate counts from it.

{
	var q = 170/60;              // tempo: quarter = 170
	var barDur = 4 / q;          // one 4/4 bar (~1.41 s)
	var entryEvery = 8;          // bars between entries
	var fifoBar = 112;           // first exit
	var bars = 168;              // stem length (1344 eighths)
	var total = bars * barDur;
	var elapsed = Sweep.kr(0, 1);
	var fund = 82.407;           // E2 — harmonic 1

	var mainAmp = 1.0;
	var revMix  = 0.2;
	var amps = [0.5, 0.42, 0.36, 0.32, 0.28, 0.25, 0.25, 0.25, 0.25];

	var voiceFuncs, voices, mix, master;

	RandSeed.ir(1, 20260905); // reproducible renders, a different seed from 003a

	// the nine pluck timbres of polymeter-003, verbatim, heavy -> light
	voiceFuncs = [
		{ |f, t| (SinOsc.ar(f * 0.5) + (SinOsc.ar(f) * 0.5)
			+ (SinOsc.ar(f * 2, 0, Decay2.ar(t, 0.002, 0.15)) * 0.3))
			* Decay2.ar(t, 0.005, 1.8) },
		{ |f, t| Pluck.ar(WhiteNoise.ar(0.8), t, 0.03, 1/f, 3, 0.4) },
		{ |f, t| SinOsc.ar(f, SinOsc.ar(f * 2) * (3 * Decay2.ar(t, 0.001, 0.09)),
			Decay2.ar(t, 0.002, 0.5)) },
		{ |f, t| MoogFF.ar(Saw.ar(f * [1, 1.005]).sum,
			f * (2 + (7 * Decay2.ar(t, 0.003, 0.12))), 2)
			* Decay2.ar(t, 0.003, 0.4) },
		{ |f, t| Pulse.ar(f, 0.25, Decay2.ar(t, 0.002, 0.25)) * 0.7 },
		{ |f, t| (SinOsc.ar(f, 0, Decay2.ar(t, 0.002, 0.6))
			+ (SinOsc.ar(f * 3, 0, Decay2.ar(t, 0.002, 0.25)) * 0.4)) * 0.8 },
		{ |f, t| Pluck.ar(WhiteNoise.ar(0.8), t, 0.03, 1/f, 0.8, 0.7) },
		{ |f, t| (SinOsc.ar(f * 2, 0, Decay2.ar(t, 0.001, 0.18))
			+ (SinOsc.ar(f * 4, 0, Decay2.ar(t, 0.001, 0.09)) * 0.5)) * 0.7 },
		{ |f, t| (SinOsc.ar(f * 2, 0, Decay2.ar(t, 0.001, 0.1))
			+ (HPF.ar(WhiteNoise.ar(Decay2.ar(t, 0.001, 0.015)), 3000) * 0.4)) * 0.6 }
	];

	// voice n: its rate floored to a power of two (p hits per bar) while its
	// pitch still cycles harmonics 1..n. Voices 1-7 exit first-in-first-out;
	// the duo (8 and 9) never exits inside the stem.
	// (10 ms of gate grace so entry hits aren't lost to control-block timing)
	voices = 9.collect { |i|
		var n = i + 1;
		var p = (2 ** n.log2.floor).asInteger;
		var entryBar = i * entryEvery;
		var exitBar = if(i < 7) { fifoBar + (i * 4) } { 10000 };
		var trig = Impulse.ar(p / barDur)
		* (elapsed >= ((entryBar * barDur) - 0.01))
		* (elapsed < (exitBar * barDur));
		var freq = (Demand.ar(trig, 0, Dseq((1..n), inf)) * fund).max(20);
		var pan = ((i % 2) * 2 - 1) * (i / 8) * 0.6;
		Pan2.ar(voiceFuncs[i].value(freq, trig), pan, amps[i])
	}.sum;

	mix = voices * mainAmp;
	mix = FreeVerb.ar(mix, revMix, 0.75, 0.4);
	mix = Compander.ar(mix, mix, 0.4, 1, 0.7, 0.005, 0.15) * 1.1;
	master = EnvGen.kr(Env([1, 1, 0], [total - 5, 5], [0, -3]), doneAction: 2);
	Limiter.ar(mix * 0.5, 0.9) * master;
}
