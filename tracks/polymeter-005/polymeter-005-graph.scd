// polymeter-005-graph.scd — the single source of truth for the synth graph.
// Loaded by polymeter-005.scd (live playback) and render.scd (offline render).
//
// 9/8 at quarter = 170, just intonation on E minor pentatonic (E G A B D).
// A harpsichord-ish plucked figure counts the bar in threes — a fast waltz,
// 3+3+3 — while polymeter-003's small bell runs the same 6-step arp that ends
// polymeter-004. Nine against six: they realign every two bars (18 eighths =
// three arp cycles), which is the piece's whole clock.
//
//   eighth  1     4     7   9
//   harp   |--3--|--3--|--3--|        the waltz: three groups of three
//   bell   |---6---|---6--            six steps, so it walks across the bar
//   lock   |============|============|  every two bars, on the downbeat
//
// It is built to follow polymeter-004's outro: that ends on the same bell arp
// over a ringing comb delay, so this track opens on the bell alone and the
// harpsichord steps in underneath it eight bars later.
//
// The harpsichord is the Karplus pluck of polymeter-003's voice 2 (the one
// that became 004's bass), taken high and doubled an octave up — the 8' and 4'
// courses of a harpsichord — with a short, bright decay and a noise tick for
// the jack. Everything else is the same family: a low pluck on its own
// six-step cycle, and a 3-step delay on the harpsichord, as in 004.
//
// The build (bars of 9/8):
//   bar 1    the bell arp alone, carrying over from 004's outro
//   bar 9    the harpsichord figure enters
//   bar 17   its 3-step delay opens up
//   bar 25   the low pluck enters on its own 6-step cycle, under the waltz
//   bar 49   a second harpsichord voice a fifth above, on its own 9-step mask
//   bar 97   breakdown: the harpsichord alone, deeper in the delay
//   bar 109  everything back
//   bar 133  the close: the bell arp alone again, fading over the last 6 bars

