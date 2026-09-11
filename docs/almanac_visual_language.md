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

An editorial **display** face for titles and dates; the platform's own
**text** face for body and UI. Typography does **not** change with the
season — only its colour does. The app should read as the same
publication in January and July.

### A screen asks for a role, never for a size

Every piece of text in the Almanac comes from a named role in
`AlmanacTextRoles` (`lib/app/theme/almanac_text_roles.dart`). A screen
writes `textTheme.sectionLabel`, never `fontSize: 14, letterSpacing:
0.8`. One-off `TextStyle`s in feature files are how eight features end up
with eight slightly different captions.

| Role | Used for |
|---|---|
| `pageTitle` | the name of a page: "The Moon", "Cycle" |
| `chapterTitle` | a major division within a page |
| `eyebrow` | the small letter-spaced line above a title |
| `sectionLabel` / `journalLabel` | the written label above a passage |
| `journalNote` | a reflective line, in the display face |
| `bodyText` | the paragraph a person reads |
| `bodyQuiet` | supporting copy, one step back |
| `annotation` | small print under a value or an illustration |
| `valueText` | a measured value: "6:48 am", "Cycle day 17" |
| `valueLabel` | the word under a value: "Sunrise" |
| `controlLabel` | the words on a button or an invitation |
| `navigationLabel` | a destination in the bottom bar |

A **value** is set in the text face, not the display face: a number
should be read, not admired. A **reflection** is set in the display face,
because somebody wrote it down.

### Fonts: bundled or nothing

**Fonts are never downloaded at runtime.** Until Step 17 that sentence
appeared in this document while the app called `GoogleFonts` with no
bundled assets — which fetches from `fonts.gstatic.com` on first use. The
dependency was removed, and a test now greps `pubspec.yaml` and `lib/` so
the claim and the code cannot drift apart again.

Which faces the app uses is decided in exactly one file,
`lib/app/theme/almanac_fonts.dart`, and no screen names a typeface. It
currently resolves to a platform serif stack for display and the
platform's own UI face for text.

**The slot for the hand-lettered face the references are set in** is
`AlmanacFonts.bundledDisplay`: drop licensed files into `assets/fonts/`,
declare them in the commented block in `pubspec.yaml`, and set that one
constant. Nothing else changes.

The script face belongs to display roles only. **Body copy stays in the
platform text face whatever happens** — readability is not something the
Almanac trades for character.

---

## 3. Paper, ink and rules

Two grounds, three weights of ink, two rules. Every extra cream is a
decision somebody has to make on every page, and the answer to "which
cream?" should almost always be "the paper".

| Token | Value | Role |
|---|---|---|
| `ground` | `#F7F1E3` | the paper; the default background of every inner page |
| `groundInset` | `#F0E9D8` | the one inset passage — tinted *into* the page |
| `ink` | `#2B2720` | titles and body copy |
| `inkMuted` | `#574F42` | captions, section labels, secondary lines |
| `inkFaint` | `#6B6253` | annotations, units, small print |
| `inkDisabled` | `#9A9080` | a control that cannot be used |
| `rule` | `#9A9080` | a rule that must be seen |
| `softRule` | `#D8CEB8` | a division that is felt more than seen |
| `selection` | `#E8DFC6` | the wash behind a selected element |

Rules:

- **No pure black, anywhere.** Warm near-black on cream reads as
  printing; `#000` reads as a screen.
- **The inset ground is darker than the paper, never lighter.** A lighter
  patch reads as a card hovering over the page; a darker one reads as ink
  laid on it. There are no shadows and no raised Material surfaces.
- **`inkFaint` still clears the body-text contrast floor.** "Faint"
  describes where text sits in the hierarchy, never how hard it is to
  read. `paper_tokens_test.dart` fails if any ink drifts.
- **Seasonal accents are re-based, not used raw** — `AlmanacPaper.accentOn`
  steps a palette colour until it is legible on cream.

---

## 4. Spacing and layout

- Spacing comes from `AppSpacing`. Prefer the larger step.
- Page margins are `AppSpacing.lg` on both sides, everywhere.
- Content is capped at `AppDimens.maxContentWidth` so a tablet gets a
  book column rather than a stretched line of text.
- Every page ends with `AppSpacing.xxl` of breathing room.
- **Emptiness is the design, not a gap in it.** If a page looks sparse,
  that is usually correct.

---

## 5. The page, the section and the rule

### The page

Two scaffolds, one composition:

- `AppScaffold` — a **chapter opening**: a top-level tab screen.
- `AlmanacPage` — a **page inside a feature**: the same composition with
  a way back.

Both put the title in the display face over a short hairline. Both
guarantee the paper, the margins, the safe area, the content cap and the
bottom room, and both are tested at 2× text.

The way back is **words with a chevron** — "‹ Back" — at the top left,
above the fold. Never a bare glyph, and never at the foot of a long page,
because a way back nobody reaches is not a way back.

