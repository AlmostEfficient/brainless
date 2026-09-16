import Foundation

// Local launch configuration only; release builds always use persisted settings.
enum DevelopmentConfiguration {
    static var apiToken: String {
        #if DEBUG
        LocalSecrets.apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        #else
        ""
        #endif
    }

    static var apiTokenOverride: String? {
        #if DEBUG
        ProcessInfo.processInfo.environment["BRAINLESS_API_TOKEN"]
        #else
        nil
        #endif
    }

    static var backendBaseURL: URL? {
        #if DEBUG
        ProcessInfo.processInfo.environment["BRAINLESS_API_BASE_URL"].flatMap(URL.init(string:))
        #else
        nil
        #endif
    }
}
