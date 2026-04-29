import Foundation
import SwiftData

@MainActor
protocol UserProfileStore {
    func loadBodyContext() throws -> UserBodyContext
    func saveBodyContext(_ bodyContext: UserBodyContext) throws
}

@MainActor
protocol TrainingPreferencesStore {
    func loadTrainingPreferences() throws -> TrainingPreferences
    func saveTrainingPreferences(_ preferences: TrainingPreferences) throws
}

@MainActor
protocol EquipmentProfileStore {
    func loadEquipmentProfile() throws -> EquipmentProfile
    func saveEquipmentProfile(_ profile: EquipmentProfile) throws
}

@MainActor
protocol WorkoutHistoryService {
    func loadSessions(limit: Int?) throws -> [WorkoutSession]
    func saveSession(_ session: WorkoutSession) throws
    func deleteSession(id: UUID) throws
    func historySummary(referenceDate: Date) throws -> WorkoutHistorySummary
}

@MainActor
final class SwiftDataUserProfileStore: UserProfileStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadBodyContext() throws -> UserBodyContext {
        guard let record = try fetchSingleton(UserProfileRecord.self) else {
            return .default
        }

        return try JSONDecoder.brainless.decode(UserBodyContext.self, from: record.jsonData)
    }

    func saveBodyContext(_ bodyContext: UserBodyContext) throws {
        let record = try fetchSingleton(UserProfileRecord.self) ?? UserProfileRecord()
        record.jsonData = try JSONEncoder.brainless.encode(bodyContext)
        record.updatedAt = Date()
        modelContext.insert(record)
        try modelContext.save()
    }

    private func fetchSingleton<T: PersistentModel>(_ type: T.Type) throws -> T? {
        var descriptor = FetchDescriptor<T>()
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

@MainActor
final class SwiftDataTrainingPreferencesStore: TrainingPreferencesStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadTrainingPreferences() throws -> TrainingPreferences {
        guard let record = try fetchSingleton(TrainingPreferencesRecord.self) else {
            return .default
        }

        return try JSONDecoder.brainless.decode(TrainingPreferences.self, from: record.jsonData)
    }

    func saveTrainingPreferences(_ preferences: TrainingPreferences) throws {
        let record = try fetchSingleton(TrainingPreferencesRecord.self) ?? TrainingPreferencesRecord()
        record.jsonData = try JSONEncoder.brainless.encode(preferences)
        record.updatedAt = Date()
        modelContext.insert(record)
        try modelContext.save()
    }

    private func fetchSingleton<T: PersistentModel>(_ type: T.Type) throws -> T? {
        var descriptor = FetchDescriptor<T>()
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

@MainActor
final class SwiftDataEquipmentProfileStore: EquipmentProfileStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadEquipmentProfile() throws -> EquipmentProfile {
        guard let record = try fetchSingleton(EquipmentProfileRecord.self) else {
            return .default
        }

        return try JSONDecoder.brainless.decode(EquipmentProfile.self, from: record.jsonData)
    }

    func saveEquipmentProfile(_ profile: EquipmentProfile) throws {
        let record = try fetchSingleton(EquipmentProfileRecord.self) ?? EquipmentProfileRecord()
        record.jsonData = try JSONEncoder.brainless.encode(profile)
        record.updatedAt = Date()
        modelContext.insert(record)
        try modelContext.save()
    }

    private func fetchSingleton<T: PersistentModel>(_ type: T.Type) throws -> T? {
        var descriptor = FetchDescriptor<T>()
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

@MainActor
final class SwiftDataWorkoutHistoryService: WorkoutHistoryService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadSessions(limit: Int? = nil) throws -> [WorkoutSession] {
        var descriptor = FetchDescriptor<WorkoutSessionRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
        }

        return try modelContext.fetch(descriptor).compactMap { record in
            try? JSONDecoder.brainless.decode(WorkoutSession.self, from: record.jsonData)
        }
    }

    func saveSession(_ session: WorkoutSession) throws {
        let existing = try record(for: session.id)
        let record = existing ?? WorkoutSessionRecord(id: session.id.uuidString)
        record.jsonData = try JSONEncoder.brainless.encode(session)
        record.updatedAt = Date()
        modelContext.insert(record)
        try modelContext.save()
    }

    func deleteSession(id: UUID) throws {
        guard let record = try record(for: id) else {
            return
        }

        modelContext.delete(record)
        try modelContext.save()
    }

    func historySummary(referenceDate: Date = Date()) throws -> WorkoutHistorySummary {
        let sessions = try loadSessions(limit: 10)
        let completed = sessions.filter { $0.status == .completed }
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)
        let workoutsThisWeek = completed.filter { session in
            guard let completedAt = session.completedAt, let weekInterval else {
                return false
            }
            return weekInterval.contains(completedAt)
        }.count

        let recentWorkouts = completed
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            .prefix(5)
            .compactMap { session -> RecentWorkoutSummary? in
                guard let completedAt = session.completedAt else {
                    return nil
                }

                let duration = session.startedAt.map {
                    max(1, Int(completedAt.timeIntervalSince($0) / 60))
                }

                return RecentWorkoutSummary(
                    id: session.id,
                    title: session.workout.title,
                    completedAt: completedAt,
                    durationMinutes: duration,
                    focus: session.workout.focus
                )
            }

        return WorkoutHistorySummary(
            totalCompletedWorkouts: completed.count,
            workoutsThisWeek: workoutsThisWeek,
            currentStreakDays: completedWorkoutStreak(from: completed, referenceDate: referenceDate),
            recentWorkouts: Array(recentWorkouts)
        )
    }

    private func record(for id: UUID) throws -> WorkoutSessionRecord? {
        let descriptor = FetchDescriptor<WorkoutSessionRecord>(
            predicate: #Predicate { $0.id == id.uuidString }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func completedWorkoutStreak(from sessions: [WorkoutSession], referenceDate: Date) -> Int {
        let calendar = Calendar.current
        let completedDays = Set(sessions.compactMap { session -> Date? in
            guard let completedAt = session.completedAt else {
                return nil
            }
            return calendar.startOfDay(for: completedAt)
        })

        var streak = 0
        var day = calendar.startOfDay(for: referenceDate)

        while completedDays.contains(day) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else {
                break
            }
            day = previousDay
        }

        return streak
    }
}
