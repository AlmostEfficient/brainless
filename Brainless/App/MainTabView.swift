import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            HomeView(
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
                userProfileStore: userProfileStore,
                trainingPreferencesStore: trainingPreferencesStore,
                equipmentProfileStore: equipmentProfileStore
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
}

#Preview {
    MainTabView()
}
