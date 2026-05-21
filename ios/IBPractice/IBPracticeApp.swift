import SwiftUI
import UIKit

@main
struct IBPracticeApp: App {
    @StateObject private var dataStore = DataStore()
    @StateObject private var progressStore = ProgressStore()

    init() {
        configureNavBarAppearance()
        configureTabBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataStore)
                .environmentObject(progressStore)
                .tint(Palette.gold)
        }
    }

    private func configureNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: 0x0A1426)
                : UIColor(hex: 0xEFECE5)
        }
        appearance.shadowColor = .clear

        let ink = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: 0xECE6D2)
                : UIColor(hex: 0x161E2E)
        }
        appearance.titleTextAttributes = [
            .foregroundColor: ink,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: ink,
            .font: UIFont(descriptor:
                UIFont.systemFont(ofSize: 34, weight: .bold)
                    .fontDescriptor
                    .withDesign(.serif) ?? UIFont.systemFont(ofSize: 34, weight: .bold).fontDescriptor,
                size: 34)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: 0x0F1B30)
                : UIColor(hex: 0xE8E2D2)
        }
        appearance.shadowColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.08)
                : UIColor(hex: 0xD9CFB7)
        }

        let gold = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: 0xD4AC4B)
                : UIColor(hex: 0x8E6B1F)
        }
        let muted = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: 0x8DA0BF)
                : UIColor(hex: 0x8B826C)
        }

        for item in [appearance.stackedLayoutAppearance,
                     appearance.inlineLayoutAppearance,
                     appearance.compactInlineLayoutAppearance] {
            item.selected.iconColor = gold
            item.selected.titleTextAttributes = [
                .foregroundColor: gold,
                .font: UIFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
            ]
            item.normal.iconColor = muted
            item.normal.titleTextAttributes = [
                .foregroundColor: muted,
                .font: UIFont.monospacedSystemFont(ofSize: 10, weight: .medium)
            ]
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
