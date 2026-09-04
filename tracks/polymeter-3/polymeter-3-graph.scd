// polymeter-3-graph.scd — the single source of truth for the synth graph.
// Loaded by polymeter-3.scd (live playback) and render.scd (offline render).
//
// A rhythmicon at quarter = 170, in two sections.
// Section 1: voice n plays n evenly spaced hits per 4/4 bar, cycling the
// first n harmonics of E2 — hit k of every bar lands on harmonic k, so
// each bar is an ascending harmonic fan; everyone meets on the downbeat.
// Voices enter one by one, 8 bars apart, heavy -> light (deep drone-bass
// pluck at 1 hit/bar to featherweight tick at 9/bar).
// Section 2 (from bar 80): start over with the same voices and notes,
// but each voice's hit rate floored to the nearest power of two — voice 3
// plays its 3 notes as half notes (a 1.5-bar pattern), voice 7 its 7
// notes as quarters (1.75 bars), voice 9 as eighths (1.125 bars). The
// odd voices no longer meet the downbeat and phase against the barline
// (full realignment: every 315 bars — never, within this piece).
// Both sections end the same way — FIFO: voices leave in the order they
// arrived, every 4 bars, until only the two lightest (glass and tick)
// remain. The sections overlap: section 2's bass pluck enters while the
// section-1 duo still ticks, and the duo stops exactly as voice 2
// arrives. At the end of section 2 the duo phases alone to the close.
// The piece builds heavy-to-light and dies heavy-to-light, twice.

