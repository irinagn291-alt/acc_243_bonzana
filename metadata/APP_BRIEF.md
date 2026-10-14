<!-- gf-brief source=37a55fb3c45a934cb09ea2e7236d5d3b83064d1abb8026ec3802c04c99f55957 written=2026-10-14T14:40:50+03:00 -->
# Footlight

## What it is

Footlight is a daily chore board for a multi-pet household. Each pet owns a column. Chores stack in that column in a fixed order, and you strike the top open chore in a column until every active chore is done and the day is sealed. It is for people who want per-pet order, not one shared list.

## Launch and onboarding

A cold first launch shows a brief system launch screen with no title, then a placeholder grid. VoiceOver reads **"Opening the grid"**.

If onboarding has not been finished, a full-screen flow covers the app and cannot be swiped away. **"Continue"** and **"Skip"** appear on every page.

1. Title **"Each pet has a column"**. Body **"Each pet has its own column. Chores stack in order inside that column."** Buttons **"Continue"** and **"Skip"**.
2. Title **"Swipe the top open chore"**. Body **"Swipe the top open chore to strike it. A swipe lower in the column keeps the order."** Buttons **"Continue"** and **"Skip"**.
3. Title **"The curtain seals the day"**. Body **"The curtain seals the day when every chore is struck, and the streak rail records that seal."** Buttons **"Continue"** and **"Skip"**.

**"Continue"** on pages 1 and 2 advances. **"Continue"** on page 3 closes the flow and opens Today with no sample pets.

**"Skip"** on any page closes the flow. If the grid has no pets, it writes one pet named **"Moth"** (species **"Cat"**, accent **"Violet"**) and one chore **"Morning feed"**.

A later launch that already finished onboarding goes straight to Today (or the empty home if there are no active chores).

## Screens

There is no tab bar. **Today** stays on screen. **"Pets"**, **"Chores"**, **"Seals"**, and **"Settings"** open as sheets.

### Today

Caption **"Today"**.

The line under it changes with the day:

- While chores are still open and none is struck: **"Strike the top open chore in a column."**
- After at least one strike and before the last one: **"Keep striking the top open chore in each column."**
- When every active chore is struck: **"Every chore is struck. This day is sealed."**

The next-step line under that:

- If a column still has an open chore: **"Swipe {chore title} under {pet name}."** (example: **"Swipe Morning feed under Moth."**)
- When the day is sealed: **"Undo the last strike if this seal was early."**

A hamburger control (VoiceOver **"More"**) opens a menu:

- **"Pets"** — opens Pets.
- **"Chores"** — opens Chores.
- **"Seals"** — opens Seals.
- **"Settings"** — opens Settings.

**"Undo last strike"** appears only after at least one strike today. It restores the most recent strike for today and, if that reopens a chore, removes today’s seal. VoiceOver **"Undo the last strike"**. The control is dimmed and ignores taps while a strike is being saved.

The grid is one column per pet. Each block shows the chore title, the pet name, and a state:

- **"Open"** — top unstruck chore in that column. A small mark sits next to the state.
- **"Waiting"** — a lower unstruck chore in that column.
- **"Struck"** — already done for today.

A right swipe or a tap on an **"Open"** block strikes it. A flash may appear; VoiceOver **"Strike saved"**. A right swipe or a tap on a **"Waiting"** or already **"Struck"** block does not strike it; it records that the order was kept.

A rail under the columns reads **"Seal streak {n}. This day is {Month D, YYYY}."** (example: **"Seal streak 0. This day is October 14, 2026."**). The streak counts consecutive sealed days walking backward from today and stays **0** until today is sealed.

If a saved grid cannot be read, a notice appears above the grid with one of:

- **"The saved grid could not be read. The last good file was restored."**
- **"The saved grid could not be read. The previous copy was restored."**
- **"The saved grid could not be read. An empty grid is ready."**

**"Try again"** reloads the grid.

When there is no active chore, Today is replaced by the empty home: **"Settings"** (VoiceOver **"Open settings"**), title **"No chores yet"**, line **"Add a pet and a routine"**, and **"Add a pet"** (opens Pets).

