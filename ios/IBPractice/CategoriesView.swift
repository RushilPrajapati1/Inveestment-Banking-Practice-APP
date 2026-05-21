import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var progress: ProgressStore
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    if searchText.isEmpty {
                        HeroMasteryCard()
                            .padding(.horizontal, 16)

                        QuickAccessRow()
                            .padding(.horizontal, 16)

                        ForEach(dataStore.groups) { group in
                            GroupSection(group: group)
                                .padding(.horizontal, 16)
                        }
                    } else {
                        SearchResultsList(query: searchText)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
            .canvasBackground()
            .navigationTitle("IB Practice")
            .searchable(text: $searchText, prompt: "Search questions")
            .navigationDestination(for: Question.self) { q in
                QuestionDetailView(question: q)
            }
            .navigationDestination(for: Category.self) { c in
                QuestionListView(title: c.label, questions: c.questions)
            }
            .navigationDestination(for: AllQuestionsDestination.self) { d in
                QuestionListView(title: d.title, questions: d.questions)
            }
        }
    }
}

struct AllQuestionsDestination: Hashable {
    let title: String
    let questions: [Question]
}

// MARK: - Hero

private struct HeroMasteryCard: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var progress: ProgressStore

    private var total: Int { dataStore.allQuestions.count }
    private var pct: Double { total == 0 ? 0 : Double(progress.knownCount) / Double(total) }

    var body: some View {
        PaperCard(cornerRadius: Theme.radiusHero, elevated: true) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Eyebrow(text: "01 · Browse", color: Palette.gold)
                    Spacer()
                    Eyebrow(text: "MASTERY")
                }

                HStack(alignment: .center, spacing: 22) {
                    ZStack {
                        ProgressRing(progress: pct, lineWidth: 9, trackColor: Palette.rule, color: Palette.gold)
                        VStack(spacing: -2) {
                            Text("\(Int(round(pct * 100)))")
                                .font(.display(28, weight: .semibold))
                                .foregroundStyle(Palette.ink)
                            Text("%")
                                .font(.eyebrow(10, weight: .medium))
                                .foregroundStyle(Palette.inkMuted)
                        }
                    }
                    .frame(width: 92, height: 92)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Catalog")
                            .font(.display(32, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .kerning(-0.5)
                        Text("\(progress.knownCount) of \(total) known")
                            .font(.subheadline)
                            .foregroundStyle(Palette.inkMuted)
                    }
                    Spacer(minLength: 0)
                }

                GoldRule()

                HStack(spacing: 0) {
                    StatColumn(label: "Known",  value: progress.knownCount, color: Palette.known)
                    Divider().frame(width: 1, height: 36).overlay(Palette.rule)
                    StatColumn(label: "Review", value: progress.reviewCount, color: Palette.review)
                    Divider().frame(width: 1, height: 36).overlay(Palette.rule)
                    StatColumn(label: "Total",  value: total, color: Palette.ink)
                }
            }
            .padding(20)
        }
    }
}

private struct StatColumn: View {
    let label: String
    let value: Int
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.display(24, weight: .semibold))
                .foregroundStyle(color)
            Eyebrow(text: label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 4)
    }
}

// MARK: - Quick access

private struct QuickAccessRow: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        PaperCard {
            VStack(spacing: 0) {
                NavigationLink(value: AllQuestionsDestination(title: "All questions", questions: dataStore.allQuestions)) {
                    QuickAccessRowItem(
                        icon: "tray.full.fill",
                        tint: Palette.gold,
                        title: "All questions",
                        subtitle: "Full bank",
                        trailingNumber: dataStore.allQuestions.count
                    )
                }
                .buttonStyle(.plain)

                Rectangle().fill(Palette.rule).frame(height: 0.75).padding(.leading, 64)

                NavigationLink(value: AllQuestionsDestination(
                    title: "Review",
                    questions: dataStore.allQuestions.filter { progress.status(for: $0.id) == .review }
                )) {
                    QuickAccessRowItem(
                        icon: "arrow.uturn.left",
                        tint: Palette.review,
                        title: "Needs review",
                        subtitle: "Marked for revisit",
                        trailingNumber: progress.reviewCount
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct QuickAccessRowItem: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    let trailingNumber: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(tint.opacity(0.45), lineWidth: 0.75)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(tint.opacity(0.12))
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.medium)).foregroundStyle(Palette.ink)
                Text(subtitle).font(.caption).foregroundStyle(Palette.inkMuted)
            }

