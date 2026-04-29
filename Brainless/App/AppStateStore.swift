import Foundation

@MainActor
final class AppStateStore {
    private let decoder = JSONDecoder.brainless
    private let encoder = JSONEncoder.brainless

    func isOnboardingComplete(settings: AppSettingsRecord?) -> Bool {
        loadSettings(settings).isOnboardingComplete
    }

    func makeSettingsData(isOnboardingComplete: Bool) throws -> Data {
        try encoder.encode(AppSettings(isOnboardingComplete: isOnboardingComplete))
    }

    func loadSettings(_ settings: AppSettingsRecord?) -> AppSettings {
        guard let settings, !settings.jsonData.isEmpty else {
            return .default
        }

        return (try? decoder.decode(AppSettings.self, from: settings.jsonData)) ?? .default
    }

    func makeSettingsData(_ settings: AppSettings) throws -> Data {
        try encoder.encode(settings)
    }
}

struct AppSettings: Codable, Equatable {
    var isOnboardingComplete: Bool
    var backendBaseURL: String
    var assetsBaseURL: String
    var apiToken: String
    var useRemoteWorkoutGeneration: Bool

    init(
        isOnboardingComplete: Bool = false,
        backendBaseURL: String = "https://nexus.raza.run/v1",
        assetsBaseURL: String = "https://assets.raza.run",
        apiToken: String = "",
        useRemoteWorkoutGeneration: Bool = false
    ) {
        self.isOnboardingComplete = isOnboardingComplete
        self.backendBaseURL = backendBaseURL
        self.assetsBaseURL = assetsBaseURL
        self.apiToken = apiToken
        self.useRemoteWorkoutGeneration = useRemoteWorkoutGeneration
    }

    static let `default` = AppSettings()
}
