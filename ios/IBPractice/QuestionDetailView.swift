import SwiftUI

struct QuestionDetailView: View {
    @EnvironmentObject private var progress: ProgressStore
    let question: Question

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard

                answerCard

                Spacer(minLength: 100)
            }
            .padding(16)
        }
        .canvasBackground()
        .navigationTitle("Question \(question.n)")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
    }

    private var headerCard: some View {
        PaperCard(cornerRadius: Theme.radiusCard, elevated: true) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: Theme.iconName(forGroup: question.group))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Palette.gold)
                    Eyebrow(text: question.category, color: Palette.gold)
                    Spacer()
                    Text("Q\(question.n)")
                        .font(.figure(11, weight: .semibold))
                        .foregroundStyle(Palette.inkSubtle)
                    if let d = question.difficulty {
                        DifficultyTag(difficulty: d)
                    }
                }

                GoldRule()

                Text(question.question)
                    .font(.display(22, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            .padding(20)
        }
    }

    private var answerCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Eyebrow(text: "Answer", color: Palette.gold)
                    GoldRule()
                }
                AnswerView(text: question.answer)
            }
            .padding(20)
        }
    }

    private var actionBar: some View {
        let status = progress.status(for: question.id)
        return VStack(spacing: 0) {
            Rectangle().fill(Palette.rule).frame(height: 0.75)
            HStack(spacing: 10) {
                actionButton(
                    title: "Review",
                    icon: "bookmark",
                    isActive: status == .review,
                    activeColor: Palette.review
                ) {
                    Theme.triggerHaptic(.light)
                    progress.toggle(question.id, .review)
                }

                actionButton(
                    title: "Known",
                    icon: "checkmark",
                    isActive: status == .known,
                    activeColor: Palette.known
                ) {
                    if status != .known { Theme.triggerSuccessHaptic() }
                    else { Theme.triggerHaptic(.light) }
                    progress.toggle(question.id, .known)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(Palette.bar)
        }
    }

    @ViewBuilder
    private func actionButton(
        title: String,
        icon: String,
        isActive: Bool,
        activeColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isActive ? "\(icon).fill" : icon)
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .foregroundStyle(isActive ? Color(.systemBackground) : Palette.ink)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isActive ? activeColor : Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isActive ? activeColor : Palette.rule, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
