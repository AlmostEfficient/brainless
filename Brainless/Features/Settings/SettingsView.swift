//
//  SettingsView.swift
//  Brainless
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

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
                Section("Body context") {
                    ProfileTextField(title: "Relevant body notes", text: $viewModel.bodyContext.bodyNotes, prompt: "Weak joints, imbalances, recurring tightness")
                    ProfileTextField(title: "Joint concerns", text: $viewModel.bodyContext.jointConcerns, prompt: "Knees, shoulders, wrists, lower back")
                    ProfileTextField(title: "Posture and mobility", text: $viewModel.bodyContext.postureAndMobility, prompt: "Nerd neck, tight hips, pelvic tilt")
                    ProfileTextField(title: "Health or physio notes", text: $viewModel.bodyContext.healthNotes, prompt: "Optional summaries")
                }

                Section("Training preferences") {
                    ProfileTextField(title: "Primary goals", text: $viewModel.trainingPreferences.primaryGoals, prompt: "Strength, hypertrophy, mobility")
                    ProfileTextField(title: "Training style", text: $viewModel.trainingPreferences.trainingStyle, prompt: "Push/pull/legs, full body")
                    ProfileTextField(title: "Session length", text: $viewModel.trainingPreferences.sessionLength, prompt: "45 minutes")
                    ProfileTextField(title: "Weekly frequency", text: $viewModel.trainingPreferences.weeklyFrequency, prompt: "3 days per week")
                    ProfileTextField(title: "Intensity preference", text: $viewModel.trainingPreferences.intensityPreference, prompt: "Moderate, joint-friendly")
                    ProfileTextField(title: "Additional notes", text: $viewModel.trainingPreferences.additionalNotes, prompt: "Exercises to prioritize or avoid")
                }

                Section("Equipment") {
                    ProfileTextField(title: "Training location", text: $viewModel.equipmentProfile.trainingLocation, prompt: "Home, commercial gym")
                    ProfileTextField(title: "Available equipment", text: $viewModel.equipmentProfile.availableEquipment, prompt: "Dumbbells, bench, bands")
                    ProfileTextField(title: "Missing equipment", text: $viewModel.equipmentProfile.missingEquipment, prompt: "No barbell, no squat rack")
                    ProfileTextField(title: "Additional notes", text: $viewModel.equipmentProfile.additionalNotes, prompt: "Space or noise constraints")
                }

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
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await viewModel.save()
                        }
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
            .task {
                await viewModel.load()
            }
            .alert("Settings error", isPresented: $viewModel.showsError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

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
