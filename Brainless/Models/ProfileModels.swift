import Foundation

struct UserBodyContext: Codable, Equatable, Hashable {
    var bodyNotes: String = ""
    var safetyPreference: SafetyPreference = .standard
}

struct TrainingPreferences: Codable, Equatable, Hashable {
    var goals: [FitnessGoal] = [.generalFitness]
    var styleNotes: String = ""
    var experience: TrainingExperience = .beginner
    var preferredSplit: WorkoutSplit = .fullBody
    var workoutsPerWeek: Int = 3
}

struct EquipmentProfile: Codable, Equatable, Hashable {
    var location: String = ""
    var availableEquipment: [EquipmentType] = [.bodyweight, .dumbbells, .bench]
    var notes: String = ""
}

struct GeneratedWorkout: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var title: String
    var summary: String = ""
    var focus: [MuscleGroup]
    var estimatedDurationMinutes: Int
    var intensity: String = "Moderate"
    var exercises: [WorkoutExercise]
    var generatedAt: Date = Date()
    var safetyNote: String = "Not medical advice. Stop any movement that causes sharp pain."
    var generationContextSummary: String? = nil
    var decisionSummary: [WorkoutDecision]? = nil
    var generationStatus: WorkoutGenerationStatus? = nil

    var isGenerationComplete: Bool { generationStatus == nil || generationStatus == .complete }
}

enum WorkoutGenerationStatus: String, Codable { case generating, complete, failed }

struct WorkoutDecision: Codable, Equatable, Hashable {
    var factor: String
    var adjustment: String
}

enum SessionIntensity: String, Codable, CaseIterable {
    case recovery = "Recovery", light = "Light", moderate = "Moderate", hard = "Hard", allOut = "All-out"
}

// A presentation reference, never the identity of the prescribed movement.
struct ExerciseAsset: Codable, Equatable, Hashable {
    var catalogID: String?
    var assetID: String
}

struct WorkoutExercise: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var muscle: String
    var equipment: [String]
    var targetSets: Int
    var targetReps: String
    var durationSeconds: Int? = nil
    var restSeconds: Int = 90
    var instructions: String
    var formCues: String = ""
    var asset: ExerciseAsset? = nil
    var sessionNote: String? = nil
    var libraryID: String? = nil
    var resolutionStatus: String? = nil

    var equipmentLabel: String { equipment.isEmpty ? "Bodyweight" : equipment.joined(separator: ", ") }
    var executionNotes: String { [sessionNote ?? "", instructions, formCues].filter { !$0.isEmpty }.joined(separator: "\n\n") }
}

extension WorkoutExercise {
    private enum CodingKeys: String, CodingKey {
        case id, name, muscle, equipment, targetSets, targetReps, durationSeconds, restSeconds
        case instructions, formCues, asset, sessionNote, libraryID, resolutionStatus
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(muscle, forKey: .muscle)
        try container.encode(equipment, forKey: .equipment)
        try container.encode(targetSets, forKey: .targetSets)
        try container.encode(targetReps, forKey: .targetReps)
        // The canonical prescription uses explicit null for untimed exercises.
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(restSeconds, forKey: .restSeconds)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(formCues, forKey: .formCues)
        try container.encodeIfPresent(asset, forKey: .asset)
        try container.encodeIfPresent(sessionNote, forKey: .sessionNote)
        try container.encodeIfPresent(libraryID, forKey: .libraryID)
        try container.encodeIfPresent(resolutionStatus, forKey: .resolutionStatus)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            name: try container.decode(String.self, forKey: .name),
            muscle: try container.decode(String.self, forKey: .muscle),
            equipment: try container.decode([String].self, forKey: .equipment),
            targetSets: try container.decode(Int.self, forKey: .targetSets),
            targetReps: try container.decode(String.self, forKey: .targetReps),
            durationSeconds: try container.decodeIfPresent(Int.self, forKey: .durationSeconds),
            restSeconds: try container.decode(Int.self, forKey: .restSeconds),
            instructions: try container.decode(String.self, forKey: .instructions),
            formCues: try container.decode(String.self, forKey: .formCues),
            asset: try? container.decodeIfPresent(ExerciseAsset.self, forKey: .asset),
            sessionNote: try container.decodeIfPresent(String.self, forKey: .sessionNote),
            libraryID: try container.decodeIfPresent(String.self, forKey: .libraryID),
            resolutionStatus: try container.decodeIfPresent(String.self, forKey: .resolutionStatus)
        )
    }
}

struct WorkoutSession: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var workout: GeneratedWorkout
    var startedAt: Date?
    var completedAt: Date?
    var status: WorkoutCompletionStatus
    var loggedSets: [LoggedSet]
    var skippedExerciseIDs: [UUID] = []
    var notes: String?
}

