# IBPractice — Screen specs

Design canvas: **iPhone 15 Pro · 393 × 852 pt**.
Status bar: 59 pt top inset. Home indicator: 34 pt bottom inset.
Tab bar height: 83 pt. Large nav bar: 96 pt; standard nav bar: 56 pt.

All colors, type, spacing, and radii reference tokens in `design-tokens.json`.

---

## 01 — Browse (Categories)

**Purpose:** entry point. Pick a category or jump to All / Review.

```
┌──────────────────────────────────────┐  ← status bar
│  400 IB Questions          ⋯         │  ← large title (28/700)
│  ┌────────────────────────────────┐  │
│  │ 🔎  Search questions           │  │  ← search field (h36, r10)
│  └────────────────────────────────┘  │
│                                       │
│  ┌────────────────────────────────┐  │
│  │ 📥 All questions          400 ›│  │  ← grouped list row
│  │ ↺  Review                  12 ›│  │
│  └────────────────────────────────┘  │
│                                       │
│  FIT                                 │  ← section header (caption/secondary)
│  ┌────────────────────────────────┐  │
│  │ Analytical / Attention   3/9  ›│  │
│  │ Communication             1/8 ›│  │
│  └────────────────────────────────┘  │
│                                       │
│  ACCOUNTING                          │
│  ┌────────────────────────────────┐  │
│  │ Income statement   [Basic] 2/7›│  │
│  │ Three statements   [Adv]   0/6›│  │
│  └────────────────────────────────┘  │
│                                       │
│  …                                   │
├──────────────────────────────────────┤
│   📚      🃏      📊                  │  ← tab bar (Browse / Cards / Progress)
│ Browse  Cards  Progress               │
└──────────────────────────────────────┘
```

- Grouped list (iOS `insetGrouped`), row min-height 56.
- Difficulty tag: pill, h20, padding 6×2, caption (12/600), uppercase.
- Counter right-aligned, secondary text, monospace digits.
- Section headers: `caption/secondary`, uppercase, 8pt top padding.

---

## 02 — Question list

**Purpose:** list of questions inside a category (or "All", or "Review").

```
┌──────────────────────────────────────┐
│  ‹ Back     Accounting · Basic       │  ← inline nav bar (h56)
│  ┌────────────────────────────────┐  │
│  │ 🔎  Search                      │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │  All | Basic | Advanced        │  │  ← segmented picker
│  │  Review only             ◯───  │  │  ← toggle
│  └────────────────────────────────┘  │
│                                       │
│  7 questions                          │
│  ┌────────────────────────────────┐  │
│  │ ● Walk me through the three  ›│  │  ← row: status dot + truncated Q
│  │   Accounting [Basic]           │  │
│  │ ○ What is working capital…   ›│  │
│  │   Accounting [Basic]           │  │
│  │ ● How does $10 of depreciat… ›│  │
│  └────────────────────────────────┘  │
│  …                                   │
└──────────────────────────────────────┘
```

- Status dot (8×8):
  - filled green = Known
  - filled orange = Review
  - outline gray = unset
- Row: 2 lines question (lineLimit 3), then meta row with category + difficulty tag.

---

## 03 — Question detail

**Purpose:** read the question + answer. Mark Known/Review.

```
┌──────────────────────────────────────┐
│  ‹ Back        Question 12           │
│                                       │
│  ACCOUNTING · [Basic]                 │  ← caption/secondary, uppercase
│  Walk me through the three            │  ← title3 (20/600)
│  financial statements.                │
│  ──────────────────────────────       │
│                                       │
│  The three major financial            │  ← body (17/400)
│  statements are the Income            │
│  Statement, Balance Sheet, and        │
│  Cash Flow Statement.                 │
│                                       │
│  • The Income Statement gives the     │  ← bulleted block
│    company's revenue and expenses…    │
│  • The Balance Sheet shows the        │
│    company's Assets…                  │
│  • The Cash Flow Statement…           │
│                                       │
│  …                                   │
├──────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────────┐ │  ← bottom action bar (safeAreaInset)
│  │  ↺ Review   │ │   ✓ Known        │ │
│  └─────────────┘ └─────────────────┘ │
└──────────────────────────────────────┘
```

