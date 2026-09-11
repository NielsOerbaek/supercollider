// run-003a.scd — the running mix's warm-up: polymeter-003's first section,
// slowed so it can open a run. Forked from tracks/polymeter-003, which is
// untouched.
//
// A rhythmicon at quarter = 170: voice n plays n evenly spaced hits per 4/4
// bar, cycling the first n harmonics of E2, so every bar is an ascending
// harmonic fan and everyone meets on the downbeat. Voices enter every 12
// bars (the original: every 8) — voice 9 at bar 96 — all nine hold together
// over bars 96-128, then leave first-in-first-out every 4 bars from bar 128.
// The glass + tick duo plays on alone from bar 152, carries on under 001's
// drums from bar 170 (the running mix's hand-over), and fades with this
// stem's end at bar 186.
//
// Grid zero is this synth's first sample; every clock and gate counts from it.

{
	var q = 170/60;              // tempo: quarter = 170
	var barDur = 4 / q;          // one 4/4 bar (~1.41 s)
	var entryEvery = 12;         // bars between entries
	var fifoBar = 128;           // first exit
	var bars = 186;              // stem length (1488 eighths)
	var total = bars * barDur;
	var elapsed = Sweep.kr(0, 1);
	var fund = 82.407;           // E2 — harmonic 1

	var mainAmp = 1.0;
	var revMix  = 0.2;
	var amps = [0.5, 0.42, 0.36, 0.32, 0.28, 0.25, 0.25, 0.25, 0.25];

	var voiceFuncs, voices, mix, master;

	RandSeed.ir(1, 20260904); // reproducible renders

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

	// voice n: n hits per bar, pitches cycling harmonics 1..n. Voices 1-7
	// exit first-in-first-out; the duo (8 and 9) never exits inside the stem.
	// (10 ms of gate grace so entry hits aren't lost to control-block timing)
	voices = 9.collect { |i|
		var n = i + 1;
		var entryBar = i * entryEvery;
		var exitBar = if(i < 7) { fifoBar + (i * 4) } { 10000 };
		var trig = Impulse.ar(n / barDur)
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
