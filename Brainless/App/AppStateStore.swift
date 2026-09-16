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
    var isOnboardingComplete: Bool = false
    var backendBaseURL: String = "https://nexus.raza.run/v1"
    var assetsBaseURL: String = "https://assets.raza.run"
    var apiToken: String = DevelopmentConfiguration.apiToken

    static let `default` = AppSettings()
}
