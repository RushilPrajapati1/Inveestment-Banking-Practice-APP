import SwiftUI

struct AnswerView: View {
    let text: String

    private struct Block: Identifiable {
        enum Kind { case paragraph(String); case bullets([String]) }
        let id = UUID()
        let kind: Kind
    }

    private var blocks: [Block] {
        let raw = text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var out: [Block] = []
        var bullets: [String] = []

        func flushBullets() {
            if !bullets.isEmpty {
                out.append(Block(kind: .bullets(bullets)))
                bullets = []
            }
        }

        for block in raw {
            if block.hasPrefix("- ") {
                let item = String(block.dropFirst(2))
                bullets.append(item)
            } else {
                flushBullets()
                out.append(Block(kind: .paragraph(block)))
            }
        }
        flushBullets()
        return out
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(blocks) { block in
                switch block.kind {
                case .paragraph(let text):
                    Text(text)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                case .bullets(let items):
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("•").foregroundStyle(.secondary)
                                Text(item)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }
}