### The section

A section on a paper page looks like this:

```
KEY THEMES                 <- AlmanacSectionLabel

content, with breathing room

──────                     <- AlmanacSectionDivider
```

and deliberately **not** like a Material card with a title bar, a border
and a shadow. Grouping is done with a label, some space and a rule; a box
is the last resort.

There is **one** section label in the app — `AlmanacSectionLabel`. The
older `SectionHeader` was folded into it in Step 17 so that there is one
implementation rather than two that could drift.

### The two rules

- `AlmanacSectionDivider` — a **short centred** rule between the
  *passages* of a page.
- `AlmanacRule` — a **full-width hairline** between the *rows* of a list.

Two rules, two jobs. A page rarely needs both at once, and neither is
ever a decoration between every section.

### The container

`AlmanacInset` (and `AppCard`, which is the same thing with more padding)
is the Almanac's only container: the inset ground, a small radius, no
shadow, no border by default. Use it where grouping genuinely aids
comprehension — a value table, one invitation at the foot of a page — and
use a label and a rule everywhere else.

---

## 6. Actions

Three weights, and the quietest one is the default answer.

| Weight | Treatment | For |
|---|---|---|
| Primary | soft natural fill, small radius | the one action a page is for |
| Secondary | outline in the rule's ink | a real alternative |
| Text | words, no box | everything else |

- **Buttons size to their content.** They are not full-bleed bars. (The
  previous theme used `Size.fromHeight`, which is `Size(infinity, h)` —
  that is what made every action in the app a full-width Material pill.)
- Minimum target is 48 dp, always, including the way back and every
  navigation destination.
- A pressed and a selected state are always visible, and **never carried
  by colour alone** — there is always a second signal: a mark, a filled
  icon, a border.
- No heavy shadows, no decorative animation on press.

### Doorways are written invitations

`AlmanacDoorway` is a line of the page's own voice with a thin ring and
an arrow after it — not a call-to-action button and not an advertisement.
Its **navigation behaviour is locked** (see §9); only its clothes changed
in Step 17.

---

## 7. Icons

- One set: Material's outlined icons at `AppIconSize.md` (24 dp).
- **Outlined when unselected, filled when selected.** That pairing is the
  app's selected-state language in the bottom bar, and it is the reason
  selection never depends on colour.
- Fine, light, and legible at a glance. A functional icon is never
  replaced by an ambiguous decorative drawing, and the bottom navigation
  must stay immediately understandable.
- Marks that are drawn rather than iconographic — the doorway's ring, the
  empty state's circle — are hairlines on the paper, never filled badges.
- **No emoji as UI iconography**, ever.

---

## 8. The bottom navigation and the Almanac control

The bar's **behaviour is locked**: the Environment first, then the user's
chosen features in registry order; full labels when they fit, otherwise
the exact short words (Env, Med, Yoga, Chak, Cycle, Cook, Garden,
Nature); horizontal scrolling rather than shrinking; no ellipsis; no
"more"; full names in semantics; 48 dp targets.

Visually it is part of the illustrated Almanac rather than a stock
`NavigationBar` dropped over it:

- the season's surface with a **hairline** above it, never a shadow;
- the selected destination carries a **small rule above it** — a bookmark
  ribbon — plus a filled icon and the accent ink. Three signals, so the
  selection never rests on colour alone. (The Material pill was removed:
  on an illustrated bar a filled capsule reads as a control panel.)
- labels at 13 pt, because this is a primary control and 10 pt navigation
  text is exactly what the short words exist to avoid.

The **top-right Almanac control** is a thin ring around a pressed-leaf
mark, labelled with the user's own title — "Millie's Almanac". Not a
settings cog, not a filled disc, and never a Settings tab.

The **drawer** is the cover of the book: paper, journal labels, fine
rules, and the same spacing as a page. Not a dense Material settings
list. Every setting and every behaviour in it is unchanged.

---

## 9. Environment is the living painting

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

## 10. Detail pages are paper, not scenery

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

- `AlmanacPaper` (`lib/app/theme/almanac_paper.dart`) — the token set in
  §3, plus `accentOn(...)` and `reprint(palette)`.
- `AlmanacPaperSurface` (`lib/core/widgets/`) — paints the ground and
  hands the re-printed palette to the theme, so a page inside it goes on
  using `Theme.of(context).textTheme` and `context.palette` as normal
  and gets paper ink without knowing about it. It lays a transparent
  `Material` on the ground so list rows and inkwells still ripple.
- `screenForFeature` (`lib/app/navigation/feature_screens.dart`) — **the
  one place the two worlds are separated.** Every feature except the
  Environment is wrapped in the paper surface there, so a chapter cannot
  forget to be paper and a new feature gets it by being added to the
  switch. There is a test for both halves.
