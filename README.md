# Footlight

Footlight is a household stagehand for multi-pet homes. Each pet owns a column of cues. You strike the top open cue in that column so every active routine is marked before the curtain drops. There is no account, no push, and no vet store.

## Architecture

The grid is a column-relay fold over cues for one daykey, grouped by pet. Phases are Blank, Open, Clearing, and Curtain. Blank means no active cue. Open means cues exist and none is struck. A swipe on the column head writes a StrikeMark and folds Open into Clearing. A swipe on any lower cue writes a LeapMark and keeps stack order. When every active routine holds a StrikeMark, the fold writes one CurtainMark and moves to Curtain, including on the same commit that left Open. Peel removes the last StrikeMark, is refused while Open, and returns Curtain to Clearing when any cue is still open. The streak walks backward only while prior daykeys stay complete.

That fold fits this product because each pet has its own order, and households interleave progress across columns. A single global queue would hide the column that is still open.

## Unique feature

Column-relay-then-strike. Only the top unstruck cue in a column accepts a right swipe that writes a StrikeMark. A swipe elsewhere in the column writes a LeapMark. The curtain ledger counts CurtainMarks and LeapMarks. Seed data already strikes the first cue in the lead column, so the opening swipe lands on the second cue or another column head.

## Art

Style: Bauhaus geometric illustration. Flat hard-edged circles, squares, and triangles construct a small animal and a vertical stack of cue blocks on a stage apron. Even light, no gradient, no photorealism, no clay, no glass, no wireframe, no letters, no words. Subjects are solid and centered. Use the app palette only. Do not introduce new hues.

The same prompt is the base for `ftl_AppIcon`, `ftl_Splash`, `ftl_Onboarding1`, `ftl_Onboarding2`, `ftl_Onboarding3`, `ftl_EmptyHome`, `ftl_EmptyList`, `ftl_CardBackdrop`, `ftl_ControlFace`, `ftl_TwistHero`, `ftl_SuccessMark`, and `ftl_HeaderDecor`.

## How this differs

Kennelstamp forces one globally focused row before a swipe. Kennelroll forces one global front stop on a strip. Footlight shows every pet column at once and enforces routine order inside each column.

## Build

```
xcodegen generate
xcodebuild build-for-testing -scheme Footlight -destination 'generic/platform=iOS Simulator'
```
