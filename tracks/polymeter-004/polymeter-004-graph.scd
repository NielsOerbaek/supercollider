// polymeter-004-graph.scd — the single source of truth for the synth graph.
// Loaded by polymeter-004.scd (live playback) and render.scd (offline render).
//
// 15/4 at quarter = 170, just intonation on E. One bar is 15 quarters
// (30 eighths, ~5.29 s) and the layers carve it differently — that
// disagreement is the whole track:
//
//   eighth   1              11             21            30
//   bass    |----- 10 -----|----- 10 -----|----- 10 -----|   three cells of five
//   drums   |--6--|--6--|--6--|--6--|--6--|                  five beats in threes
//   arp 6   |--6--|--6--|--6--|--6--|--6--|                  locks to the drum groups
//   arp 8   |---8---|---8---|---8---|---8--                  30 mod 8 = 6: rotates
//   deep    |X            X                |                  beat 1 and 7-and
//
// Bass is voice 2 of polymeter-003 (the warm Karplus-Strong pluck) dropped
// to E1, and it transforms across the track: front and centre and slapped at
// the top, then progressively further back, longer and more sustained, on a
// 3-step delay with high feedback. See the bass arc below. Each cell accents 1, 2-and and 3-and — a front-loaded 3-2 kick-off
// then five eighths of air — with ghost notes filling the tail, placed
// differently in each cell so the bar reads as a 15/4 phrase and not as one
// cell played three times. Every pitch in the track — bass, arps and the
// deep marker — is E minor pentatonic (E G A B D) in just intonation. The
// three cells centre on E, G and D, and the line inside each leaps rather
// than walks, changing direction on nearly every hit; the last cell sags to
// a low D before picking its way home. Nothing resolves — it just leans back
// onto E on every downbeat.
//
// Drums are the polymeter-002 rack, bitcrushed the way that track crushes
// its drop: latch-downsampled at a wandering rate and quantized to ~4 bits,
// mixed against the dry so the kick keeps its punch. The kick is
// four-on-the-floor — every one of the 15 quarters, accented on the five
// group heads — so the 3-grouping is carried by the hat accents, while the
// snare deliberately runs across it in twos. That stacks the bar four deep:
//
//   kick   every 1 quarter    15 hits
//   snare  every 2            beats 2 4 6 8 10 12 14, +15 to pin the phase
//          (and from the moment it lands, the kick drops four-on-the-floor
//           for a syncopated two-step that interlocks with it)
//   hat    accents every 3    the five group heads
//   bass   cells of 5         three per bar
//
// 15 is the least common multiple of 3 and 5, so those two only ever meet on
// the downbeat; 2 does not divide 15 at all, which is why the snare needs its
// beat-15 hit to keep from flipping over bar to bar.
//
// Under all of it, polymeter-003's voice 1 — the deep drone-bass pluck —
// marks just two points in the bar: beat 1 and the and of beat 7 (grid steps
// 0 and 13). Thirteen steps apart, then seventeen back round, so the bar is
// pinned lopsidedly; step 13 is an odd step, so it lands off the
// four-on-the-floor kick entirely. It takes E under cell A and G under cell
// B, tracking the root motion.
//
// Two of polymeter-003's lighter voices arp on top: its small bell (voice 6)
// on a 6-step cycle, which divides 30 exactly and so locks to the drum
// groups, and its glass (voice 8) on an 8-step cycle, which does not — it
// shifts 6 steps every bar and comes back round every 4 bars.
//
// The build:
//   bar 1   bass and the deep bar-marker alone — a two-bar intro
//   bar 3   hat, and claps on 1 5 6 10 11 15 — the first and last beat of each
//           bass cell. No kick at all yet.
//   bar 7   the kit proper, in a 5/4 two-step: snare on 2-and and 5 of every
//           five-beat cell, kick on 1 and 3-and, so kick and snare alternate
//           3-2-3-2 — plus polymeter-002's scattered 32nd-note jungle bursts
//           and the hat doubling to a 16th line
//   bar 11  both arps at once — the 6-step bell hard left, the 8-step glass
//           hard right, arriving together so the split opens in one move
//   bar 20  halfway, and the peak of the crush arc: the kit cuts out and
//           polymeter-001's clap takes over alone on the full 3-2 pattern
//           (1 2-and 3-and 5 6 7-and 8-and 10 11 12-and 13-and 15). The arps
//           switch to a second, more active form, and the plucky bass walks
//           back out of the distance into clear view over these eight bars
//   bar 28  the kit returns alongside the clap, in the original two-step:
//           kick 0 5 12 21 27 against the even-beat backbeat. The bass stays
//           up front.
//   bar 37  outro: all percussion stops and the bass stops being played —
//           the arps run on over the comb delay feeding back on itself
//   bar 39  the whole thing fades over the last two bars

