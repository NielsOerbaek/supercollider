# Session log — polymeter-3 (Study No. 3)

Continuation of the session in tracks/polymeter-2/SESSION-LOG.md, from the
moment this track began (2026-09-04). Same format: **user messages
verbatim** (typos included), assistant work summarized in italics. Full
conversation: <https://claude.ai/code/session_01RCsG5EUV8jKv62xX2m1Wkz>.

---

> Let's start polymeter-3. Design 9 different plucky sounds. First in
> drone base 1 hit per bar, next lighter, 2 hits per bar 2 first notes in
> harmonic scare, and to on until very light 9 hits per bar, first 9 notes
> in harmonic scale. They should be added one after one 8 bars apart. 170
> as always. base reverb.

*Assistant recognized the design as a rhythmicon (Cowell/Theremin, 1931):
voice n plays n hits per bar on the first n harmonics of E2, so hit k of
every bar lands on harmonic k — each bar an ascending harmonic fan. Nine
distinct pluck timbres built, heavy to light, staggered entries 8 bars
apart.*

> Great! After all voices have been added and we've run for a bit w should
> start over, but with a different concept. Each voice has the same notes,
> but instead of voice 3 being 1/3 notes, it should be flored to the
> nearest power of two. so voice three has three 1/2 notes and voice 7 has
> 7 1/4 notes. Now the patterns will not align on the down beat anymore
> and with phase in over several measures.

*Section 2: rates floored to powers of two while pitch cycles keep their
n notes — non-power-of-two voices carry patterns of 1.125-1.75 bars that
rotate against the barline (full realignment every 315 bars, i.e. never
within the piece). Reich-style melodic phasing on a locked binary grid.*

> Instead of fading out i'd like the voices to disappear by a FIFO
> principle, so we will end up just with the lighter voices.

*Voices exit in arrival order, every 4 bars; the glass and tick duo phase
alone to the close.*

> Great! Add same outro to section 1.

*Both sections now share the arc — build heavy-to-light, dismantle
heavy-to-light — with section 1's light-duo passage handing off directly
to section 2's bass-pluck restart.*

> commit and push

*This commit.*
