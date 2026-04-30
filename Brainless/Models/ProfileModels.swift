import Foundation

struct UserBodyContext: Codable, Equatable, Hashable {
    var id: UUID
    var updatedAt: Date
    var bodyNotes: String
    var knownLimitations: [String]
    var postureConcerns: [String]
    var painOrInjuryNotes: String
    var professionalGuidanceNotes: String
    var safetyPreference: SafetyPreference
    var dateOfBirth: Date?
    var biologicalSex: BiologicalSex
    var heightCentimeters: Double?
    var weightKilograms: Double?
    var injuriesOrLimitations: [String]

    init(
        id: UUID = UUID(),
        updatedAt: Date = Date(),
        bodyNotes: String = "",
        knownLimitations: [String] = [],
        postureConcerns: [String] = [],
        painOrInjuryNotes: String = "",
        professionalGuidanceNotes: String = "",
        safetyPreference: SafetyPreference = .standard,
        dateOfBirth: Date? = nil,
        biologicalSex: BiologicalSex = .preferNotToSay,
        heightCentimeters: Double? = nil,
        weightKilograms: Double? = nil,
        injuriesOrLimitations: [String] = []
    ) {
        self.id = id
        self.updatedAt = updatedAt
        self.bodyNotes = bodyNotes
        self.knownLimitations = knownLimitations
        self.postureConcerns = postureConcerns
        self.painOrInjuryNotes = painOrInjuryNotes
        self.professionalGuidanceNotes = professionalGuidanceNotes
        self.safetyPreference = safetyPreference
        self.dateOfBirth = dateOfBirth
        self.biologicalSex = biologicalSex
        self.heightCentimeters = heightCentimeters
        self.weightKilograms = weightKilograms
        self.injuriesOrLimitations = injuriesOrLimitations
    }
}

struct TrainingPreferences: Codable, Equatable, Hashable {
    var id: UUID
    var updatedAt: Date
    var goals: [FitnessGoal]
    var preferredDurationMinutes: Int
    var avoidances: [String]
    var styleNotes: String
    var primaryGoal: FitnessGoal
    var secondaryGoals: [FitnessGoal]
    var experience: TrainingExperience
    var preferredSplit: WorkoutSplit
    var workoutsPerWeek: Int
    var sessionLengthMinutes: Int
    var preferredIntensity: WorkoutIntensity
    var preferredMuscles: [MuscleGroup]
    var avoidedMuscles: [MuscleGroup]

    init(
        id: UUID = UUID(),
        updatedAt: Date = Date(),
        goals: [FitnessGoal] = [],
        preferredDurationMinutes: Int? = nil,
        avoidances: [String] = [],
        styleNotes: String = "",
        primaryGoal: FitnessGoal = .generalFitness,
        secondaryGoals: [FitnessGoal] = [],
        experience: TrainingExperience = .beginner,
        preferredSplit: WorkoutSplit = .fullBody,
        workoutsPerWeek: Int = 3,
        sessionLengthMinutes: Int = 45,
        preferredIntensity: WorkoutIntensity = .moderate,
        preferredMuscles: [MuscleGroup] = [],
        avoidedMuscles: [MuscleGroup] = []
    ) {
        self.id = id
        self.updatedAt = updatedAt
        self.goals = goals.isEmpty ? [primaryGoal] + secondaryGoals : goals
        self.preferredDurationMinutes = preferredDurationMinutes ?? sessionLengthMinutes
        self.avoidances = avoidances
        self.styleNotes = styleNotes
        self.primaryGoal = primaryGoal
        self.secondaryGoals = secondaryGoals
        self.experience = experience
        self.preferredSplit = preferredSplit
        self.workoutsPerWeek = workoutsPerWeek
        self.sessionLengthMinutes = sessionLengthMinutes
        self.preferredIntensity = preferredIntensity
        self.preferredMuscles = preferredMuscles
        self.avoidedMuscles = avoidedMuscles
    }
}

struct EquipmentProfile: Codable, Equatable, Hashable {
    var id: UUID
    var updatedAt: Date
    var location: String
    var availableEquipment: [EquipmentType]
    var missingEquipment: [String]
    var freeTextNotes: String
    var notes: String

