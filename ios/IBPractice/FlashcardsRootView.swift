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
            .canvasBackground()
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
    @State private var dragOffset: CGSize = .zero
    @State private var isCommitting: Bool = false

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
        VStack(spacing: 14) {
            controls
                .padding(.horizontal, 16)

            if deck.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                deckSection
                actions
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .padding(.top, 4)
        .onChange(of: signature, initial: true) { _, new in
            if new != lastSignature {
                lastSignature = new
                rebuild()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Palette.inkSubtle)
            Text("Empty deck")
                .font(.display(20, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Text("Adjust filters to build a deck.")
                .font(.subheadline)
                .foregroundStyle(Palette.inkMuted)
        }
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 10) {
            Menu {
                Button { selectedSlug = nil } label: {
                    Label("All categories", systemImage: "tray.full")
                }
                Divider()
                ForEach(dataStore.groups) { group in
                    Section(group.name) {
                        ForEach(group.categories) { cat in
                            Button(cat.label) { selectedSlug = cat.slug }
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: Theme.iconName(forGroup: selectedGroupName))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.gold)
                    Eyebrow(text: "Deck", color: Palette.gold)
                    Text(selectedCategoryLabel)
                        .foregroundStyle(Palette.ink)
                        .font(.body)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.inkSubtle)
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radiusControl, style: .continuous)
                        .fill(Palette.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusControl, style: .continuous)
                        .stroke(Palette.rule, lineWidth: 0.75)
                )
            }

            HStack(spacing: 10) {
                Picker("Difficulty", selection: $difficultyFilter) {
                    ForEach(QuestionListView.DifficultyFilter.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)

                Button {
                    Theme.triggerSelectionHaptic()
                    onlyReview.toggle()
                } label: {
                    Image(systemName: onlyReview ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .foregroundStyle(onlyReview ? Color(.systemBackground) : Palette.review)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(onlyReview ? Palette.review : Palette.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Palette.review.opacity(0.6), lineWidth: 0.75)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var selectedCategoryLabel: String {
        if let slug = selectedSlug, let cat = dataStore.category(slug: slug) {
            return cat.label
        }
        return "All categories"
    }

    private var selectedGroupName: String {
        if let slug = selectedSlug, let cat = dataStore.category(slug: slug) {
            return cat.group
        }
        return ""
    }

    // MARK: Deck

    private var deckSection: some View {
        let idx = order.indices.contains(pos) ? order[pos] : 0
        let q = deck.indices.contains(idx) ? deck[idx] : deck[0]
        let status = progress.status(for: q.id)
        let rotation = Double(dragOffset.width / 22)

        return VStack(spacing: 12) {
            HStack {
                Text("\(pos + 1)")
                    .font(.display(20, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Text("/ \(order.count)")
                    .font(.figure(13, weight: .medium))
                    .foregroundStyle(Palette.inkMuted)
                Spacer()
                Button {
                    Theme.triggerHaptic(.light)
                    shuffle()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "shuffle")
                        Text("Shuffle")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.gold)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            ZStack {
                if pos < order.count - 1 {
                    cardBase(status: nil)
                        .scaleEffect(0.95)
                        .offset(y: 8)
                        .opacity(0.5)
                }

                cardContent(question: q, status: status)
                    .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    .offset(x: dragOffset.width, y: dragOffset.height * 0.1)
                    .rotationEffect(.degrees(rotation))
                    .overlay(
                        swipeOverlay
                            .opacity(min(abs(dragOffset.width) / 120, 1))
                            .allowsHitTesting(false)
                    )
                    .gesture(swipeGesture)
                    .onTapGesture {
                        Theme.triggerSelectionHaptic()
                        withAnimation(.easeInOut(duration: 0.45)) {
                            flipped.toggle()
                        }
                    }
            }
            .padding(.horizontal, 16)
        }
    }

    private func cardBase(status: ProgressStatus?) -> some View {
        RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
            .fill(Palette.card)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                    .stroke(borderColor(for: status), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, minHeight: 380, maxHeight: 460)
    }

    @ViewBuilder
    private func cardContent(question q: Question, status: ProgressStatus?) -> some View {
        ZStack {
            cardBase(status: status)

            cardFace(question: q, isBack: false)
                .opacity(flipped ? 0 : 1)
                .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            cardFace(question: q, isBack: true)
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(flipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity, minHeight: 380, maxHeight: 460)
    }

    @ViewBuilder
    private func cardFace(question q: Question, isBack: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: Theme.iconName(forGroup: q.group))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.gold)
                Eyebrow(text: q.category, color: Palette.gold)
                Spacer()
                if let d = q.difficulty {
                    DifficultyTag(difficulty: d)
                }
            }

            GoldRule()

            if isBack {
                ScrollView {
                    AnswerView(text: q.answer)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text(q.question)
                        .font(.display(22, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap")
                            .font(.footnote)
                        Text("TAP TO REVEAL")
                            .font(.eyebrow(10, weight: .semibold))
                            .tracking(1.4)
                    }
                    .foregroundStyle(Palette.inkSubtle)
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var swipeOverlay: some View {
        let leftThreshold = dragOffset.width < -20
        let rightThreshold = dragOffset.width > 20
        if leftThreshold || rightThreshold {
            HStack {
                if rightThreshold {
                    badge(text: "Prev", icon: "chevron.left")
                    Spacer()
                } else if leftThreshold {
                    Spacer()
                    badge(text: "Next", icon: "chevron.right")
                }
            }
            .padding(24)
        }
    }

    private func badge(text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
            Text(text.uppercased())
        }
        .font(.eyebrow(10, weight: .semibold))
        .tracking(1.0)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(Palette.gold)
        .background(Palette.goldSoft)
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Palette.gold.opacity(0.5), lineWidth: 0.75)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if isCommitting { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                let dx = value.translation.width
                let threshold: CGFloat = 90
                if dx < -threshold, pos < order.count - 1 {
                    commit(direction: -1)
                } else if dx > threshold, pos > 0 {
                    commit(direction: 1)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    private func commit(direction: Int) {
        isCommitting = true
        Theme.triggerHaptic(.light)
        let exitX: CGFloat = direction < 0 ? -500 : 500
        withAnimation(.easeOut(duration: 0.22)) {
            dragOffset = CGSize(width: exitX, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            flipped = false
            if direction < 0 {
                pos = min(order.count - 1, pos + 1)
            } else {
                pos = max(0, pos - 1)
            }
            dragOffset = CGSize(width: -exitX, height: 0)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                dragOffset = .zero
            }
            isCommitting = false
        }
    }

    // MARK: Actions

    private var actions: some View {
        let idx = order.indices.contains(pos) ? order[pos] : 0
        let q = deck.indices.contains(idx) ? deck[idx] : deck[0]
        let status = progress.status(for: q.id)

        return HStack(spacing: 8) {
            iconButton(icon: "chevron.left", enabled: pos > 0) {
                commit(direction: 1)
            }

            statusButton(
                title: "Review",
                icon: "bookmark",
                isActive: status == .review,
                color: Palette.review
            ) {
                Theme.triggerHaptic(.light)
                mark(.review, for: q.id, currentStatus: status)
            }

            statusButton(
                title: "Known",
                icon: "checkmark",
                isActive: status == .known,
                color: Palette.known
            ) {
                if status != .known { Theme.triggerSuccessHaptic() } else { Theme.triggerHaptic(.light) }
                mark(.known, for: q.id, currentStatus: status)
            }

            iconButton(icon: "chevron.right", enabled: pos < order.count - 1) {
                commit(direction: -1)
            }
        }
    }

    @ViewBuilder
    private func iconButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .frame(width: 48, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Palette.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Palette.rule, lineWidth: 0.75)
                )
                .foregroundStyle(enabled ? Palette.ink : Palette.inkSubtle.opacity(0.5))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    @ViewBuilder
    private func statusButton(
        title: String,
        icon: String,
        isActive: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isActive ? "\(icon).fill" : icon)
                    .font(.subheadline.weight(.semibold))
                Text(title).font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .foregroundStyle(isActive ? Color(.systemBackground) : Palette.ink)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isActive ? color : Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isActive ? color : Palette.rule, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func borderColor(for status: ProgressStatus?) -> Color {
        switch status {
        case .known: return Palette.known.opacity(0.55)
        case .review: return Palette.review.opacity(0.55)
        case .none: return Palette.ruleStrong
        }
    }

    // MARK: Logic

    private func rebuild() {
        order = Array(deck.indices)
        pos = 0
        flipped = false
        dragOffset = .zero
    }

    private func shuffle() {
        order.shuffle()
        pos = 0
        flipped = false
        withAnimation(.spring()) { dragOffset = .zero }
    }

    private func mark(_ status: ProgressStatus, for id: String, currentStatus: ProgressStatus?) {
        progress.setStatus(id, currentStatus == status ? nil : status)
        if pos < order.count - 1 {
            commit(direction: -1)
        }
    }
}
