import Foundation

struct MockWorkoutGenerationService: WorkoutGenerationService {
    private let delayNanoseconds: UInt64

    init(delayNanoseconds: UInt64 = 450_000_000) {
        self.delayNanoseconds = delayNanoseconds
    }

    func generateWorkout(for request: WorkoutGenerationRequest) async throws -> GeneratedWorkout {
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        switch request.trainingPreferences.primaryGoal {
        case .mobility:
            return try mobilityWorkout(request: request).validated()
        case .strength, .hypertrophy:
            return try strengthWorkout(request: request).validated()
        default:
            return try balancedWorkout(request: request).validated()
        }
    }

    private func balancedWorkout(request: WorkoutGenerationRequest) -> GeneratedWorkout {
        GeneratedWorkout(
            title: "Balanced Push-Pull Builder",
            focus: [.chest, .back, .quads, .core],
            estimatedDurationMinutes: request.trainingPreferences.sessionLengthMinutes,
            exercises: [
                WorkoutExercise(
                    catalogItem: ExerciseCatalogItem(id: "8N3J1K2", name: "Dumbbell Goblet Squat", muscle: "quads", equipment: "dumbbells"),
                    targetSets: 3,
                    targetReps: "8-10",
                    restSeconds: 75,
                    notes: "Keep the weight close and drive through the whole foot."
                ),
                WorkoutExercise(
                    catalogItem: ExerciseCatalogItem(id: "C4P9LQ7", name: "Push-Up", muscle: "chest", equipment: "bodyweight"),
                    targetSets: 3,
                    targetReps: "8-12",
                    restSeconds: 60,
                    notes: "Brace your ribs down and stop each rep with clean shoulder control."
                ),
                WorkoutExercise(
                    catalogItem: ExerciseCatalogItem(id: "F7R2T6B", name: "Band Seated Row", muscle: "back", equipment: "resistance bands"),
                    targetSets: 3,
                    targetReps: "10-12",
                    restSeconds: 60,
                    notes: "Pull elbows toward your pockets without shrugging."
                ),
                WorkoutExercise(
                    catalogItem: ExerciseCatalogItem(id: "P9K4W2M", name: "Forearm Plank", muscle: "core", equipment: "bodyweight"),
                    targetSets: 3,
                    targetReps: "30-40 sec",
                    restSeconds: 45,
                    notes: "Push the floor away and keep a straight line from shoulders to heels."
                )
            ],
            rationale: rationale(
                fallback: "A compact full-body session with simple equipment and steady pacing.",
                request: request
            )
        )
    }

    private func strengthWorkout(request: WorkoutGenerationRequest) -> GeneratedWorkout {
        GeneratedWorkout(
            title: "Simple Strength Session",
            focus: [.glutes, .back, .shoulders],
            estimatedDurationMinutes: max(request.trainingPreferences.sessionLengthMinutes, 45),
            exercises: [
                WorkoutExercise(catalogItem: ExerciseCatalogItem(id: "L5D8Q1S", name: "Barbell Romanian Deadlift", muscle: "hamstrings", equipment: "barbell"), targetSets: 4, targetReps: "6-8", restSeconds: 120, notes: "Hinge until hamstrings load, then stand tall without overextending."),
                WorkoutExercise(catalogItem: ExerciseCatalogItem(id: "A2M7P5C", name: "Dumbbell Shoulder Press", muscle: "shoulders", equipment: "dumbbells"), targetSets: 4, targetReps: "6-8", restSeconds: 105, notes: "Press slightly back so the weights finish over mid-foot."),
                WorkoutExercise(catalogItem: ExerciseCatalogItem(id: "R8T1H4V", name: "Assisted Pull-Up", muscle: "back", equipment: "pull-up bar"), targetSets: 3, targetReps: "5-8", restSeconds: 120, notes: "Start each pull by bringing shoulder blades down.")
            ],
            rationale: rationale(
                fallback: "A lower-rep workout focused on controlled compound patterns.",
                request: request
            )
        )
    }

    private func mobilityWorkout(request: WorkoutGenerationRequest) -> GeneratedWorkout {
        GeneratedWorkout(
            title: "Mobility Reset",
            focus: [.core, .shoulders, .glutes],
            estimatedDurationMinutes: min(request.trainingPreferences.sessionLengthMinutes, 30),
            exercises: [
                WorkoutExercise(catalogItem: ExerciseCatalogItem(id: "M1B6Z9K", name: "Cat Cow Stretch", muscle: "core", equipment: "bodyweight"), targetSets: 2, targetReps: "8 slow reps", restSeconds: 20, notes: "Move one vertebra at a time and breathe through each position."),
                WorkoutExercise(catalogItem: ExerciseCatalogItem(id: "H3C8N2D", name: "World Greatest Stretch", muscle: "glutes", equipment: "bodyweight"), targetSets: 2, targetReps: "5 each side", restSeconds: 30, notes: "Keep the back leg active while rotating through the upper back."),
                WorkoutExercise(catalogItem: ExerciseCatalogItem(id: "S6Q2A7J", name: "Band Shoulder Dislocates", muscle: "shoulders", equipment: "resistance bands"), targetSets: 2, targetReps: "10-12", restSeconds: 30, notes: "Widen your grip enough to keep the motion smooth.")
            ],
            rationale: rationale(
                fallback: "A low-impact reset for hips, shoulders, and trunk control.",
                request: request
            )
        )
    }

    private func rationale(fallback: String, request: WorkoutGenerationRequest) -> String {
        let equipmentNote = request.equipmentProfile.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard equipmentNote.isEmpty == false else {
            return fallback
        }

        return "\(fallback) Tuned for: \(equipmentNote)"
    }
}
