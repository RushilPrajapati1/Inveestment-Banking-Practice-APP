import SwiftUI

@main
struct IBPracticeApp: App {
    @StateObject private var dataStore = DataStore()
    @StateObject private var progressStore = ProgressStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataStore)
                .environmentObject(progressStore)
        }
    }
}
