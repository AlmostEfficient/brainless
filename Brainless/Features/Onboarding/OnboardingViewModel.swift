import Foundation
import Observation

// MARK: - ViewModel

@MainActor
@Observable
final class OnboardingViewModel {
    var step: OnboardingStep = .intro
    var bodyContext = BodyContextDraft()
    var trainingPreferences = TrainingPreferencesDraft()
    var equipmentProfile = EquipmentProfileDraft()
    var isSaving = false
    var showsSaveError = false
    var saveErrorMessage = ""

    private let saveProfile: @MainActor (BodyContextDraft, TrainingPreferencesDraft, EquipmentProfileDraft) async throws -> Void
    private let onCompleted: () throws -> Void

    init(
        saveProfile: @escaping @MainActor (BodyContextDraft, TrainingPreferencesDraft, EquipmentProfileDraft) async throws -> Void,
        onCompleted: @escaping () throws -> Void = {}
    ) {
        self.saveProfile = saveProfile
        self.onCompleted = onCompleted
    }

    init(
        userProfileStore: UserProfileStore,
        trainingPreferencesStore: TrainingPreferencesStore,
        equipmentProfileStore: EquipmentProfileStore,
        onCompleted: @escaping () throws -> Void = {}
    ) {
        self.saveProfile = { bodyContext, trainingPreferences, equipmentProfile in
            try userProfileStore.saveBodyContext(UserBodyContext(draft: bodyContext))
            try trainingPreferencesStore.saveTrainingPreferences(TrainingPreferences(draft: trainingPreferences))
            try equipmentProfileStore.saveEquipmentProfile(EquipmentProfile(draft: equipmentProfile))
        }
        self.onCompleted = onCompleted
    }

    var canContinue: Bool {
        switch step {
        case .intro:              true
        case .bodyContext:        bodyContext.isComplete
        case .trainingPreferences: trainingPreferences.isComplete
        case .equipment:          equipmentProfile.isComplete
        case .completion:         bodyContext.isComplete && trainingPreferences.isComplete && equipmentProfile.isComplete && !isSaving
        }
    }

    func selectStep(_ target: OnboardingStep) {
        guard !isSaving else { return }
        if target.rawValue < step.rawValue || (target == step.next && canContinue) {
            step = target
        }
    }

    func goBack() {
        guard let previousStep = step.previous, !isSaving else { return }
        step = previousStep
    }

    func advance() async {
        guard canContinue, !isSaving else { return }
        if step == .completion {
            await complete()
            return
        }
        if let nextStep = step.next {
            step = nextStep
        }
    }

    private func complete() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await saveProfile(bodyContext, trainingPreferences, equipmentProfile)
            try onCompleted()
        } catch {
            saveErrorMessage = error.localizedDescription
            showsSaveError = true
        }
    }
}

// MARK: - Step Enum

enum OnboardingStep: Int, CaseIterable {
    case intro
    case bodyContext
    case trainingPreferences
    case equipment
    case completion

    var previous: OnboardingStep? { Self(rawValue: rawValue - 1) }
    var next: OnboardingStep? { Self(rawValue: rawValue + 1) }

    var primaryActionTitle: String {
        switch self {
        case .completion: "Let's go"
        default:          "Continue"
        }
    }
}

