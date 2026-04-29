//
//  ProfileDrafts.swift
//  Brainless
//

import Foundation

struct BodyContextDraft: Equatable {
    var bodyNotes = ""
    var safetyPreference: SafetyPreference = .standard

    var isComplete: Bool { true }
}

struct TrainingPreferencesDraft: Equatable {
    var goals: Set<FitnessGoal> = []
    var experience: TrainingExperience = .intermediate
    var preferredSplit: WorkoutSplit = .fullBody
    var workoutsPerWeek: Int = 3
    var additionalNotes = ""

    var isComplete: Bool { !goals.isEmpty }
}

enum TrainingLocation: String, CaseIterable, Identifiable {
    case home = "Home"
    case commercialGym = "Commercial Gym"
    case apartmentGym = "Apartment Gym"
    case outdoors = "Outdoors"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .commercialGym: "building.2"
        case .apartmentGym: "building"
        case .outdoors: "leaf"
        }
    }
}

struct EquipmentProfileDraft: Equatable {
    var location: TrainingLocation? = nil
    var equipment: Set<EquipmentType> = []
    var additionalNotes = ""

    var isComplete: Bool { location != nil || !equipment.isEmpty }
}

extension String {
    var trimmedForProfile: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