struct LoggedSet: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var workoutExerciseID: UUID
    var setNumber: Int
    var reps: Int
    var weightKilograms: Double?
    var completedAt: Date
    var perceivedExertion: Int?
}

struct WorkoutHistorySummary: Codable, Equatable, Hashable {
    var totalCompletedWorkouts: Int
    var workoutsThisWeek: Int
    var currentStreakDays: Int
    var recentWorkouts: [RecentWorkoutSummary]
    var referenceDate: Date? = nil

    static let empty = WorkoutHistorySummary(
        totalCompletedWorkouts: 0,
        workoutsThisWeek: 0,
        currentStreakDays: 0,
        recentWorkouts: []
    )
}

struct RecentWorkoutSummary: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var title: String
    var completedAt: Date
    var durationMinutes: Int?
    var focus: [MuscleGroup]
    var exercises: [String] = []
    var status: WorkoutCompletionStatus = .completed
    var notes: String? = nil
    var exerciseDetails: [HistoricalExercise] = []
}

struct HistoricalExercise: Codable, Equatable, Hashable {
    var name: String
    var muscle: String
    var prescribedSets: Int
    var prescribedReps: String
    var skipped: Bool
    var loggedSets: [HistoricalSet]
}

struct HistoricalSet: Codable, Equatable, Hashable {
    var setNumber: Int
    var reps: Int
    var weightKilograms: Double?
    var perceivedExertion: Int?
}

struct WorkoutChatMessage: Codable, Equatable, Hashable {
    var role: String
    var content: String
}

struct WorkoutGenerationRequest: Codable, Equatable, Hashable {
    var bodyContext: UserBodyContext
    var trainingPreferences: TrainingPreferences
    var equipmentProfile: EquipmentProfile
    var workoutIntent: String = ""
    var todayNotes: String = ""
    var requestedDurationMinutes: Int? = nil
    var requestedIntensity: SessionIntensity = .moderate
    var historySummary: WorkoutHistorySummary? = nil
    var clientRequestID: UUID = UUID()
    var messages: [WorkoutChatMessage] = []
    var edit: WorkoutEditRequest? = nil
}

struct WorkoutEditRequest: Codable, Equatable, Hashable {
    var workout: GeneratedWorkout
    var instruction: String
}

struct WorkoutGenerationResponse: Codable, Equatable, Hashable {
    var workout: GeneratedWorkout
}

extension UserBodyContext {
    static let `default` = UserBodyContext()
    static let sample = UserBodyContext(bodyNotes: "Avoid high-impact jumping")
}

extension TrainingPreferences {
    static let `default` = TrainingPreferences()
    static let sample = TrainingPreferences(
        goals: [.strength, .hypertrophy],
        experience: .intermediate,
        preferredSplit: .upperLower,
        workoutsPerWeek: 4
    )
}

extension EquipmentProfile {
    static let `default` = EquipmentProfile()
    static let sample = EquipmentProfile(
        availableEquipment: [.bodyweight, .dumbbells, .barbell, .bench, .pullUpBar],
        notes: "Home gym setup"
    )
}

extension GeneratedWorkout {
    static let sample: GeneratedWorkout = {
        let exercises = [
            WorkoutExercise(name: "Push-up", muscle: "chest", equipment: [], targetSets: 3, targetReps: "8-12", instructions: "Keep your body straight, lower your chest toward the floor, then press up.", asset: ExerciseAsset(catalogID: "I4hDWkc", assetID: "I4hDWkc")),
            WorkoutExercise(name: "Dumbbell goblet squat", muscle: "quads", equipment: ["dumbbells"], targetSets: 3, targetReps: "10-12", instructions: "Hold one dumbbell at your chest, sit down between your hips, then stand.", asset: ExerciseAsset(catalogID: "yn8yg1r", assetID: "yn8yg1r")),
            WorkoutExercise(name: "Forearm plank", muscle: "core", equipment: [], targetSets: 3, targetReps: "30-45 sec", instructions: "Rest on your forearms and toes and hold a straight line from head to heels.")
        ]

        return GeneratedWorkout(
            title: "Balanced Strength",
            summary: "Simple full-body session using available home equipment.",
            focus: [.chest, .quads, .core],
            estimatedDurationMinutes: 40,
            exercises: exercises
        )
    }()
}

extension WorkoutSession {
    static let sample = WorkoutSession(
        id: UUID(),
        workout: .sample,
        startedAt: Date().addingTimeInterval(-3_600),
        completedAt: Date().addingTimeInterval(-900),
        status: .completed,
        loggedSets: [],
        notes: "Felt strong."
    )
}

extension JSONEncoder {
    static var brainless: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var brainless: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO-8601 date")
        }
        return decoder
    }
}
