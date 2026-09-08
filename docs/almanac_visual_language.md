# The Almanac visual language

One almanac, with different views into the same current moment.

This document is the locked reference for how Almanac looks and moves. It
is written for the person implementing the next screen, and it is
deliberately short: the rules that matter are the ones somebody can hold
in their head while drawing a page.

**The single most important rule, above every other rule here:**

> When choosing between visual richness and consistency,
> **choose consistency.**

A page that is beautiful and unlike the rest of the app makes the app
worse. Eight feature areas that each look lovely on their own terms are
eight apps.

---

## 1. Art style

- **Warm cream/paper base.** Every surface reads as paper, not as a
  screen. Cream by day; the same paper by lamplight at night.
- **Soft organic shapes.** Curves before rectangles. Nothing in nature
  has a 2 px border.
- **Low detail.** Fewer strokes than you think you need.
- **Hand-drawn, painted-field-journal feeling.** Somebody's notebook,
  not a product.
- **Understated botanical and celestial illustration.** A sprig, a disc,
  a bird — never a bouquet.
- **Recognisable before realistic.** Nobody identifies a tūī from a
  forty-pixel drawing. The **name** does that, and the name is always
  there in text. The drawing says *"something noticed"*.
- **Generous negative space.** Emptiness is the design, not a gap in it.
- **No glossy generic wellness-dashboard appearance.** No gradients for
  their own sake, no glassmorphism, no drop shadows, no progress rings,
  no card grids, no metric tiles.
- **No unrelated illustration styles between features.** One hand drew
  all of it.

### What this rules out, concretely

Streaks, badges, points, levels, celebration animations, "you're on
fire", ring charts, sparklines on a wellbeing page, stock photography,
emoji as iconography, and any illustration that could have come from a
different app.

---

## 2. Typography

An editorial serif for headings and display text; a clean sans for body
and UI. Typography does **not** change with the season — only its colour
does. The app should read as the same publication in January and July.

The desired direction is more **handwritten / field-journal** than a
generic Material app. The typography role for this exists as
`AlmanacJournalText` (`lib/app/theme/journal_typography.dart`):
`journalLabel` for a small hand-lettered-feeling label, `journalNote` for
a reflective line.

**Current state:** both roles are derived from the existing editorial
serif. They are the seam, not the finished thing. Choosing and shipping a
genuine handwritten face is a later visual-design task, and when it
happens it changes those two getters and nothing else. Fonts are never
downloaded at runtime.

---

## 3. Environment is the living painting

The Environment screen is the app's anchor and the one place that carries
a full landscape. Its composition is settled. Do not move its sections,
change its order, replace its landscape, add a feature-card grid, or
reinterpret its layout.

### The landscape geometry rule (hard)

**The landscape is ONE PLACE.**

Across spring, summer, autumn, winter, sunrise, day, sunset and night,
the underlying land geometry is **identical**. These must not change
shape between states:

- mountains
- mountain angle
- hills
- islands
- shoreline
- land mass
- horizon
- water boundary

Season and day/night may change:

- palette
- light
- sky colour
- water colour
- foreground vegetation
- density of foreground growth
- flowers and leaves
- how much foreground visually overlaps the distant landscape

But the land underneath stays fixed. This is what makes the scene feel
like **one painting changing through time** rather than eight different
pictures. A viewer should be able to point at the same hill in January
and July.

---

## 4. Detail pages are paper, not scenery

> **ENVIRONMENT IS OUTSIDE. DETAIL PAGES ARE THE BOOK.**
>
> The Environment changes with the world outside.
> The pages inside the Almanac remain paper.

This is a locked rule, and it is the one people are most likely to break
by being helpful.

**Environment / Home** is the living painting. It responds strongly to
the astronomical season, to sunrise, day, sunset and night, to sky
colour, landscape lighting, water colour and foreground vegetation. That
is its job.

**Inner / detail pages** are pages *of* the Almanac. They stay on the
**same warm cream paper** through spring, summer, autumn, winter,
daytime and night. A detail page does **not** turn into a dark surface
because it happens to be dark outside, and there is no seasonal variant
of the paper either. Opening one should feel like turning to a page of a
physical almanac — not like stepping outside again into a different
version of the same scene.

There is therefore:

- **no night paper**
- **no four seasonal page backgrounds**
- **no dark mode for a detail page**

### What may still respond to context

A detail page is not cut off from the season. It may still use the
active palette, subtly, for:

- accent lines
- small selected states
- the moon's shading
- botanical and celestial illustration accents
- restrained icon and detail colour
- contextual labels where they help

**But the main paper background stays warm cream.** A seasonal accent
taken from a night palette is re-based so it is still legible on cream
(`AlmanacPaper.accentOn`), so the season is present without the page
losing its ground.

### How it is implemented

One token, one primitive, no hard-coded colour anywhere else:

- `AlmanacPaper` (`lib/app/theme/almanac_paper.dart`) — `ground`, `ink`,
  `inkMuted`, `rule`, `accentOn(...)`, and `reprint(palette)`.
- `AlmanacPaperSurface` (`lib/core/widgets/`) — paints the ground and
  hands the re-printed palette to the theme, so a page inside it goes on
  using `Theme.of(context).textTheme` and `context.palette` as normal
  and gets paper ink without knowing about it.

That is what lets future inner pages — Cycle, Cycle Syncing, a recipe, a
plant, a Nature Log entry — share one stable inner-page language by
wrapping themselves in the primitive and changing nothing else.

### The rest of the rule

A detail page uses:

- the paper ground
- lots of breathing room
- **one** central or small feature illustration
- the field-journal typographic feeling
- fine separators (`AlmanacSectionDivider`), not boxes and borders
- minimal seasonal accent
- no unnecessary environmental scenery

The page should clearly belong to the same Almanac **without requiring
four seasonal paintings and day/night versions of every feature screen.**
That is the whole reason this rule exists: consistency that scales.

The Moon detail page is the reference implementation. It has no
landscape, no flowers around the moon, no botanical wreath, no
decorative forest and no seasonal background illustration. The moon is
the visual focus and almost everything else is space.

---

## 5. Animation language

> **NATURE MOVES. INTERFACE STAYS STILL.**

Motion is allowed when the thing being drawn actually moves.

**Allowed:**

- the sun moves, because real time moves
- the moon's position and phase change, because astronomy changes
- daylight and sky colours transition
- subtle water movement, where appropriate
- the breathing orb moves, because breathing moves
- the Yoga figure moves, because a body moves
- a one-shot growth or settle when a list of drawn things first appears

**Not allowed:**

- permanently floating cards
- pulsing navigation
- bouncing headings
- decorative looping icons
- random leaf movement everywhere
- constant UI motion for visual interest

**No permanent ticker** may be introduced by a page that is not itself a
timed session. Reduced motion (`MediaQuery.disableAnimationsOf`) always
draws the final state at once, and every screen has a test asserting
nothing is left ticking after it settles.

Page transitions are short, and fade or scale. A shared-element
transition is welcome only where it is stable; consistency and stability
outrank visual cleverness.

---

## 6. One Almanac: context, guidance, doorway

The eight feature areas are views into the same current moment, not eight
apps. The relationship is always:

```
CONTEXT   ->   GUIDANCE   ->   OPTIONAL DOORWAY TO AN ENABLED FEATURE
```

**The user's feature choices control the doorway. They never remove the
guidance.**

If Cookbook is switched off, food guidance in Cycle still appears — only
"See recipes →" is absent. If Meditation is switched off, the Moon's
reflective practices still appear, and "Try a meditation →" is absent.
This is a firm product rule, and it is tested.

Features read context through the shared seam (`lib/core/context/`) and
never through each other's widgets or stores.

---

## 7. Voice

- Offer, never instruct. "You might", "can be used as", "may be a moment
  to".
- Hedge honestly. "Often flowering around this time", never "you will
  see".
- No health, medical, hormonal or fertility claims anywhere, in any
  feature.
- Spiritual and reflective language is welcome, and is framed as such:
  "In some modern spiritual traditions…".
- No score. No total anybody is asked to beat.
- Say what the app does not know, out loud, rather than filling the gap
  with a guess.

### Framing, not disclaiming

A page with a factual half and a reflective half separates them **by
tone**, not by warning the reader about the second one.

- The factual half states what is true: the phase, the illumination,
  waxing or waning.
- The reflective half is introduced once — "In some modern spiritual
  traditions, the phases of the moon are used as moments for
  reflection." — and then simply written.

Name the tradition **once**, at the top of the reflective passage. Do
not open every paragraph with it, and do not add a closing sentence
explaining what the writing is not. The exclusions still hold and are
still tested; they are not something to tell the reader about. The
screen should read like an almanac, not a policy document.