### Pets

Title **"Pets"**. **"Close"** dismisses (VoiceOver **"Close pets"**). **"Add"** starts a new pet (VoiceOver **"Add a pet"**). The keyboard bar has **"Done"**.

Empty: **"No pets yet"**, **"Add a pet to open a column."**, and **"Add a pet"**.

Each row shows the pet name and **"{species}. Accent {Violet|Ink|Mist}."** (example: **"Cat. Accent Violet."**). Tap a row to edit. Swipe a row to **"Delete"**.

Confirm delete: **"Delete {name}?"** (or **"Delete this pet?"**), message **"{name} leaves the grid. Its routines leave the grid."** (or **"Its routines leave the grid."**), **"Delete"** or **"Cancel"**.

Editor fields: **"Name"**, **"Species"**, **"Accent"** with **"Violet"**, **"Ink"**, **"Mist"**, and **"Save pet"**. **"Save pet"** stays disabled until both **"Name"** and **"Species"** have text. If only one is filled: **"Enter a name and a species before saving."**

If pets cannot load: **"Pets could not be shown"**, the recovery line, and **"Try again"**.

### Chores

Title **"Chores"**. **"Close"** dismisses (VoiceOver **"Close chores"**).

If there are no pets: **"No chores yet"**, **"Add a pet before attaching a routine."**, and **"Add a pet"** (closes Chores and opens Pets).

If there are pets but no chores: **"No chores yet"**, **"Attach feed, walk, or meds to a pet."**, and **"Add a chore"**. **"Add a chore"** immediately writes **"Morning feed"** for the first pet (active, sort **0**) and then shows the list.

List section **"On the grid"**. Each row shows the chore title and **"{pet name}. Order {n}. {Active|Paused}."** (example: **"Moth. Order 0. Active."**). Tap a row to load it into **"Attach"**. Swipe to delete.

Confirm delete: **"Delete this chore?"**, **"This chore leaves the grid, and its strike for today leaves with it."**, **"Delete"** or **"Cancel"**.

Section **"Attach"**:

- **"Chore"** — **"Morning feed"**, **"Evening walk"**, or **"Evening meds"** only.
- **"Pet"** — the pet’s name.
- Stepper **"Sort {n}"** from **0** to **20**. Lower numbers sit higher in the column.
- **"Active"** — on keeps the chore on Today; off marks it **"Paused"** and removes it from Today.
- **"Save chore"** — writes a new chore or updates the one being edited. Disabled until a pet is chosen. If save is refused: **"Choose a pet before saving this chore."**

If chores cannot load: **"Chores could not be shown"**, the recovery line, and **"Try again"**.

### Seals

Title **"Seals"**. **"Close"** dismisses (VoiceOver **"Close the seal ledger"**).

Empty: **"No seals yet"**, **"Strike every column and the day writes a seal here."**, and **"Back to today"**.

When there is history:

- Section **"Seals"** — each row **"Sealed day {YYYYMMDD}."** (example: **"Sealed day 20261014."**). If none: **"No curtain seal is stored."**
- Section **"Order kept"** — each row **"Order kept on day {YYYYMMDD}."**. If none: **"No lower swipe is stored."**

If the ledger cannot load: **"The ledger could not be shown"**, the recovery line, and **"Try again"**.

### Settings

Title **"Settings"**. **"Close"** dismisses (VoiceOver **"Close settings"**).

Summary: **"The grid has no pets yet."** or **"{n} pets on the grid. {n} chores."** (the wording stays **"pets"** / **"chores"** even when the count is 1).

If a recovery notice is present, it is shown with **"Try again"**.

- **"Run onboarding again"** — closes Settings and shows the three onboarding pages. Pets and chores already on the grid stay. **"Skip"** writes **"Moth"** only if there are still no pets.
- **"Reset all data"** — confirm **"Reset the grid?"**, **"Every pet, routine, and mark will be erased."**, **"Erase the grid"** or **"Cancel"**. **"Erase the grid"** wipes the board and returns to onboarding.
- **"Contact Footlight"** — opens the contact page.

