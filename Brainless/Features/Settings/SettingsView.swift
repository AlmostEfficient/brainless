//
//  SettingsView.swift
//  Brainless
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    #if DEBUG
    @Environment(\.modelContext) private var modelContext
    @State private var showingResetConfirmation = false
    #endif

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    init(
        userProfileStore: UserProfileStore,
        trainingPreferencesStore: TrainingPreferencesStore,
        equipmentProfileStore: EquipmentProfileStore,
        backendBaseURL: String = "https://nexus.raza.run/v1",
        assetsBaseURL: String = "https://assets.raza.run",
        apiToken: String = ""
    ) {
        self.init(
            viewModel: SettingsViewModel(
                userProfileStore: userProfileStore,
                trainingPreferencesStore: trainingPreferencesStore,
                equipmentProfileStore: equipmentProfileStore,
                backendBaseURL: backendBaseURL,
                assetsBaseURL: assetsBaseURL,
                apiToken: apiToken
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                bodyContextSection
                goalsSection
                trainingSection
                equipmentSection
                apiSection
                #if DEBUG
                debugSection
                #endif
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await viewModel.save() }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                }
            }
            .task { await viewModel.load() }
            .alert("Settings error", isPresented: $viewModel.showsError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    private var bodyContextSection: some View {
        Section("Body context") {
            TextField(
                "Injuries, joint concerns, posture, limits (optional)",
                text: $viewModel.bodyContext.bodyNotes,
                axis: .vertical
            )
            .lineLimit(3...6)

            Picker("Safety approach", selection: $viewModel.bodyContext.safetyPreference) {
                Text("Standard").tag(SafetyPreference.standard)
                Text("Conservative").tag(SafetyPreference.conservative)
                Text("Very conservative").tag(SafetyPreference.veryConservative)
            }
        }
    }

    private var goalsSection: some View {
        Section("Goals") {
            FlowLayout(spacing: 8) {
                ForEach(FitnessGoal.allCases) { goal in
                    SelectionChip(
                        label: goal.displayName,
                        isSelected: viewModel.trainingPreferences.goals.contains(goal)
                    ) {
                        viewModel.trainingPreferences.goals =
                            viewModel.trainingPreferences.goals.symmetricDifference([goal])
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        }
    }

    private var trainingSection: some View {
        Section("Training") {
            Picker("Experience", selection: $viewModel.trainingPreferences.experience) {
                ForEach(TrainingExperience.allCases) { exp in
                    Text(exp.displayName).tag(exp)
                }
            }

            Picker("Split", selection: $viewModel.trainingPreferences.preferredSplit) {
                ForEach(WorkoutSplit.allCases) { split in
                    Text(split.displayName).tag(split)
                }
            }

            InlineStepperView(
                label: "Days per week",
                value: $viewModel.trainingPreferences.workoutsPerWeek,
                range: 2...7
            )

            TextField("Additional notes (optional)", text: $viewModel.trainingPreferences.additionalNotes, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    private var equipmentSection: some View {
        Section("Equipment") {
            Picker("Location", selection: $viewModel.equipmentProfile.location) {
                Text("Not set").tag(Optional<TrainingLocation>.none)
                ForEach(TrainingLocation.allCases) { loc in
                    Text(loc.rawValue).tag(Optional(loc))
                }
            }

            FlowLayout(spacing: 8) {
                ForEach(EquipmentType.allCases) { type in
                    SelectionChip(
                        label: type.displayName,
                        isSelected: viewModel.equipmentProfile.equipment.contains(type)
                    ) {
                        viewModel.equipmentProfile.equipment =
                            viewModel.equipmentProfile.equipment.symmetricDifference([type])
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

            TextField("Any constraints? (optional)", text: $viewModel.equipmentProfile.additionalNotes, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    private var apiSection: some View {
        Section("API and assets") {
            TextField("Backend base URL", text: $viewModel.backendBaseURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)

            TextField("Assets base URL", text: $viewModel.assetsBaseURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)

            SecureField("API token", text: $viewModel.apiToken)
                .textInputAutocapitalization(.never)
        }
    }

    #if DEBUG
    private var debugSection: some View {
        Section("Debug") {
            Button("Reset app data", role: .destructive) {
                showingResetConfirmation = true
            }
        }
        .alert("Reset app data?", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive, action: resetAllData)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Deletes all profiles, history, and settings. You'll see onboarding again.")
        }
    }

    private func resetAllData() {
        try? modelContext.delete(model: AppSettingsRecord.self)
        try? modelContext.delete(model: UserProfileRecord.self)
        try? modelContext.delete(model: TrainingPreferencesRecord.self)
        try? modelContext.delete(model: EquipmentProfileRecord.self)
        try? modelContext.delete(model: WorkoutSessionRecord.self)
        try? modelContext.save()
    }
    #endif
}

// MARK: - ViewModel

@Observable
final class SettingsViewModel {
    var bodyContext = BodyContextDraft()
    var trainingPreferences = TrainingPreferencesDraft()
    var equipmentProfile = EquipmentProfileDraft()
    var backendBaseURL = "https://nexus.raza.run/v1"
    var assetsBaseURL = "https://assets.raza.run"
    var apiToken = ""
    var isLoading = false
    var isSaving = false
    var showsError = false
    var errorMessage = ""

    private let loadSettings: @MainActor () async throws -> SettingsSnapshot
    private let saveSettings: @MainActor (SettingsSnapshot) async throws -> Void

    init(
        loadSettings: @escaping @MainActor () async throws -> SettingsSnapshot,
        saveSettings: @escaping @MainActor (SettingsSnapshot) async throws -> Void
    ) {
        self.loadSettings = loadSettings
        self.saveSettings = saveSettings
    }

    init(
        userProfileStore: UserProfileStore,
        trainingPreferencesStore: TrainingPreferencesStore,
        equipmentProfileStore: EquipmentProfileStore,
        backendBaseURL: String = "https://nexus.raza.run/v1",
        assetsBaseURL: String = "https://assets.raza.run",
        apiToken: String = ""
    ) {
        self.loadSettings = {
            SettingsSnapshot(
                bodyContext: BodyContextDraft(bodyContext: try userProfileStore.loadBodyContext()),
                trainingPreferences: TrainingPreferencesDraft(trainingPreferences: try trainingPreferencesStore.loadTrainingPreferences()),
                equipmentProfile: EquipmentProfileDraft(equipmentProfile: try equipmentProfileStore.loadEquipmentProfile()),
                backendBaseURL: backendBaseURL,
                assetsBaseURL: assetsBaseURL,
                apiToken: apiToken
            )
        }
        self.saveSettings = { snapshot in
            try userProfileStore.saveBodyContext(UserBodyContext(draft: snapshot.bodyContext))
            try trainingPreferencesStore.saveTrainingPreferences(TrainingPreferences(draft: snapshot.trainingPreferences))
            try equipmentProfileStore.saveEquipmentProfile(EquipmentProfile(draft: snapshot.equipmentProfile))
        }
    }

    var canSave: Bool {
        bodyContext.isComplete && trainingPreferences.isComplete && equipmentProfile.isComplete
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let snapshot = try await loadSettings()
            bodyContext = snapshot.bodyContext
            trainingPreferences = snapshot.trainingPreferences
            equipmentProfile = snapshot.equipmentProfile
            backendBaseURL = snapshot.backendBaseURL
            assetsBaseURL = snapshot.assetsBaseURL
            apiToken = snapshot.apiToken
        } catch {
            show(error)
        }
    }

    func save() async {
        guard canSave, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await saveSettings(currentSnapshot)
        } catch {
            show(error)
        }
    }

    private var currentSnapshot: SettingsSnapshot {
        SettingsSnapshot(
            bodyContext: bodyContext,
            trainingPreferences: trainingPreferences,
            equipmentProfile: equipmentProfile,
            backendBaseURL: backendBaseURL.trimmedForProfile,
            assetsBaseURL: assetsBaseURL.trimmedForProfile,
            apiToken: apiToken.trimmedForProfile
        )
    }

    private func show(_ error: Error) {
        errorMessage = error.localizedDescription
        showsError = true
    }
}

struct SettingsSnapshot: Equatable {
    var bodyContext: BodyContextDraft
    var trainingPreferences: TrainingPreferencesDraft
    var equipmentProfile: EquipmentProfileDraft
    var backendBaseURL: String
    var assetsBaseURL: String
    var apiToken: String

    static let empty = SettingsSnapshot(
        bodyContext: BodyContextDraft(),
        trainingPreferences: TrainingPreferencesDraft(),
        equipmentProfile: EquipmentProfileDraft(),
        backendBaseURL: "https://nexus.raza.run/v1",
        assetsBaseURL: "https://assets.raza.run",
        apiToken: ""
    )
}

#Preview {
    SettingsView(
        viewModel: SettingsViewModel(
            loadSettings: { .empty },
            saveSettings: { _ in }
        )
    )
}
