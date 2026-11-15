---
name: apple-design
description: Apple's approach to interface design and fluid, physical motion, translated for the web. Use when building or reviewing gesture-driven UI, spring animations, drag/swipe/sheet interactions, momentum and interruptible transitions, translucent materials and depth, typography (optical sizing, tracking, leading), reduced-motion, or the design foundations (feedback, spatial consistency, restraint) behind Apple-style interfaces.
source: https://github.com/emilkowalski/skills/tree/main/skills/apple-design
---

# Apple Design

How Apple builds interfaces that stop feeling like a computer and start feeling like an extension of you. Knowledge distilled from Apple's WWDC design talks — chiefly *Designing Fluid Interfaces* (WWDC 2018). The through-line: **an interface feels alive when motion starts from the current on-screen value, inherits the user's velocity, projects momentum forward, and can be grabbed and reversed at any instant.** Springs are the tool that makes this natural, because they are inherently interruptible and velocity-aware.

## The Core Idea

> "When we align the interface to the way we think and move, something magical happens — it stops feeling like a computer and starts feeling like a seamless extension of us."

An interface is fluid when it behaves like the physical world: things respond instantly, move continuously, carry momentum, resist at boundaries, and can be redirected mid-motion. Apple frames design as serving four human needs: **safety/predictability, understanding, achievement, and joy.**

## 1. Response — kill latency

- **Respond on pointer-down, not on release.** Highlight a button the instant it's pressed. Waiting for `click`/touch-up to show feedback feels dead.
- **Be vigilant about every latency.** Audit debounces, artificial timers, transition waits, the ~300ms tap delay. Anything on the input path that isn't essential is a regression.
- **Feedback must be continuous *during* the interaction, not just at the end.** Update the UI 1:1 with the pointer the whole way through.

```css
.button:active { transform: scale(0.97); transition: transform 100ms ease-out; }
```

## 2. Direct manipulation — 1:1 tracking

> "Touch and content should move together."

- Respect the offset from *where they grabbed it*; snapping to the element's center on grab breaks the illusion.
- Track a short velocity/position history (last few moves), not just the current point.

## 3. Interruptibility — the single most important principle

- **Never lock out input during a transition.**
- **Always animate from the *presentation* (current) value, never the target value.**
- **Avoid fixed-duration transitions/keyframes for anything gesture-driven** — springs animate from the current value by default.
- **When a gesture reverses, blend velocity — don't hard-cut it.**
- **Decompose 2D motion into independent X and Y springs.**

## 4. Behavior over animation — use springs

- **Damping ratio** — overshoot control. `1.0` = critically damped. `< 1.0` = bouncy.
- **Response** — how quickly the value reaches the target, in seconds. Not "duration".

Defaults: most UI at damping `1.0`; add bounce (`~0.8`) **only when the gesture carried momentum**.

| Interaction | Damping | Response |
| --- | --- | --- |
| Move / reposition | `1.0` | `0.4` |
| Rotation | `0.8` | `0.4` |
| Drawer / sheet | `0.8` | `0.3` |

## 5. Velocity handoff — the seam between drag and animation

Pass the pointer's release velocity as the spring's initial velocity. If normalized: `relativeVelocity = gestureVelocity / (target − current)`.

## 6. Momentum projection — animate to where the gesture is *going*

```js
function project(initialVelocity /* px/s */, decelerationRate = 0.998) {
  return (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate);
}
const projectedEndpoint = currentPosition + project(releaseVelocity);
const target = nearestSnapPoint(projectedEndpoint);
animateSpringTo(target, { velocity: releaseVelocity });
```

Use the exponential-decay form, not `v²/(2·decel)`.

## 7. Spatial consistency — symmetric paths, anchored origins

- **Enter and exit along the same path.**
- **Anchor interactions to their source** (`transform-origin` = trigger).

## 8. Hint in the direction of the gesture

Intermediate motion should telegraph where things are going.

## 9. Rubber-banding — soft boundaries

```js
function rubberband(overshoot, dimension, constant = 0.55) {
  return (overshoot * dimension * constant) / (dimension + constant * Math.abs(overshoot));
}
```

## 10. Gesture design details (the "feel" checklist)

- **Tap:** highlight on touch-*down*, commit on touch-*up*; ~10px hysteresis; cancel by dragging away and back.
- **Drag/swipe:** ~10px threshold before committing direction, then track 1:1.
- **Detect plausible gestures in parallel from the first move**, cancel losers once intent is clear.
- **Minimize disambiguation delays.**

## 11. Frame-level smoothness

- Subtle motion blur/stretch for very fast motion.
- Animate only compositor-friendly properties — `transform` and `opacity`.
- Add `will-change` only after measuring.

## 12. Materials & depth — translucency conveys hierarchy

