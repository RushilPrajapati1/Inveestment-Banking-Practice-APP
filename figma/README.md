# IBPractice — Design package

This folder is the "Figma file" you can hand to Claude Code (or any designer).
A real `.fig` file is a proprietary Figma binary that can only be authored
inside Figma — so this folder bundles the same information in formats Claude
*can* read and Figma *can* import.

## What's here

```
figma/
├── README.md              ← you are here
├── SPEC.md                ← screen-by-screen layout + behavior spec
├── design-tokens.json     ← colors, type, spacing, radius (importable)
└── screens/
    ├── 01-browse.svg              ← Browse tab (categories)
    ├── 02-question-list.svg       ← Questions inside a category
    ├── 03-question-detail.svg     ← Question + answer + action bar
    ├── 04-flashcards-front.svg    ← Flashcards, question side
    ├── 05-flashcards-back.svg     ← Flashcards, answer side
    └── 06-progress.svg            ← Progress tab
```

## Import into Figma

1. Open (or create) a Figma file.
2. **File → Import…** and select all the SVGs in `screens/`. Figma will create
   one frame per file at the iPhone 15 Pro size (393 × 852).
3. Alternatively: drag the SVGs from Finder straight onto the canvas.

Each SVG is a self-contained frame — text is real text, shapes are real shapes,
so you can edit any element after import.

## Hand to Claude Code

```
Use the design in ./figma/ as the source of truth for the iOS app.
Tokens are in design-tokens.json. Screen specs are in SPEC.md.
Visual mocks are in screens/*.svg.
```

Claude can read all of these directly.

## Tokens at a glance

- **Accent:** `#287BEF` (used for primary buttons, links, active tabs)
- **Known:** `#34C759`  **Review:** `#FF9F0A`
- **Difficulty — Basic:** `#34C759`  **Advanced:** `#FF8A1A`
- **Surfaces:** `#FFFFFF` background, `#F2F2F7` grouped background, `#FFFFFF` cards
- **Text:** `#1C1C1E` primary, `#6B6B70` secondary
- **Radius:** 10 (controls), 14 (rows), 18 (cards)
- **Spacing scale:** 4 / 8 / 12 / 16 / 20 / 24
- **Type:** SF Pro — Title 28/700, Headline 17/600, Body 17/400, Caption 12/600

## Mapping to code

Every screen in `screens/` corresponds to a SwiftUI view in `ios/IBPractice/`:

| Screen | SwiftUI file |
|---|---|
| 01 Browse | `CategoriesView.swift` |
| 02 Question list | `QuestionListView.swift` |
| 03 Question detail | `QuestionDetailView.swift` |
| 04–05 Flashcards | `FlashcardsRootView.swift` |
| 06 Progress | `ProgressTabView.swift` |
