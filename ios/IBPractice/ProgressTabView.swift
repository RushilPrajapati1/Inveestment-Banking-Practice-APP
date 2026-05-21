import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var progress: ProgressStore
    @State private var confirmReset = false

    private var total: Int { dataStore.allQuestions.count }
    private var pct: Double { total == 0 ? 0 : Double(progress.knownCount) / Double(total) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    heroCard
                        .padding(.horizontal, 16)

                    statRow
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Eyebrow(text: "By section", color: Palette.gold)
                            GoldRule()
                        }
                        .padding(.horizontal, 4)

                        ForEach(dataStore.groups) { group in
                            GroupProgressBlock(group: group)
                        }
                    }
                    .padding(.horizontal, 16)

                    resetButton
                        .padding(.horizontal, 16)

                    Spacer(minLength: 24)
                }
                .padding(.vertical, 12)
            }
            .canvasBackground()
            .navigationTitle("Progress")
            .confirmationDialog(
                "Reset all progress?",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    Theme.triggerSuccessHaptic()
                    progress.reset()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears Known and Review markers on every question.")
            }
        }
    }

    private var heroCard: some View {
        PaperCard(cornerRadius: Theme.radiusHero, elevated: true) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Eyebrow(text: "06 · Progress", color: Palette.gold)
                    Spacer()
                    Eyebrow(text: "Lifetime")
                }

                HStack(alignment: .center, spacing: 22) {
                    ZStack {
                        ProgressRing(progress: pct, lineWidth: 12, trackColor: Palette.rule, color: Palette.gold)
                        VStack(spacing: -4) {
                            Text("\(Int(round(pct * 100)))")
                                .font(.display(44, weight: .semibold))
                                .foregroundStyle(Palette.ink)
                                .monospacedDigit()
                            Text("PERCENT")
                                .font(.eyebrow(9, weight: .semibold))
                                .tracking(1.6)
                                .foregroundStyle(Palette.inkMuted)
                        }
                    }
                    .frame(width: 132, height: 132)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mastery")
                            .font(.display(28, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .kerning(-0.4)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(progress.knownCount)")
                                .font(.display(22, weight: .semibold))
                                .foregroundStyle(Palette.ink)
                            Text("/ \(total)")
                                .font(.figure(15, weight: .medium))
                                .foregroundStyle(Palette.inkMuted)
                        }
                        Text("questions known")
                            .font(.caption)
                            .foregroundStyle(Palette.inkMuted)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(20)
        }
    }

    private var statRow: some View {
        HStack(spacing: 10) {
            StatTile(label: "Known", value: progress.knownCount, color: Palette.known, icon: "checkmark.seal.fill")
            StatTile(label: "Review", value: progress.reviewCount, color: Palette.review, icon: "bookmark.fill")
            StatTile(
                label: "Unseen",
                value: max(0, total - progress.knownCount - progress.reviewCount),
                color: Palette.inkMuted,
                icon: "circle.dotted"
            )
        }
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            Theme.triggerHaptic(.medium)
            confirmReset = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                Text("Reset progress")
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(Palette.review)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                    .fill(Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                    .stroke(Palette.review.opacity(0.4), lineWidth: 0.75)
            )
        }
    }
}

private struct StatTile: View {
    let label: String
    let value: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Eyebrow(text: label)
            }
            Text("\(value)")
                .font(.display(28, weight: .semibold))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                .fill(Palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                .stroke(Palette.rule, lineWidth: 0.75)
        )
    }
}

private struct GroupProgressBlock: View {
    @EnvironmentObject private var progress: ProgressStore
    let group: CategoryGroup
    @State private var expanded: Bool = true

    private var totalKnown: Int {
        group.categories.reduce(0) { $0 + progress.knownCount(in: $1) }
    }

    var body: some View {
        PaperCard {
            VStack(spacing: 0) {
                Button {
                    Theme.triggerSelectionHaptic()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        expanded.toggle()
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Palette.gold.opacity(0.4), lineWidth: 0.75)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Palette.goldSoft)
                                )
                                .frame(width: 36, height: 36)
                            Image(systemName: Theme.iconName(forGroup: group.name))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Palette.gold)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(group.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Palette.ink)
                            HStack(spacing: 4) {
                                Text("\(totalKnown)")
                                    .font(.figure(12, weight: .semibold))
                                    .foregroundStyle(Palette.known)
                                Text("/ \(group.totalCount) known")
                                    .font(.figure(12, weight: .medium))
                                    .foregroundStyle(Palette.inkMuted)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.inkSubtle)
                            .rotationEffect(.degrees(expanded ? 0 : -90))
                    }
                    .padding(16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if expanded {
                    Rectangle().fill(Palette.rule).frame(height: 0.75)
                    VStack(spacing: 14) {
                        ForEach(group.categories) { cat in
                            CategoryProgressRow(category: cat)
                        }
                    }
                    .padding(16)
                    .transition(.opacity)
                }
            }
        }
    }
}

private struct CategoryProgressRow: View {
    @EnvironmentObject private var progress: ProgressStore
    let category: Category

    var body: some View {
        let known = progress.knownCount(in: category)
        let ratio = category.count == 0 ? 0 : Double(known) / Double(category.count)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category.name)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                if let d = category.difficulty {
                    DifficultyTag(difficulty: d)
                }
                Spacer()
                Text("\(known)/\(category.count)")
                    .font(.figure(12, weight: .medium))
                    .foregroundStyle(Palette.inkMuted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Palette.rule)
                    Capsule()
                        .fill(Palette.gold)
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 4)
        }
    }
}
