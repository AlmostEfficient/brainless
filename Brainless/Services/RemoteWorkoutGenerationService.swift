import Foundation

struct RemoteWorkoutGenerationService: WorkoutGenerationService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func generateWorkout(for request: WorkoutGenerationRequest) async throws -> GeneratedWorkout {
        let response: WorkoutGenerationResponse = try await apiClient.post("/generate-workout", body: request)
        return try response.workout.validated()
    }
}

private extension APIClient {
    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        let pathComponent = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appending(path: pathComponent)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WorkoutGenerationError.requestFailed("Workout generation returned an invalid response.")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw WorkoutGenerationError.requestFailed("Workout generation failed with status \(httpResponse.statusCode).")
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw WorkoutGenerationError.requestFailed("Workout generation returned data this app could not read.")
        }
    }
}
