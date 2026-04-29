import Foundation

enum WorkoutGenerationError: LocalizedError, Equatable {
    case emptyWorkout
    case invalidDuration
    case missingExerciseCatalogItem
    case duplicateExercise(String)
    case unavailableEquipment(String)
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyWorkout:
            "The generated workout did not include any exercises."
        case .invalidDuration:
            "The generated workout has an invalid duration."
        case .missingExerciseCatalogItem:
            "One or more exercises are missing catalog information."
        case .duplicateExercise(let exerciseID):
            "The generated workout repeated exercise \(exerciseID)."
        case .unavailableEquipment(let equipment):
            "The generated workout includes unavailable equipment: \(equipment)."
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

    func validated(against request: WorkoutGenerationRequest) throws -> GeneratedWorkout {
        let workout = try validated()
        let allowedCatalogIDs = Set(request.exerciseCatalog.map(\.id))
        let availableEquipment = Set(request.equipmentProfile.availableEquipment.flatMap(\.catalogEquipmentAliases))
        var seenExerciseIDs = Set<String>()

        for exercise in workout.exercises {
            let exerciseID = exercise.catalogItem.id
            guard allowedCatalogIDs.contains(exerciseID) else {
                throw WorkoutGenerationError.missingExerciseCatalogItem
            }

            guard !seenExerciseIDs.contains(exerciseID) else {
                throw WorkoutGenerationError.duplicateExercise(exerciseID)
            }
            seenExerciseIDs.insert(exerciseID)

            if !availableEquipment.isEmpty {
                let exerciseEquipment = Set(exercise.catalogItem.equipment.catalogEquipmentAliases)
                guard !exerciseEquipment.isDisjoint(with: availableEquipment) else {
                    throw WorkoutGenerationError.unavailableEquipment(exercise.catalogItem.equipment)
                }
            }
        }

        return workout
    }
}

private extension EquipmentType {
    var catalogEquipmentAliases: [String] {
        switch self {
        case .bodyweight:
            ["bodyweight", "body weight"]
        case .dumbbells:
            ["dumbbells", "dumbbell"]
        case .barbell:
            ["barbell"]
        case .kettlebell:
            ["kettlebell"]
        case .resistanceBands:
            ["resistanceBands", "resistance band", "band"]
        case .cableMachine:
            ["cableMachine", "cable"]
        case .machine:
            ["machine", "leverage machine", "smith machine"]
        case .bench:
            ["bench", "body weight"]
        case .pullUpBar:
            ["pullUpBar", "pull-up bar", "body weight"]
        case .cardioMachine:
            ["cardioMachine", "stationary bike", "elliptical machine", "skierg machine"]
        }
    }
}

private extension String {
    var catalogEquipmentAliases: [String] {
        switch trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "bodyweight", "body weight":
            ["bodyweight", "body weight"]
        case "dumbbells", "dumbbell":
            ["dumbbells", "dumbbell"]
        case "resistancebands", "resistance band", "band":
            ["resistanceBands", "resistance band", "band"]
        case "cablemachine", "cable":
            ["cableMachine", "cable"]
        case "pullupbar", "pull-up bar":
            ["pullUpBar", "pull-up bar", "body weight"]
        case "leverage machine", "smith machine", "machine":
            ["machine", "leverage machine", "smith machine"]
        case "stationary bike", "elliptical machine", "skierg machine":
            ["cardioMachine", "stationary bike", "elliptical machine", "skierg machine"]
        default:
            [trimmingCharacters(in: .whitespacesAndNewlines)]
        }
    }
}
