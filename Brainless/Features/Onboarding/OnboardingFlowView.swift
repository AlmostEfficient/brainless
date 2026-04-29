//
//  OnboardingFlowView.swift
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

                    CompletionStepView(
                        isSaving: viewModel.isSaving,
                        goals: viewModel.trainingPreferences.goals,
                        split: viewModel.trainingPreferences.preferredSplit,
                        location: viewModel.equipmentProfile.location,
                        safety: viewModel.bodyContext.safetyPreference
                    )
                    .tag(OnboardingStep.completion)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                OnboardingFooter(
                    step: viewModel.step,
                    canContinue: viewModel.canContinue,
                    isSaving: viewModel.isSaving,
                    backAction: viewModel.goBack,
                    nextAction: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        Task { await viewModel.advance() }
                    }
                )
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Could not save profile", isPresented: $viewModel.showsSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.saveErrorMessage)
            }
        }
    }
}

// MARK: - ViewModel

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
        case .intro:              true
        case .bodyContext:        bodyContext.isComplete
        case .trainingPreferences: trainingPreferences.isComplete
        case .equipment:          equipmentProfile.isComplete
        case .completion:         !isSaving
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

// MARK: - Step Views

private struct IntroStepView: View {
    var body: some View {
        ProfileFormPage(title: "Built for the\nway you train.") {
            Text("Tell Brainless about your body, goals, and gear once. It generates every workout for you.")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 16) {
                FeatureBullet(systemImage: "figure.strengthtraining.traditional", text: "Workouts matched to your body")
                FeatureBullet(systemImage: "slider.horizontal.3", text: "Your equipment, your constraints")
                FeatureBullet(systemImage: "sparkles", text: "AI handles the programming")
            }
        }
    }
}

private struct BodyContextStepView: View {
    @Binding var draft: BodyContextDraft

    var body: some View {
        ProfileFormPage(title: "Your body.") {
            Text("Optional. Anything Brainless should work around.")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField(
                "Injuries, joint concerns, posture, limits",
                text: $draft.bodyNotes,
                axis: .vertical
            )
            .lineLimit(4...8)
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))

            FormSectionLabel("Safety approach")

            Picker("Safety approach", selection: $draft.safetyPreference) {
                Text("Standard").tag(SafetyPreference.standard)
                Text("Conservative").tag(SafetyPreference.conservative)
                Text("Very conservative").tag(SafetyPreference.veryConservative)
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct TrainingPreferencesStepView: View {
    @Binding var draft: TrainingPreferencesDraft

    var body: some View {
        ProfileFormPage(title: "Your training.") {
            FormSectionLabel("What are you training for?")
            FlowLayout(spacing: 8) {
                ForEach(FitnessGoal.allCases) { goal in
                    SelectionChip(
                        label: goal.displayName,
                        isSelected: draft.goals.contains(goal)
                    ) {
                        draft.goals = draft.goals.symmetricDifference([goal])
                    }
                }
            }

            FormSectionLabel("Experience level")
            Picker("Experience", selection: $draft.experience) {
                ForEach(TrainingExperience.allCases) { exp in
                    Text(exp.displayName).tag(exp)
                }
            }
            .pickerStyle(.segmented)

            FormSectionLabel("Preferred split")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(WorkoutSplit.allCases) { split in
                    SplitCard(split: split, isSelected: draft.preferredSplit == split) {
                        draft.preferredSplit = split
                    }
                }
            }

            InlineStepperView(label: "Days per week", value: $draft.workoutsPerWeek, range: 2...7)

            FormSectionLabel("Session length")
            Picker("Session length", selection: $draft.sessionLengthMinutes) {
                Text("30 min").tag(30)
                Text("45 min").tag(45)
                Text("60 min").tag(60)
                Text("90 min").tag(90)
            }
            .pickerStyle(.segmented)

            FormSectionLabel("Intensity")
            Picker("Intensity", selection: $draft.intensity) {
                ForEach(WorkoutIntensity.allCases) { intensity in
                    Text(intensity.displayName).tag(intensity)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct EquipmentProfileStepView: View {
    @Binding var draft: EquipmentProfileDraft

    var body: some View {
        ProfileFormPage(title: "Your gear.") {
            FormSectionLabel("Where do you train?")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(TrainingLocation.allCases) { location in
                    LocationCard(location: location, isSelected: draft.location == location) {
                        draft.location = draft.location == location ? nil : location
                    }
                }
            }

            FormSectionLabel("What do you have?")
            FlowLayout(spacing: 8) {
                ForEach(EquipmentType.allCases) { type in
                    SelectionChip(
                        label: type.displayName,
                        isSelected: draft.equipment.contains(type)
                    ) {
                        draft.equipment = draft.equipment.symmetricDifference([type])
                    }
                }
            }

            TextField("Any constraints? (optional)", text: $draft.additionalNotes, axis: .vertical)
                .lineLimit(2...4)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

private struct CompletionStepView: View {
    let isSaving: Bool
    let goals: Set<FitnessGoal>
    let split: WorkoutSplit
    let location: TrainingLocation?
    let safety: SafetyPreference

    var body: some View {
        ProfileFormPage(title: "You're set.") {
            Text("Brainless is ready to build workouts around you.")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            if isSaving {
                ProgressView("Saving")
                    .padding(.top, 8)
            } else {
                let goalsText = FitnessGoal.allCases
                    .filter { goals.contains($0) }
                    .map(\.displayName)
                    .joined(separator: ", ")

                VStack(spacing: 8) {
                    SummaryRow(label: "Goals", value: goalsText.isEmpty ? "—" : goalsText)
                    if split != .fullBody {
                        SummaryRow(label: "Split", value: split.displayName)
                    }
                    if let location {
                        SummaryRow(label: "Location", value: location.rawValue)
                    }
                    if safety != .standard {
                        SummaryRow(label: "Safety", value: safety.displayName)
                    }
                }
            }
        }
    }
}

// MARK: - Shared Step Components

struct ProfileFormPage<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(title)
                    .font(.largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 32)

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct FormSectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }
}

private struct FeatureBullet: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28, alignment: .center)
            Text(text)
                .font(.body)
        }
    }
}

private struct SplitCard: View {
    let split: WorkoutSplit
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(split.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

private struct LocationCard: View {
    let location: TrainingLocation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: location.systemImage)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                Text(location.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct OnboardingFooter: View {
    let step: OnboardingStep
    let canContinue: Bool
    let isSaving: Bool
    let backAction: () -> Void
    let nextAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 6) {
                ForEach(OnboardingStep.allCases, id: \.self) { s in
                    Circle()
                        .fill(s == step ? Color.accentColor : Color(.tertiaryLabel))
                        .frame(width: s == step ? 8 : 6, height: s == step ? 8 : 6)
                        .animation(.spring(response: 0.3), value: step)
                }
            }

            HStack(spacing: 12) {
                if step.previous != nil {
                    Button("Back", action: backAction)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(isSaving)
                }

                Button {
                    nextAction()
                } label: {
                    Group {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(step.primaryActionTitle)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canContinue || isSaving)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(.bar)
    }
}

#Preview {
    OnboardingFlowView(
        viewModel: OnboardingViewModel(saveProfile: { _, _, _ in })
    )
}
