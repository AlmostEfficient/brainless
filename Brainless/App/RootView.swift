import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppSettingsRecord.updatedAt, order: .reverse) private var settingsRecords: [AppSettingsRecord]

    var body: some View {
        if dependencies.appStateStore.isOnboardingComplete(settings: settingsRecords.first) {
            MainTabView()
        } else {
            OnboardingFlowView(
                userProfileStore: SwiftDataUserProfileStore(modelContext: modelContext),
                trainingPreferencesStore: SwiftDataTrainingPreferencesStore(modelContext: modelContext),
                equipmentProfileStore: SwiftDataEquipmentProfileStore(modelContext: modelContext),
                onCompleted: completeOnboarding
            )
        }
    }

    private func completeOnboarding() throws {
        let record = settingsRecords.first ?? AppSettingsRecord()
        var settings = dependencies.appStateStore.loadSettings(record)
        settings.isOnboardingComplete = true
        record.jsonData = try dependencies.appStateStore.makeSettingsData(settings)
        record.updatedAt = .now

        if settingsRecords.isEmpty {
            modelContext.insert(record)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

}

#Preview {
    RootView()
        .modelContainer(for: [
            AppSettingsRecord.self,
            UserProfileRecord.self,
            TrainingPreferencesRecord.self,
            EquipmentProfileRecord.self,
            WorkoutSessionRecord.self,
        ], inMemory: true)
}
