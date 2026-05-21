import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var progress: ProgressStore
    @State private var confirmReset = false

    private var total: Int { dataStore.allQuestions.count }
    private var pct: Int { total == 0 ? 0 : Int(round(Double(progress.knownCount) / Double(total) * 100)) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("\(progress.knownCount) known")
                                .font(.headline)
                            Spacer()
                            Text("\(pct)%")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: Double(progress.knownCount), total: Double(max(total, 1)))
                        HStack(spacing: 16) {
                            Stat(label: "Known", value: progress.knownCount, tint: .green)
                            Stat(label: "Review", value: progress.reviewCount, tint: .orange)
                            Stat(label: "Total", value: total, tint: .secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Categories") {
                    ForEach(dataStore.groups) { group in
                        DisclosureGroup(group.name) {
                            ForEach(group.categories) { cat in
                                CategoryProgressRow(category: cat)
                            }
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        Label("Reset progress", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Progress")
            .confirmationDialog(
                "Reset all progress?",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) { progress.reset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears Known and Review markers on every question.")
            }
        }
    }
}

private struct Stat: View {
    let label: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(tint)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CategoryProgressRow: View {
    @EnvironmentObject private var progress: ProgressStore
    let category: Category

    var body: some View {
        let known = progress.knownCount(in: category)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category.name).font(.subheadline)
                if let d = category.difficulty {
                    DifficultyTag(difficulty: d)
                }
                Spacer()
                Text("\(known)/\(category.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(known), total: Double(max(category.count, 1)))
        }
        .padding(.vertical, 4)
    }
}
