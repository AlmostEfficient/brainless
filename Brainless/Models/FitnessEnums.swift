import Foundation

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case female
    case male
    case other
    case preferNotToSay

    var id: String { rawValue }
}

enum FitnessGoal: String, Codable, CaseIterable, Identifiable {
    case strength
    case hypertrophy
    case endurance
    case fatLoss
    case generalFitness
    case mobility

    var id: String { rawValue }
}

enum TrainingExperience: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }
}

enum WorkoutSplit: String, Codable, CaseIterable, Identifiable {
    case fullBody
    case upperLower
    case pushPullLegs
    case bodyPart
    case custom

    var id: String { rawValue }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case forearms
    case core
    case glutes
    case quads
    case hamstrings
    case calves
    case fullBody
    case cardio

    var id: String { rawValue }
}

enum EquipmentType: String, Codable, CaseIterable, Identifiable {
    case bodyweight
    case dumbbells
    case barbell
    case kettlebell
    case resistanceBands
    case cableMachine
    case machine
    case bench
    case pullUpBar
    case cardioMachine

    var id: String { rawValue }
}

enum WorkoutIntensity: String, Codable, CaseIterable, Identifiable {
    case easy
    case moderate
    case hard

    var id: String { rawValue }
}

enum WorkoutCompletionStatus: String, Codable, CaseIterable, Identifiable {
    case planned
    case inProgress
    case completed
    case skipped

    var id: String { rawValue }
}

enum SafetyPreference: String, Codable, CaseIterable, Identifiable {
    case standard
    case conservative
    case veryConservative

    var id: String { rawValue }
}

extension MuscleGroup {
    var displayName: String {
        switch self {
        case .fullBody:
            "Full Body"
        default:
            rawValue.capitalized
        }
    }
}