- **Build nav/toolbars/sheets as translucent layers** (`blur` + semi-transparent background) with content scrolling underneath.
- **Material weight encodes hierarchy:** darker/heavier separates structural regions (sidebars); lighter draws attention (buttons). **Never stack a light translucent surface on another** — legibility collapses.
- **Bigger surfaces read as thicker:** stronger blur + deeper shadow than small chips. Context-aware shadows.
- **Dim to focus, separate to keep flow.**
- **Vibrancy keeps text legible:** higher contrast, slightly heavier weight, small letter-spacing bump. Put color on a solid layer, not the translucent foreground.
- **Scroll edge effects, not hard dividers.**
- **Materialize, don't just fade:** animate blur radius + scale together on enter/exit.

```css
.toolbar {
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(20px) saturate(180%);
  border-top: 1px solid rgba(255, 255, 255, 0.4); /* bright top edge = light catching the material */
}
```

## 13. Multimodal feedback — motion + sound + haptics

1. **Causality** — trigger on the causal event.
2. **Harmony** — visual, sound, haptic on the **same frame**.
3. **Utility** — reserve for meaningful moments (success, error, commit, snap).

## 14. Reduced motion & accessibility

- **`prefers-reduced-motion: reduce`** → short opacity cross-fades, no elastic/overshoot.
- **`prefers-reduced-transparency: reduce`** → frostier/solid surfaces, drop the blur.
- **`prefers-contrast: more`** → near-solid backgrounds with a defined border.
- Avoid full-viewport moving backgrounds, slow loops (~0.2 Hz), abrupt brightness jumps.

```css
@media (prefers-reduced-motion: reduce) { .sheet { transition: opacity 200ms ease; transform: none !important; } }
@media (prefers-reduced-transparency: reduce) { .toolbar { background: white; backdrop-filter: none; } }
```

## 15. Typography — optical sizing, tracking, leading

- **Tracking is size-specific** — large display text wants *negative* tracking, small text slightly *positive*. Never one value for all sizes.
- **Leading tracks size inversely** — tight on large headings, looser on body.
- **Hierarchy from weight + size + leading as a set**, not size alone.
- **Respect Dynamic Type**; scale layout with the text.
- **Default to the platform's system font** before a custom face.

```css
:root { font: 100%/1.5 system-ui, sans-serif; }
.display { font-size: clamp(2rem, 5vw, 4rem); line-height: 1.05; letter-spacing: -0.02em; font-optical-sizing: auto; }
```

## 16. Design foundations — the eight principles

1. **Purpose.** Decide what *not* to build; every feature spends the user's time, attention, and trust.
2. **Agency.** Keep people in control; forgiveness and easy undo; confirmation dialogs only for genuinely destructive, irreversible actions.
3. **Responsibility.** Act in the user's interest: privacy, safety, previews, disclaimers.
4. **Familiarity.** Build on what people know; consistent behaviour and placement.
5. **Flexibility.** Adapt to context, device, and ability; allow personalization.
6. **Simplicity — not minimalism.** Strip the unnecessary so the core purpose shines; hierarchy makes the most important thing the most obvious.
7. **Craft.** Every spacing, timing, alignment is deliberate. Jitter, misalignment, and broken rotation read as carelessness.
8. **Delight.** The result of getting the other seven right, not confetti on top.

Tactical rules: four feedback kinds (status, completion, warning, error); **wayfinding** (Where am I? Where can I go? How do I get out?); grouping & mapping; direct, specific labels.

## 17. Process

- **Prototype interactively** — a working demo beats static mockups and sets the bar.
- **Design interaction and visuals together.**
- **Test with real people**, review motion frame-by-frame.

## Quick Reference

| Need | Technique | Concrete value |
| --- | --- | --- |
| Default UI spring | Critically damped | `damping 1.0`, `response 0.3–0.4` |
| Momentum / flick | Under-damped, slight bounce | `damping ~0.8`, `response 0.3–0.4` |
| Gesture → spring velocity | Hand off release velocity | `v / (target − current)` if normalized |
| Flick landing point | Project momentum | `current + (v/1000)·d/(1−d)`, `d ≈ 0.998` |
| Interrupt cleanly | Start from live value | read on-screen transform |
| Avoid reversal "brick wall" | Carry velocity through re-target | velocity-aware spring |
| 1:1 drag | Pointer capture | respect grab offset |
| Feedback | On pointer-down, continuous | never only at the end |
| Boundary | Rubber-band | progressive resistance |
| Translucent chrome | `backdrop-filter` layer | content scrolls under |
| Type tracking | Size-specific | tighten large (`-0.02em`), body ~0 |
| Reduced motion | Cross-fade, not slide | `@media (prefers-reduced-motion)` |
