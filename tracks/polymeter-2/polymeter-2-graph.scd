// polymeter-2-graph.scd — the single source of truth for the synth graph.
// Loaded by polymeter-2.scd (live playback) and render.scd (offline render).
//
// 12/8 glitch groove at quarter = 170: the polymeter-1 drum rack re-grooved
// into a syncopated 12/8, a blip melody on a 10-sixteenth (5/8) cycle that
// rotates against the bar, three flavors of glitch, and comb delays whose
// times and pans both wander. All pitch is just intonation on E, like
// track 1.

{
	var q = 170/60;              // tempo: quarter = 170
	var e8 = 1 / (q * 2);        // eighth-note duration in seconds
	var clk = Impulse.ar(q * 2); // the eighth-note clock
	var total = 1008 * e8;       // 84 bars of 12/8 (~2:58)
	var elapsed = Sweep.kr(0, 1);
	var fund = 82.407;           // E2 — JI fundamental, same family as track 1

	// ---- layer levels: muck about here (0 mutes a layer) ----
	var drumAmp   = 0.9;
	var bassAmp   = 0.55;
	var toneAmp   = 0.4;
	var blipAmp   = 0.55;
	var glitchAmp = 0.4;
	var droneAmp  = 0.05;
	var revMix    = 0.15;

	var gateA, gateB, kickTrig, snareTrig, hatTrig, kick, snare, hat, drums;
	var bassTrig, bassSlideTrig, bassSlide, bassF, bass;
	var toneTrig, tone;
	var blipClk, blipTrig, blipRatio, blipF, blipDry, blipDel, blip;
	var zapTrig, zap, stutter, clicks, glitch, glitchEnv, glitchDel;
	var drone, mix, master;

	// ---- drums: the track-1 drum rack, two sections ----
	// A (start to bar 32): syncopated 12/8 on a 3+3+2+2+2 carve-up.
	// Then 16 drumless bars (32-48) where bass/tone/blips/glitches run alone.
	// B (bar 48 on): hectic — snare hammering every even eighth
	// (2,4,6,8,10,12), busier kick, denser hats.
	gateA = elapsed < (384 * e8);
	gateB = elapsed >= (576 * e8);
	kickTrig = clk * ((gateA * Demand.ar(clk, 0, Dseq([1,  0,  0,  0.7,0,  0,  0,  0.9,0,  0.5,0,  0  ], inf)))
		+ (gateB * Demand.ar(clk, 0, Dseq([1,  0,  0.6,0,  0.8,0,  0.7,0,  0.9,0,  0.6,0.8], inf))));
	snareTrig = clk * ((gateA * Demand.ar(clk, 0, Dseq([0,  0,  0.4,0,  0,  1,  0,  0,  0.3,0,  1,  0.5], inf)))
		+ (gateB * Demand.ar(clk, 0, Dseq([0,  0.8,0,  1,  0,  0.8,0,  1,  0,  0.8,0,  1  ], inf))));
	hatTrig = clk * ((gateA * Demand.ar(clk, 0, Dseq([0.9,0.3,0.5,0.9,0.3,0.5,0.9,0.4,0.9,0.4,0.9,0.6], inf)))
		+ (gateB * Demand.ar(clk, 0, Dseq([0.9,0.6,0.8,0.6,0.9,0.6,0.8,0.6,0.9,0.6,0.8,0.6], inf))));

	// kick tuned to E1 with a fast pitch drop + click; snare body at 9/4
	kick  = (SinOsc.ar(fund * 0.5 * (1 + (8 * Decay2.ar(kickTrig, 0.001, 0.07))),
		0, Decay2.ar(kickTrig, 0.005, 0.3)) * 1.6)
	+ (HPF.ar(WhiteNoise.ar(Decay2.ar(kickTrig, 0.001, 0.02)), 1000) * 0.5);
	snare = WhiteNoise.ar(Decay2.ar(snareTrig, 0.005, 0.16))
	+ SinOsc.ar(fund * 9/4, 0, Decay2.ar(snareTrig, 0.005, 0.09));
	hat   = HPF.ar(WhiteNoise.ar(Decay2.ar(hatTrig, 0.002, 0.05)), 9000);
	drums = (kick + snare + (hat * 0.6)) * drumAmp;

	// ---- bass, from bar 16: fat and distorted, four even hits per bar ----
	// on eighths 1-4-7-10 (dotted quarters); the fourth hit of every bar
	// slides down an octave, then the pitch snaps back for the downbeat
	bassTrig = clk * Demand.ar(clk, 0, Dseq([1,0,0, 0.9,0,0, 0.9,0,0, 1,0,0], inf))
	* (elapsed >= (192 * e8));
	bassSlideTrig = TDuty.ar(Dseq([9 * e8, Dseq([12 * e8], inf)], 1), 0, 1, 0, 1);
	bassSlide = EnvGen.ar(
		Env([1, 1, 0.5, 1], [0.06, (3 * e8) - 0.16, 0.1], [0, -4, 0]),
		bassSlideTrig);
	bassF = fund * bassSlide;
	bass  = MoogFF.ar(Saw.ar(bassF * [1, 1.004]).sum + SinOsc.ar(bassF * 0.5),
		bassF * (3 + (6 * Decay2.ar(bassTrig, 0.005, 0.3))), 2.8)
	* Decay2.ar(bassTrig, 0.01, 0.45);
	bass  = (bass * 8).tanh * bassAmp; // hard tanh drive = the fat

	// ---- lighter tone, from bar 24: a soft E3 pluck on the 16th grid at ----
	// 1, 2-and, 5-and, 7, 8-and, 11-and — a symmetric 3+6+3+3+6+3 carve-up
	// of the 24 sixteenths. It also feeds the moving blip delay below.
	toneTrig = Impulse.ar(q * 4) * Demand.ar(Impulse.ar(q * 4), 0,
		Dseq([1,0,0,0.8, 0,0,0,0,0, 0.9,0,0, 1,0,0,0.9, 0,0,0,0,0, 0.8,0,0], inf))
	* (elapsed >= (288 * e8));
	tone = SinOsc.ar(fund * 2, 0, Decay2.ar(toneTrig, 0.004, 0.18))
	+ (Pulse.ar(fund * 2, 0.3, Decay2.ar(toneTrig, 0.004, 0.07)) * 0.25);

	// ---- blips: sixteenth-note plinks on a 10-step (5/8) cycle that ----
	// rotates against the 12/8 bar; high JI ratios of E. Enters at bar 4.
	// mask rests (0) skip steps while the pitch line advances underneath
	blipClk  = Impulse.ar(q * 4);
	blipTrig = blipClk * Demand.ar(blipClk, 0,
		Dseq([1,0,0.7,0, 0.8,0, 0,0.9, 0,0.6], inf))
	* (elapsed >= (48 * e8));
	blipRatio = Demand.ar(blipClk, 0,
		Dseq([4, 6, 9, 24/5, 8, 12, 9, 16, 48/5, 6], inf));
	blipF = fund * blipRatio;
	blipDry = SinOsc.ar(blipF, 0, Decay2.ar(blipTrig, 0.001, 0.09))
	+ SinOsc.ar(blipF * 2, 0, Decay2.ar(blipTrig, 0.001, 0.03) * 0.4);

	// ---- glitches, fading in from bar 16: three flavors ----
	// zaps: random-pitched resonant noise stabs on an irregular Dust clock;
	// stutter: the mix latched at collapsing sample rates, in short bursts;
	// clicks: thin dust up top
	glitchEnv = EnvGen.kr(Env.asr(6, 1, 4), elapsed >= (192 * e8));
	zapTrig = Dust.ar(LFNoise2.kr(0.11).range(0.4, 2.5));
	zap = BPF.ar(WhiteNoise.ar(4), TExpRand.ar(400, 6000, zapTrig), 0.15)
	* Decay2.ar(zapTrig, 0.001, 0.06);
	stutter = Latch.ar(drums + blipDry + (bass * 0.7), Impulse.ar(LFNoise2.kr(0.3).exprange(400, 3500)))
	* Decay2.ar(Dust.ar(1.2), 0.002, 0.07) * 1.5;
	clicks = HPF.ar(Dust2.ar(3), 4000) * 0.4;
	glitch = (zap + stutter + clicks) * glitchEnv;

	// ---- moving delays: comb lines whose delay times AND pan positions ----
	// wander on independent slow random walks — echoes drift around the
	// stereo field and detach rhythmically from their sources
	blipDel   = CombL.ar(blipDry + (tone * 0.6), 0.7, LFNoise2.kr(0.08).range(e8 * 1.5, e8 * 4.5), 1.5);
	glitchDel = CombL.ar(glitch, 0.5, LFNoise2.kr(0.15).range(e8 * 0.75, e8 * 3), 1.2);
	blip = (Pan2.ar(blipDry, LFNoise2.kr(0.25) * 0.7)
		+ Pan2.ar(blipDel, LFNoise2.kr(0.21) * 0.9, 0.6)) * blipAmp;
	glitch = (Pan2.ar(glitch, LFNoise2.kr(0.4) * 0.8)
		+ Pan2.ar(glitchDel, LFNoise2.kr(0.33) * 0.9, 0.7)) * glitchAmp;

	// quiet root drone so the JI blips have a floor
	drone = (SinOsc.ar(fund * 0.5) + (SinOsc.ar(fund) * 0.4)) * droneAmp;

	mix = ((drums + bass + drone) ! 2) + Pan2.ar(tone, -0.2, toneAmp) + blip + glitch;
	mix = FreeVerb.ar(mix, revMix, 0.6, 0.35);
	// very gentle glue compression; loudness normalization is in make_mp3.sh
	mix = Compander.ar(mix, mix, 0.4, 1, 0.7, 0.005, 0.15) * 1.15;
	master = EnvGen.kr(Env([1, 1, 0], [total - 8, 8], [0, -3]), doneAction: 2);
	Limiter.ar(mix * 0.5, 0.9) * master;
}