            Spacer()

            Text("\(trailingNumber)")
                .font(.figure(14, weight: .semibold))
                .foregroundStyle(Palette.inkMuted)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.inkSubtle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Group section

private struct GroupSection: View {
    let group: CategoryGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: Theme.iconName(forGroup: group.name))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.gold)
                Eyebrow(text: group.name, color: Palette.gold)
                GoldRule()
                Text("\(group.totalCount)")
                    .font(.figure(12, weight: .semibold))
                    .foregroundStyle(Palette.inkSubtle)
            }
            .padding(.horizontal, 4)

            PaperCard {
                VStack(spacing: 0) {
                    ForEach(Array(group.categories.enumerated()), id: \.element.id) { idx, category in
                        NavigationLink(value: category) {
                            CategoryCardRow(category: category)
                        }
                        .buttonStyle(.plain)
                        if idx < group.categories.count - 1 {
                            Rectangle().fill(Palette.rule).frame(height: 0.75).padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }
}

private struct CategoryCardRow: View {
    @EnvironmentObject private var progress: ProgressStore
    let category: Category

    private var known: Int { progress.knownCount(in: category) }
    private var ratio: Double { category.count == 0 ? 0 : Double(known) / Double(category.count) }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle().stroke(Palette.rule, lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: max(0.001, ratio))
                    .stroke(Palette.gold, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(round(ratio * 100)))")
                    .font(.figure(9, weight: .semibold))
                    .foregroundStyle(Palette.ink)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(category.name)
                    .font(.body)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let d = category.difficulty {
                        DifficultyTag(difficulty: d)
                    }
                    Text("\(known)/\(category.count)")
                        .font(.figure(11, weight: .medium))
                        .foregroundStyle(Palette.inkMuted)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.inkSubtle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

// MARK: - Search results

private struct SearchResultsList: View {
    @EnvironmentObject private var dataStore: DataStore
    let query: String

    private var results: [Question] {
        let q = query.lowercased()
        return dataStore.allQuestions.filter {
            $0.question.lowercased().contains(q) || $0.answer.lowercased().contains(q)
        }
    }

    var body: some View {
        if results.isEmpty {
            VStack(spacing: 14) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Palette.inkSubtle)
                Text("No matches for")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkMuted)
                Text("“\(query)”")
                    .font(.display(20, weight: .semibold))
                    .foregroundStyle(Palette.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Eyebrow(text: "Results", color: Palette.gold)
                    GoldRule()
                    Text("\(results.count)")
                        .font(.figure(12, weight: .semibold))
                        .foregroundStyle(Palette.inkSubtle)
                }
                .padding(.horizontal, 4)

                PaperCard {
                    VStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { idx, q in
                            NavigationLink(value: q) {
                                QuestionRowLabel(question: q)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            if idx < results.count - 1 {
                                Rectangle().fill(Palette.rule).frame(height: 0.75).padding(.leading, 36)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Difficulty tag

struct DifficultyTag: View {
    let difficulty: Difficulty

    var body: some View {
        Text(difficulty.rawValue.uppercased())
            .font(.eyebrow(9, weight: .bold))
            .tracking(0.8)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(background)
            .foregroundStyle(foreground)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(foreground.opacity(0.35), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var background: Color {
        switch difficulty {
        case .basic: return Palette.knownSoft
        case .advanced: return Palette.reviewSoft
        }
    }
    private var foreground: Color {
        switch difficulty {
        case .basic: return Palette.known
        case .advanced: return Palette.review
        }
    }
}
