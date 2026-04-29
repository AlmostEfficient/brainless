import Foundation

enum WorkoutGenerationError: LocalizedError, Equatable {
    case emptyWorkout
    case invalidDuration
    case missingExerciseCatalogItem
    case transportUnavailable
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyWorkout:
            "The generated workout did not include any exercises."
        case .invalidDuration:
            "The generated workout has an invalid duration."
        case .missingExerciseCatalogItem:
            "One or more exercises are missing catalog information."
        case .transportUnavailable:
            "Workout generation is not connected yet."
        case .requestFailed(let message):
            message
        }
    }
}

protocol WorkoutGenerationService {
    func generateWorkout(for request: WorkoutGenerationRequest) async throws -> GeneratedWorkout
}

extension GeneratedWorkout {
    func validated() throws -> GeneratedWorkout {
        guard estimatedDurationMinutes > 0 else {
            throw WorkoutGenerationError.invalidDuration
        }

        guard exercises.isEmpty == false else {
            throw WorkoutGenerationError.emptyWorkout
        }

        let hasInvalidExercise = exercises.contains { workoutExercise in
            workoutExercise.catalogItem.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            workoutExercise.catalogItem.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard hasInvalidExercise == false else {
            throw WorkoutGenerationError.missingExerciseCatalogItem
        }

        return self
    }
}
