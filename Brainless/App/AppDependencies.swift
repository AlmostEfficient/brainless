import Foundation
import SwiftUI

struct AppDependencies {
    let appStateStore: AppStateStore
    let backendBaseURL: URL
}

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue = AppDependencies(
        appStateStore: AppStateStore(),
        backendBaseURL: URL(string: "https://nexus.raza.run/v1")!
    )
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}

