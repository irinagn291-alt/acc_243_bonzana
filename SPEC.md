# Footlight — Build Specification

> Portfolio app 200, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Check off each pet's daily chores in order until every routine is finished.

| Field | Value |
| --- | --- |
| Product name | Footlight |
| Bundle identifier | `com.footlight.grid` |
| Domain | https://footlight-grid.pro |
| Contact URL | https://footlight-grid.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `ftl_` |
| User-Agent | `Footlight/1.0 (iOS; +https://footlight-grid.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Footlight -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A household stagehand strikes the top open cue in each pet's column on the cap grid so every active routine is marked before the curtain drops.

### 2.1 User flow

1. Swipe the top open cue in a pet column to strike it done
2. Open the Pets sheet to add a pet and pick its column color
3. Open the Routines sheet to attach feed, walk, or meds cues to a pet
4. Peel the last strike if you hit the wrong column head
5. Watch the streak rail update when the curtain seals today
6. Return tomorrow when the daykey rolls and the grid reopens

### 2.2 Essential behaviour

- Cap grid home with one column per pet and cues stacked by routine priority
- Column-relay strike: only each column's top open cue accepts a right swipe
- Local pets editor on a sheet with name, species, and column accent
- Local routines editor on a sheet linking chores to pets with sort order
- Curtain seal when every active routine holds a StrikeMark for the daykey
- Peel undo for the last StrikeMark and a streak rail on sealed days
- Offline-only storage with no accounts, push, or vet store

---

## 3. Uniqueness assignment for Footlight

| Axis | Assigned value |
| --- | --- |
| Architecture | **Column-relay ADT fold (Open | Clearing | Curtain); the grid is a fold over Cues for the daykey grouped by Pet columns; Swipe on a column-head unstrike Cue writes StrikeMark and folds Open to Clearing; Swipe on a non-head Cue in the same column writes LeapMark and keeps order; when every active Routine holds a StrikeMark, Curtain writes CurtainMark and folds Clearing to Curtain; Peel removes the last StrikeMark and folds Curtain to Clearing when any Cue lacks a strike; Peel on Open is refused; Swipe on Curtain is refused; empty grid writes Blank** |
| UI approach | **UIKit UICollectionViewFlowLayout subclass · timeline** |
| Naming convention | **Stagehand / greenroom lexicon (Grid, Pet, Routine, Cue, StrikeMark, LeapMark, CurtainMark, Peel, ColumnHead)** |
| File organization | **By stagehand role (Grid, Pet, Routine, Cue, StrikeMark, LeapMark, CurtainMark, Peel, ColumnHead)** |
| Dependency strategy | **None (zero external dependencies) · no SPM entry, no CocoaPods, no vendored source; UIKit, Core Graphics, AVFoundation and URLSession only** |
| Design direction | **lingo · theater · branded** |
| Typography | **Palatino** |
| Navigation pattern | **Cap-grid-locked chrome (the cue cap grid never leaves; Pets, Routines and Settings arrive as sheets; column-head strike fuses on Today; streak rail on grid footer; no tab bar)** |
| AI art style | **Bauhaus geometric · illustration** |
| Functional twist | **Column-relay-then-strike (only each column's top unstrike Cue accepts Swipe to write StrikeMark; Swipe elsewhere in column writes LeapMark; CurtainMark when every active Routine is struck; Peel reopens Clearing; Swipe on Curtain refused; seed strikes first Cue in lead column so opening Swipe is on second Cue or another column head)** |
| Persistence | **UserDefaults+Codable · one Grid root record holding Pets, Routines, Cues and Marks, encoded under a single key with debounced save after each mark** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — pet_chores

**Core** — A household stagehand strikes the top open cue in each pet's column on the cap grid so every active routine is marked before the curtain drops.

**Audience** — Multi-pet households who need per-animal order without a single global queue, not a mood pet or a vet storefront.

**User flow**

1. Swipe the top open cue in a pet column to strike it done
2. Open the Pets sheet to add a pet and pick its column color
3. Open the Routines sheet to attach feed, walk, or meds cues to a pet
4. Peel the last strike if you hit the wrong column head
5. Watch the streak rail update when the curtain seals today
6. Return tomorrow when the daykey rolls and the grid reopens

**Essential features**

- Cap grid home with one column per pet and cues stacked by routine priority
- Column-relay strike: only each column's top open cue accepts a right swipe
- Local pets editor on a sheet with name, species, and column accent
- Local routines editor on a sheet linking chores to pets with sort order
- Curtain seal when every active routine holds a StrikeMark for the daykey
- Peel undo for the last StrikeMark and a streak rail on sealed days
- Offline-only storage with no accounts, push, or vet store

**Twist** — Column-relay-then-strike. Home is the cue cap grid. Each Pet owns a vertical stack of Cues from its Routines. Only the top unstrike Cue in a column accepts a right Swipe to write StrikeMark; Swipe on any other Cue in that column writes LeapMark and keeps order. When every active Routine holds a StrikeMark for today, Curtain writes CurtainMark and folds Open to Curtain. Peel drops the last StrikeMark and reopens Clearing when any Cue lacks a strike; Peel on Curtain is refused. Swipe on Curtain is refused. Seed already writes StrikeMark on the first Cue in the lead Pet column so the opening Swipe lands on that column's second Cue or another pet's column head. Home verb: strike-the-column-head—not focus-then-swipe, not swipe-the-front-stop, not pick-then-serve. History counts CurtainMarks and LeapMarks, not minutes on screen.

**Why this is not a repeat** — Kennelstamp enforces one globally focused row before swipe; Kennelroll enforces one global front stop on a strip; Footlight shows every pet column at once and enforces routine order within each column while allowing interleaved progress across pets—the same pet_chores family with a different relay invariant, not new copy on the same queue.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Today plaque. Swipe to stamp.
- Invariant: Day complete iff every active routine has a log. Streak walks backward while complete.
- Never: No vet store.
- Desk `watch_rate`: OLS s/day vs day; R²; DU/DD/CU/CL/CD spread; COSC |dev|≤4.
- Taste DNA is section 7.6. Do not invent a second look.
- A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

### 3.1 Architecture contract

The Grid is a fold over Cues for one Int daykey in YYYYMMDD form, grouped into Pet columns, with phases Blank, Open, Clearing, and Curtain. Blank is written when no active Cue exists. Open is the phase when active Cues exist and none holds a StrikeMark; a right swipe on the ColumnHead writes a StrikeMark and folds Open to Clearing, and a swipe on any lower Cue writes a LeapMark, keeps stack order, and does not change phase. When every active Routine holds a StrikeMark, Curtain writes one CurtainMark and folds Clearing to Curtain, including on the same commit that left Open, and any swipe on Curtain is refused. Peel removes the last StrikeMark, is refused on Open, and folds Curtain to Clearing when any active Cue lacks a strike; removing the final StrikeMark returns the grid to Open and drops that daykey's CurtainMark. Day complete means every active Routine has a StrikeMark for the daykey, and the streak walks backward only while prior daykeys stay complete.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

Today hosts one UICollectionView whose layout is a UICollectionViewFlowLayout subclass. Each Pet is a section and each Cue is a cell stacked top to bottom by routine priority, so the column reads as a short vertical timeline and the ColumnHead is the top unstruck cell. A right swipe on that head cell writes StrikeMark. A right swipe on any other cell in the column writes LeapMark. The streak rail is a footer supplementary view in the same collection, so the flow layout remains the only custom surface. SwiftUI hosts that collection with UIViewRepresentable. Pets, Routines, Settings, and onboarding use stock List, Form, and Button. The day line is one short statement above the grid, the grid fills the remaining height edge to edge, and columns may differ in height. Phase changes cross-fade in 180ms ease-out, and Reduce Motion swaps instantly. One haptic fires when a StrikeMark or CurtainMark commits. LeapMark, Peel, and opening a sheet stay silent. Every cue cell is at least 44pt with contentShape on the whole chrome. Column accent is paired with the pet name and a strike or open label, so colour is never the only signal. Icon-only controls have VoiceOver labels. Blank fills the screen with generated art, the headline No chores yet, the line Add a pet and a routine, and a full-width button at the bottom.

### 3.3 Naming contract

Convention: Stagehand / greenroom lexicon (Grid, Pet, Routine, Cue, StrikeMark, LeapMark, CurtainMark, Peel, ColumnHead).

Examples to follow: GridFold (the daykey fold), ColumnHead (the top unstruck Cue in a Pet column), strikeColumnHead() (writes StrikeMark), peelLastStrike() (refused while Open).

### 3.4 Dependency contract

Zero external dependencies. project.yml has no packages entry, no CocoaPods, and no vendored third-party source. The axis allows only UIKit, Core Graphics, AVFoundation, and URLSession. This app imports UIKit for the collection view and Core Graphics for the flow layout's column rules. It does not import AVFoundation, because the product has no camera, and it does not call URLSession, because the grid never leaves the device and the cgi search.pl endpoint is unused.

### 3.5 Navigation contract

The cue cap grid is the permanent root and never pushes away. There is no tab bar and no TabView. Pets, Routines, and Settings arrive as sheets from controls on the grid chrome. Column-head strike stays fused on Today as the swipe. The streak rail stays on the grid footer. Read ProcessInfo.processInfo.arguments once after onboarding is complete. The launch key today shows the grid, log presents the Routines sheet, goals presents the Pets sheet, and settings presents the Settings sheet. Those keys are launch arguments, not tabs. If onboarding is still showing, the hook does not run.

### 3.6 Screen composition contract

Grid-root fused today (Today holds the cap grid and fused column-head strike; Pets and Routines arrive as sheets; Settings as sheet; streak rail on Today footer; maps family Today|Pets|Routines|Settings without TabView)

1. Onboarding. Three full-page stages, not a destination on the grid chrome. The first says each pet has its own column. The second says swipe the top open cue. The third says the curtain seals the day when every routine is struck and the streak rail records that seal. Continue sits full width at the bottom. Skip still writes one pet and one routine and sets the completion flag. Settings can run it again. The Simulator seed marks it complete.
2. Today, the Grid root. Holds the cap grid, the fused column-head strike, and the streak rail footer. Seed shows several pets and several cues, with the lead column's first cue already struck and the next column head able to take a swipe. Blank uses the full-page empty state. Curtain is a phase of this screen, not a separate route.
3. Pets sheet. Add and edit a pet with name, species, and column accent. Delete names the pet and states that its routines leave the grid. This sheet is the goals launch key.
4. Routines sheet. Attach feed, walk, or meds cues to a pet, with sort order and an active flag. This sheet is the log launch key.
5. Settings sheet. Re-run onboarding, reset all data with a confirm that names the grid and says every pet, routine, and mark will be erased, and a contact control that opens https://footlight-grid.pro/contact-us. No accounts, no push, and no vet store.

No scan screen and no search screen.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

---

## 4. Target file organization

Scheme: **By stagehand role (Grid, Pet, Routine, Cue, StrikeMark, LeapMark, CurtainMark, Peel, ColumnHead)**

```
Footlight/
  Grid/
  GridFold.swift
  GridStore.swift
  GridScreen.swift
  OnboardingFlow.swift
  SettingsSheet.swift