{
	var q = 170/60;              // tempo: quarter = 170
	var e8 = 1 / (q * 2);        // eighth-note duration — the grid step
	var barDur = 9 * e8;         // one 9/8 bar (~1.59 s)
	var bars = 144;
	var total = bars * barDur;
	var elapsed = Sweep.kr(0, 1);
	var fund = 82.407;           // E2 — every pitch below is fund * a JI ratio

	// ---- layer levels: muck about here (0 mutes a layer) ----
	var harpAmp  = 0.5;
	var harp2Amp = 0.32;         // the second voice, a fifth above
	var bellAmp  = 0.3;
	var lowAmp   = 0.5;
	var delAmp   = 0.3;          // the harpsichord's 3-step delay
	var revMix   = 0.22;

	// the harpsichord's bar: nine steps counted 1 & a 2 & a 3 & a. The three
	// group heads carry the weight; the rest are the ornaments between them.
	var harpMask  = [1.0, 0, 0.5, 0.9, 0, 0.45, 0.85, 0.5, 0.4];
	// E minor pentatonic, E4-E5. Nine notes against the bell's six, so the
	// pairing of note and arp note changes every bar and comes back every two.
	var harpPitch = [8, 6, 64/9, 24/5, 16/3, 8, 64/9, 6, 16/3];
	//               E5  B4  D5    G4    A4    E5  D5    B4  A4
	// the second voice: sparser, a fifth above where it speaks
	var harp2Mask  = [0, 0.7, 0, 0.6, 0, 0.55, 0, 0.5, 0.45];
	var harp2Pitch = [12, 9, 32/3, 12, 8, 9, 32/3, 12, 9];
	//                B5  G5 A5     B5  E5 G5 A5    B5  G5
	// the low pluck runs six steps, not the bar's nine, so it rotates against
	// the waltz and comes back round with it every two bars — the same
	// relationship the bell has. Three hits per cycle and six notes, so the
	// line itself takes four bars to repeat: E1 G1 D2 B1 G1 A1.
	var lowMask  = [1.0, 0, 0.7, 0, 0.8, 0];
	var lowPitch = [1/2, 3/5, 8/9, 3/4, 3/5, 2/3];
	// polymeter-004's outro arp, note for note: six steps, so it rotates
	var bellMask  = [1, 0.7, 0.9, 0.6, 0.85, 0.8];
	var bellPitch = [4, 2, 32/9, 12/5, 3, 8/3];   // E4 E3 D4 G3 B3 A3

	var clk, harpTrig, harpVel, harpF, harp, harp2Trig, harp2Vel, harp2F, harp2;
	var lowTrig, lowVel, lowF, low, bellTrig, bellF, bell;
	var breakGate, harpDel, delFade, mix, master;

	RandSeed.ir(1, 20260916);    // reproducible renders

	clk = Impulse.ar(q * 2);     // the eighth-note clock: 9 steps to the bar

	// the breakdown, bars 97-109: everything but the harpsichord steps out
	breakGate = (elapsed < (96 * barDur)) + (elapsed >= (108 * barDur));

	// ---- the harpsichord: two plucked courses an octave apart ----
	// Pluck with a low coef rings bright and long-ish; the pair at f and 2f is
	// the 8' and 4' course, and the noise tick on top is the jack's clatter,
	// which is what makes a harpsichord read as plucked rather than struck.
	harpTrig = clk * (elapsed >= ((8 * barDur) - 0.01))
	* Demand.ar(clk, 0, Dseq(harpMask, inf));
	harpVel = Latch.ar(harpTrig, harpTrig);
	harpF = (fund * Demand.ar(harpTrig, 0, Dseq(harpPitch, inf))).max(20);
	harp = Pluck.ar(WhiteNoise.ar(0.8), harpTrig, 0.05, 1/harpF, 1.4, 0.18)
	+ (Pluck.ar(WhiteNoise.ar(0.6), harpTrig, 0.05, 1/(harpF * 2), 0.9, 0.22) * 0.5);
	harp = harp + (HPF.ar(WhiteNoise.ar(Decay2.ar(harpTrig, 0.0005, 0.008)), 4000) * 0.5);
	harp = (harp * 1.6).tanh * Lag.ar(harpVel, 0.002);

	harp2Trig = clk * (elapsed >= ((48 * barDur) - 0.01)) * breakGate
	* Demand.ar(clk, 0, Dseq(harp2Mask, inf));
	harp2Vel = Latch.ar(harp2Trig, harp2Trig);
	harp2F = (fund * Demand.ar(harp2Trig, 0, Dseq(harp2Pitch, inf))).max(20);
	harp2 = Pluck.ar(WhiteNoise.ar(0.7), harp2Trig, 0.05, 1/harp2F, 1.1, 0.2);
	harp2 = harp2 + (HPF.ar(WhiteNoise.ar(Decay2.ar(harp2Trig, 0.0005, 0.006)), 5000) * 0.4);
	harp2 = (harp2 * 1.4).tanh * Lag.ar(harp2Vel, 0.002);

	// ---- the low pluck: six steps against the bar's nine ----
	lowTrig = clk * (elapsed >= ((24 * barDur) - 0.01)) * breakGate
	* Demand.ar(clk, 0, Dseq(lowMask, inf));
	lowVel = Latch.ar(lowTrig, lowTrig);
	lowF = (fund * Demand.ar(lowTrig, 0, Dseq(lowPitch, inf))).max(20);
	low = Pluck.ar(WhiteNoise.ar(0.8), lowTrig, 0.05, 1/lowF, 2.2, 0.4);
	low = low + (SinOsc.ar(lowF, 0, Decay2.ar(lowTrig, 0.004, 0.3)) * lowVel * 0.5);
	low = (low * 1.8).tanh * Lag.ar(lowVel, 0.002);

	// ---- polymeter-003's bell on polymeter-004's outro arp ----
	// six steps against the harpsichord's nine: the two meet every two bars
	bellTrig = clk * Demand.ar(clk, 0, Dseq(bellMask, inf));
	bellF = Latch.ar(fund * Demand.ar(clk, 0, Dseq(bellPitch, inf)), bellTrig).max(20);
	bell = (SinOsc.ar(bellF, 0, Decay2.ar(bellTrig, 0.002, 0.6))
		+ (SinOsc.ar(bellF * 3, 0, Decay2.ar(bellTrig, 0.002, 0.25)) * 0.4)) * 0.8;

	// ---- the harpsichord's 3-step delay, as in 004 ----
	// three eighths — one of the waltz's groups — so the echoes land on the
	// next group's head and the figure answers itself across the bar. It opens
	// from bar 17 and deepens through the breakdown.
	delFade = ((elapsed - (16 * barDur)) / (8 * barDur)).clip(0, 1);
	harpDel = CombC.ar(HPF.ar(harp + (harp2 * 0.5), 400), 0.6, 3 * e8,
		3 + (6 * (1 - breakGate)));
	harpDel = BHiShelf.ar(harpDel, 2500, 1, 4) * delFade
	* (delAmp * (1 + (0.8 * (1 - breakGate))));

	mix = Pan2.ar(harp, -0.12, harpAmp) + Pan2.ar(harp2, 0.3, harp2Amp)
	+ Pan2.ar(harpDel, 0.25) + Pan2.ar(low, 0, lowAmp)
	+ Pan2.ar(bell, SinOsc.kr(1 / (4 * barDur)) * 0.5, bellAmp);
	mix = FreeVerb.ar(mix, revMix, 0.8, 0.4);
	// gentle glue; loudness normalization lives in make_mp3.sh
	mix = Compander.ar(mix, mix, 0.4, 1, 0.7, 0.005, 0.15) * 1.1;
	master = EnvGen.kr(Env([1, 1, 0], [total - (6 * barDur), 6 * barDur], [0, -3]),
		doneAction: 2);
	Limiter.ar(mix * 0.5, 0.9) * master;
}
