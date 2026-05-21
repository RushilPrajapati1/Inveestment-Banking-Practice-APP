# IBPractice — iOS app

Native SwiftUI port of the 400 IB Questions web app.

## Open in Xcode

```
open ios/IBPractice.xcodeproj
```

Then press ⌘R to run on an iPhone simulator.

Requires Xcode 16 or newer (uses file-system-synchronized groups).

## Structure

- `IBPractice/IBPracticeApp.swift` — `@main` entry point
- `IBPractice/RootView.swift` — TabView (Browse / Flashcards / Progress)
- `IBPractice/CategoriesView.swift` — sidebar / category navigation with search
- `IBPractice/QuestionListView.swift` — filtered list of questions per category
- `IBPractice/QuestionDetailView.swift` — question + answer + Known/Review buttons
- `IBPractice/FlashcardsRootView.swift` — flashcards with swipe & shuffle
- `IBPractice/ProgressTabView.swift` — overall + per-category progress
- `IBPractice/AnswerView.swift` — paragraph/bullet renderer for answer text
- `IBPractice/Models.swift` — Codable types matching `data/questions.json`
- `IBPractice/DataStore.swift` — loads the bundled JSON
- `IBPractice/ProgressStore.swift` — UserDefaults-backed Known/Review state
- `IBPractice/Resources/questions.json` — bundled copy of the dataset

## Notes

- iOS 17+ deployment target.
- Progress is stored locally in `UserDefaults` under key `ib.progress.v1`.
- To refresh the data, replace `IBPractice/Resources/questions.json` from the
  project root (`data/questions.json`). Files in `IBPractice/` are auto-synced
  into the build via Xcode's synchronized folder group — no project edits needed.