Pet/
  PetRecord.swift
  PetSheet.swift
Routine/
  RoutineRecord.swift
  RoutineSheet.swift
Cue/
  CueRecord.swift
  CueColumnCell.swift
StrikeMark/
  StrikeMark.swift
LeapMark/
  LeapMark.swift
CurtainMark/
  CurtainMark.swift
Peel/
  PeelStrike.swift
ColumnHead/
  ColumnHead.swift
  CapGridFlowLayout.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Today
A first-class screen for **Today**. Must render empty, populated and error states.

### 5.3 Pets
A first-class screen for **Pets**. Must render empty, populated and error states.

### 5.4 Routines
A first-class screen for **Routines**. Must render empty, populated and error states.

### 5.5 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.6 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.7 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Pet** — named per this app's convention.
- **Routine** — named per this app's convention.
- **ChoreLog** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **lingo · theater · branded**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#3C3C3C` | Screen background |
| `surface` | `#535353` | Cards, rows, sheets |
| `ink` | `#FFFFFF` | Primary text and icons |
| `accent` | `#CE82FF` | Primary action, key figure, progress fill |
| `muted` | `#BABABA` | Secondary text, dividers, disabled |

The scaffold already wrote these exact values to `Footlight/DesignTokens.swift`
(`DesignTokens.bg`, `.surface`, `.ink`, `.accent`, `.muted`, plus
`DesignTokens.fontFamily`). Reach every colour through `DesignTokens` — a
typed accessor on top of it is fine. Keep the file and its hex values; do not
move them into `Assets.xcassets` and never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **Palatino**

