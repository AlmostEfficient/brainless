import SwiftUI

struct WorkoutPreviewView: View {
    let workout: GeneratedWorkout
    let onStart: () -> Void
    let onRegenerate: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                focusAreas
                exerciseList
                safetyNote
                actions
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(workout.title)
                .font(.largeTitle.bold())

            Text(workout.summary)
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                metric("\(workout.estimatedDurationMinutes) min", systemImage: "clock")
                metric(workout.intensity, systemImage: "bolt")
            }
        }
    }

    private var focusAreas: some View {
        FlowLayout(spacing: 8) {
            ForEach(workout.focusAreas, id: \.self) { focusArea in
                Text(focusArea)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
            }
        }
    }

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.title3.bold())

            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, workoutExercise in
                WorkoutExerciseRow(index: index + 1, workoutExercise: workoutExercise)
            }
        }
    }

    private var safetyNote: some View {
        Label {
            Text(workout.safetyNote)
                .font(.subheadline)
        } icon: {
            Image(systemName: "exclamationmark.shield")
        }
        .foregroundStyle(.orange)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button(action: onStart) {
                Label("Start Workout", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(action: onRegenerate) {
                Label("Regenerate", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private func metric(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct WorkoutExerciseRow: View {
    let index: Int
    let workoutExercise: WorkoutExercise

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(index)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.accentColor, in: Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text(workoutExercise.catalogItem.name)
                    .font(.headline)

                Text("\(workoutExercise.targetSets) sets - \(workoutExercise.targetReps) - \(workoutExercise.restSeconds)s rest")
                    .font(.subheadline.weight(.medium))

                Text("\(workoutExercise.catalogItem.muscle.capitalized) - \(workoutExercise.catalogItem.equipment.capitalized)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let notes = workoutExercise.notes {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}


#Preview {
    NavigationStack {
        WorkoutPreviewView(
            workout: .sample,
            onStart: {},
            onRegenerate: {}
        )
    }
}
