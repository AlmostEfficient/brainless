//
//  ProfileDraftAdapters.swift
//  Brainless
//

import Foundation

// MARK: - Draft → Model

extension UserBodyContext {
    init(draft: BodyContextDraft) {
        self.init(
            bodyNotes: draft.bodyNotes.trimmedForProfile,
            safetyPreference: draft.safetyPreference
        )
    }
}

extension TrainingPreferences {
    init(draft: TrainingPreferencesDraft) {
        let goalsArray = FitnessGoal.allCases.filter { draft.goals.contains($0) }
        self.init(
            goals: goalsArray,
            styleNotes: draft.additionalNotes.trimmedForProfile,
            experience: draft.experience,
            preferredSplit: draft.preferredSplit,
            workoutsPerWeek: draft.workoutsPerWeek
        )
    }
}

extension EquipmentProfile {
    init(draft: EquipmentProfileDraft) {
        let equipmentArray = draft.equipment.isEmpty
            ? [EquipmentType.bodyweight]
            : EquipmentType.allCases.filter { draft.equipment.contains($0) }
        self.init(
            location: draft.location?.rawValue ?? "",
            availableEquipment: equipmentArray,
            notes: draft.additionalNotes.trimmedForProfile
        )
    }
}

// MARK: - Model → Draft

extension BodyContextDraft {
    init(bodyContext: UserBodyContext) {
        bodyNotes = bodyContext.bodyNotes
        safetyPreference = bodyContext.safetyPreference
    }
}

extension TrainingPreferencesDraft {
    init(trainingPreferences: TrainingPreferences) {
        goals = Set(trainingPreferences.goals)
        experience = trainingPreferences.experience
        preferredSplit = trainingPreferences.preferredSplit
        workoutsPerWeek = trainingPreferences.workoutsPerWeek
        additionalNotes = trainingPreferences.styleNotes
    }
}

extension EquipmentProfileDraft {
    init(equipmentProfile: EquipmentProfile) {
        location = TrainingLocation(rawValue: equipmentProfile.location)
        equipment = Set(equipmentProfile.availableEquipment)
        additionalNotes = equipmentProfile.notes
    }
}
