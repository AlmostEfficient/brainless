//
//  OnboardingView.swift
//  Brainless
//

import SwiftUI

struct OnboardingFlowView: View {
    @State private var viewModel: OnboardingViewModel

    init(viewModel: OnboardingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    init(
        userProfileStore: UserProfileStore,
        trainingPreferencesStore: TrainingPreferencesStore,
        equipmentProfileStore: EquipmentProfileStore,
        onCompleted: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: OnboardingViewModel(
                userProfileStore: userProfileStore,
                trainingPreferencesStore: trainingPreferencesStore,
                equipmentProfileStore: equipmentProfileStore,
                onCompleted: onCompleted
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $viewModel.step) {
                    IntroStepView()
                        .tag(OnboardingStep.intro)

                    BodyContextStepView(draft: $viewModel.bodyContext)
                        .tag(OnboardingStep.bodyContext)

                    TrainingPreferencesStepView(draft: $viewModel.trainingPreferences)
                        .tag(OnboardingStep.trainingPreferences)

                    EquipmentProfileStepView(draft: $viewModel.equipmentProfile)
                        .tag(OnboardingStep.equipment)

                    CompletionStepView(isSaving: viewModel.isSaving)
                        .tag(OnboardingStep.completion)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                OnboardingFooter(
                    step: viewModel.step,
                    canContinue: viewModel.canContinue,
                    isSaving: viewModel.isSaving,
                    backAction: viewModel.goBack,
                    nextAction: {
                        Task {
                            await viewModel.advance()
                        }
                    }
                )
            }
            .navigationTitle("Set up profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Could not save profile", isPresented: $viewModel.showsSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.saveErrorMessage)
            }
        }
    }
}

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
    private let onCompleted: () -> Void

    init(
        saveProfile: @escaping @MainActor (BodyContextDraft, TrainingPreferencesDraft, EquipmentProfileDraft) async throws -> Void,
        onCompleted: @escaping () -> Void = {}
    ) {
        self.saveProfile = saveProfile
        self.onCompleted = onCompleted
    }

    init(
        userProfileStore: UserProfileStore,
        trainingPreferencesStore: TrainingPreferencesStore,
        equipmentProfileStore: EquipmentProfileStore,
        onCompleted: @escaping () -> Void = {}
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
        case .intro:
            true
        case .bodyContext:
            bodyContext.isComplete
        case .trainingPreferences:
            trainingPreferences.isComplete
        case .equipment:
            equipmentProfile.isComplete
        case .completion:
            !isSaving
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
            onCompleted()
        } catch {
            saveErrorMessage = error.localizedDescription
            showsSaveError = true
        }
    }
}

enum OnboardingStep: Int, CaseIterable {
    case intro
    case bodyContext
    case trainingPreferences
    case equipment
    case completion

    var previous: OnboardingStep? {
        Self(rawValue: rawValue - 1)
    }

    var next: OnboardingStep? {
        Self(rawValue: rawValue + 1)
    }

    var primaryActionTitle: String {
        switch self {
        case .completion:
            "Save"
        default:
            "Continue"
        }
    }
}

private struct IntroStepView: View {
    var body: some View {
        ProfileFormPage(title: "Tell Brainless what matters") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your long-term body context, goals, and equipment constraints help shape each generated workout.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("Brainless is not medical advice. Use your judgment, avoid movements that feel unsafe, and follow guidance from qualified clinicians when you have pain, injuries, or medical conditions.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct BodyContextStepView: View {
    @Binding var draft: BodyContextDraft

    var body: some View {
        ProfileFormPage(title: "Body context") {
            ProfileTextField(title: "Relevant body notes", text: $draft.bodyNotes, prompt: "Weak joints, imbalances, recurring tightness, pain triggers")
            ProfileTextField(title: "Joint concerns", text: $draft.jointConcerns, prompt: "Knees, shoulders, wrists, lower back")
            ProfileTextField(title: "Posture and mobility", text: $draft.postureAndMobility, prompt: "Nerd neck, tight hips, pelvic tilt, ankle mobility")
            ProfileTextField(title: "Health or physio notes", text: $draft.healthNotes, prompt: "Optional summaries you want workouts to respect")
        }
    }
}

private struct TrainingPreferencesStepView: View {
    @Binding var draft: TrainingPreferencesDraft

    var body: some View {
        ProfileFormPage(title: "Training preferences") {
            ProfileTextField(title: "Primary goals", text: $draft.primaryGoals, prompt: "Strength, hypertrophy, mobility, corrective work")
            ProfileTextField(title: "Training style", text: $draft.trainingStyle, prompt: "Push/pull/legs, full body, athletic, bodybuilding")
            ProfileTextField(title: "Session length", text: $draft.sessionLength, prompt: "30 minutes, 45 minutes, under an hour")
            ProfileTextField(title: "Weekly frequency", text: $draft.weeklyFrequency, prompt: "3 days per week, weekdays only")
            ProfileTextField(title: "Intensity preference", text: $draft.intensityPreference, prompt: "Moderate, hard but joint-friendly, low impact")
            ProfileTextField(title: "Additional notes", text: $draft.additionalNotes, prompt: "Exercises you like, avoid, or want prioritized")
        }
    }
}

private struct EquipmentProfileStepView: View {
    @Binding var draft: EquipmentProfileDraft

    var body: some View {
        ProfileFormPage(title: "Equipment") {
            ProfileTextField(title: "Training location", text: $draft.trainingLocation, prompt: "Home, commercial gym, apartment gym")
            ProfileTextField(title: "Available equipment", text: $draft.availableEquipment, prompt: "Dumbbells, cable machine, bench, bands")
            ProfileTextField(title: "Missing equipment", text: $draft.missingEquipment, prompt: "No barbell, no squat rack, no pull-up bar")
            ProfileTextField(title: "Additional notes", text: $draft.additionalNotes, prompt: "Space limits, noisy movements to avoid")
        }
    }
}

private struct CompletionStepView: View {
    let isSaving: Bool

    var body: some View {
        ProfileFormPage(title: "Ready to train") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Save this profile to personalize generated workouts and keep future settings editable.")
                    .foregroundStyle(.secondary)

                if isSaving {
                    ProgressView("Saving")
                }
            }
        }
    }
}

struct ProfileFormPage<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(title)
                    .font(.largeTitle.bold())
                    .padding(.top, 24)

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            TextField(prompt, text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
}

private struct OnboardingFooter: View {
    let step: OnboardingStep
    let canContinue: Bool
    let isSaving: Bool
    let backAction: () -> Void
    let nextAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(step.rawValue + 1), total: Double(OnboardingStep.allCases.count))

            HStack(spacing: 12) {
                Button("Back", action: backAction)
                    .buttonStyle(.bordered)
                    .disabled(step.previous == nil || isSaving)

                Button(step.primaryActionTitle, action: nextAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canContinue || isSaving)
            }
        }
        .padding(20)
        .background(.bar)
    }
}

#Preview {
    OnboardingFlowView(
        viewModel: OnboardingViewModel(saveProfile: { _, _, _ in })
    )
}
