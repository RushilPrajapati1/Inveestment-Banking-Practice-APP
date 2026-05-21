import SwiftUI

struct QuestionDetailView: View {
    @EnvironmentObject private var progress: ProgressStore
    let question: Question

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(question.category)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        if let d = question.difficulty {
                            DifficultyTag(difficulty: d)
                        }
                    }
                    Text(question.question)
                        .font(.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                AnswerView(text: question.answer)

                Spacer(minLength: 60)
            }
            .padding()
        }
        .navigationTitle("Question \(question.n)")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button {
                    progress.toggle(question.id, .review)
                } label: {
                    Label("Review", systemImage: "arrow.uturn.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(progress.status(for: question.id) == .review ? .orange : .gray)

                Button {
                    progress.toggle(question.id, .known)
                } label: {
                    Label("Known", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(progress.status(for: question.id) == .known ? .green : .accentColor)
            }
            .padding()
            .background(.bar)
        }
    }
}
