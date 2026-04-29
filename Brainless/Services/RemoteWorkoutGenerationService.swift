import Foundation

struct RemoteWorkoutGenerationService: WorkoutGenerationService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func generateWorkout(for request: WorkoutGenerationRequest) async throws -> GeneratedWorkout {
        let response: WorkoutGenerationResponse = try await apiClient.post("/generate-workout", body: request)
        return try response.workout.validated(against: request)
    }
}
