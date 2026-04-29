//
//  ProfileDrafts.swift
//  Brainless
//

import Foundation

struct BodyContextDraft: Equatable {
    var bodyNotes = ""
    var jointConcerns = ""
    var postureAndMobility = ""
    var healthNotes = ""

    var isComplete: Bool {
        !bodyNotes.trimmedForProfile.isEmpty
    }
}

struct TrainingPreferencesDraft: Equatable {
    var primaryGoals = ""
    var trainingStyle = ""
    var sessionLength = ""
    var weeklyFrequency = ""
    var intensityPreference = ""
    var additionalNotes = ""

    var isComplete: Bool {
        !primaryGoals.trimmedForProfile.isEmpty
    }
}

struct EquipmentProfileDraft: Equatable {
    var trainingLocation = ""
    var availableEquipment = ""
    var missingEquipment = ""
    var additionalNotes = ""

    var isComplete: Bool {
        !availableEquipment.trimmedForProfile.isEmpty || !trainingLocation.trimmedForProfile.isEmpty
    }
}

extension String {
    var trimmedForProfile: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
