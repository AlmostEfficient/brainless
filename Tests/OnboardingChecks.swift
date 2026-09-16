import Foundation
import SwiftData

@main
struct OnboardingChecks {
    @MainActor
    static func main() async throws {
        let schema = Schema([UserProfileRecord.self, TrainingPreferencesRecord.self, EquipmentProfileRecord.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let bodyStore = SwiftDataUserProfileStore(modelContext: container.mainContext)
        let trainingStore = SwiftDataTrainingPreferencesStore(modelContext: container.mainContext)
        let equipmentStore = SwiftDataEquipmentProfileStore(modelContext: container.mainContext)
        var completed = false
        let model = OnboardingViewModel(userProfileStore: bodyStore, trainingPreferencesStore: trainingStore, equipmentProfileStore: equipmentStore, onCompleted: { completed = true })

        await model.advance()
        model.bodyContext.bodyNotes = " Prefer low-impact movements. "
        model.bodyContext.safetyPreference = .conservative
        await model.advance()
        precondition(model.step == .trainingPreferences)
        model.selectStep(.equipment)
        precondition(model.step == .trainingPreferences, "Swiping must not bypass required goals")
        model.trainingPreferences.goals = [.strength]
        model.trainingPreferences.workoutsPerWeek = 4
        await model.advance()
        model.selectStep(.completion)
        precondition(model.step == .equipment, "Swiping must not bypass equipment context")
        model.equipmentProfile.location = .home
        model.equipmentProfile.equipment = [.bodyweight, .dumbbells]
        model.equipmentProfile.additionalNotes = " No bench. "
        await model.advance()
        precondition(model.step == .completion)
        await model.advance()
        precondition(completed && !model.isSaving && !model.showsSaveError)
        let savedBody = try bodyStore.loadBodyContext()
        let savedTraining = try trainingStore.loadTrainingPreferences()
        let savedEquipment = try equipmentStore.loadEquipmentProfile()
        precondition(savedBody.bodyNotes == "Prefer low-impact movements.")
        precondition(savedBody.safetyPreference == .conservative)
        precondition(savedTraining.goals == [.strength])
        precondition(savedTraining.workoutsPerWeek == 4)
        precondition(savedEquipment.notes == "No bench.")
        precondition(savedEquipment.availableEquipment == [.bodyweight, .dumbbells])

        var attempts = 0
        let failing = OnboardingViewModel(saveProfile: { _, _, _ in }, onCompleted: {
            attempts += 1
            if attempts == 1 { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot save settings"]) }
        })
        failing.step = .completion
        await failing.advance()
        precondition(attempts == 0, "Completion must validate the entire profile")
        failing.trainingPreferences.goals = [.mobility]
        failing.equipmentProfile.equipment = [.bodyweight]
        await failing.advance()
        precondition(failing.showsSaveError && failing.saveErrorMessage == "Cannot save settings" && !failing.isSaving)
        failing.showsSaveError = false
        await failing.advance()
        precondition(attempts == 2 && !failing.isSaving)
        print("PASS: onboarding navigation, required choices, SwiftData persistence, save-error recovery")
    }
}