Palatino is the only text face, reached through one accessor with at most six steps: display, title, headline, body, caption, and micro. Palatino-Bold carries the short Today statement and sheet titles. Palatino-Roman carries humanist body near 17pt and the captions. There is no poster size and no second family. Streak length, cue counts, and the YYYYMMDD daykey go through NumberFormatter with monospaced digits. Sizes use UIFontMetrics so Dynamic Type scales them, nothing uses a fixed size that ignores Dynamic Type, and nothing sits below 12pt. At the largest accessibility size the ColumnHead still shows the cue name and the pet name. Day boundaries use Calendar.current.startOfDay before the Int daykey is formed.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **24pt** for cards, sheets and primary surfaces; **10pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **hairline+fill** — a 1pt hairline border plus a flat fill tint, reused everywhere a surface sits above another.

Primary control: **soft card** — primary actions live inside a rounded card using the radius below, not a flat row with no fill.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **UIKit UICollectionViewFlowLayout subclass · timeline**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **UIKit UICollectionViewFlowLayout subclass · timeline** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

### 7.6 Taste DNA

Aesthetic: **warm** (Warm soft: friendly radii, comfortable pad, one playful moment.)

Reference system: **lingo** — steal rhythm and restraint, not their colours or logos.

Mood: **Playful, minimal design with bright colors, rounded shapes, tactile 3D borders, and friendly illustrations for approachable interfaces.**.

