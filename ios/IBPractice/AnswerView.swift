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
                bullets.append(String(block.dropFirst(2)))
            } else {
                flushBullets()
                out.append(Block(kind: .paragraph(block)))
            }
        }
        flushBullets()
        return out
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(blocks) { block in
                switch block.kind {
                case .paragraph(let text):
                    Text(text)
                        .font(.body)
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                case .bullets(let items):
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Rectangle()
                                    .fill(Palette.gold)
                                    .frame(width: 8, height: 1)
                                    .offset(y: -5)
                                Text(item)
                                    .font(.body)
                                    .foregroundStyle(Palette.ink)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }
}
