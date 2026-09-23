import Foundation

final class StreamProtocol: URLProtocol, @unchecked Sendable {
    static var payload = Data()
    static var truncate = false
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        precondition(request.value(forHTTPHeaderField: "Accept") == "text/event-stream")
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/event-stream"])!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.payload)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main
struct WorkoutStreamingChecks {
    @MainActor static func main() async throws {
        let response = try JSONDecoder.brainless.decode(WorkoutGenerationResponse.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        let workout = response.workout
        var metadata = workout
        metadata.exercises = []
        func event<T: Encodable>(_ name: String, _ object: T) throws -> String {
            "event: \(name)\ndata: \(String(decoding: try JSONEncoder.brainless.encode(object), as: UTF8.self))\n\n"
        }
        struct ExerciseEvent: Encodable { var exercise: WorkoutExercise; var index: Int }
        var wire = try event("workout", metadata)
        for (index, exercise) in workout.exercises.enumerated() { wire += try event("exercise", ExerciseEvent(exercise: exercise, index: index)) }
        let partialWire = wire
        wire += try event("complete", response)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StreamProtocol.self]
        let service = RemoteWorkoutGenerationService(apiClient: APIClient(session: URLSession(configuration: config)))
        let request = WorkoutGenerationRequest(bodyContext: .default, trainingPreferences: .default, equipmentProfile: .default)
        StreamProtocol.payload = Data(wire.utf8)
        var updates: [GeneratedWorkout] = []
        let result = try await service.streamWorkout(for: request) { updates.append($0) }
        precondition(result.isGenerationComplete)
        precondition(updates.count == workout.exercises.count + 1)
        precondition(updates[0].generationStatus == .generating && updates[0].exercises.count == 1)
        precondition(updates.last!.isGenerationComplete)
        precondition(updates.allSatisfy { $0.id == workout.id })
        StreamProtocol.payload = Data(partialWire.utf8)
        do { _ = try await service.streamWorkout(for: request) { _ in }; fatalError("Truncated stream accepted") }
        catch WorkoutGenerationError.requestFailed {}
        let note = "Keep the load conservative today."
        var exercise = workout.exercises[0]
        exercise.sessionNote = note
        precondition(exercise.executionNotes.hasPrefix(note))
        print("PASS: real URLSession stream decoding, incremental state, stable IDs, completion, truncation, session guidance")
    }
}