Home rhythm (`theater`, comfortable): A crop, one statement, one control. The rest is field.

Warm soft: friendly radii, comfortable pad, one playful moment. Layout `theater`, density comfortable. Kit 24/10, hairline+fill, soft card. Palette recipe `branded`. Almost no travel. Cross-fade 180ms ease-out. Numbers tick, they do not fly. Reduce Motion: instant swap. Reduce Motion: fade only. Do not invent a second radius or a second accent.

Type move: Mono numerals, humanist body, no poster type. Reference type feel: warm.

Motion (`quiet`): Almost no travel. Cross-fade 180ms ease-out. Numbers tick, they do not fly. Reduce Motion: instant swap.

Voice (`editorial`): Complete sentences, no slang, no hype. Captions are real lines.

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- iPhone allows portrait, landscape left, and landscape right. iPad allows all
  four orientations. Keep both lists in the Info settings, and let a rotated
  screen scroll instead of clipping.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Sibling cards, images and titles never overlap. Each cell owns its frame;
  `scaledToFill` is clipped to that cell. A chopped headline or two canvases
  in one slot is a defect, not a collage.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable · one Grid root record holding Pets, Routines, Cues and Marks, encoded under a single key with debounced save after each mark**

One Codable Grid root holds Pets, Routines, Cues, StrikeMarks, LeapMarks, and CurtainMarks. It is encoded to Data and stored in UserDefaults under the single key ftl.grid.v1. Each mark schedules a debounced save of about 400ms, and the same save runs immediately when the scene enters the background so a force-quit keeps the last mark. The UI talks only to a GridStore seam and never reads UserDefaults itself. A daykey is an Int in YYYYMMDD form derived from Calendar.current.startOfDay. When the daykey rolls, prior marks stay and the new day's Cues open with no StrikeMark. resetAllData() removes ftl.grid.v1 and is reachable from Settings. On the Simulator only, and only once, ftl.demo.v1 seeds several pets and several cues, writes a StrikeMark on the first Cue of the lead column, and marks onboarding complete. A device never receives that seed.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Footlight/1.0 (iOS; +https://footlight-grid.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- iPhone: portrait, landscape left, landscape right. iPad: all four orientations (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


