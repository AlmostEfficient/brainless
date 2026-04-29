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
        apiToken: String = LocalSecretsFallback.apiToken,
        useRemoteWorkoutGeneration: Bool = true
    ) {
        self.isOnboardingComplete = isOnboardingComplete
        self.backendBaseURL = backendBaseURL
        self.assetsBaseURL = assetsBaseURL
        self.apiToken = apiToken.isEmpty ? LocalSecretsFallback.apiToken : apiToken
        self.useRemoteWorkoutGeneration = true
    }

    static let `default` = AppSettings()

    enum CodingKeys: String, CodingKey {
        case isOnboardingComplete
        case backendBaseURL
        case assetsBaseURL
        case apiToken
        case useRemoteWorkoutGeneration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            isOnboardingComplete: try container.decodeIfPresent(Bool.self, forKey: .isOnboardingComplete) ?? false,
            backendBaseURL: try container.decodeIfPresent(String.self, forKey: .backendBaseURL) ?? Self.default.backendBaseURL,
            assetsBaseURL: try container.decodeIfPresent(String.self, forKey: .assetsBaseURL) ?? Self.default.assetsBaseURL,
            apiToken: try container.decodeIfPresent(String.self, forKey: .apiToken) ?? "",
            useRemoteWorkoutGeneration: true
        )
    }
}
