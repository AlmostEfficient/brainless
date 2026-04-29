import Foundation

enum LocalSecretsFallback {
    static var apiToken: String {
        #if DEBUG
        LocalSecrets.apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        #else
        ""
        #endif
    }
}
