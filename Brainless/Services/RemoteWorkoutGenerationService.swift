import Foundation

struct RemoteWorkoutGenerationService: WorkoutGenerationService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) { self.apiClient = apiClient }

    func generateWorkout(for request: WorkoutGenerationRequest) async throws -> GeneratedWorkout {
        try await streamWorkout(for: request, onUpdate: { _ in })
    }

    func streamWorkout(for request: WorkoutGenerationRequest, onUpdate: @escaping @MainActor (GeneratedWorkout) -> Void) async throws -> GeneratedWorkout {
        var partial: GeneratedWorkout?
        var completed: GeneratedWorkout?
        struct ExerciseEvent: Decodable { var exercise: WorkoutExercise; var index: Int }
        try await apiClient.stream("/generate-workout", body: request) { event, data in
            switch event {
            case "workout":
                partial = try JSONDecoder.brainless.decode(GeneratedWorkout.self, from: data)
                partial?.generationStatus = .generating
            case "exercise":
                let next = try JSONDecoder.brainless.decode(ExerciseEvent.self, from: data)
                guard var workout = partial, next.index == workout.exercises.count else { throw WorkoutGenerationError.invalidWorkout }
                workout.exercises.append(next.exercise)
                _ = try workout.validated()
                partial = workout
                await onUpdate(workout)
            case "complete":
                var workout = try JSONDecoder.brainless.decode(WorkoutGenerationResponse.self, from: data).workout.validated()
                workout.generationStatus = .complete
                completed = workout
                await onUpdate(workout)
            case "error":
                throw WorkoutGenerationError.requestFailed("Generation stopped. Received exercises are available, but the workout is incomplete.")
            default: break
            }
        }
        guard let completed else { throw WorkoutGenerationError.requestFailed("Workout stream ended before completion.") }
        return completed
    }
}