- Bottom bar: 64 pt tall, `surface/bar` background, 12 pt gap, 16 pt side padding.
- Review = `.bordered` tint `status/review` if active, gray otherwise.
- Known  = `.borderedProminent` tint `status/known` if active, accent otherwise.

---

## 04 — Flashcards (front)

**Purpose:** drilling mode.

```
┌──────────────────────────────────────┐
│  Flashcards                           │  ← large title
│  ┌────────────────────────────────┐  │
│  │ Accounting — Basic        ⌄    │  │  ← category menu (r10)
│  └────────────────────────────────┘  │
│  All | Basic | Advanced               │  ← segmented
│  Review only             ◯───         │
│                                       │
│   3 / 42                  ⤮ Shuffle   │  ← bar
│  ╔══════════════════════════════════╗ │
│  ║ ACCOUNTING  [Basic]              ║ │  ← card (r18, secondary bg)
│  ║                                  ║ │
│  ║ Walk me through the three        ║ │
│  ║ financial statements.            ║ │
│  ║                                  ║ │
│  ║                                  ║ │
│  ║       Tap to reveal answer       ║ │  ← hint (footnote/secondary)
│  ╚══════════════════════════════════╝ │
│                                       │
│  ┌──┐ ┌────────┐ ┌────────┐ ┌──┐     │
│  │ ‹│ │ ↺ Rev. │ │ ✓ Known│ │› │     │  ← actions row
│  └──┘ └────────┘ └────────┘ └──┘     │
└──────────────────────────────────────┘
```

- Card swipe left → next, swipe right → prev (min translation 40 pt).
- Tap → flip with `easeInOut` 0.18s.

## 05 — Flashcards (back)

Same frame; the card content swaps to the formatted answer:

```
  ╔══════════════════════════════════╗
  ║ ACCOUNTING  [Basic]              ║
  ║                                  ║
  ║ The three major financial        ║
  ║ statements are the Income…       ║
  ║                                  ║
  ║ • The Income Statement gives…    ║
  ║ • The Balance Sheet shows…       ║
  ║ • The Cash Flow Statement…       ║
  ╚══════════════════════════════════╝
```

Card border color: gray when unmarked, green when Known, orange when Review.

---

## 06 — Progress

**Purpose:** see how much you've covered and reset.

```
┌──────────────────────────────────────┐
│  Progress                             │
│  ┌────────────────────────────────┐  │
│  │ 42 known              11 %     │  │  ← headline + monospaced %
│  │ ████████░░░░░░░░░░░░░░░░░░     │  │  ← linear progress
│  │  42        12        400        │  │  ← stat columns (Known/Review/Total)
│  │  Known    Review     Total      │  │
│  └────────────────────────────────┘  │
│                                       │
│  CATEGORIES                          │
│  ▾ Fit                                │
│      Analytical          3/9         │
│      ██████░░░░                       │
│      Communication       1/8         │
│      ██░░░░░░░                        │
│  ▸ Accounting                         │
│  ▸ Valuation                          │
│  …                                   │
│                                       │
│  ┌────────────────────────────────┐  │
│  │   🗑  Reset progress           │  │  ← destructive button
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

- Confirmation dialog on Reset: "This clears Known and Review markers on every question."

---

## Components

- **DifficultyTag** — pill capsule, caption text, color from `color.difficulty.{basic|advanced}`. Background uses the `.bg` token (15–18% alpha of the foreground).
- **StatusDot** — 8×8 circle: filled `status/known`, filled `status/review`, or 1pt stroke `border/divider`.
- **QuestionRow** — leading dot, multi-line question (lineLimit 3), trailing `›` chevron handled by `NavigationLink`.
- **AnswerBody** — paragraphs (body/primary) separated by 12pt; bullet lists with `•` + 8pt gap.

## Behavior notes

- Tab order: **Browse · Flashcards · Progress**.
- Progress is persisted in `UserDefaults` under `ib.progress.v1`.
- Search filters by case-insensitive substring over question + answer.
- "Review only" toggle is local to the current screen (not persisted across screens).
