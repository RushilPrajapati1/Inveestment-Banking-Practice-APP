import SwiftUI

struct QuestionListView: View {
    @EnvironmentObject private var progress: ProgressStore

    let title: String
    let questions: [Question]

    @State private var searchText = ""
    @State private var difficultyFilter: DifficultyFilter = .all
    @State private var onlyReview = false

    enum DifficultyFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case basic = "Basic"
        case advanced = "Advanced"
        var id: String { rawValue }
    }

    private var filtered: [Question] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return questions.filter { item in
            if onlyReview, progress.status(for: item.id) != .review { return false }
            switch difficultyFilter {
            case .all: break
            case .basic: if item.difficulty != .basic { return false }
            case .advanced: if item.difficulty != .advanced { return false }
            }
            if !q.isEmpty {
                let hay = (item.question + " " + item.answer).lowercased()
                if !hay.contains(q) { return false }
            }
            return true
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                filterCard
                    .padding(.horizontal, 16)

                resultsSection
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
        }
        .canvasBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search")
        .navigationDestination(for: Question.self) { q in
            QuestionDetailView(question: q)
        }
    }

    private var filterCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Eyebrow(text: "Filters", color: Palette.gold)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "Difficulty")
                    Picker("Difficulty", selection: $difficultyFilter) {
                        ForEach(DifficultyFilter.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Rectangle().fill(Palette.rule).frame(height: 0.75)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Review only")
                            .font(.body)
                            .foregroundStyle(Palette.ink)
                        Text("Show questions marked for revisit")
                            .font(.caption)
                            .foregroundStyle(Palette.inkMuted)
                    }
                    Spacer()
                    Toggle("", isOn: $onlyReview)
                        .labelsHidden()
                        .tint(Palette.gold)
                }
            }
            .padding(16)
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: "\(filtered.count) Question\(filtered.count == 1 ? "" : "s")", color: Palette.gold)
                GoldRule()
            }
            .padding(.horizontal, 4)

            if filtered.isEmpty {
                PaperCard {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(Palette.inkSubtle)
                        Text("No questions match these filters")
                            .font(.subheadline)
                            .foregroundStyle(Palette.inkMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                PaperCard {
                    VStack(spacing: 0) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, q in
                            NavigationLink(value: q) {
                                QuestionRowLabel(question: q)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 13)
                            }
                            .buttonStyle(.plain)
                            if idx < filtered.count - 1 {
                                Rectangle().fill(Palette.rule).frame(height: 0.75).padding(.leading, 36)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct QuestionRowLabel: View {
    @EnvironmentObject private var progress: ProgressStore
    let question: Question

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            statusGlyph
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 6) {
                Text(question.question)
                    .font(.body)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(3)
                HStack(spacing: 6) {
                    Text(question.category)
                        .font(.eyebrow(10, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(Palette.inkMuted)
                    if let d = question.difficulty {
                        DifficultyTag(difficulty: d)
                    }
                    Spacer()
                    Text("Q\(question.n)")
                        .font(.figure(10, weight: .medium))
                        .foregroundStyle(Palette.inkSubtle)
                }
            }
        }
    }

    @ViewBuilder private var statusGlyph: some View {
        switch progress.status(for: question.id) {
        case .known:
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.known)
        case .review:
            Image(systemName: "bookmark.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.review)
        case .none:
            Image(systemName: "circle.dotted")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.inkSubtle)
        }
    }
}
