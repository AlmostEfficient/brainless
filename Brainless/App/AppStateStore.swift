import Foundation

@MainActor
final class AppStateStore {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func isOnboardingComplete(settings: AppSettingsRecord?) -> Bool {
        guard let settings else {
            return false
        }

        return (try? decoder.decode(AppSettings.self, from: settings.jsonData).isOnboardingComplete) ?? false
    }

    func makeSettingsData(isOnboardingComplete: Bool) throws -> Data {
        try encoder.encode(AppSettings(isOnboardingComplete: isOnboardingComplete))
    }
}

private struct AppSettings: Codable {
    var isOnboardingComplete: Bool
}

