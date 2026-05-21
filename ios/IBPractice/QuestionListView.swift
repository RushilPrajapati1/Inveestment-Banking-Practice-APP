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
        List {
            Section {
                Picker("Difficulty", selection: $difficultyFilter) {
                    ForEach(DifficultyFilter.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                Toggle("Review only", isOn: $onlyReview)
            }

            Section {
                ForEach(filtered) { q in
                    NavigationLink(value: q) {
                        QuestionRowLabel(question: q)
                    }
                }
            } header: {
                Text("\(filtered.count) question\(filtered.count == 1 ? "" : "s")")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search")
        .navigationDestination(for: Question.self) { q in
            QuestionDetailView(question: q)
        }
    }
}

struct QuestionRowLabel: View {
    @EnvironmentObject private var progress: ProgressStore
    let question: Question

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            statusDot
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(question.question)
                    .font(.body)
                    .lineLimit(3)
                HStack(spacing: 6) {
                    Text(question.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let d = question.difficulty {
                        DifficultyTag(difficulty: d)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder private var statusDot: some View {
        switch progress.status(for: question.id) {
        case .known:
            Circle().fill(Color.green).frame(width: 8, height: 8)
        case .review:
            Circle().fill(Color.orange).frame(width: 8, height: 8)
        case .none:
            Circle().stroke(Color.secondary.opacity(0.4)).frame(width: 8, height: 8)
        }
    }
}