If Settings cannot read an empty broken grid: **"Settings could not read the grid"**, the recovery line, **"Try again"**, and the same three controls.

## Features

- One column per pet on Today
- Chores stacked in order inside that column
- Strike the top **"Open"** chore with a right swipe or a tap
- **"Waiting"** chores stay in order; a swipe or tap there keeps the order instead of striking
- **"Struck"** marks a chore done for today
- **"Undo last strike"**
- The day seals when every active chore is struck
- **"Seal streak"** on Today
- **"Seals"** history and **"Order kept"** history
- Add and edit pets: **"Name"**, **"Species"**, **"Accent"** (**"Violet"**, **"Ink"**, **"Mist"**)
- Attach **"Morning feed"**, **"Evening walk"**, or **"Evening meds"** to a pet
- **"Sort"** order and **"Active"** / **"Paused"**
- **"Run onboarding again"**
- **"Reset all data"**
- **"Contact Footlight"**

## Behaviours that can look like bugs

- After **"Continue"** through all three onboarding pages, Today shows **"No chores yet"** and **"Add a pet and a routine"**. Add a pet, then a chore, or use **"Skip"** so **"Moth"** and **"Morning feed"** appear.
- **"Add a pet before attaching a routine."** blocks Chores until a pet exists. Use **"Add a pet"**.
- **"Save pet"** will not run while **"Name"** or **"Species"** is empty. Fill both, or wait out **"Enter a name and a species before saving."**
- **"Save chore"** will not run until a pet is chosen. If refused: **"Choose a pet before saving this chore."**
- **"Add a chore"** on the empty Chores screen does not open a blank form. It immediately creates **"Morning feed"** for the first pet.
- A swipe or tap on **"Waiting"** does not check the chore off. The **"Open"** chore stays **"Open"**. The attempt is stored under **"Order kept"** on Seals.
- A swipe or tap on **"Struck"** does not unstrike it. Only **"Undo last strike"** undoes, and only the latest strike today.
- After **"Every chore is struck. This day is sealed."**, swipes and taps on the grid do nothing. Use **"Undo last strike"** to reopen the last chore.
- **"Undo last strike"** is hidden until at least one strike exists today.
- Two taps or swipes on the same chore in quick succession: the second is ignored.
- The grid dims and ignores input for a moment while a strike is saved.
- Turning **"Active"** off and saving removes that chore from Today. It remains on Chores as **"Paused"**. Turn **"Active"** on and **"Save chore"** to put it back.
- A new calendar day reopens every active chore. Yesterday’s strikes do not carry over. Past seals stay on Seals.
- Onboarding cannot be dismissed by a swipe. Use **"Continue"** or **"Skip"**.
- **"Run onboarding again"** does not wipe the board. Only **"Erase the grid"** does.
- Settings may say **"1 pets on the grid. 1 chores."** The wording does not change for a single item.
- Seals list days as eight-digit numbers such as **"Sealed day 20261014."**, not as calendar dates. The streak rail uses a calendar date.

## Starter content and resume

**"Skip"** writes **"Moth"** (**"Cat"**, **"Violet"**) and **"Morning feed"**. Finishing with **"Continue"** writes none.

Pets, chores, today’s strikes, seals, and order-kept records stay on this device and come back on the next launch the same day. Unfinished columns stay as they were. A new calendar day starts every active chore **"Open"** again. **"Reset all data"** / **"Erase the grid"** clears everything and returns to onboarding.

## Permissions

None.

## Absent

Absent: login or accounts, in-app purchase, ads, analytics, user-generated content for other people, account deletion flow, App Tracking Transparency prompt.

## Data and support

Everything stays on this device. **"Contact Footlight"** in Settings opens the contact page.

## Scanning and health

None. The app does not scan barcodes or QR codes. **"Evening meds"** is only a chore title. There is no health or medical information and no citations.

## Platform

English copy only. No region lock. The day flips with the device calendar. The streak date is always an English **"Month D, YYYY"** line.

Portrait only, full screen, on iPhone and iPad. Dark appearance. Minimum iOS 17.0.

## Category

Lifestyle
