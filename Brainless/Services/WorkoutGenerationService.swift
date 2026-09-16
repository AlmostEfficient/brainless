import Foundation

enum WorkoutGenerationError: LocalizedError, Equatable {
    case invalidWorkout
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidWorkout: "The generated workout has an incomplete exercise or invalid prescription. Please try again."
        case .requestFailed(let message): message
        }
    }
}

protocol WorkoutGenerationService {
    func generateWorkout(for request: WorkoutGenerationRequest) async throws -> GeneratedWorkout
}

extension GeneratedWorkout {
    func validated() throws -> GeneratedWorkout {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              (1...360).contains(estimatedDurationMinutes),
              (1...40).contains(exercises.count),
              Set(exercises.map(\.id)).count == exercises.count else {
            throw WorkoutGenerationError.invalidWorkout
        }
        for exercise in exercises {
            guard [exercise.name, exercise.instructions, exercise.targetReps].allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
                  (1...50).contains(exercise.targetSets),
                  (0...3600).contains(exercise.restSeconds),
                  exercise.durationSeconds.map({ (1...86400).contains($0) }) ?? true else {
                throw WorkoutGenerationError.invalidWorkout
            }
        }
        return self
    }
}
