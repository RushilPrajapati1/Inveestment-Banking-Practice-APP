import Foundation

enum Difficulty: String, Codable, CaseIterable, Hashable {
    case basic = "Basic"
    case advanced = "Advanced"
}

struct Question: Codable, Identifiable, Hashable {
    let id: String
    let n: Int
    let category: String
    let group: String
    let difficulty: Difficulty?
    let question: String
    let answer: String
}

struct Category: Codable, Identifiable, Hashable {
    let name: String
    let group: String
    let difficulty: Difficulty?
    let slug: String
    let count: Int
    let questions: [Question]
    var id: String { slug }

    var label: String {
        if let d = difficulty { return "\(name) — \(d.rawValue)" }
        return name
    }
}

struct CategoryGroup: Identifiable, Hashable {
    let name: String
    let categories: [Category]
    var id: String { name }
    var totalCount: Int { categories.reduce(0) { $0 + $1.count } }
}

struct Dataset: Codable {
    let categories: [Category]
}

enum ProgressStatus: String, Codable {
    case known
    case review
}