    init(
        id: UUID = UUID(),
        updatedAt: Date = Date(),
        location: String = "",
        availableEquipment: [EquipmentType] = [.bodyweight, .dumbbells, .bench],
        missingEquipment: [String] = [],
        freeTextNotes: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.updatedAt = updatedAt
        self.location = location
        self.availableEquipment = availableEquipment
        self.missingEquipment = missingEquipment
        self.freeTextNotes = freeTextNotes
        self.notes = notes
    }
}

struct ExerciseCatalogItem: Codable, Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var muscle: String
    var equipment: String
}

struct GeneratedWorkout: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var title: String
    var summary: String
    var focus: [MuscleGroup]
    var focusAreas: [String]
    var estimatedDurationMinutes: Int
    var intensity: String
    var exercises: [WorkoutExercise]
    var generatedAt: Date
    var rationale: String?
    var safetyNote: String
    var generationContextSummary: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case focus
        case focusAreas
        case estimatedDurationMinutes
        case intensity
        case exercises
        case generatedAt
        case rationale
        case safetyNote
        case generationContextSummary
    }

    init(
        id: UUID = UUID(),
        title: String,
        summary: String = "",
        focus: [MuscleGroup],
        focusAreas: [String] = [],
        estimatedDurationMinutes: Int,
        intensity: String = "Moderate",
        exercises: [WorkoutExercise],
        generatedAt: Date = Date(),
        rationale: String? = nil,
        safetyNote: String = "Warm up first, keep reps controlled, and stop any movement that causes sharp pain.",
        generationContextSummary: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary.isEmpty ? (rationale ?? "A generated session matched to your profile, equipment, and recent training.") : summary
        self.focus = focus
        self.focusAreas = focusAreas.isEmpty ? focus.map(\.displayName) : focusAreas
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.intensity = intensity
        self.exercises = exercises
        self.generatedAt = generatedAt
        self.rationale = rationale
        self.safetyNote = safetyNote
        self.generationContextSummary = generationContextSummary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let title = try container.decode(String.self, forKey: .title)
        let summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        let focusValues = try container.decodeIfPresent([String].self, forKey: .focus) ?? []
        let focus = focusValues.compactMap(MuscleGroup.init(catalogValue:))
        let focusAreas = try container.decodeIfPresent([String].self, forKey: .focusAreas) ?? focusValues
        let estimatedDurationMinutes = try container.decode(Int.self, forKey: .estimatedDurationMinutes)
        let intensity = try container.decodeIfPresent(String.self, forKey: .intensity) ?? "Moderate"
        let exercises = try container.decode([WorkoutExercise].self, forKey: .exercises)
        let generatedAt = try container.decodeIfPresent(Date.self, forKey: .generatedAt) ?? Date()
        let rationale = try container.decodeIfPresent(String.self, forKey: .rationale)
        let safetyNote = try container.decodeIfPresent(String.self, forKey: .safetyNote) ?? "Warm up first, keep reps controlled, and stop any movement that causes sharp pain."
        let generationContextSummary = try container.decodeIfPresent(String.self, forKey: .generationContextSummary)

        self.init(
            id: id,
            title: title,
            summary: summary,
            focus: focus,
            focusAreas: focusAreas,
            estimatedDurationMinutes: estimatedDurationMinutes,
            intensity: intensity,
            exercises: exercises,
            generatedAt: generatedAt,
            rationale: rationale,
            safetyNote: safetyNote,
            generationContextSummary: generationContextSummary
        )
    }
}

