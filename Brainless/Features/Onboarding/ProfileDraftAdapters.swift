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
            preferredDurationMinutes: draft.sessionLengthMinutes,
            styleNotes: draft.additionalNotes.trimmedForProfile,
            primaryGoal: goalsArray.first ?? .generalFitness,
            secondaryGoals: Array(goalsArray.dropFirst()),
            experience: draft.experience,
            preferredSplit: draft.preferredSplit,
            workoutsPerWeek: draft.workoutsPerWeek,
            sessionLengthMinutes: draft.sessionLengthMinutes,
            preferredIntensity: draft.intensity
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
            freeTextNotes: draft.additionalNotes.trimmedForProfile,
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
        let allGoals = trainingPreferences.goals.isEmpty
            ? [trainingPreferences.primaryGoal] + trainingPreferences.secondaryGoals
            : trainingPreferences.goals
        goals = Set(allGoals)
        experience = trainingPreferences.experience
        preferredSplit = trainingPreferences.preferredSplit
        workoutsPerWeek = trainingPreferences.workoutsPerWeek
        sessionLengthMinutes = trainingPreferences.sessionLengthMinutes
        intensity = trainingPreferences.preferredIntensity
        additionalNotes = trainingPreferences.styleNotes
    }
}

extension EquipmentProfileDraft {
    init(equipmentProfile: EquipmentProfile) {
        location = TrainingLocation(rawValue: equipmentProfile.location)
        equipment = Set(equipmentProfile.availableEquipment)
        additionalNotes = equipmentProfile.freeTextNotes.isEmpty
            ? equipmentProfile.notes
            : equipmentProfile.freeTextNotes
    }
}
