import Foundation
import SwiftData

@Model
final class AppSettingsRecord {
    @Attribute(.unique) var id: String
    var jsonData: Data
    var updatedAt: Date

    init(id: String = "app-settings", jsonData: Data = Data(), updatedAt: Date = .now) {
        self.id = id
        self.jsonData = jsonData
        self.updatedAt = updatedAt
    }
}

@Model
final class UserProfileRecord {
    @Attribute(.unique) var id: String
    var jsonData: Data
    var updatedAt: Date

    init(id: String = "user-profile", jsonData: Data = Data(), updatedAt: Date = .now) {
        self.id = id
        self.jsonData = jsonData
        self.updatedAt = updatedAt
    }
}

@Model
final class TrainingPreferencesRecord {
    @Attribute(.unique) var id: String
    var jsonData: Data
    var updatedAt: Date

    init(id: String = "training-preferences", jsonData: Data = Data(), updatedAt: Date = .now) {
        self.id = id
        self.jsonData = jsonData
        self.updatedAt = updatedAt
    }
}

@Model
final class EquipmentProfileRecord {
    @Attribute(.unique) var id: String
    var jsonData: Data
    var updatedAt: Date

    init(id: String = "equipment-profile", jsonData: Data = Data(), updatedAt: Date = .now) {
        self.id = id
        self.jsonData = jsonData
        self.updatedAt = updatedAt
    }
}

@Model
final class WorkoutSessionRecord {
    @Attribute(.unique) var id: String
    var jsonData: Data
    var updatedAt: Date

    init(id: String = UUID().uuidString, jsonData: Data = Data(), updatedAt: Date = .now) {
        self.id = id
        self.jsonData = jsonData
        self.updatedAt = updatedAt
    }
}

