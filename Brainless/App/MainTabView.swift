import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppSettingsRecord.updatedAt, order: .reverse) private var settingsRecords: [AppSettingsRecord]

    var body: some View {
        TabView {
            HomeView(
                service: workoutGenerationService,
                catalogService: exerciseCatalogService,
                assetURLBuilder: exerciseAssetURLBuilder,
                userProfileStore: userProfileStore,
                trainingPreferencesStore: trainingPreferencesStore,
                equipmentProfileStore: equipmentProfileStore,
                historyService: historyService
            )
            .tabItem {
                Label("Today", systemImage: "house.fill")
            }

            HistoryListView(historyService: historyService)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }

            SettingsView(
                viewModel: SettingsViewModel(
                    loadSettings: loadSettingsSnapshot,
                    saveSettings: saveSettingsSnapshot
                )
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }

    private var userProfileStore: UserProfileStore {
        SwiftDataUserProfileStore(modelContext: modelContext)
    }

    private var trainingPreferencesStore: TrainingPreferencesStore {
        SwiftDataTrainingPreferencesStore(modelContext: modelContext)
    }

    private var equipmentProfileStore: EquipmentProfileStore {
        SwiftDataEquipmentProfileStore(modelContext: modelContext)
    }

    private var historyService: WorkoutHistoryService {
        SwiftDataWorkoutHistoryService(modelContext: modelContext)
    }

    private var appSettings: AppSettings {
        dependencies.appStateStore.loadSettings(settingsRecords.first)
    }

    private var apiClient: APIClient {
        APIClient(
            baseURL: URL(string: appSettings.backendBaseURL) ?? dependencies.backendBaseURL,
            tokenProvider: StaticAPITokenProvider(token: appSettings.apiToken)
        )
    }

    private var workoutGenerationService: WorkoutGenerationService {
        if appSettings.useRemoteWorkoutGeneration {
            RemoteWorkoutGenerationService(apiClient: apiClient)
        } else {
            UnavailableWorkoutGenerationService()
        }
    }

    private var exerciseCatalogService: ExerciseCatalogService {
        RemoteExerciseCatalogService(apiClient: apiClient)
    }

    private var exerciseAssetURLBuilder: ExerciseAssetURLBuilder {
        ExerciseAssetURLBuilder(
            assetsBaseURL: URL(string: appSettings.assetsBaseURL) ?? URL(string: "https://assets.raza.run")!
        )
    }

    private func loadSettingsSnapshot() async throws -> SettingsSnapshot {
        let settings = appSettings
        return SettingsSnapshot(
            bodyContext: BodyContextDraft(bodyContext: try userProfileStore.loadBodyContext()),
            trainingPreferences: TrainingPreferencesDraft(trainingPreferences: try trainingPreferencesStore.loadTrainingPreferences()),
            equipmentProfile: EquipmentProfileDraft(equipmentProfile: try equipmentProfileStore.loadEquipmentProfile()),
            backendBaseURL: settings.backendBaseURL,
            assetsBaseURL: settings.assetsBaseURL,
            apiToken: settings.apiToken,
            useRemoteWorkoutGeneration: settings.useRemoteWorkoutGeneration
        )
    }

    private func saveSettingsSnapshot(_ snapshot: SettingsSnapshot) async throws {
        try userProfileStore.saveBodyContext(UserBodyContext(draft: snapshot.bodyContext))
        try trainingPreferencesStore.saveTrainingPreferences(TrainingPreferences(draft: snapshot.trainingPreferences))
        try equipmentProfileStore.saveEquipmentProfile(EquipmentProfile(draft: snapshot.equipmentProfile))

        var settings = appSettings
        settings.backendBaseURL = snapshot.backendBaseURL
        settings.assetsBaseURL = snapshot.assetsBaseURL
        settings.apiToken = snapshot.apiToken
        settings.useRemoteWorkoutGeneration = snapshot.useRemoteWorkoutGeneration

        let record = settingsRecords.first ?? AppSettingsRecord()
        record.jsonData = try dependencies.appStateStore.makeSettingsData(settings)
        record.updatedAt = .now

        if settingsRecords.isEmpty {
            modelContext.insert(record)
        }

        try modelContext.save()
    }
}

#Preview {
    MainTabView()
}
