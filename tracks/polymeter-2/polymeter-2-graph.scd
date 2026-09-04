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
	var total = 912 * e8;        // 76 bars of 12/8 — the full-mix arc (~2:41)
	var outroLen = 192 * e8;     // 16 more bars: the crushed drums alone, dissolving
	var elapsed = Sweep.kr(0, 1);
	var fund = 82.407;           // E2 — JI fundamental, same family as track 1

	// ---- layer levels: muck about here (0 mutes a layer) ----
	var drumAmp   = 0.9;
	var bassAmp   = 0.55;
	var toneAmp   = 0.4;
	var blipAmp   = 0.55;
	var glitchAmp = 0.4;
	var screechAmp = 0.10;
	var droneAmp  = 0.10;
	var revMix    = 0.15;

	var gateA, gateB, clk16, kickTrig, snareTrig, hatTrig, kick, snare, hat, drums;
	var burstGate, burstTrig, snare2, drumsCrushed, drumCrushMix;
	var wid, mid, side, revAmt;
	var bassTrig, bassSlideTrig, bassSlide, bassF, bass;
	var toneTrig, toneF, tone;
	var screech;
	var blipClk, blipTrig, blipRatio, blipF, blipDry, blipDel, blip;
	var zapTrig, zap, stutter, clicks, glitch, glitchEnv, glitchDel;
	var drone, mix, master;
	var preDrop, gapRamp, gapCrushed, outroRamp, others, othersFade;
	var btRamp, btBus, btCrushed, strumTrig, strings, gtrRamp;

	// ---- drums: the track-1 drum rack, two sections ----
	// A (start to bar 24): syncopated 12/8 on a 3+3+2+2+2 carve-up.
	// Then 16 drumless bars (24-40) where bass/tone/blips/glitches run alone.
	// B (bar 40 on): half-time jungle two-step on the 16th grid. One pattern
	// stretched over 2 bars of 12/8 = 48 sixteenths = exactly the first
	// 3 bars of 4/4, so the classic kick-1 / snare-2-and-4 shape (with
	// per-bar ghost variations) tiles our meter without truncation.
	RandSeed.ir(1, 20260904); // seed the random UGens: renders reproduce
	gateA = elapsed < (288 * e8);
	gateB = elapsed >= (480 * e8);
	clk16 = Impulse.ar(q * 4);
	// the two naked bars before the drop (bars 38-40): blips and glitches
	// fall away, leaving bass + tone alone under maximum disintegration
	preDrop = (elapsed >= (456 * e8)) * (elapsed < (480 * e8));
	// climbs 0 -> 1 across the first 12 outro bars: drives the drum crush
	// to total dissolution after the rest of the mix has left
	outroRamp = ((elapsed - total) / (144 * e8)).clip(0, 1);
	kickTrig = (clk * gateA * Demand.ar(clk, 0,
		Dseq([1,  0,  0,  0.7,0,  0,  0,  0.9,0,  0.5,0,  0  ], inf)))
	+ (clk16 * gateB * Demand.ar(clk16, 0, Dseq([
		1,0,0,0,   0,0,0,0,   0,0,1,0,   0,0,0,0,
		1,0,0,0,   0,0,0,0,   0,0,1,0,   0,0,0.7,0,
		1,0,0,0.6, 0,0,0,0,   0,0,1,0,   0,0,0,0  ], inf)));
	snareTrig = (clk * gateA * Demand.ar(clk, 0,
		Dseq([0,  0,  0.4,0,  0,  1,  0,  0,  0.3,0,  1,  0.5], inf)))
	+ (clk16 * gateB * Demand.ar(clk16, 0, Dseq([
		0,0,0,0,   1,0,0,0,   0,0,0,0.4, 1,0,0,0,
		0,0,0,0,   1,0,0,0.3, 0,0,0,0,   1,0,0,0.4,
		0,0,0,0,   1,0,0,0,   0,0.4,0,0, 1,0,0.3,0 ], inf)));
	hatTrig = (clk * gateA * Demand.ar(clk, 0,
		Dseq([0.9,0.3,0.5,0.9,0.3,0.5,0.9,0.4,0.9,0.4,0.9,0.6], inf)))
	+ (clk16 * gateB * Demand.ar(clk16, 0, Dseq([
		0.8,0.2,0.4,0.3, 0.7,0.2,0.5,0.2, 0.8,0.3,0.4,0.2, 0.7,0.2,0.5,0.3,
		0.8,0.2,0.4,0.3, 0.7,0.2,0.5,0.2, 0.8,0.3,0.4,0.2, 0.7,0.2,0.5,0.3,
		0.8,0.2,0.4,0.3, 0.7,0.2,0.5,0.2, 0.8,0.3,0.4,0.2, 0.7,0.2,0.5,0.3 ], inf)));

	// kick tuned to E1 with a fast pitch drop + click; snare body at 9/4
	kick  = (SinOsc.ar(fund * 0.5 * (1 + (8 * Decay2.ar(kickTrig, 0.001, 0.07))),
		0, Decay2.ar(kickTrig, 0.005, 0.3)) * 1.6)
	+ (HPF.ar(WhiteNoise.ar(Decay2.ar(kickTrig, 0.001, 0.02)), 1000) * 0.5);
	snare = WhiteNoise.ar(Decay2.ar(snareTrig, 0.005, 0.16))
	+ SinOsc.ar(fund * 9/4, 0, Decay2.ar(snareTrig, 0.005, 0.09));
	hat   = HPF.ar(WhiteNoise.ar(Decay2.ar(hatTrig, 0.002, 0.05)), 9000);

	// second, brighter snare: hectic randomized 32nd-note bursts (seeded
	// above, so every render is identical), section B only. Dust opens
	// short burst windows; TRand varies each hit inside them.
	burstGate = Trig.ar(Dust.ar(0.45), 0.21);
	burstTrig = Impulse.ar(q * 8) * burstGate * gateB;
	snare2 = (HPF.ar(WhiteNoise.ar, 2500) + BPF.ar(WhiteNoise.ar(2), 3800, 0.3))
	* Decay2.ar(burstTrig * TRand.ar(0.25, 1, burstTrig), 0.001, 0.05) * 0.8;

	drums = (kick + snare + snare2 + (hat * 0.6)) * drumAmp;

	// on the drop, the drums get their own crusher: latch-downsampled at a
	// wandering rate, quantized to ~4 bits, driven hard — 75% wet in
	// section B, dry everywhere else (the 25% dry keeps the kick's punch).
	// the stutter glitch taps `drums` after this, so it chews the crushed
	// version too
	// in the outro the crusher takes over completely: sample rate collapses
	// toward gravel, bit depth falls toward 1, wet goes to 100%
	drumsCrushed = (Latch.ar(drums,
		Impulse.ar(LFNoise2.kr(0.5).exprange(1500, 8000) * (1 - (0.93 * outroRamp))))
		.round(2 ** (LFNoise2.kr(0.4).range(3.5, 5.5) - (2.5 * outroRamp)).neg * 2) * 5).tanh * 0.8;
	drumCrushMix = (Lag.kr(gateB, 0.5) * 0.6).max(outroRamp);
	drums = (drums * (1 - drumCrushMix)) + (drumsCrushed * drumCrushMix);

	// ---- bass, from bar 8: fat and distorted, four even hits per bar ----
	// on eighths 1-4-7-10 (dotted quarters); the fourth hit of every bar
	// slides down an octave, then the pitch snaps back for the downbeat
	bassTrig = clk * Demand.ar(clk, 0, Dseq([1,0,0, 0.9,0,0, 0.9,0,0, 1,0,0], inf))
	* (elapsed >= (96 * e8));
	bassSlideTrig = TDuty.ar(Dseq([9 * e8, Dseq([12 * e8], inf)], 1), 0, 1, 0, 1);
	bassSlide = EnvGen.ar(
		Env([1, 1, 0.5, 1], [0.06, (3 * e8) - 0.16, 0.1], [0, -4, 0]),
		bassSlideTrig);
	bassF = fund * bassSlide;
	// longitudinal: the filter's overall brightness opens across the track
	bass  = MoogFF.ar(Saw.ar(bassF * [1, 1.004]).sum + SinOsc.ar(bassF * 0.5),
		bassF * (3 + (6 * Decay2.ar(bassTrig, 0.005, 0.3))) * Line.kr(0.75, 1.8, total), 2.8)
	* Decay2.ar(bassTrig, 0.01, 0.45);
	bass  = (bass * 8).tanh * bassAmp; // hard tanh drive = the fat

	// ---- tone, from bar 16: an FM pluck with a signature — the rhythm is ----
	// 1, 2-and, 5-and, 7, 8-and, 11-and (3+6+3+3+6+3 of the 24 sixteenths)
	// and the pitch advances only on hits through a fixed six-note motif:
	// E3 B3 G3 E3 E4 B3 (pure JI ratios). The FM index envelope gives it a
	// bright kalimba-ish bite; the noise tick is the attack. Feeds the
	// moving blip delay below.
	toneTrig = Impulse.ar(q * 4) * Demand.ar(Impulse.ar(q * 4), 0,
		Dseq([1,0,0,0.8, 0,0,0,0,0, 0.9,0,0, 1,0,0,0.9, 0,0,0,0,0, 0.8,0,0], inf))
	* (elapsed >= (192 * e8));
	toneF = fund * Demand.ar(toneTrig, 0, Dseq([2, 3, 12/5, 2, 4, 3], inf));
	tone = SinOsc.ar(toneF,
		SinOsc.ar(toneF * 2) * (2.5 * Decay2.ar(toneTrig, 0.001, 0.08)),
		Decay2.ar(toneTrig, 0.002, 0.25))
	+ (HPF.ar(WhiteNoise.ar(Decay2.ar(toneTrig, 0.001, 0.01)), 3000) * 0.3);

	// ---- blips: sixteenth-note plinks on a 10-step (5/8) cycle that ----
	// rotates against the 12/8 bar; high JI ratios of E. Enters at bar 4.
	// mask rests (0) skip steps while the pitch line advances underneath
	blipClk  = Impulse.ar(q * 4);
	blipTrig = blipClk * Demand.ar(blipClk, 0,
		Dseq([1,0,0.7,0, 0.8,0, 0,0.9, 0,0.6], inf))
	* (elapsed >= (48 * e8)) * (1 - preDrop);
	blipRatio = Demand.ar(blipClk, 0,
		Dseq([4, 6, 9, 24/5, 8, 12, 9, 16, 48/5, 6], inf));
	blipF = fund * blipRatio;
	blipDry = SinOsc.ar(blipF, 0, Decay2.ar(blipTrig, 0.001, 0.09))
	+ SinOsc.ar(blipF * 2, 0, Decay2.ar(blipTrig, 0.001, 0.03) * 0.4);

	// ---- glitches, fading in from bar 16: three flavors ----
	// zaps: random-pitched resonant noise stabs on an irregular Dust clock;
	// stutter: the mix latched at collapsing sample rates, in short bursts;
	// clicks: thin dust up top
	glitchEnv = EnvGen.kr(Env.asr(6, 1, 4), elapsed >= (120 * e8))
	* (1 - preDrop.lag(0.2)); // glitches also clear out for the naked bars
	zapTrig = Dust.ar(LFNoise2.kr(0.11).range(0.4, 2.5));
	zap = BPF.ar(WhiteNoise.ar(4), TExpRand.ar(400, 6000, zapTrig), 0.15)
	* Decay2.ar(zapTrig, 0.001, 0.06);
	stutter = Latch.ar(drums + blipDry + (bass * 0.7), Impulse.ar(LFNoise2.kr(0.3).exprange(400, 3500)))
	* Decay2.ar(Dust.ar(1.2), 0.002, 0.07) * 1.5;
	clicks = HPF.ar(Dust2.ar(3), 4000) * 0.4;
	glitch = (zap + stutter + clicks) * glitchEnv;

	// ---- "screech" reworked, with the bar-48 drop: a badly distorted ----
	// guitar strumming as fast as possible on a mid-high chord (E4-B4-E5,
	// pure JI). Each "string" fires slightly later per strum (the drag of
	// a pick across strings), detuned saw pairs into heavy clipping and an
	// amp-ish bandpass; strum rate wobbles around 12-15 Hz. Haas-widened,
	// ducked by every kick so it pumps with the beat.
	// left and right are two fully independent performances: separate strum
	// clocks (they drift against each other), wider per-channel detunings —
	// decorrelation is what makes the room feel large
	strumTrig = [Impulse.ar(LFNoise2.kr(0.3).range(11, 15)),
		Impulse.ar(LFNoise2.kr(0.27).range(11.5, 15.5))];
	// the guitar's own evolution (entry at bar 48 -> bar 76): a high B5
	// string gradually joins, and the layer bitcrushes deeper
	gtrRamp = ((elapsed - (576 * e8)) / (336 * e8)).clip(0, 1);
	strings = [0, 1].collect { |chan|
		var sum = [4, 6, 8].collect { |ratio, i|
			var trig = DelayN.ar(strumTrig[chan], 0.04, i * 0.006);
			Saw.ar(fund * ratio * [1 + (chan * 0.008), 1.01 - (chan * 0.007)]).sum
			* Decay2.ar(trig, 0.002, 0.25)
		}.sum;
		var hi = Saw.ar(fund * 12 * [1 + (chan * 0.006), 1.009 - (chan * 0.005)]).sum
		* Decay2.ar(DelayN.ar(strumTrig[chan], 0.04, 0.02), 0.002, 0.2);
		// pink noise riding each strum — string scrape and amp hiss,
		// distorted along with the chord so it stops sounding clean
		sum + (hi * 1.1 * gtrRamp)
		+ (PinkNoise.ar(2.8) * Decay2.ar(strumTrig[chan], 0.002, 0.38))
	};
	// heavy clipping, darker top (distance), then the thematic crusher:
	// wet, coarseness and bit depth all deepen with gtrRamp
	screech = HPF.ar(LPF.ar((strings * 14).tanh, 3800), 220);
	// (the latch rate floors at ~2.4 kHz so the arriving B5 string isn't
	// aliased away by the very crusher that deepens beneath it)
	screech = (screech * (1 - (0.65 * gtrRamp)))
	+ (Latch.ar(screech, Impulse.ar(6000 * (1 - (0.6 * gtrRamp))))
		.round(2 ** (7 - (4.5 * gtrRamp)).neg * 2) * (0.65 * gtrRamp));
	// big room, wet-forward, then the side channel expanded 1.8x — the
	// reverb tails are decorrelated (different inputs per side), so the
	// widening blows the room open rather than just panning harder
	screech = (screech * 0.45) + FreeVerb.ar(screech, 1, 0.95, 0.4);
	mid  = (screech[0] + screech[1]) * 0.5;
	side = (screech[0] - screech[1]) * 0.5 * 1.8;
	screech = [mid + side, mid - side]
	* (1 - (0.5 * Decay2.ar(kickTrig, 0.005, 0.25)))
	// enters 8 bars after the drop, fading in over a further 8 bars (~17 s).
	// the +5 curve keeps it near-inaudible for most of the fade and blooms
	// late — a true slow fade (the default -4 curve rises almost instantly)
	* EnvGen.kr(Env.asr(96 * e8, 1, 4, 5), elapsed >= (576 * e8)) * screechAmp;

	// ---- moving delays: comb lines whose delay times AND pan positions ----
	// wander on independent slow random walks — echoes drift around the
	// stereo field and detach rhythmically from their sources
	// longitudinal: both delay tails lengthen slowly across the whole track
	// (maxdelaytime must exceed the wander range's top — an undersized
	// buffer here reads out of bounds and can produce garbage samples)
	blipDel   = CombL.ar(blipDry + (tone * 0.6), 1.0, LFNoise2.kr(0.08).range(e8 * 1.5, e8 * 4.5), Line.kr(1, 3.5, total));
	glitchDel = CombL.ar(glitch, 0.8, LFNoise2.kr(0.15).range(e8 * 0.75, e8 * 3), Line.kr(0.8, 2.5, total));
	// the whole blip layer (delay tail included) ducks out for the naked
	// pre-drop bars — gating only the triggers left the echoes ringing
	blip = (Pan2.ar(blipDry, LFNoise2.kr(0.25) * 0.7)
		+ Pan2.ar(blipDel, LFNoise2.kr(0.21) * 0.9, 0.6))
	* (blipAmp * (1 - (preDrop.lag(0.4) * 0.92)));
	glitch = (Pan2.ar(glitch, LFNoise2.kr(0.4) * 0.8)
		+ Pan2.ar(glitchDel, LFNoise2.kr(0.33) * 0.9, 0.7)) * glitchAmp;

	// quiet root drone so the JI blips have a floor (ducked in the naked bars)
	drone = (SinOsc.ar(fund * 0.5) + (SinOsc.ar(fund) * 0.4)) * droneAmp
	* (1 - (preDrop.lag(0.5) * 0.85));

	// bass + tone get their own crusher whose ramp rises through the gap
	// and NEVER releases — they carry the disintegration through the drop,
	// so the drop stacks clean jungle drums on top of still-ruined bass/tone
	// instead of resetting the intensity
	btRamp = ((elapsed - (288 * e8)) / (168 * e8)).clip(0, 1);
	btBus = (bass ! 2) + Pan2.ar(tone, -0.2, toneAmp);
	btCrushed = Latch.ar(btBus, Impulse.ar(8000 * (1 - (0.85 * btRamp))))
	.round(2 ** (8 - (5 * btRamp)).neg * 2);
	btBus = (btBus * (1 - (0.75 * btRamp))) + (btCrushed * (0.75 * btRamp));

	// everything except the drums STOPS dead on the downbeat of bar 85 —
	// no fade — and the drums take it from there. (the 10 ms lag is just
	// declick, inaudible as a fade)
	othersFade = (elapsed < total).lag(0.01);
	others = (drone ! 2) + btBus + blip + glitch + screech;
	mix = (drums ! 2) + (others * othersFade);

	// through the drumless stretch the whole mix disintegrates by degrees:
	// crusher wet, coarseness and bit depth all ramp from bar 32 to bar 46,
	// hold through the two naked pre-drop bars — then vanish at the exact
	// instant of the drop, so the drop lands clean
	gapRamp = ((elapsed - (288 * e8)) / (168 * e8)).clip(0, 1) * (elapsed < (480 * e8));
	gapCrushed = Latch.ar(mix, Impulse.ar(9000 * (1 - (0.88 * gapRamp))))
	.round(2 ** (8 - (5.5 * gapRamp)).neg * 2);
	mix = (mix * (1 - (0.7 * gapRamp))) + (gapCrushed * (0.7 * gapRamp));

	// ---- longitudinal motion on the main mix ----
	// stereo width breathes on a very slow random walk; a drifting master
	// tilt filter dulls and reopens the top end over minutes; the reverb
	// swells to double depth through the drumless stretch and eases back
	wid  = LFNoise2.kr(0.025).range(0.65, 1.3);
	mid  = (mix[0] + mix[1]) * 0.5;
	side = (mix[0] - mix[1]) * 0.5 * wid;
	mix  = [mid + side, mid - side];
	mix  = LPF.ar(mix, LFNoise2.kr(0.03).exprange(4500, 16000));
	// general saturation on the whole mix — leans harder after the drop
	mix  = (mix * (1.6 + (0.9 * Lag.kr(gateB, 2)))).tanh * 0.55;
	revAmt = revMix * (1 + ((elapsed >= (288 * e8)) * (elapsed < (480 * e8))).lag(5));
	mix = FreeVerb.ar(mix, revAmt, 0.6, 0.35);
	// very gentle glue compression; loudness normalization is in make_mp3.sh
	mix = Compander.ar(mix, mix, 0.4, 1, 0.7, 0.005, 0.15) * 1.15;
	// no general fade: the outro IS the crushed drums dissolving; the last
	// 3 s just ease the remaining dust to silence
	master = EnvGen.kr(Env([1, 1, 0], [total + outroLen - 3, 3], [0, -3]), doneAction: 2);
	Limiter.ar(mix * 0.5, 0.9) * master;
}
