//
//  CommanderScorekeeperApp.swift
//  CommanderScorekeeper
//
//  Main application entry point.
//  Configures Core Data and app-level dependencies.
//

import SwiftUI

@main
struct CommanderScorekeeperApp: App {

    // MARK: - Properties

    /// Core Data persistence controller
    let persistenceController = PersistenceController.shared

    /// Commander database
    let commanderDatabase = CommanderDatabase.shared

    // MARK: - Initialization

    init() {
        // Configure app appearance
        configureAppearance()

        // Prepare haptic feedback generators
        HapticManager.shared.prepareGenerators()

        #if DEBUG
        print("🚀 Commander Scorekeeper launched")
        print("📊 Loaded \(commanderDatabase.commanders.count) commanders")
        #endif
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(commanderDatabase)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Cleanup old sessions on app launch
                    persistenceController.cleanupOldSessions(keepLast: 100)
                }
        }
    }

    // MARK: - Configuration

    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Constants.Colors.backgroundSecondary)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Constants.Colors.textPrimary)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Constants.Colors.textPrimary)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        // Configure tab bar appearance (if needed in future)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Constants.Colors.backgroundSecondary)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Configure list appearance
        UITableView.appearance().backgroundColor = UIColor(Constants.Colors.backgroundPrimary)
        UITableView.appearance().separatorColor = UIColor(Constants.Colors.backgroundPrimary)
    }
}
