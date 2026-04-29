import Foundation
import SwiftData

@MainActor
struct AppContainer {
    let modelContainer: ModelContainer
    let dependencies: AppDependencies

    init(
        modelContainer: ModelContainer = BrainlessApp.makeModelContainer(),
        backendBaseURL: URL = URL(string: "https://nexus.raza.run/v1")!
    ) {
        self.modelContainer = modelContainer
        self.dependencies = AppDependencies(
            appStateStore: AppStateStore(),
            backendBaseURL: backendBaseURL
        )
    }
}

