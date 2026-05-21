import SwiftUI

struct FlashcardsRootView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var selectedSlug: String? = nil
    @State private var difficultyFilter: QuestionListView.DifficultyFilter = .all
    @State private var onlyReview = false

    var body: some View {
        NavigationStack {
            FlashcardsView(
                selectedSlug: $selectedSlug,
                difficultyFilter: $difficultyFilter,
                onlyReview: $onlyReview
            )
            .navigationTitle("Flashcards")
        }
    }
}

struct FlashcardsView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var progress: ProgressStore

    @Binding var selectedSlug: String?
    @Binding var difficultyFilter: QuestionListView.DifficultyFilter
    @Binding var onlyReview: Bool

    @State private var order: [Int] = []
    @State private var pos: Int = 0
    @State private var flipped: Bool = false
    @State private var lastSignature: String = ""

    private var deck: [Question] {
        let base: [Question]
        if let slug = selectedSlug, let cat = dataStore.category(slug: slug) {
            base = cat.questions
        } else {
            base = dataStore.allQuestions
        }
        return base.filter { item in
            if onlyReview, progress.status(for: item.id) != .review { return false }
            switch difficultyFilter {
            case .all: return true
            case .basic: return item.difficulty == .basic
            case .advanced: return item.difficulty == .advanced
            }
        }
    }

    private var signature: String {
        deck.map(\.id).joined(separator: "|")
    }

    var body: some View {
        VStack(spacing: 12) {
            controls

            if deck.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No flashcards",
                    systemImage: "rectangle.stack",
                    description: Text("Adjust filters to build a deck.")
                )
                Spacer()
            } else {
                cardSection
                actions
            }
        }
        .padding(.horizontal)
        .onChange(of: signature, initial: true) { _, new in
            if new != lastSignature {
                lastSignature = new
                rebuild()
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Menu {
                Button("All categories") { selectedSlug = nil }
                Divider()
                ForEach(dataStore.groups) { group in
                    Section(group.name) {
                        ForEach(group.categories) { cat in
                            Button(cat.label) { selectedSlug = cat.slug }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategoryLabel)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }

            Picker("Difficulty", selection: $difficultyFilter) {
                ForEach(QuestionListView.DifficultyFilter.allCases) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Review only", isOn: $onlyReview)
                .font(.subheadline)
        }
        .padding(.top, 4)
    }

    private var selectedCategoryLabel: String {
        if let slug = selectedSlug, let cat = dataStore.category(slug: slug) {
            return cat.label
        }
        return "All categories"
    }

    private var cardSection: some View {
        let idx = order.indices.contains(pos) ? order[pos] : 0
        let q = deck.indices.contains(idx) ? deck[idx] : deck[0]
        let status = progress.status(for: q.id)

        return VStack(spacing: 8) {
            HStack {
                Text("\(pos + 1) / \(order.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    shuffle()
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                        .font(.subheadline)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(borderColor(for: status), lineWidth: 1.5)
                    )

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(q.category)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        if let d = q.difficulty {
                            DifficultyTag(difficulty: d)
                        }
                        Spacer()
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            if !flipped {
                                Text(q.question)
                                    .font(.title3.weight(.semibold))
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 8)
                                Text("Tap to reveal answer")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                AnswerView(text: q.answer)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(18)
            }
            .frame(maxWidth: .infinity, minHeight: 320, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.18)) { flipped.toggle() }
            }
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.width < -40 { go(1) }
                        else if value.translation.width > 40 { go(-1) }
                    }
            )
        }
    }

    private var actions: some View {
        let idx = order.indices.contains(pos) ? order[pos] : 0
        let q = deck.indices.contains(idx) ? deck[idx] : deck[0]
        let status = progress.status(for: q.id)

        return HStack(spacing: 8) {
            Button {
                go(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(pos == 0)

            Button {
                mark(.review, for: q.id, currentStatus: status)
            } label: {
                Label("Review", systemImage: "arrow.uturn.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(status == .review ? .orange : .gray)

            Button {
                mark(.known, for: q.id, currentStatus: status)
            } label: {
                Label("Known", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(status == .known ? .green : .accentColor)

            Button {
                go(1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(pos >= order.count - 1)
        }
        .padding(.bottom, 8)
    }

    private func borderColor(for status: ProgressStatus?) -> Color {
        switch status {
        case .known: return .green.opacity(0.6)
        case .review: return .orange.opacity(0.6)
        case .none: return .gray.opacity(0.25)
        }
    }

    private func rebuild() {
        order = Array(deck.indices)
        pos = 0
        flipped = false
    }

    private func go(_ delta: Int) {
        flipped = false
        pos = max(0, min(order.count - 1, pos + delta))
    }

    private func shuffle() {
        order.shuffle()
        pos = 0
        flipped = false
    }

    private func mark(_ status: ProgressStatus, for id: String, currentStatus: ProgressStatus?) {
        progress.setStatus(id, currentStatus == status ? nil : status)
        if pos < order.count - 1 { go(1) }
    }
}
