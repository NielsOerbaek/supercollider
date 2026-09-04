// polymeter-graph.scd — the single source of truth for the synth graph.
// Loaded by polymeter.scd (live playback) and render.scd (offline render):
// this file's last expression is the graph function, so `.load` returns it.
// Edit sounds/patterns here; both players pick the change up automatically.

{
	var q = 170/60;              // quarters per second (tempo: quarter = 170)
	var e8 = 1 / (q * 2);        // eighth-note duration in seconds
	var clk = Impulse.ar(q * 2); // the shared eighth-note clock
	var cycle = 630 * e8;        // one full realignment of the three meters (~2:23)
	var total = 1040 * e8;       // shortened arc: cycle 1 + most of cycle 2 (~3:04 of music)
	var outro = 22;              // arpeggio-only tail
	var intro = 5;               // pink-noise riser before the downbeat
	var trackEnd = total + outro + intro;
	var elapsed = Sweep.kr(0, 1); // seconds since the synth started

	var fund = 82.407;           // E2 — every pitch below is fund * ratio

	// ---- layer levels: muck about here (0 mutes a layer) ----
	var drumAmp  = 0.9;
	var bassAmp  = 0.5;
	var arpAmp   = 0.5;          // forward in the mix — the arp is the lead voice
	var droneAmp = 0.06;         // quiet 1/1 drone so the JI intervals have a floor
	var clapAmp  = 0.6;          // the big clap that enters at beat 120
	var pinkAmp  = 0.14;         // filtered pink-noise wash, second cycle only
	var harmAmp  = 0.18;         // two-note pad harmonies, from the half-cycle
	var revMix   = 0.12;         // general reverb amount (0 = dry)

	var kickTrig, snareTrig, hatTrig, kick, snare, hat, drums;
	var bassRatio, bassF, bass, bassTrig, slideTrig, slide, vib;
	var arpRatio, arpF, arp, arpClk, arpTrig, arpRate, susArc, outroSus;
	var clapTrig, clapEnv, clap, clapRise, pink, pinkEnv;
	var harmDur, harmTrig, harmF1, harmF2, harmEnv, harm;
	var drone, mix, outroFade, crushSR, bits, crush, wet, master;

	// ---- drummer, 5/4 — 10-step masks, counted "1 & 2 & 3 & 4 & 5 &" ----
	// each mask value scales the hit (0 = rest); swap numbers to re-groove
	// emphasis on 1, 2-and, 4, 5 — a 3+3+2+2 grouping of the ten eighths.
	// kick takes 1, 2-and, 4; snare lands the 5 with ghosts on 3-and & 4-and;
	// hats accent all four emphasis points
	kickTrig  = clk * Demand.ar(clk, 0, Dseq([1,  0,  0.9,  0 ,0  ,  0  ,  1,  0  ,  0,  0.4], inf));
	snareTrig = clk * Demand.ar(clk, 0, Dseq([0,  0,  0  , 0.5,  0,  0.4,0  ,  0.3,1  ,  0  ], inf));
	hatTrig   = clk * Demand.ar(clk, 0, Dseq([0.9,0.3,0.4,0.9,0.3,0.4,0.9,0.4,0.9,0.5], inf));

	// kick tuned to E1 (fund/2) with a fast pitch drop; snare body at 9/4 over fund.
	// the noise click on top makes the 41 Hz body read on small speakers
	kick  = (SinOsc.ar(fund * 0.5 * (1 + (8 * Decay2.ar(kickTrig, 0.001, 0.07))),
		0, Decay2.ar(kickTrig, 0.005, 0.3)) * 1.6)
	+ (HPF.ar(WhiteNoise.ar(Decay2.ar(kickTrig, 0.001, 0.02)), 1000) * 0.5);
	snare = WhiteNoise.ar(Decay2.ar(snareTrig, 0.005, 0.16))
	+ SinOsc.ar(fund * 9/4, 0, Decay2.ar(snareTrig, 0.005, 0.09));
	hat   = HPF.ar(WhiteNoise.ar(Decay2.ar(hatTrig, 0.002, 0.05)), 9000);
	drums = (kick + snare + (hat * 0.6)) * drumAmp;

	// ---- big clap: 4/4 backbeat (2 and 4 of an 8-eighth bar), its own ----
	// meter rotating against the 5/4 kit. Enters at beat 120 (240 eighths),
	// drops out the moment the harmonies arrive (top of cycle 2, 630
	// eighths), stays out for 64 beats, then crescendos back in over 8
	// beats instead of just switching on.
	// the delayed trigger copies are the classic multi-burst clap smear
	clapRise = ((elapsed - (758 * e8)) / (16 * e8)).clip(0, 1);
	clapTrig = clk * Demand.ar(clk, 0, Dseq([0,0,1,0,0,0,1,0], inf))
	* (elapsed > (240 * e8))
	* ((elapsed < (630 * e8)) + clapRise).min(1);
	clapEnv  = Decay2.ar(clapTrig, 0.001, 0.2)
	+ Decay2.ar(DelayN.ar(clapTrig, 0.03, 0.011), 0.001, 0.1)
	+ Decay2.ar(DelayN.ar(clapTrig, 0.03, 0.023), 0.001, 0.08);
	clap = BPF.ar(WhiteNoise.ar(2), 1800, 0.7) * clapEnv * clapAmp;

	// ---- bass, 7/4 — three-tone syncopated ostinato: root, minor third ----
	// (6/5) and the harmonic seventh (7/4 — a 7-limit interval no piano
	// can play, in the 7/4 bar). Rhythm is 2+3+3+1+2+3 eighths = 14,
	// leaning on the offbeats. The pattern alternates over two bars, and
	// every other bar its closing 7/4 note slides down to the root.
	// (duration Dseqs appear once per stream because each demand stream
	// consumes its own copy — sharing one instance would double-step it)
	bassRatio = Duty.ar(Dseq([2, 3, 3, 1, 2, 3], inf) * e8, 0,
		Dseq([1, 1, 6/5, 1, 7/4, 6/5,  1, 1, 6/5, 1, 6/5, 7/4], inf));
	// gating the trigger (not the signal) means the bass enters cleanly
	// on its own next note after beat 20, not mid-tone
	bassTrig  = TDuty.ar(Dseq([2, 3, 3, 1, 2, 3], inf) * e8)
	* (elapsed >= (40 * e8));
	// the slide fires at eighth 25 of every 28-eighth (two-bar) cycle:
	// the final 7/4 glides down to the root (x 4/7), then snaps back to
	// neutral just before the next bar's first note
	slideTrig = TDuty.ar(Dseq([25 * e8, Dseq([28 * e8], inf)], 1), 0, 1, 0, 1);
	slide = EnvGen.ar(
		Env([1, 1, 4/7, 1], [0.08, (3 * e8) - 0.2, 0.1], [0, -4, 0]),
		slideTrig);
	// delayed vibrato: each note starts straight, then a small wobble blooms
	// in ~150 ms after the attack — reads as "played" rather than sequenced
	vib   = 1 + (SinOsc.kr(5) * 0.006 * EnvGen.ar(Env([0, 0, 1], [0.15, 0.3]), bassTrig));
	bassF = fund * bassRatio * slide * vib;
	// tiny detune on the saw pair is timbral chorus, not tuning.
	// resonant Moog-style filter swoops per note (bright attack closing
	// down over the note), then gentle tanh drive for growl and thickness
	bass  = MoogFF.ar(Saw.ar(bassF * [1, 1.003]).sum + SinOsc.ar(bassF * 0.5),
		bassF * (2 + (8 * Decay2.ar(bassTrig, 0.005, 0.25))),
		2.5) * Decay2.ar(bassTrig, 0.01, 0.7);
	bass  = (bass * 4).tanh * 1.2 * bassAmp;

	// ---- arpeggio — zigzag contour over pure Em(add9) ratios: 2=E3, ----
	// 12/5=G3, 3=B3, 4=E4, 9/2=F#4, 24/5=G4, 6=B4, 8=E5. The mask skips
	// steps (0 = rest) while the pitch sequence keeps advancing underneath,
	// so the contour that surfaces differs from the contour that's written.
	// Note-rate staircase up 4-6-8-12-16 and back down, with the triplet
	// stages (6ths, 12ths) kept shorter (24 beats) than the others (40):
	// up — 4ths at entry (beat 80), 6ths @120, 8ths @144, 12ths @184,
	// 16ths @208; down — 12ths @380, 8ths @404, 6ths @444, 4ths @468, so
	// the outro rings out over calm quarters. Mask and pitch ride the
	// same switchable clock, so the pattern survives every rate change.
	arpRate = Select.kr(
		(elapsed >= (240 * e8)) + (elapsed >= (288 * e8))
		+ (elapsed >= (368 * e8)) + (elapsed >= (416 * e8))
		- (elapsed >= (760 * e8)) - (elapsed >= (808 * e8))
		- (elapsed >= (888 * e8)) - (elapsed >= (936 * e8)),
		[1, 1.5, 2, 3, 4]); // notes per quarter: 4/6/8/12/16 per whole note
	arpClk  = Impulse.ar(q * arpRate);
	arpTrig = arpClk * Demand.ar(arpClk, 0,
		Dseq([1,0.5,0.7, 0,0.8,0.5, 1,0,0.6, 0.7,0.5,0, 0.9,0.6,0, 0.8,0,0.5], inf))
	* (elapsed >= (160 * e8)); // arpeggio enters at beat 80
	arpRatio = Demand.ar(arpClk, 0,
		Dseq([3, 2, 9/2, 12/5, 4, 3, 6, 24/5, 9/2, 8, 6, 4, 24/5, 3, 9/2, 12/5, 4, 2], inf));
	arpF = fund * arpRatio;
	// mid-track arc: note decay stretches ~7x so the plucks bloom into
	// full tones, then shrinks back (rises from ~2:03, peaks ~2:44)
	susArc = EnvGen.kr(Env([0, 0, 1, 0], [560 * e8, 30, 30], \sin));
	// in the outro the sustain grows again: the slow quarters ring out long
	outroSus = EnvGen.kr(Env([0, 0, 1], [total, outro * 0.7]));
	arp  = SinOsc.ar(arpF, 0, Decay2.ar(arpTrig, 0.002, 0.12 * (1 + (6 * susArc) + (10 * outroSus))))
	+ Pulse.ar(arpF, 0.15, Decay2.ar(arpTrig, 0.002, 0.04 * (1 + (6 * susArc) + (10 * outroSus))));
	arp  = arp + CombN.ar(arp, 0.5, e8 * 3, 1.8, 0.5); // dotted-eighth shimmer
	// the autopan glides to center and stops once the outro begins.
	// level is compensated for note density (1/sqrt of the rate, lagged
	// through the stage changes): sparse quarters play full, dense 16ths
	// pull back, so the arp sits evenly at center stage across the track
	// the susArc bloom is also compensated so it reads as longer notes,
	// not a louder passage (net lift ~2 dB at the peak)
	arp  = Pan2.ar(arp, SinOsc.kr(0.11) * 0.75 // autopan width: 0 = center, 1 = hard L/R
		* EnvGen.kr(Env([1, 1, 0], [total, 8])))
	* (arpAmp * (Lag.kr(arpRate, 3) ** -0.5)
		* ((1 + (6 * susArc)) ** -0.28));

	// ---- drone: octave-below root + root + pure fifth, very quiet ----
	// drone fades in alongside the bass so the intro is drums only
	drone = (SinOsc.ar(fund * 0.5) + (SinOsc.ar(fund) * 0.5)
		+ (SinOsc.ar(fund * 3/2) * 0.2)) * droneAmp
	* EnvGen.kr(Env.asr(4, 1, 4), elapsed >= (40 * e8));

	// ---- two-note harmonies — long pads from the top of cycle 2: ----
	// the root (E3) holds constant while the second voice moves every
	// 40 beats (80 eighths) through 6 intervals over it — B (fifth),
	// G (minor third), A (fourth), C# (major sixth), F# (major ninth),
	// E (octave) — then round again.
	// Instead of an elapsed-gate, the streams get a 630-eighth first
	// duration, so the sequence starts on its first interval exactly at
	// the cycle boundary and stays on the 40-beat grid. (harmDur is a
	// function: each demand stream needs its own copy of the sequence.)
	harmDur  = { Dseq([630 * e8, Dseq([80 * e8], inf)], 1) };
	harmTrig = TDuty.ar(harmDur.value, 0, 1, 0, 1); // gapFirst: silent through cycle 1
	harmF1   = fund * 2; // the constant root voice
	harmF2   = fund * Duty.ar(harmDur.value, 0,
		Dseq([3, Dseq([3, 12/5, 8/3, 27/8, 9/2, 4], inf)], 1));
	harmEnv  = Decay2.ar(harmTrig, 3, 18); // swells in, sustains the full 40-beat hold
	harm = Pan2.ar(SinOsc.ar(harmF1) + (VarSaw.ar(harmF1, 0, 0.4) * 0.3), -0.35)
	+ Pan2.ar(SinOsc.ar(harmF2) + (VarSaw.ar(harmF2, 0, 0.4) * 0.3), 0.35);
	harm = LPF.ar(harm, 2500) * harmEnv * harmAmp;

	// ---- evolving pink-noise wash — fades in over 10 s at the top of ----
	// cycle 2; the resonant filter sweeps on its own slow random walk
	pinkEnv = EnvGen.kr(Env.asr(10, 1, 6), elapsed >= cycle);
	pink = RLPF.ar(PinkNoise.ar,
		LFNoise2.kr(0.08).exprange(250, 5000), 0.3)
	* LFNoise2.kr(0.15).range(0.4, 1) * pinkEnv * pinkAmp;

	// everything except the arpeggio fades out slowly (12 s) at the end
	// of cycle 2, leaving the arp alone for the disintegrating outro
	outroFade = EnvGen.kr(Env([1, 1, 0], [total - 12, 12], [0, -2]));
	mix = ((((drums + clap + bass + drone + pink) ! 2) + harm) * outroFade)
	+ arp;

	// ---- evolving bitcrusher on the whole mix ----
	// sample-rate reduction (Latch) and bit depth both wander on slow
	// noise LFOs; the wet amount swells and recedes once per full cycle,
	// so each cycle degrades into crunch and comes back out clean.
	// extreme settings: at the peak of each cycle the track very nearly
	// disintegrates — sample rates down into the hundreds, under 2 bits.
	crushSR = LFNoise2.kr(0.09).exprange(300, 9000);
	bits    = LFNoise2.kr(0.07).range(1.5, 8);
	crush   = Latch.ar(mix, Impulse.ar(crushSR)).round(2 ** bits.neg * 2);
	// nearly dry for the first minute, then the effect ramps up over the
	// next minute or so; from there it breathes once per cycle at depth —
	// and relaxes through the outro so the ending rings out mostly clean
	wet     = (0.06 + (0.89
		* EnvGen.kr(Env([0, 0, 1], [60, 65], [0, 3]))
		* SinOsc.kr(1/cycle, 1.5pi).range(0.35, 1)))
	* EnvGen.kr(Env([1, 1, 0.25], [total, outro * 0.7]));
	mix     = (mix * (1 - wet)) + (crush * wet);

	// a little shared room on everything — after the crusher, so the
	// crunch gets some air around it too
	mix = FreeVerb.ar(mix, revMix, 0.65, 0.4);

	// very gentle ~1.4:1 glue compression with light makeup — just a touch
	// of cohesion; loudness normalization (flat gain) lives in make_mp3.sh
	mix = Compander.ar(mix, mix, 0.4, 1, 0.7, 0.005, 0.15) * 1.15;

	// the intro: the whole finished mix rides a delay line while a filtered
	// pink-noise riser sweeps up (200 Hz -> 8 kHz) across the 5 s, peaks
	// right as the downbeat kick lands, then fades out over the first 5 s
	// of the drums. The delay shifts audio only — every gate and pattern
	// phase inside the piece is untouched
	mix = DelayN.ar(mix, intro, intro)
	+ (RLPF.ar(PinkNoise.ar(2 ! 2), XLine.kr(200, 8000, intro), 0.3)
		* EnvGen.kr(Env([0, 0.1, 0.25, 0], [0.5, intro - 0.5, 10], \sin)));

	// master envelope: no fade-in (the downbeat kick must land at full
	// strength on sample one), hold through both cycles and the outro,
	// 6 s fade, then free
	master = EnvGen.kr(
		Env([1, 1, 0], [trackEnd - 6, 6], [0, -3]),
		doneAction: 2);
	Limiter.ar(mix * 0.5, 0.9) * master;
}