- `AlmanacPage` / `AppScaffold` (`lib/core/widgets/`) — the page
  composition described in §5.

That is what lets inner pages — Cycle, a recipe, a plant, a Nature Log
entry — share one stable inner-page language without each implementing
it.

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

## 11. Animation language

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

## 12. Illustration grammar

Everything drawn in the app — the Environment, the moon, botanical
accents, ingredients, Nature Log marks, chakra artwork, the Yoga figure —
is drawn to one grammar, and it is drawn **programmatically**: there are
no raster assets, nothing is traced from a reference screenshot, and
nothing is fetched.

**Character:**

- soft painted/vector hybrid; broad organic shapes
- low detail — fewer strokes than you think you need
- soft edges where practical
- **no heavy black outlines**; a contour is the shape's own darker tone
- a limited natural palette, taken from the active season and re-based
  for the paper
- subtle texture only, and only where it earns its place
- recognisable **silhouettes** — the shape carries the meaning
- enough imperfection to read as illustrated rather than generated
- not photorealistic, not childish clip art, not flat corporate icon art

**Scale discipline:** a detail page has **one** thing that is allowed to
be big. On the Moon page it is the moon. Everything else is space.

**Recognisable before realistic.** Nobody identifies a tūī from a
forty-pixel drawing. The *name* does that, and the name is always there
in text; the drawing says "something noticed".

Illustration is decorative by definition, so it is wrapped in
`ExcludeSemantics` and the page says in words whatever the picture says.

---

## 13. Accessibility is part of the visual system

Not a review step afterwards. A visual rule that cannot pass these is not
adopted.

- **Contrast.** Body ink clears 4.5:1 on its ground; graphical and
  decorative elements clear 3:1. The paper tokens are tested directly,
  and the seasonal palettes are tested at every point of the twilight
  blend.
- **Text scale.** Every page is tested at 1×, 1.5× and 2×. Headings wrap,
  layouts grow, and **no content that matters is ever truncated with an
  ellipsis**. Where a label genuinely cannot fit, the design picks a
  shorter *word* — it does not cut one off.
- **Targets.** 48 dp minimum for everything pressable.
- **Never colour alone.** Selection, state and meaning always carry a
  second signal.
- **Reduced motion.** `MediaQuery.disableAnimationsOf` draws the final
  state at once, everywhere, and no page leaves a ticker running.
- **Semantics before decoration.** Drawn things are excluded from the
  semantic tree and summarised in words — one node that reads as a
  sentence, not thirty fragments.

**Environment chrome.** The bar and the header sit over a painting that
changes all day. They take their colour from the contrast-tested palette
tokens, never from a decorative colour sampled out of the scene. The
known twilight-contrast concern belongs to the landscape rebuild and is
recorded in §14.

---

## 14. How the visual references are used

Five approved references were supplied with Step 17. They are **visual
references, not assets**: nothing is traced, no screenshot is used as a
background, and the app depends on none of these files.

| Reference | What was taken from it |
|---|---|
| Home / Environment | composition personality, the amount of air, how the header and the bar belong to the illustration rather than sitting on it |
| Four seasons (day) | one fixed world; the season changes palette, light and foreground density and nothing structural |
| Four seasons (night) | the same geography after dark, and chrome that stays readable over it |
| Sunrise / sunset | dawn and dusk as colour states of the same place, per season |
| Moon detail | the definitive inner-page language: paper, one large illustration, restrained facts, then reflection |

Rules for reading a reference:

- **Approved reference beats older implementation** for visual direction —
  unless it would cost accessibility, required functionality, truthful
  information, the locked product architecture, or a 48 dp target.
- **Do not infer functionality from a picture.** A reference showing
  moonrise and moonset times is not a requirement to invent moonrise and
  moonset times; the app shows what it actually calculates.
- **Not every object in a reference is a requirement.**

### Deferred to the Environment rebuild (Step 18)

The landscape itself — mountains, hills, islands, shoreline, horizon,
seasonal vegetation, the sunrise and sunset paintings, the sky hero and
the twilight contrast of the scene behind the chrome. Step 17 built the
system those will be drawn against and deliberately did not touch them.

## 15. One Almanac: context, guidance, doorway

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

### A feature that is switched off goes dormant (hard)

**An optional Almanac feature that is turned off becomes dormant. Its
locally stored data is retained unless the user explicitly deletes it,
but other features do not read it while the feature is disabled.**

So when Cycle is not part of the user's Almanac there is no cycle heading
and no cycle collection anywhere — and, behind the page, no phase is
derived and `CycleStore` is not opened at all. The availability check
comes *before* the read, in one place in the app layer, and the features
consuming the context are only ever handed a `CyclePhase?`. Turning the
feature back on finds the data where it was.

This is the rule for every future cross-feature context, not a detail of
Cycle. See the README for how it is wired and tested.

---

## 16. Voice

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