struct WorkoutExercise: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var catalogItem: ExerciseCatalogItem
    var orderIndex: Int
    var targetSets: Int
    var sets: Int
    var targetReps: String
    var reps: String?
    var durationSeconds: Int?
    var restSeconds: Int
    var notes: String?
    var coachingNote: String?
    var substitutionNote: String?
    var safetyNote: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case catalogItem
        case orderIndex
        case targetSets
        case sets
        case targetReps
        case reps
        case durationSeconds
        case restSeconds
        case notes
        case coachingNote
        case substitutionNote
        case safetyNote
    }

    init(
        id: UUID = UUID(),
        catalogItem: ExerciseCatalogItem,
        orderIndex: Int = 0,
        targetSets: Int,
        sets: Int? = nil,
        targetReps: String,
        reps: String? = nil,
        durationSeconds: Int? = nil,
        restSeconds: Int = 90,
        notes: String? = nil,
        coachingNote: String? = nil,
        substitutionNote: String? = nil,
        safetyNote: String? = nil
    ) {
        self.id = id
        self.catalogItem = catalogItem
        self.orderIndex = orderIndex
        self.targetSets = targetSets
        self.sets = sets ?? targetSets
        self.targetReps = targetReps
        self.reps = reps ?? targetReps
        self.durationSeconds = durationSeconds
        self.restSeconds = restSeconds
        self.notes = notes
        self.coachingNote = coachingNote ?? notes
        self.substitutionNote = substitutionNote
        self.safetyNote = safetyNote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let catalogItem = try container.decode(ExerciseCatalogItem.self, forKey: .catalogItem)
        let orderIndex = try container.decodeIfPresent(Int.self, forKey: .orderIndex) ?? 0
        let targetSets = try container.decodeIfPresent(Int.self, forKey: .targetSets)
            ?? container.decodeIfPresent(Int.self, forKey: .sets)
            ?? 1
        let sets = try container.decodeIfPresent(Int.self, forKey: .sets)
        let targetReps = try container.decodeIfPresent(String.self, forKey: .targetReps)
            ?? container.decodeIfPresent(String.self, forKey: .reps)
            ?? ""
        let reps = try container.decodeIfPresent(String.self, forKey: .reps)
        let durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
        let restSeconds = try container.decodeIfPresent(Int.self, forKey: .restSeconds) ?? 90
        let notes = try container.decodeIfPresent(String.self, forKey: .notes)
        let coachingNote = try container.decodeIfPresent(String.self, forKey: .coachingNote)
        let substitutionNote = try container.decodeIfPresent(String.self, forKey: .substitutionNote)
        let safetyNote = try container.decodeIfPresent(String.self, forKey: .safetyNote)

        self.init(
            id: id,
            catalogItem: catalogItem,
            orderIndex: orderIndex,
            targetSets: targetSets,
            sets: sets,
            targetReps: targetReps,
            reps: reps,
            durationSeconds: durationSeconds,
            restSeconds: restSeconds,
            notes: notes,
            coachingNote: coachingNote,
            substitutionNote: substitutionNote,
            safetyNote: safetyNote
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
}

struct WorkoutGenerationRequest: Codable, Equatable, Hashable {
    var bodyContext: UserBodyContext
    var trainingPreferences: TrainingPreferences
    var equipmentProfile: EquipmentProfile
    var workoutIntent: String
    var todayNotes: String
    var requestedDurationMinutes: Int?
    var historySummary: WorkoutHistorySummary?
    var clientRequestID: UUID
    var exerciseCatalog: [ExerciseCatalogItem]
    var recentHistory: WorkoutHistorySummary?

    init(
        bodyContext: UserBodyContext,
        trainingPreferences: TrainingPreferences,
        equipmentProfile: EquipmentProfile,
        workoutIntent: String = "",
        todayNotes: String = "",
        requestedDurationMinutes: Int? = nil,
        historySummary: WorkoutHistorySummary? = nil,
        clientRequestID: UUID = UUID(),
        exerciseCatalog: [ExerciseCatalogItem],
        recentHistory: WorkoutHistorySummary? = nil
    ) {
        self.bodyContext = bodyContext
        self.trainingPreferences = trainingPreferences
        self.equipmentProfile = equipmentProfile
        self.workoutIntent = workoutIntent
        self.todayNotes = todayNotes
        self.requestedDurationMinutes = requestedDurationMinutes
        self.historySummary = historySummary ?? recentHistory
        self.clientRequestID = clientRequestID
        self.exerciseCatalog = exerciseCatalog
        self.recentHistory = recentHistory ?? historySummary
    }
}

struct WorkoutGenerationResponse: Codable, Equatable, Hashable {
    var workout: GeneratedWorkout
    var alternatives: [GeneratedWorkout]
    var warnings: [String]

    private enum CodingKeys: String, CodingKey {
        case workout
        case alternatives
        case warnings
    }

    init(workout: GeneratedWorkout, alternatives: [GeneratedWorkout] = [], warnings: [String] = []) {
        self.workout = workout
        self.alternatives = alternatives
        self.warnings = warnings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.workout = try container.decode(GeneratedWorkout.self, forKey: .workout)
        self.alternatives = try container.decodeIfPresent([GeneratedWorkout].self, forKey: .alternatives) ?? []
        self.warnings = try container.decodeIfPresent([String].self, forKey: .warnings) ?? []
    }
}

private extension MuscleGroup {
    nonisolated init?(catalogValue: String) {
        switch catalogValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "pectorals", "chest":
            self = .chest
        case "lats", "traps", "upper back", "back":
            self = .back
        case "delts", "shoulders":
            self = .shoulders
        case "abs", "core":
            self = .core
        case "quadriceps", "quads":
            self = .quads
        case "hamstrings":
            self = .hamstrings
        case "biceps":
            self = .biceps
        case "triceps":
            self = .triceps
        case "forearms":
            self = .forearms
        case "glutes":
            self = .glutes
        case "calves":
            self = .calves
        case "full body", "fullbody":
            self = .fullBody
        case "cardio":
            self = .cardio
        default:
            self.init(rawValue: catalogValue)
        }
    }
}

