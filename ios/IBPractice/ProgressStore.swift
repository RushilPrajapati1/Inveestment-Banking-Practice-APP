import Foundation
import SwiftUI

@MainActor
final class ProgressStore: ObservableObject {
    private static let storageKey = "ib.progress.v1"

    @Published private(set) var statuses: [String: ProgressStatus] = [:]

    init() {
        load()
    }

    func status(for id: String) -> ProgressStatus? {
        statuses[id]
    }

    func toggle(_ id: String, _ status: ProgressStatus) {
        if statuses[id] == status {
            statuses[id] = nil
        } else {
            statuses[id] = status
        }
        persist()
    }

    func setStatus(_ id: String, _ status: ProgressStatus?) {
        if let status {
            statuses[id] = status
        } else {
            statuses[id] = nil
        }
        persist()
    }

    func reset() {
        statuses = [:]
        persist()
    }

    var knownCount: Int {
        statuses.values.filter { $0 == .known }.count
    }

    var reviewCount: Int {
        statuses.values.filter { $0 == .review }.count
    }

    func knownCount(in category: Category) -> Int {
        category.questions.reduce(0) { acc, q in
            acc + (statuses[q.id] == .known ? 1 : 0)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([String: ProgressStatus].self, from: data) {
            statuses = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(statuses) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
