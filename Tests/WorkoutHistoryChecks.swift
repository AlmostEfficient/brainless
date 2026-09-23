import Foundation
import SwiftData

@main
struct WorkoutHistoryChecks {
    @MainActor
    static func main() throws {
        let schema = Schema([WorkoutSessionRecord.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let store = SwiftDataWorkoutHistoryService(modelContext: container.mainContext)
        let now = Date()
        var completed = WorkoutSession.sample
        completed.completedAt = now.addingTimeInterval(-3 * 86400)
        completed.startedAt = completed.completedAt!.addingTimeInterval(-1800)
        completed.loggedSets = [LoggedSet(id: UUID(), workoutExerciseID: completed.workout.exercises[0].id, setNumber: 1, reps: 12, weightKilograms: 20, completedAt: completed.completedAt!, perceivedExertion: 7)]
        try store.saveSession(completed)
        var partial = completed
        partial.id = UUID()
        partial.status = .inProgress
        partial.completedAt = now.addingTimeInterval(-86400)
        partial.startedAt = partial.completedAt!.addingTimeInterval(-600)
        partial.notes = "Stopped early; not all prescribed sets performed"
        partial.skippedExerciseIDs = [partial.workout.exercises[1].id]
        try store.saveSession(partial)
        let history = try store.historySummary(referenceDate: now)
        precondition(history.totalCompletedWorkouts == 1)
        precondition(history.recentWorkouts.count == 2)
        let recent = history.recentWorkouts[0]
        precondition(recent.status == .inProgress && recent.notes == partial.notes)
        precondition(recent.exerciseDetails[0].loggedSets[0].weightKilograms == 20)
        precondition(recent.exerciseDetails[0].loggedSets[0].perceivedExertion == 7)
        precondition(recent.exerciseDetails[1].skipped && recent.exerciseDetails[1].loggedSets.isEmpty)
        precondition(history.referenceDate == now)
        let request = WorkoutGenerationRequest(bodyContext: .sample, trainingPreferences: .sample, equipmentProfile: .sample, requestedIntensity: .hard, historySummary: history)
        let data = try JSONEncoder.brainless.encode(request)
        try data.write(to: URL(fileURLWithPath: "/tmp/brainless-history-request.json"))
        let restored = try JSONDecoder.brainless.decode(WorkoutGenerationRequest.self, from: data)
        precondition(restored.requestedIntensity == .hard)
        precondition(restored.historySummary!.recentWorkouts[0].exerciseDetails == recent.exerciseDetails)
        print("PASS: actual/partial history, skipped exercises, loads, effort, feedback, reference time and explicit intensity reach the request")
    }
}
