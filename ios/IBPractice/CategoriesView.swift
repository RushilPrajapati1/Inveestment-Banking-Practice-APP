import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var progress: ProgressStore
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        QuestionListView(
                            title: "All questions",
                            questions: dataStore.allQuestions
                        )
                    } label: {
                        HStack {
                            Label("All questions", systemImage: "tray.full")
                            Spacer()
                            Text("\(dataStore.allQuestions.count)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }

                    NavigationLink {
                        QuestionListView(
                            title: "Review",
                            questions: dataStore.allQuestions.filter { progress.status(for: $0.id) == .review }
                        )
                    } label: {
                        HStack {
                            Label("Review", systemImage: "arrow.uturn.left.circle")
                            Spacer()
                            Text("\(progress.reviewCount)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }

                ForEach(dataStore.groups) { group in
                    Section(group.name) {
                        ForEach(group.categories) { category in
                            NavigationLink {
                                QuestionListView(
                                    title: category.label,
                                    questions: category.questions
                                )
                            } label: {
                                CategoryRow(category: category)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("400 IB Questions")
            .searchable(text: $searchText, prompt: "Search questions")
            .overlay {
                if !searchText.isEmpty {
                    SearchResultsView(query: searchText)
                        .background(Color(.systemBackground))
                }
            }
        }
    }
}

private struct CategoryRow: View {
    @EnvironmentObject private var progress: ProgressStore
    let category: Category

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.body)
                if let d = category.difficulty {
                    DifficultyTag(difficulty: d)
                }
            }
            Spacer()
            Text("\(progress.knownCount(in: category))/\(category.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}

private struct SearchResultsView: View {
    @EnvironmentObject private var dataStore: DataStore
    let query: String

    private var results: [Question] {
        let q = query.lowercased()
        return dataStore.allQuestions.filter {
            $0.question.lowercased().contains(q) || $0.answer.lowercased().contains(q)
        }
    }

    var body: some View {
        Group {
            if results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List(results) { question in
                    NavigationLink(value: question) {
                        QuestionRowLabel(question: question)
                    }
                }
                .navigationDestination(for: Question.self) { q in
                    QuestionDetailView(question: q)
                }
            }
        }
    }
}

struct DifficultyTag: View {
    let difficulty: Difficulty

    var body: some View {
        Text(difficulty.rawValue.uppercased())
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(Capsule())
    }

    private var background: Color {
        switch difficulty {
        case .basic: return Color.green.opacity(0.15)
        case .advanced: return Color.orange.opacity(0.18)
        }
    }
    private var foreground: Color {
        switch difficulty {
        case .basic: return .green
        case .advanced: return .orange
        }
    }
}
