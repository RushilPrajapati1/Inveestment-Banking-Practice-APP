import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            CategoriesView()
                .tabItem {
                    Label("Browse", systemImage: "list.bullet.rectangle")
                }

            FlashcardsRootView()
                .tabItem {
                    Label("Flashcards", systemImage: "rectangle.stack")
                }

            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(DataStore())
        .environmentObject(ProgressStore())
}
