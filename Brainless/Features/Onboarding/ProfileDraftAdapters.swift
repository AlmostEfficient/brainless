//
//  ProfileDraftAdapters.swift
//  Brainless
//

import Foundation

extension BodyContextDraft {
    init(bodyContext: UserBodyContext) {
        bodyNotes = bodyContext.bodyNotes.isEmpty ? bodyContext.injuriesOrLimitations.joined(separator: "\n") : bodyContext.bodyNotes
        jointConcerns = bodyContext.knownLimitations.joined(separator: "\n")
        postureAndMobility = bodyContext.postureConcerns.joined(separator: "\n")
        healthNotes = [
            bodyContext.painOrInjuryNotes,
            bodyContext.professionalGuidanceNotes
        ]
        .filter { !$0.trimmedForProfile.isEmpty }
        .joined(separator: "\n")
    }
}

extension TrainingPreferencesDraft {
    init(trainingPreferences: TrainingPreferences) {
        primaryGoals = trainingPreferences.primaryGoal.displayName
        trainingStyle = trainingPreferences.preferredSplit.displayName
        sessionLength = "\(trainingPreferences.sessionLengthMinutes)"
        weeklyFrequency = "\(trainingPreferences.workoutsPerWeek)"
        intensityPreference = trainingPreferences.preferredIntensity.displayName
        additionalNotes = trainingPreferences.secondaryGoals.map(\.displayName).joined(separator: ", ")
    }
}

extension EquipmentProfileDraft {
    init(equipmentProfile: EquipmentProfile) {
        trainingLocation = equipmentProfile.location
        availableEquipment = equipmentProfile.availableEquipment.map(\.displayName).joined(separator: ", ")
        missingEquipment = equipmentProfile.missingEquipment.joined(separator: ", ")
        additionalNotes = equipmentProfile.freeTextNotes.isEmpty ? equipmentProfile.notes : equipmentProfile.freeTextNotes
    }
}

extension UserBodyContext {
    init(draft: BodyContextDraft) {
        self.init(
            bodyNotes: draft.bodyNotes.trimmedForProfile,
            knownLimitations: draft.jointConcerns.profileLines,
            postureConcerns: draft.postureAndMobility.profileLines,
            painOrInjuryNotes: draft.healthNotes.trimmedForProfile,
            professionalGuidanceNotes: draft.healthNotes.trimmedForProfile,
            safetyPreference: draft.healthNotes.isEmpty ? .standard : .conservative,
            injuriesOrLimitations: [
                draft.jointConcerns,
                draft.postureAndMobility,
                draft.healthNotes
            ].flatMap { $0.profileLines }
        )
    }
}

extension TrainingPreferences {
    init(draft: TrainingPreferencesDraft) {
        let goals = FitnessGoal.matches(in: draft.primaryGoals + " " + draft.additionalNotes)
        let split = WorkoutSplit.match(in: draft.trainingStyle) ?? .custom
        let intensity = WorkoutIntensity.match(in: draft.intensityPreference) ?? .moderate

        self.init(
            goals: goals,
            preferredDurationMinutes: Int(draft.sessionLength.onlyDigits) ?? 45,
            styleNotes: draft.additionalNotes.trimmedForProfile,
            primaryGoal: goals.first ?? .generalFitness,
            secondaryGoals: Array(goals.dropFirst()),
            preferredSplit: split,
            workoutsPerWeek: Int(draft.weeklyFrequency.onlyDigits) ?? 3,
            sessionLengthMinutes: Int(draft.sessionLength.onlyDigits) ?? 45,
            preferredIntensity: intensity
        )
    }
}

extension EquipmentProfile {
    init(draft: EquipmentProfileDraft) {
        let equipment = EquipmentType.matches(in: draft.availableEquipment)
        let notes = [
            draft.trainingLocation,
            draft.missingEquipment,
            draft.additionalNotes
        ]
        .filter { !$0.trimmedForProfile.isEmpty }
        .joined(separator: "\n")

        self.init(
            location: draft.trainingLocation.trimmedForProfile,
            availableEquipment: equipment.isEmpty ? [.bodyweight] : equipment,
            missingEquipment: draft.missingEquipment.profileLines,
            freeTextNotes: draft.additionalNotes.trimmedForProfile,
            notes: notes
        )
    }
}

private extension String {
    var profileLines: [String] {
        components(separatedBy: .newlines)
            .map(\.trimmedForProfile)
            .filter { !$0.isEmpty }
    }

    var onlyDigits: String {
        filter(\.isNumber)
    }
}

private extension FitnessGoal {
    var displayName: String {
        switch self {
        case .strength: "Strength"
        case .hypertrophy: "Hypertrophy"
        case .endurance: "Endurance"
        case .fatLoss: "Fat loss"
        case .generalFitness: "General fitness"
        case .mobility: "Mobility"
        }
    }

    static func matches(in text: String) -> [FitnessGoal] {
        allCases.filter { text.localizedCaseInsensitiveContains($0.displayName) || text.localizedCaseInsensitiveContains($0.rawValue) }
    }
}

private extension WorkoutSplit {
    var displayName: String {
        switch self {
        case .fullBody: "Full body"
        case .upperLower: "Upper/lower"
        case .pushPullLegs: "Push/pull/legs"
        case .bodyPart: "Body part"
        case .custom: "Custom"
        }
    }

    static func match(in text: String) -> WorkoutSplit? {
        allCases.first { text.localizedCaseInsensitiveContains($0.displayName) || text.localizedCaseInsensitiveContains($0.rawValue) }
    }
}

private extension WorkoutIntensity {
    var displayName: String {
        switch self {
        case .easy: "Easy"
        case .moderate: "Moderate"
        case .hard: "Hard"
        }
    }

    static func match(in text: String) -> WorkoutIntensity? {
        allCases.first { text.localizedCaseInsensitiveContains($0.displayName) || text.localizedCaseInsensitiveContains($0.rawValue) }
    }
}

private extension EquipmentType {
    var displayName: String {
        switch self {
        case .bodyweight: "Bodyweight"
        case .dumbbells: "Dumbbells"
        case .barbell: "Barbell"
        case .kettlebell: "Kettlebell"
        case .resistanceBands: "Resistance bands"
        case .cableMachine: "Cable machine"
        case .machine: "Machine"
        case .bench: "Bench"
        case .pullUpBar: "Pull-up bar"
        case .cardioMachine: "Cardio machine"
        }
    }

    static func matches(in text: String) -> [EquipmentType] {
        allCases.filter { text.localizedCaseInsensitiveContains($0.displayName) || text.localizedCaseInsensitiveContains($0.rawValue) }
    }
}
