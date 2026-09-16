import Foundation

// A fixed UI fixture; deliberately includes known media and a text-only exercise.
struct MockWorkoutGenerationService: WorkoutGenerationService {
    func generateWorkout(for request: WorkoutGenerationRequest) async throws -> GeneratedWorkout {
        var workout = GeneratedWorkout.sample
        workout.id = UUID()
        workout.generatedAt = Date()
        workout.estimatedDurationMinutes = request.requestedDurationMinutes ?? 45
        return try workout.validated()
    }
}
