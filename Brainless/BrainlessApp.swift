//
//  BrainlessApp.swift
//  Brainless
//
//  Created by Abdullah Raza on 29/04/2026.
//

import SwiftUI
import SwiftData

@main
struct BrainlessApp: App {
    private let container: AppContainer

    init() {
        container = AppContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appDependencies, container.dependencies)
        }
        .modelContainer(container.modelContainer)
    }
}

extension BrainlessApp {
    nonisolated static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            AppSettingsRecord.self,
            UserProfileRecord.self,
            TrainingPreferencesRecord.self,
            EquipmentProfileRecord.self,
            WorkoutSessionRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