### First minute on a clean install (Guideline 2.1)

A reviewer judges completeness (Guideline 2.1) in the first minute on a clean
install. The loop must finish there without knowing the app's rules. Long form:
`docs/REVIEW-LESSONS-2026-09-25.md`.

- The home verb writes a visible object on the first tap of a clean install:
  a row, a card, a mark on the dial. No second screen needed to see it.
- Never leave the home control disabled until an unexplained condition holds
  ("two links first", "long press first", "add a volume first"). Accept the
  first input with sane defaults and show the rule afterwards.
- The twist fires after a successful write, as a visible consequence (a highlight,
  a caption, a next step), never instead of the write.
- A refusal is allowed only after the first success, and it must name the next
  tap that works.
- Nothing in the first session waits for midnight, a second day, a second item or
  a streak. A screen that can only fill later shows its action, not a wait.
- Every empty state names one action, and that action completes on the spot.
- Next to home there is at least one more screen that works on a clean install.
- The subtitle and the first description line name an everyday action a stranger
  understands. Coined words may decorate labels; each primary button still says
  what it does.
- A failed network lookup falls back to local data or typed input with a message;
  the loop still finishes offline.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.lifestyle`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.lifestyle
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Column-relay-then-strike (only each column's top unstrike Cue accepts Swipe to write StrikeMark; Swipe elsewhere in column writes LeapMark; CurtainMark when every active Routine is struck; Peel reopens Clearing; Swipe on Curtain refused; seed strikes first Cue in lead column so opening Swipe is on second Cue or another column head)

Home is the cue cap grid: a right swipe strikes only the ColumnHead, the top unstruck Cue in that Pet's stack. A swipe on any other Cue in the same column writes a LeapMark and keeps sort order, so columns advance independently. When every active Routine holds a StrikeMark for the daykey, Curtain writes a CurtainMark and folds Clearing to Curtain, and swipe on Curtain is refused. Peel removes the last StrikeMark and reopens Clearing whenever any Cue lacks a strike; Peel on Open is refused. The Simulator seed already writes a StrikeMark on the first Cue of the lead column so the opening swipe is that column's second Cue or another column head. Unit tests cover the invariant that a day is complete exactly when every active Routine has a StrikeMark, and that the streak walks backward only while those days stay complete.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Bauhaus geometric · illustration**


Base prompt, reused and extended for every asset:

```
Bauhaus geometric illustration. Flat hard-edged circles, squares, and triangles construct a small animal and a vertical stack of cue blocks on a stage apron. Even light, no gradient, no photorealism, no clay, no glass, no wireframe, no letters, no words. Subjects are solid and centered. Use the app palette only. Do not introduce new hues.
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `ftl_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `ftl_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `ftl_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `ftl_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `ftl_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `ftl_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `ftl_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `ftl_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `ftl_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `ftl_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `ftl_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Column-relay-then-strike (only each column's top unstrike Cue accepts Swipe to write StrikeMark; Swipe elsewhere in column writes LeapMark; CurtainMark when every active Routine is struck; Peel reopens Clearing; Swipe on Curtain refused; seed strikes first Cue in lead column so opening Swipe is on second Cue or another column head)' feature screen. |
| 11 | `ftl_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `ftl_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |

### Prompt per asset

**`ftl_AppIcon`** — 1024x1024

```
Bauhaus geometric illustration, opaque full-bleed emblem of a constructed animal head in front of three vertical bars, subject inside the middle, no text, no letters, no rounded mask, no drop shadow.
```

**`ftl_Splash`** — 1290x2796

```
Bauhaus geometric illustration, tall stage field of large flat shapes with a quiet uncluttered centre band, full-bleed, no text, no letters.
```

**`ftl_Onboarding1`** — 1024x1536

```
Bauhaus geometric illustration, cutout of two constructed animals standing beside a short stack of blocks, solid subjects centered, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ftl_Onboarding2`** — 1024x1536

```
Bauhaus geometric illustration, cutout of a geometric hand swiping the top block off a vertical stack, solid subject centered, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ftl_Onboarding3`** — 1024x1536

```
Bauhaus geometric illustration, cutout of a folded curtain shape above a short rail of solid marks, solid subject centered, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ftl_EmptyHome`** — 1024x1024

```
Bauhaus geometric illustration, cutout of a solid closed crate made of stacked rectangles, fully opaque subject, transparent corners, not glass, not hollow, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ftl_EmptyList`** — 1024x1024

```
Bauhaus geometric illustration, cutout of an empty geometric shelf, one solid object, transparent corners, not a wire frame, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ftl_CardBackdrop`** — 1200x800

```
Bauhaus geometric illustration, abstract full-bleed field of large overlapping circles and bars, low detail so type can sit on it, no text, no letters.
```

**`ftl_ControlFace`** — 512x512

```
Bauhaus geometric illustration, cutout of one solid filled wedge, the strike control, occupying the center, not an outline, not a hollow ring, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ftl_TwistHero`** — 1024x1024

```
Bauhaus geometric illustration, cutout of a vertical column of solid blocks with only the top block offset, a small constructed animal beside it, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ftl_SuccessMark`** — 512x512

```
Bauhaus geometric illustration, cutout of a solid filled seal made of a circle and a square, occupying the middle, not a thin outline, not a hollow ring, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`ftl_HeaderDecor`** — 1200x600