extension UserBodyContext {
    static let `default` = UserBodyContext()
    static let sample = UserBodyContext(
        dateOfBirth: Calendar.current.date(from: DateComponents(year: 1994, month: 6, day: 15)),
        biologicalSex: .preferNotToSay,
        heightCentimeters: 178,
        weightKilograms: 78,
        injuriesOrLimitations: ["Avoid high-impact jumping"]
    )
}

extension TrainingPreferences {
    static let `default` = TrainingPreferences()
    static let sample = TrainingPreferences(
        primaryGoal: .strength,
        secondaryGoals: [.hypertrophy],
        experience: .intermediate,
        preferredSplit: .upperLower,
        workoutsPerWeek: 4,
        sessionLengthMinutes: 50,
        preferredIntensity: .moderate,
        preferredMuscles: [.chest, .back, .quads],
        avoidedMuscles: []
    )
}

extension EquipmentProfile {
    static let `default` = EquipmentProfile()
    static let sample = EquipmentProfile(
        availableEquipment: [.bodyweight, .dumbbells, .barbell, .bench, .pullUpBar],
        notes: "Home gym setup"
    )
}

extension ExerciseCatalogItem {
    static let samples: [ExerciseCatalogItem] = [
        ExerciseCatalogItem(id: "push-up", name: "Push-Up", muscle: "chest", equipment: "bodyweight"),
        ExerciseCatalogItem(id: "goblet-squat", name: "Goblet Squat", muscle: "quads", equipment: "dumbbells"),
        ExerciseCatalogItem(id: "pull-up", name: "Pull-Up", muscle: "back", equipment: "pull-up bar"),
        ExerciseCatalogItem(id: "plank", name: "Plank", muscle: "core", equipment: "bodyweight")
    ]
}

extension GeneratedWorkout {
    static let sample: GeneratedWorkout = {
        let exercises = [
            WorkoutExercise(catalogItem: ExerciseCatalogItem.samples[0], targetSets: 3, targetReps: "8-12"),
            WorkoutExercise(catalogItem: ExerciseCatalogItem.samples[1], targetSets: 3, targetReps: "10-12"),
            WorkoutExercise(catalogItem: ExerciseCatalogItem.samples[3], targetSets: 3, targetReps: "30-45 sec")
        ]

        return GeneratedWorkout(
            title: "Balanced Strength",
            focus: [.chest, .quads, .core],
            estimatedDurationMinutes: 40,
            exercises: exercises,
            rationale: "Simple full-body session using available home equipment."
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
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
