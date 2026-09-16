import Foundation

struct TextWorkoutPlan: Encodable, Identifiable, Equatable, Hashable {
    var id: UUID
    var generatedAt: Date
    var message: String
    var title: String
    var summary: String
    var estimatedDurationMinutes: Int
    var intensity: String
    var sections: [TextWorkoutSection]
    var safetyNote: String
    var contextSummary: String
}

struct TextWorkoutSection: Encodable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var title: String
    var purpose: String
    var exercises: [TextWorkoutExercise]
}

struct TextWorkoutExercise: Encodable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var prescription: String
    var instructions: String
    var rest: String
    var notes: String = ""
    var asset: ExerciseAsset? = nil
}

extension TextWorkoutPlan {
    static let sample = TextWorkoutPlan(
        id: UUID(),
        generatedAt: Date(),
        message: "I kept this simple and biased toward clean reps.",
        title: "Upper Strength",
        summary: "A text-first upper-body workout with controlled pulling and pressing.",
        estimatedDurationMinutes: 45,
        intensity: "Moderate",
        sections: [
            TextWorkoutSection(
                title: "Main Work",
                purpose: "Build strength while keeping the session easy to follow.",
                exercises: [
                    TextWorkoutExercise(
                        name: "Chest-supported dumbbell row",
                        prescription: "4 sets x 8-10 reps",
                        instructions: "Keep your chest planted, pause at the top, and lower under control.",
                        rest: "Rest 90 seconds.",
                        notes: "Start with your weaker side."
                    ),
                    TextWorkoutExercise(
                        name: "Incline dumbbell press",
                        prescription: "3 sets x 8-12 reps",
                        instructions: "Use a moderate incline and stop each rep before your shoulders roll forward.",
                        rest: "Rest 90 seconds."
                    )
                ]
            )
        ],
        safetyNote: "Not medical advice. Stop any movement that causes sharp pain.",
        contextSummary: "Generated from today's request, equipment, and recent training."
    )
}

// The text screen is a presentation of the same workout, not a second API contract.
extension TextWorkoutPlan {
    init(workout: GeneratedWorkout) {
        id = workout.id
        generatedAt = workout.generatedAt
        message = workout.summary
        title = workout.title
        summary = workout.summary
        estimatedDurationMinutes = workout.estimatedDurationMinutes
        intensity = workout.intensity
        safetyNote = workout.safetyNote
        contextSummary = workout.generationContextSummary ?? ""
        sections = [TextWorkoutSection(title: workout.title, purpose: workout.summary, exercises: workout.exercises.map { exercise in
            var result = TextWorkoutExercise(id: exercise.id, name: exercise.name,
                prescription: "\(exercise.targetSets) sets × \(exercise.targetReps)",
                instructions: exercise.instructions, rest: "Rest \(exercise.restSeconds) seconds.", notes: exercise.formCues)
            result.asset = exercise.asset
            return result
        })]
    }
}