{
	var q = 170/60;              // tempo: quarter = 170
	var s8 = 1 / (q * 2);        // eighth-note duration (~0.176 s) — the grid step
	var barDur = 30 * s8;        // one 15/4 bar (~5.29 s)
	var drumBar = 2;             // hat + claps enter (downbeat of bar 3), no kick
	var snareBar = 6;            // the 5/4 two-step kit, 4 bars later
	var arpBar = 10;             // both arps, together — one entry, not two
	var clapBar = 20;            // halfway: the kit drops out, the clap takes over
	var kitReturnBar = 28;       // the kit comes back, now alongside the clap
	var outroBar = 36;           // all percussion stops; arps + delay feedback
	                             // (2 bars), then 2 bars of fade to the end
	var bars = 40;               // ~3:32
	var total = bars * barDur;
	var elapsed = Sweep.kr(0, 1);
	var fund = 82.407;           // E2 — the JI fundamental, as in tracks 1-3

	// ---- layer levels: muck about here (0 mutes a layer) ----
	var bassAmp  = 0.44;         // front-of-mix level at the top of the track
	var deepAmp  = 0.42;
	var drumAmp  = 1.2;
	// per-element trims — the kick sits well under its polymeter-002 weight
	// because it is driven hard and doubled by voice 1 underneath
	var kickLvl  = 0.5;
	var snareLvl = 1.5;
	var burstLvl = 1.7;
	var hatLvl   = 0.5;
	var hat16Lvl = 0.42;         // the offbeat 16th drive
	var clapAmp  = 1.05;         // the clap hits hard — it is carrying the half alone
	// measured equal: the bell voice is inherently ~5.4 dB hotter than the
	// glass at the same nominal amp, so these are not the same number
	var arp6Amp  = 0.25;
	var arp8Amp  = 0.40;
	// Crushing is an arc across the whole piece, not a setting: a half-sine
	// over the full length, starting near zero and peaking exactly at the
	// midpoint — bar 20, where the kit cuts out.
	// The arc is soft-capped: below crushKnee it is untouched (that is the
	// level the two-step drums arrive at in bar 7, ~0.45), and above it the
	// curve is compressed so the peak lands at crushCap instead of 1. It still
	// has a clear peak rather than a plateau — just a lower one.
	var crushKnee = 0.45;
	var crushCap  = 0.8;
	var drumCrushMax  = 0.9;     // wet share of the drum crusher at arc = 1
	var crushDriveMax = 6.2;     // (the cap means neither is ever reached)
	// the same arc also runs a crusher on the main bus for the whole track —
	// everything, not just the drums, and not just around the drop. Its wet
	// share follows the arc linearly, and its severity (latch rate, bit
	// depth, drive) scales with it too, so it is a faint grain early on and
	// real damage only near the peak.
	var masterCrushMax = 0.5;
	var revMix   = 0.2;          // the shared room, same as track 3

	// the bar on a 30-eighth grid. Rows are the three bass cells;
	// a value is that hit's velocity, 0 is a rest.
	//                 1    &    2    &    3    &    4    &    5    &
	var bassMask = [
		1.0, 0,   0.25, 0.85, 0,   0.9, 0,   0.22, 0,    0.3,   // cell A — E
		1.0, 0,   0.25, 0.85, 0,   0.9, 0,   0,    0.24, 0,     // cell B — G
		1.0, 0.2, 0,    0.85, 0,   0.9, 0,   0.22, 0,    0.35   // cell C — Bb
	];
	// one entry per hit, in order — the pitch stream advances only when the
	// bass actually speaks. Everything is E minor pentatonic (E G A B D;
	// 1, 6/5, 4/3, 3/2, 16/9 in JI) and the notes are written as absolute
	// scale degrees rather than one interval shape transposed onto three
	// roots — transposing is what was generating the chromatic notes, since
	// the b3 of G is Bb and the b3 of Bb is Db. Angularity now comes from
	// the leaps: the line changes direction on nearly every hit.
	var bassPitch = [
		// cell A, centred on E — E1 E2 D2 G1 D2 E1
		1/2,  1,    8/9,  3/5,  8/9,  1/2,
		// cell B, centred on G — G1 D2 B1 E2 D2
		3/5,  8/9,  3/4,  1,    8/9,
		// cell C, centred on D and sagging home — D1 D2 A1 B1 G1 E1
		4/9,  8/9,  2/3,  3/4,  3/5,  1/2
	];

	// the deep bar-marker: beat 1 (step 0) and 7-and (step 13), nothing else
	var deepMask = [
		1.0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0.85, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	];
	var deepPitch = [1, 6/5];    // E under cell A, G under cell B

	// the drums, same 30-eighth grid. Quarters are the even steps.
	//
	// bars 3-6: no kick. Claps on beats 1 5 6 10 11 15 — steps 0 8 10 18 20
	// 28 — which is the first and last beat of each five-beat bass cell, so
	// the claps frame the bass's grouping before the kit arrives.
	var clapIntroMask = [
		1.0,  0, 0, 0, 0, 0, 0, 0, 0.85, 0,
		0.95, 0, 0, 0, 0, 0, 0, 0, 0.85, 0,
		0.95, 0, 0, 0, 0, 0, 0, 0, 0.85, 0
	];
	// bars 7-19: a 5/4 two-step. Each ten-step cell is one 5/4 bar, counted
	// 1 & 2 & 3 & 4 & 5 &. Snare on 2-and and 5 (cell steps 3 and 8); kick on
	// 1 and 3-and (0 and 5), dropping cell B's 3-and to keep it sparse. Kick
	// and snare alternate 3-2-3-2 — together they spell out almost exactly
	// the clap pattern that takes over at bar 20.
	var kick54 = [
		1.0,  0, 0, 0, 0, 0.8, 0, 0, 0, 0,
		0.95, 0, 0, 0, 0, 0,   0, 0, 0, 0,
		0.95, 0, 0, 0, 0, 0.8, 0, 0, 0, 0
	];
	var snare54 = [
		0, 0, 0, 0.85, 0, 0, 0, 0, 1.0, 0,
		0, 0, 0, 0.85, 0, 0, 0, 0, 1.0, 0,
		0, 0, 0, 0.85, 0, 0, 0, 0, 1.0, 0
	];
	// bars 28-36, after the drop: the original two-step. The kick weaves on
	// steps 0 5 12 21 27, all clear of the backbeat's even steps, so the two
	// interlock rather than stack. The backbeat runs in TWOS — beats 2 4 6 8
	// 10 12 14, then 15: fifteen is odd, so an even-beat pattern would flip
	// phase every bar, and the extra hit on 15 is what pins it.
	var kickTwoStep = [
		1.0, 0, 0, 0, 0, 0.85, 0, 0, 0, 0,
		0, 0, 1.0, 0, 0, 0, 0, 0, 0, 0,
		0, 0.8, 0, 0, 0, 0, 0, 0.85, 0, 0
	];
	var snareMask = [
		0, 0, 1.0, 0, 0,   0, 0.9, 0, 0,    0,
		1.0, 0, 0,   0, 0.9, 0, 0,   0, 1.0,  0,
		0, 0, 0.9, 0, 0,   0, 1.0, 0, 0.75, 0
	];
	var hatMask = [
		0.75, 0.5, 0.3, 0.5, 0.3, 0.5, 0.75, 0.5, 0.3, 0.5,
		0.3,  0.5, 0.75, 0.5, 0.3, 0.5, 0.3, 0.5, 0.75, 0.5,
		0.3,  0.5, 0.3, 0.5, 0.75, 0.5, 0.3, 0.5, 0.3, 0.5
	];

	// the clap, from the halfway point: 1, 2-and, 3-and, 5, 6, 7-and, 8-and,
	// 10, 11, 12-and, 13-and, 15 — steps 0 3 5 8 10 13 15 18 20 23 25 28.
	// That is a perfect 3-2 alternation: six five-step cycles across the bar,
	// which is the BASS's grouping, not the kit's. The drums that just left
	// were counting in threes; the clap that replaces them counts in fives,
	// locking to the bass cells instead.
	var clapMask = [
		1.0,  0, 0, 0.9, 0, 0.95, 0, 0, 0.88, 0,
		0.95, 0, 0, 0.9, 0, 0.95, 0, 0, 0.88, 0,
		0.95, 0, 0, 0.9, 0, 0.95, 0, 0, 0.88, 0
	];

	// From bar 20 — the eight bars where the clap plays alone and the arps are
	// the only melodic movement left — both arps take a second, more active
	// form: no rests, wider leaps, and a level lift while they are exposed.
	// They keep the new material after the kit returns; it is a development,
	// not a detour.
	var arp6MaskAlt  = [1, 0.7, 0.9, 0.6, 0.85, 0.8];
	var arp6PitchAlt = [4, 2, 32/9, 12/5, 3, 8/3];         // E4 E3 D4 G3 B3 A3
	var arp8MaskAlt  = [1, 0.6, 0.85, 0.6, 0.9, 0.55, 0.8, 0.6];
	var arp8PitchAlt = [8, 24/5, 64/9, 6, 16/3, 8, 4, 6];  // E5 G4 D5 B4 A4 E5 E4 B4

	// the two arps, on the same eighth grid but in their own cycle lengths.
	// Pitches are the same E minor pentatonic pool as the bass (E G A B D),
	// moved up two and three octaves, so the arps spell the same harmony the
	// bass walks underneath.
	// 6 steps = 3 quarters = exactly one drum group, so this one locks.
	var arp6Mask  = [1, 0.6, 0.85, 0.5, 0, 0.75];
	var arp6Pitch = [2, 12/5, 3, 32/9, 2, 8/3];            // E3 G3 B3 D4 (E3) A3
	// 8 steps against a 30-step bar: shifts 6 steps a bar, round every 4.
	var arp8Mask  = [0.9, 0.5, 0.7, 0.55, 0.8, 0.45, 0.7, 0.5];
	var arp8Pitch = [4, 64/9, 16/3, 8, 24/5, 4, 6, 64/9];  // E4 D5 A4 E5 G4 E4 B4 D5

	var clk, bassTrig, bassVel, bassF, bass;
	var bassRamp, bassDecay, bassDry, bassDel, bassRev, delayFade;
	var bassRise, bassEmerge, bassLvl, rawArc, sec1, sec2, sec3;
	var deepTrig, deepF, deep;
	var drumGate, snareGate, kitGate, kickTrig, snareTrig, hatTrig, kick, snare, hat;
	var clapTrig, clapEnv, clap, kickDrive, kickSub;
	var burstGate, burstTrig, snare2, drums, drumsCrushed, clk16, hat16Trig, hat16;
	var crushArc, drumCrush, crushDrive, masterCrush, mixCrushed;
	var outroGate, outroDuck;
	var arp6Trig, arp6F, arp6, arp8Trig, arp8F, arp8, arpAlt, arpEvo, arpLift;
	var mix, master;

	RandSeed.ir(1, 20260910); // reproducible renders

	clk = Impulse.ar(q * 2);     // the eighth-note clock: 30 steps to the bar

	// the crush arc: 0 -> 1 -> 0 across the piece, peaking at the midpoint
	// the outro: at bar 37 every percussion layer stops and the bass stops
	// being played. The comb delay keeps regenerating from its own feedback,
	// so what is left is the arps over a bass that is only echoes of itself.
	// Ducking the delay's INPUT (not just the dry) is what makes it feedback
	// rather than a tail — nothing new goes in.
	outroGate = elapsed < (outroBar * barDur);
	outroDuck = Lag.kr(outroGate, 1.2);

	rawArc      = ((elapsed / total).clip(0, 1) * pi).sin;
	crushArc    = rawArc - ((rawArc - crushKnee).max(0)
		* (1 - ((crushCap - crushKnee) / (1 - crushKnee))));
	drumCrush   = 0.12 + ((drumCrushMax - 0.12) * crushArc);
	crushDrive  = 1.2 + ((crushDriveMax - 1.2) * crushArc);
	masterCrush = crushArc * masterCrushMax;

	// ---- bass: polymeter-003's voice 2, an octave down ----
	// The trigger carries its own velocity, so Latch holds it for the whole
	// note. Velocity is applied AFTER the drive, not before: saturating a
	// scaled excitation squashes a 0.22 ghost and a 1.0 accent to the same
	// level and the groove goes flat. Constant excitation -> constant tanh
	// character -> then scale, so the ghosts stay ghosts. maxdelaytime is
	// raised from the 0.03 of track 3 (E1 needs a 24 ms delay line); decay
	// and coef are voice 2's verbatim. Pluck refills its delay line on every
	// trigger, so the line is monophonic and each hit cuts the one before.
	bassTrig = clk * outroGate * Demand.ar(clk, 0, Dseq(bassMask, inf));
	bassVel  = Latch.ar(bassTrig, bassTrig);
	bassF    = (fund * Demand.ar(bassTrig, 0, Dseq(bassPitch, inf))).max(20);
	// The bass's arc. From bar 3 it recedes: six knobs move together — level
	// falls, the Pluck's decay stretches and its loop damping eases so notes
	// ring instead of dying, the tanh drive backs off (the drive is most of
	// what reads as "slap"), the sub's envelope lengthens, the top rolls away
	// with distance, and the delay and reverb come up underneath. It keeps
	// receding until the drop at bar 20, then walks back out across the
	// eight clap-only bars — plucky, front, and with the delay back at its
	// opening settings — and stays there through the two-step section.
	// bassRamp is 0 at the front and ~0.47 at its furthest point.
	bassRise   = ((elapsed - (2 * barDur)) / (total - (2 * barDur))).clip(0, 1)
		.min((clapBar - 2) / (bars - 2));
	bassEmerge = ((elapsed - (clapBar * barDur))
		/ ((kitReturnBar - clapBar) * barDur)).clip(0, 1);
	bassRamp   = bassRise * (1 - bassEmerge);
	// back in a much denser mix than the one it left, so it comes back
	// lifted, or "clear view" would just mean level with the intro
	bassLvl    = bassAmp * (1 + (0.5 * bassEmerge));
	bassDecay = 2 + (7 * bassRamp);
	bass = Pluck.ar(WhiteNoise.ar(0.8), bassTrig, 0.05, 1/bassF,
		bassDecay, 0.4 - (0.12 * bassRamp));
	bass = (bass * (2.2 - (1.35 * bassRamp))).tanh * Lag.ar(bassVel, 0.002);
	bass = bass + (SinOsc.ar(bassF, 0,
		Decay2.ar(bassTrig, 0.004, 0.3 + (0.7 * bassRamp))) * bassVel * 0.6);
	bass = LPF.ar(bass, 5000 - (3400 * bassRamp));
	bassDry = bass * (1 - (0.62 * bassRamp));
	// a 3-step delay — 3 eighths, exactly one drum group — with fairly high
	// feedback: decaytime 8 s against a 0.53 s delay is ~4 dB per repeat, so
	// about 0.63 feedback at its height. The feedback itself grows across the
	// track (4 s -> 11 s of decay, roughly 0.45 -> 0.70 per repeat) so the
	// bloom keeps opening out to the last bar. It is fed the HIGH end of the
	// bass — the pick attack and string noise, not the body — so the repeats
	// ring bright and airy above the part rather than clouding the low end,
	// with a shelf lift on top. The x3 makes up what the high-pass removes.
	// in the outro the feedback is pushed long (+8 s of decay) — with the
	// bass back at its opening settings the comb would otherwise ring out in
	// about four seconds, and the outro is meant to be that feedback
	bassDel = HPF.ar(CombC.ar(HPF.ar(bass * outroDuck, 900) * 3, 0.6, 3 * s8,
		4 + (7 * bassRamp) + (8 * (1 - outroDuck))), 500);
	// the delay is silent for the first bar, blooms in across bars 2-6, and is
	// then on for the rest of the track — so the bass states the riff clean
	// once before the repeats start filling in around it. It keeps growing
	// with bassRamp after that, along with everything else.
	delayFade = ((elapsed - barDur) / (4 * barDur)).clip(0, 1);
	bassDel = BHiShelf.ar(bassDel, 2500, 1, 5)
	* delayFade * (0.15 + (0.11 * bassRamp));
	// the wet sends rise, but by less than the dry falls — otherwise the bass
	// changes character without ever actually receding, which is what a first
	// pass at this did (net level moved 0.5 dB across the whole track).
	bassRev = FreeVerb.ar(bass, 1, 0.85, 0.4) * (0.04 + (0.14 * bassRamp));

	// ---- the deep bar-marker: polymeter-003's voice 1, verbatim ----
	// sub + fundamental + a short second partial, under a 1.8 s bloom. The
	// gaps (2.3 s and 3.0 s) are long enough that each note is nearly gone
	// before the next, so it reads as a pin, not a drone.
	deepTrig = clk * outroGate * Demand.ar(clk, 0, Dseq(deepMask, inf));
	deepF = (fund * Demand.ar(deepTrig, 0, Dseq(deepPitch, inf))).max(20);
	deep = (SinOsc.ar(deepF * 0.5) + (SinOsc.ar(deepF) * 0.5)
		+ (SinOsc.ar(deepF * 2, 0, Decay2.ar(deepTrig, 0.002, 0.15)) * 0.3))
	* Decay2.ar(deepTrig, 0.005, 1.8);

	// ---- drums: the track-2 rack, in three sections ----
	// (10 ms of gate grace, as in track 3, so the entry hits aren't lost to
	// control-block timing — Sweep is control rate, the triggers audio rate)
	//   sec1  bars 3-6    hat only (the claps are below, outside the bus)
	//   sec2  bars 7-19   the 5/4 two-step
	//   sec3  bars 28-36  the original two-step, alongside the clap
	// kitGate is the kit's overall on/off: out for the eight clap-only bars
	// and for the outro.
	kitGate   = ((elapsed < (clapBar * barDur))
		+ (elapsed >= ((kitReturnBar * barDur) - 0.01))) * outroGate;
	drumGate  = (elapsed >= ((drumBar * barDur) - 0.01)) * kitGate;
	snareGate = (elapsed >= ((snareBar * barDur) - 0.01)) * kitGate;
	sec1 = (elapsed >= ((drumBar * barDur) - 0.01)) * (elapsed < ((snareBar * barDur) - 0.01));
	sec2 = (elapsed >= ((snareBar * barDur) - 0.01)) * (elapsed < (clapBar * barDur));
	sec3 = (elapsed >= ((kitReturnBar * barDur) - 0.01)) * outroGate;
	// every pattern stream runs on the same clock the whole time, so none
	// loses its place; the section gates only choose which one is heard
	kickTrig  = clk * (
		(Demand.ar(clk, 0, Dseq(kick54, inf))      * sec2)
		+ (Demand.ar(clk, 0, Dseq(kickTwoStep, inf)) * sec3));
	snareTrig = clk * (
		(Demand.ar(clk, 0, Dseq(snare54, inf))   * sec2)
		+ (Demand.ar(clk, 0, Dseq(snareMask, inf)) * sec3));
	hatTrig   = clk * drumGate * Demand.ar(clk, 0, Dseq(hatMask, inf));

	kick  = (SinOsc.ar(fund * 0.5 * (1 + (8 * Decay2.ar(kickTrig, 0.001, 0.07))),
		0, Decay2.ar(kickTrig, 0.005, 0.3)) * 1.6)
	+ (HPF.ar(WhiteNoise.ar(Decay2.ar(kickTrig, 0.001, 0.02)), 1000) * 0.5);
	// the kick only ever plays two-step, sparse, so it is always driven hard —
	// with so few hits it has to carry more, and it breaks up rather than
	// staying clean. Trimmed after the tanh, which adds level as it squares
	// the waveform off.
	kickDrive = 4.2;
	kick = (kick * kickDrive).tanh * 0.68;
	// polymeter-003's voice 1 under every kick: sub, fundamental and a short
	// second partial. Its bloom is shortened from the 1.8 s of track 3 to
	// 1.0 — at five or so hits a bar the full length piles up into mud.
	kickSub = (SinOsc.ar(fund * 0.5) + (SinOsc.ar(fund) * 0.5)
		+ (SinOsc.ar(fund * 2, 0, Decay2.ar(kickTrig, 0.002, 0.15)) * 0.3))
	* Decay2.ar(kickTrig, 0.005, 1.0) * 0.9;
	kick = kick + kickSub;
	snare = WhiteNoise.ar(Decay2.ar(snareTrig, 0.005, 0.16))
	+ SinOsc.ar(fund * 12/5, 0, Decay2.ar(snareTrig, 0.005, 0.09)); // G3, in scale
	hat   = HPF.ar(WhiteNoise.ar(Decay2.ar(hatTrig, 0.002, 0.05)), 9000);
	// a thinner hat on the off-16ths, arriving with the snares: the eighth
	// hats become a continuous 16th line and the whole kit starts pushing.
	// Dseq([0, x]) on the 16th clock sounds only between the eighths.
	clk16 = Impulse.ar(q * 4);
	hat16Trig = clk16 * snareGate * Demand.ar(clk16, 0, Dseq([0, 0.5], inf));
	hat16 = HPF.ar(WhiteNoise.ar(Decay2.ar(hat16Trig, 0.001, 0.028)), 11000);

	// polymeter-002's second snare: hectic randomized 32nd-note bursts
	// (seeded above, so every render is identical). Dust opens short burst
	// windows; TRand varies each hit inside them. Arrives with the backbeat.
	burstGate = Trig.ar(Dust.ar(1.1), 0.26);
	burstTrig = Impulse.ar(q * 8) * burstGate * snareGate;
	snare2 = (HPF.ar(WhiteNoise.ar, 2500) + BPF.ar(WhiteNoise.ar(2), 3800, 0.3))
	* Decay2.ar(burstTrig * TRand.ar(0.25, 1, burstTrig), 0.001, 0.05) * 0.8;

	drums = ((kick * kickLvl) + (snare * snareLvl) + (snare2 * burstLvl)
		+ (hat * hatLvl) + (hat16 * hat16Lvl)) * drumAmp;

	// the track-2 crusher on the drum bus: latch-downsampled at a wandering
	// rate, quantized, driven — all following the capped crush arc. The dry
	// share is what keeps the kick's punch.
	// sample rate and bit depth both collapse as the arc rises: the latch
	// runs 5x faster and 2.6 bits deeper at the extremes than at the peak
	drumsCrushed = (Latch.ar(drums, Impulse.ar(
		LFNoise2.kr(0.5).exprange(600, 3200) * (1 + (4 * (1 - crushArc)))))
		.round(2 ** (LFNoise2.kr(0.4).range(4.4, 6.0) - (2.6 * crushArc)).neg * 2)
		* crushDrive).tanh * 1.1;
	drums = (drums * (1 - drumCrush)) + (drumsCrushed * drumCrush);

	// ---- the clap: polymeter-001's multi-burst clap ----
	// Three delayed noise bursts smeared 11 and 23 ms behind the first — the
	// classic clap stack. Deliberately outside the drum bus and its crusher:
	// the drum crusher rounds transients off, and this needs to hit bare and
	// hard. It plays twice: framing the bass cells in bars 3-6 before the kit
	// exists, then the full 3-2 pattern from the drop to the outro.
	clapTrig = clk * (
		(Demand.ar(clk, 0, Dseq(clapIntroMask, inf)) * sec1)
		+ (Demand.ar(clk, 0, Dseq(clapMask, inf))
			* (elapsed >= ((clapBar * barDur) - 0.01)) * outroGate));
	clapEnv  = Decay2.ar(clapTrig, 0.001, 0.2)
	+ Decay2.ar(DelayN.ar(clapTrig, 0.03, 0.011), 0.001, 0.1)
	+ Decay2.ar(DelayN.ar(clapTrig, 0.03, 0.023), 0.001, 0.08);
	clap = BPF.ar(WhiteNoise.ar(2), 1800, 0.7) * clapEnv;
	clap = (clap * 1.8).tanh * clapAmp;

	// ---- the two arps: polymeter-003's voices 6 and 8, verbatim ----
	// Pitch is demanded on every step so the mask and the note cycle stay
	// locked, then latched at the trigger — otherwise a ringing bell would
	// glide as the stream moved under it.
	// each arp runs both its streams on the same clock and switches at bar 20,
	// so neither loses its place in its own cycle
	arpAlt  = elapsed >= ((clapBar * barDur) - 0.01);
	arpEvo  = ((elapsed - (arpBar * barDur)) / (total - (arpBar * barDur))).clip(0, 1);
	arpLift = 1 + (0.55 * Lag.kr((elapsed >= (clapBar * barDur))
		* (elapsed < (kitReturnBar * barDur)), 0.4));

	arp6Trig = clk * (elapsed >= ((arpBar * barDur) - 0.01))
	* ((Demand.ar(clk, 0, Dseq(arp6Mask, inf))    * (1 - arpAlt))
		+ (Demand.ar(clk, 0, Dseq(arp6MaskAlt, inf)) * arpAlt));
	arp6F = Latch.ar(fund
		* ((Demand.ar(clk, 0, Dseq(arp6Pitch, inf))    * (1 - arpAlt))
			+ (Demand.ar(clk, 0, Dseq(arp6PitchAlt, inf)) * arpAlt)),
		arp6Trig).max(20);
	// voice 6 — small bell (pure twelfth partial)
	arp6 = (SinOsc.ar(arp6F, 0, Decay2.ar(arp6Trig, 0.002, 0.6))
		+ (SinOsc.ar(arp6F * 3, 0, Decay2.ar(arp6Trig, 0.002, 0.25)) * 0.4)) * 0.8;
	// saturation that grows from its entry to the last bar, plus a share of
	// the global crush arc — so the arps dirty up along with everything else
	arp6 = (arp6 * (1.2 + (4.5 * arpEvo))).tanh * (1 - (0.3 * arpEvo));
	arp6 = (arp6 * (1 - (0.5 * crushArc)))
	+ (Latch.ar(arp6, Impulse.ar(LFNoise2.kr(0.35).exprange(1400, 7000)))
		.round(2 ** LFNoise2.kr(0.3).range(3.0, 5.0).neg * 2) * (0.5 * crushArc));

	arp8Trig = clk * (elapsed >= ((arpBar * barDur) - 0.01))
	* ((Demand.ar(clk, 0, Dseq(arp8Mask, inf))    * (1 - arpAlt))
		+ (Demand.ar(clk, 0, Dseq(arp8MaskAlt, inf)) * arpAlt));
	arp8F = Latch.ar(fund
		* ((Demand.ar(clk, 0, Dseq(arp8Pitch, inf))    * (1 - arpAlt))
			+ (Demand.ar(clk, 0, Dseq(arp8PitchAlt, inf)) * arpAlt)),
		arp8Trig).max(20);
	// voice 8 — glass (octave-pair sines, very short)
	arp8 = (SinOsc.ar(arp8F * 2, 0, Decay2.ar(arp8Trig, 0.001, 0.18))
		+ (SinOsc.ar(arp8F * 4, 0, Decay2.ar(arp8Trig, 0.001, 0.09)) * 0.5)) * 0.7;
	arp8 = (arp8 * (1.15 + (3.8 * arpEvo))).tanh * (1 - (0.28 * arpEvo));
	arp8 = (arp8 * (1 - (0.45 * crushArc)))
	+ (Latch.ar(arp8, Impulse.ar(LFNoise2.kr(0.29).exprange(2000, 9000)))
		.round(2 ** LFNoise2.kr(0.26).range(3.4, 5.4).neg * 2) * (0.45 * crushArc));

	// bassAmp scales the WHOLE bass layer, wet paths included — applying it
	// only to the dry path left the delay and reverb outside the knob, so
	// bassAmp = 0 did not actually mute the bass the way the header claims
	mix = Pan2.ar(bassDry * bassLvl, -0.08) + Pan2.ar(bassDel * bassLvl, 0.22)
	+ Pan2.ar(bassRev * bassLvl, -0.15)
	+ Pan2.ar(deep, 0, deepAmp) + Pan2.ar(drums, 0.05) + Pan2.ar(clap, 0)
	+ Pan2.ar(arp6, -0.88, arp6Amp * arpLift) + Pan2.ar(arp8, 0.88, arp8Amp * arpLift);
	mix = FreeVerb.ar(mix, revMix, 0.75, 0.4);
	// gentle glue; loudness normalization lives in make_mp3.sh
	mix = Compander.ar(mix, mix, 0.4, 1, 0.7, 0.005, 0.15) * 1.1;
	// the main-bus crusher, running the whole track on the same arc. Its
	// severity scales too: at low arc it latches 4x faster, keeps 2 more bits
	// and barely drives, so early on it is grain rather than damage.
	mixCrushed = (Latch.ar(mix, Impulse.ar(LFNoise2.kr(0.4).exprange(900, 5000)
		* (1 + (3 * (1 - (crushArc / crushCap))))))
		.round(2 ** (LFNoise2.kr(0.3).range(2.4, 4.2)
			+ (2 * (1 - (crushArc / crushCap)))).neg * 2)
		* (1 + (1.8 * (crushArc / crushCap)))).tanh * 0.85;
	mix = (mix * (1 - masterCrush)) + (mixCrushed * masterCrush);
	// two bars of outro, then two bars of fade
	master = EnvGen.kr(Env([1, 1, 0], [total - (2 * barDur), 2 * barDur], [0, -3]),
		doneAction: 2);
	Limiter.ar(mix * 0.5, 0.9) * master;
}
