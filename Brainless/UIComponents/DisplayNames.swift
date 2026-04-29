//
//  DisplayNames.swift
//  Brainless
//

import Foundation

extension FitnessGoal {
    var displayName: String {
        switch self {
        case .strength:       "Strength"
        case .hypertrophy:    "Hypertrophy"
        case .endurance:      "Endurance"
        case .fatLoss:        "Fat Loss"
        case .generalFitness: "General Fitness"
        case .mobility:       "Mobility"
        }
    }
}

extension TrainingExperience {
    var displayName: String {
        switch self {
        case .beginner:     "Beginner"
        case .intermediate: "Intermediate"
        case .advanced:     "Advanced"
        }
    }
}

extension WorkoutSplit {
    var displayName: String {
        switch self {
        case .fullBody:     "Full Body"
        case .upperLower:   "Upper / Lower"
        case .pushPullLegs: "Push / Pull / Legs"
        case .bodyPart:     "Body Part"
        case .custom:       "Custom"
        }
    }
}

extension WorkoutIntensity {
    var displayName: String {
        switch self {
        case .easy:     "Easy"
        case .moderate: "Moderate"
        case .hard:     "Hard"
        }
    }
}

extension SafetyPreference {
    var displayName: String {
        switch self {
        case .standard:         "Standard"
        case .conservative:     "Conservative"
        case .veryConservative: "Very Conservative"
        }
    }
}

extension EquipmentType {
    var displayName: String {
        switch self {
        case .bodyweight:      "Bodyweight"
        case .dumbbells:       "Dumbbells"
        case .barbell:         "Barbell"
        case .kettlebell:      "Kettlebell"
        case .resistanceBands: "Bands"
        case .cableMachine:    "Cable Machine"
        case .machine:         "Machine"
        case .bench:           "Bench"
        case .pullUpBar:       "Pull-Up Bar"
        case .cardioMachine:   "Cardio"
        }
    }
}

