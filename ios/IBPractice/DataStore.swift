import Foundation

@MainActor
final class DataStore: ObservableObject {
    @Published private(set) var categories: [Category] = []
    @Published private(set) var groups: [CategoryGroup] = []
    @Published private(set) var allQuestions: [Question] = []

    init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            assertionFailure("questions.json missing from bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let dataset = try JSONDecoder().decode(Dataset.self, from: data)
            self.categories = dataset.categories
            self.allQuestions = dataset.categories.flatMap { $0.questions }
            self.groups = Self.makeGroups(from: dataset.categories)
        } catch {
            assertionFailure("failed to decode questions.json: \(error)")
        }
    }

    private static func makeGroups(from categories: [Category]) -> [CategoryGroup] {
        var order: [String] = []
        var buckets: [String: [Category]] = [:]
        for c in categories {
            if buckets[c.group] == nil {
                buckets[c.group] = []
                order.append(c.group)
            }
            buckets[c.group]?.append(c)
        }
        return order.map { name in
            CategoryGroup(name: name, categories: buckets[name] ?? [])
        }
    }

    func category(slug: String) -> Category? {
        categories.first { $0.slug == slug }
    }
}