{
	var q = 170/60;              // tempo: quarter = 170
	var barDur = 4 / q;          // one 4/4 bar (~1.41 s)
	var fifo1Bar = 72;           // section-1 FIFO exits start here
	var sec2Bar = 100;           // section 2 ("start over") begins here
	var fifo2Bar = 172;          // section-2 FIFO exits start here
	var total = 208 * barDur;    // glass + tick alone from bar 196 to the end
	var elapsed = Sweep.kr(0, 1);
	var fund = 82.407;           // E2 — harmonic 1

	// ---- levels: muck about here ----
	var mainAmp = 1.0;
	var revMix  = 0.2;           // the shared room
	var amps = [0.5, 0.42, 0.36, 0.32, 0.28, 0.25, 0.25, 0.25, 0.25]; // per voice

	var voiceFuncs, voices, mix, master;

	RandSeed.ir(1, 20260904); // reproducible renders

	// ---- nine distinct pluck timbres, ordered heavy -> light ----
	voiceFuncs = [
		// 1: deep drone-bass pluck — sub + fundamental, long bloom
		{ |f, t| (SinOsc.ar(f * 0.5) + (SinOsc.ar(f) * 0.5)
			+ (SinOsc.ar(f * 2, 0, Decay2.ar(t, 0.002, 0.15)) * 0.3))
			* Decay2.ar(t, 0.005, 1.8) },
		// 2: warm plucked string (Karplus-Strong)
		{ |f, t| Pluck.ar(WhiteNoise.ar(0.8), t, 0.03, 1/f, 3, 0.4) },
		// 3: FM pluck, kalimba-ish bite
		{ |f, t| SinOsc.ar(f, SinOsc.ar(f * 2) * (3 * Decay2.ar(t, 0.001, 0.09)),
			Decay2.ar(t, 0.002, 0.5)) },
		// 4: filter-swept saw pluck
		{ |f, t| MoogFF.ar(Saw.ar(f * [1, 1.005]).sum,
			f * (2 + (7 * Decay2.ar(t, 0.003, 0.12))), 2)
			* Decay2.ar(t, 0.003, 0.4) },
		// 5: chip pluck (thin square)
		{ |f, t| Pulse.ar(f, 0.25, Decay2.ar(t, 0.002, 0.25)) * 0.7 },
		// 6: small bell (pure twelfth partial)
		{ |f, t| (SinOsc.ar(f, 0, Decay2.ar(t, 0.002, 0.6))
			+ (SinOsc.ar(f * 3, 0, Decay2.ar(t, 0.002, 0.25)) * 0.4)) * 0.8 },
		// 7: muted string (dark Karplus-Strong)
		{ |f, t| Pluck.ar(WhiteNoise.ar(0.8), t, 0.03, 1/f, 0.8, 0.7) },
		// 8: glass (octave-pair sines, very short)
		{ |f, t| (SinOsc.ar(f * 2, 0, Decay2.ar(t, 0.001, 0.18))
			+ (SinOsc.ar(f * 4, 0, Decay2.ar(t, 0.001, 0.09)) * 0.5)) * 0.7 },
		// 9: featherweight tick
		{ |f, t| (SinOsc.ar(f * 2, 0, Decay2.ar(t, 0.001, 0.1))
			+ (HPF.ar(WhiteNoise.ar(Decay2.ar(t, 0.001, 0.015)), 3000) * 0.4)) * 0.6 }
	];

	// ---- the rhythmicon, twice ----
	// Section 1 — voice n: n hits per bar (rate n/bar), pitches cycling
	// harmonics 1..n, entering at bar (n-1)*8. Everything stops at sec2Bar.
	// Section 2 — same voices re-enter one by one, 8 bars apart, but the
	// hit rate is floored to the nearest power of two (p = 2^floor(log2 n))
	// while the n-note pitch cycle stays — so non-power-of-two voices carry
	// patterns of n/p bars that phase against the barline.
	// (10 ms of gate grace so entry hits aren't lost to control-block
	// timing; the .max(20) guards Pluck's 1/freq against any zero.)
	// FIFO in both sections: voice i leaves at fifoBar + 4i (voice 1 first,
	// every 4 bars). Voices 8 and 9 never FIFO out — in section 1 they run
	// 8 bars INTO section 2 (overlapping its bass re-entry, stopping just
	// as voice 2 arrives); in section 2 they run to the end of the piece.
	// Each voice switches its pitch stream from the sec-1 to the sec-2
	// Demand at its own sec-1 exit (the streams never overlap per voice).
	voices = 9.collect { |i|
		var n = i + 1;
		var p = (2 ** n.log2.floor).asInteger;
		var exit1Bar = if(i < 7) { fifo1Bar + (i * 4) } { sec2Bar + 8 };
		var exit2Bar = if(i < 7) { fifo2Bar + (i * 4) } { 10000 };
		var gsw = elapsed >= (exit1Bar * barDur);
		var trig1 = Impulse.ar(n / barDur)
		* (elapsed >= ((i * 8 * barDur) - 0.01))
		* (elapsed < (exit1Bar * barDur));
		var trig2 = Impulse.ar(p / barDur)
		* (elapsed >= (((sec2Bar + (i * 8)) * barDur) - 0.01))
		* (elapsed < (exit2Bar * barDur));
		var f1 = Demand.ar(trig1, 0, Dseq((1..n), inf)) * fund;
		var f2 = Demand.ar(trig2, 0, Dseq((1..n), inf)) * fund;
		var freq = ((f1 * (1 - gsw)) + (f2 * gsw)).max(20);
		var pan = ((i % 2) * 2 - 1) * (i / 8) * 0.6;
		Pan2.ar(voiceFuncs[i].value(freq, trig1 + trig2), pan, amps[i])
	}.sum;

	mix = voices * mainAmp;
	mix = FreeVerb.ar(mix, revMix, 0.75, 0.4);
	// gentle glue; loudness normalization lives in make_mp3.sh
	mix = Compander.ar(mix, mix, 0.4, 1, 0.7, 0.005, 0.15) * 1.1;
	master = EnvGen.kr(Env([1, 1, 0], [total - 5, 5], [0, -3]), doneAction: 2);
	Limiter.ar(mix * 0.5, 0.9) * master;
}