```
Bauhaus geometric illustration, wide cutout ornament of repeating triangles and short bars, solid shapes, transparent corners, no text, no letters.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated SOLID opaque subject in the center, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail. A hollow glass box or wire frame with a transparent center is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`ftl.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.
- A `TabView` with exactly three tabs. That is the factory stamp — two or
  four-to-five destinations, or a different chrome. ReviewScreen keys are
  not tabs.


---

## 17. Tests

Add a unit test target `FootlightTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. `Footlight/ReviewLaunch.swift` (scaffold, keep it) parses `ProcessInfo.processInfo.arguments`.
   Read `ReviewLaunch.screen` once after onboarding:
   `-ReviewScreen today|log|goals` switches the running app's live navigation. Extra cover slugs open those screens.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Footlight -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Column-relay ADT fold (Open | Clearing | Curtain); the grid is a fold over Cues for the daykey grouped by Pet columns; Swipe on a column-head unstrike Cue writes StrikeMark and folds Open to Clearing; Swipe on a non-head Cue in the same column writes LeapMark and keeps order; when every active Routine holds a StrikeMark, Curtain writes CurtainMark and folds Clearing to Curtain; Peel removes the last StrikeMark and folds Curtain to Clearing when any Cue lacks a strike; Peel on Open is refused; Swipe on Curtain is refused; empty grid writes Blank** with no leakage across layers.
- [ ] UI approach matches **UIKit UICollectionViewFlowLayout subclass · timeline**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Cap-grid-locked chrome (the cue cap grid never leaves; Pets, Routines and Settings arrive as sheets; column-head strike fuses on Today; streak rail on grid footer; no tab bar)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **Palatino** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Footlight
xcodegen generate
xcodebuild build-for-testing -scheme Footlight -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.footlight.grid/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild -scheme Footlight -destination 'generic/platform=iOS' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.footlight.grid/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcrun simctl list devices available
xcodebuild test-without-building -scheme Footlight -destination 'platform=iOS Simulator,id=<UDID>' -jobs 4 -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.footlight.grid/DerivedData'
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY, DEVELOPMENT_TEAM, SWIFT_TREAT_WARNINGS_AS_ERRORS or -derivedDataPath in project.yml — they are command-line only. CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
