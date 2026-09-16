import Foundation

@main
struct WorkoutContractChecks {
    static func main() throws {
        let decoder = JSONDecoder.brainless
        let request = WorkoutGenerationRequest(
            bodyContext: .sample,
            trainingPreferences: .sample,
            equipmentProfile: .sample,
            workoutIntent: "A short full-body session",
            requestedDurationMinutes: 10
        )
        let requestData = try JSONEncoder.brainless.encode(request)
        let encodedRequest = try JSONSerialization.jsonObject(with: requestData) as! [String: Any]
        let expectedKeys: [String: Set<String>] = [
            "bodyContext": ["bodyNotes", "safetyPreference"],
            "trainingPreferences": ["goals", "styleNotes", "experience", "preferredSplit", "workoutsPerWeek"],
            "equipmentProfile": ["location", "availableEquipment", "notes"]
        ]
        for (key, expected) in expectedKeys {
            precondition(Set((encodedRequest[key] as! [String: Any]).keys) == expected)
        }
        try requestData.write(to: URL(fileURLWithPath: "/tmp/brainless-current-request.json"))
        for path in CommandLine.arguments.dropFirst() {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let workout = try decoder.decode(WorkoutGenerationResponse.self, from: data).workout.validated()
            precondition(!workout.exercises.isEmpty)
            let text = TextWorkoutPlan(workout: workout)
            precondition(text.sections[0].exercises.map(\.id) == workout.exercises.map(\.id))
            precondition(text.sections[0].exercises.map(\.instructions) == workout.exercises.map(\.instructions))
            var session = WorkoutSession.sample
            session.workout = workout
            let saved = try JSONEncoder.brainless.encode(session)
            let restored = try decoder.decode(WorkoutSession.self, from: saved)
            precondition(restored.workout.exercises == workout.exercises)
            precondition(restored.workout.id == workout.id)

            // Broken, absent and null metadata must not affect text or validation.
            for asset in [nil, NSNull(), ["assetID": 5], ["assetID": "../invalid"]] as [Any?] {
                var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                var rawWorkout = object["workout"] as! [String: Any]
                var rawExercises = rawWorkout["exercises"] as! [[String: Any]]
                for i in rawExercises.indices { rawExercises[i]["asset"] = asset }
                rawWorkout["exercises"] = rawExercises
                object["workout"] = rawWorkout
                let modified = try JSONSerialization.data(withJSONObject: object)
                let result = try decoder.decode(WorkoutGenerationResponse.self, from: modified).workout.validated()
                precondition(result.exercises.map(\.name) == workout.exercises.map(\.name))
                precondition(result.exercises.allSatisfy { ExerciseAssetURLBuilder().gifURL(for: $0.asset?.assetID) == nil })
            }
            print("PASS: decode, validate, presentation adapter, persistence, invalid/absent media: \(path)")
        }
        precondition(ExerciseAssetURLBuilder().gifURL(for: nil) == nil)
        precondition(ExerciseAssetURLBuilder().gifURL(for: "I4hDWkc")?.absoluteString == "https://assets.raza.run/exercises/gifs/I4hDWkc.gif")
        var repeated = GeneratedWorkout.sample
        var another = repeated.exercises[0]
        another.id = UUID()
        repeated.exercises.append(another)
        _ = try repeated.validated()
        repeated.exercises[1].id = repeated.exercises[0].id
        do { _ = try repeated.validated(); fatalError("Expected duplicate occurrence ID failure") }
        catch WorkoutGenerationError.invalidWorkout {}
        var invalid = GeneratedWorkout.sample
        invalid.exercises[0].instructions = ""
        do { _ = try invalid.validated(); fatalError("Expected validation failure") }
        catch WorkoutGenerationError.invalidWorkout {}
    }
}
