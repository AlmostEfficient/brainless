import SwiftUI
import Combine

struct WorkoutModeView: View {
    let workout: GeneratedWorkout
    var onSaveCompleted: (WorkoutSession) -> Void = { _ in }
    var onSavePartial: (WorkoutSession) -> Void = { _ in }
    var onDiscard: () -> Void = {}

    @State private var selectedExerciseID: UUID?
    @State private var startedAt = Date()
    @State private var skippedExerciseIDs: Set<UUID> = []
    @State private var loggedSetsByExercise: [UUID: [LoggedSet]] = [:]
    @State private var restEndsAt: Date?
    @State private var restNow = Date()
    @State private var isFinishSheetPresented = false

    private let restTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            if workout.exercises.isEmpty {
                ContentUnavailableView("No Exercises", systemImage: "figure.strengthtraining.traditional")
            } else {
                TabView(selection: $selectedExerciseID) {
                    ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExercisePage(
                            exercise: exercise,
                            position: index + 1,
                            total: workout.exercises.count,
                            isSkipped: skippedExerciseIDs.contains(exercise.id),
                            loggedSets: loggedSetsByExercise[exercise.id, default: []],
                            restRemaining: restRemaining,
                            onLogSet: { logSet(for: exercise, draft: $0) },
                            onDeleteSet: { deleteSet($0, from: exercise) },
                            onSkip: { skip(exercise) },
                            onStartRest: { startRest(seconds: exercise.restSeconds) }
                        )
                        .tag(Optional(exercise.id))
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }

            header
        }
        .onAppear {
            selectedExerciseID = selectedExerciseID ?? workout.exercises.first?.id
        }
        .onReceive(restTicker) { restNow = $0 }
        .sheet(isPresented: $isFinishSheetPresented) {
            FinishWorkoutSheet(
                loggedSetCount: loggedSetsByExercise.values.reduce(0) { $0 + $1.count },
                skippedCount: skippedExerciseIDs.count,
                onSaveCompleted: {
                    onSaveCompleted(buildSession(status: .completed))
                    isFinishSheetPresented = false
                },
                onSavePartial: {
                    onSavePartial(buildSession(status: .inProgress))
                    isFinishSheetPresented = false
                },
                onDiscard: {
                    onDiscard()
                    isFinishSheetPresented = false
                }
            )
            .presentationDetents([.medium])
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(headerDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                isFinishSheetPresented = true
            } label: {
                Label("Finish", systemImage: "checkmark.circle.fill")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    private var headerDetail: String {
        let focus = workout.focus.prefix(2).map(\.displayName).joined(separator: ", ")
        return focus.isEmpty ? "\(workout.estimatedDurationMinutes) min" : "\(workout.estimatedDurationMinutes) min • \(focus)"
    }

    private var restRemaining: Int? {
        guard let restEndsAt else { return nil }
        let remaining = Int(ceil(restEndsAt.timeIntervalSince(restNow)))
        return remaining > 0 ? remaining : nil
    }

    private func logSet(for exercise: WorkoutExercise, draft: DraftLoggedSet) {
        let nextSetNumber = (loggedSetsByExercise[exercise.id]?.count ?? 0) + 1
        let loggedSet = LoggedSet(
            id: UUID(),
            workoutExerciseID: exercise.id,
            setNumber: nextSetNumber,
            reps: draft.reps ?? 0,
            weightKilograms: draft.weightKilograms,
            completedAt: Date(),
            perceivedExertion: draft.perceivedExertion
        )
        loggedSetsByExercise[exercise.id, default: []].append(loggedSet)
    }

    private func deleteSet(_ set: LoggedSet, from exercise: WorkoutExercise) {
        loggedSetsByExercise[exercise.id, default: []].removeAll { $0.id == set.id }
    }

    private func skip(_ exercise: WorkoutExercise) {
        if skippedExerciseIDs.contains(exercise.id) {
            skippedExerciseIDs.remove(exercise.id)
        } else {
            skippedExerciseIDs.insert(exercise.id)
        }
        advance(after: exercise)
    }

    private func startRest(seconds: Int) {
        restNow = Date()
        restEndsAt = Date().addingTimeInterval(TimeInterval(max(seconds, 1)))
    }

    private func advance(after exercise: WorkoutExercise) {
        guard let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        let nextIndex = workout.exercises.index(after: index)
        if workout.exercises.indices.contains(nextIndex) {
            withAnimation { selectedExerciseID = workout.exercises[nextIndex].id }
        }
    }

    private func buildSession(status: WorkoutCompletionStatus) -> WorkoutSession {
        WorkoutSession(
            id: UUID(),
            workout: workout,
            startedAt: startedAt,
            completedAt: Date(),
            status: status,
            loggedSets: loggedSetsByExercise.values.flatMap { $0 }.sorted { $0.completedAt < $1.completedAt },
            notes: skippedExerciseIDs.isEmpty ? nil : "Skipped \(skippedExerciseIDs.count) exercise(s)."
        )
    }
}

private struct ExercisePage: View {
    let exercise: WorkoutExercise
    let position: Int
    let total: Int
    let isSkipped: Bool
    let loggedSets: [LoggedSet]
    let restRemaining: Int?
    let onLogSet: (DraftLoggedSet) -> Void
    let onDeleteSet: (LoggedSet) -> Void
    let onSkip: () -> Void
    let onStartRest: () -> Void

    @State private var draftSet = DraftLoggedSet()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ExerciseVisualView(exerciseID: exercise.catalogItem.id)
                    .frame(height: 300)
                    .padding(.top, 78)

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(position) of \(total)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(exercise.catalogItem.name)
                            .font(.largeTitle.weight(.bold))
                            .lineLimit(3)
                    }
                    Spacer()
                    if isSkipped {
                        Image(systemName: "forward.end.fill")
                            .foregroundStyle(.orange)
                    }
                }

                PrescriptionBlock(exercise: exercise)
                NotesBlock(title: "Coaching", systemImage: "lightbulb", text: exercise.notes)
                NotesBlock(title: "Safety", systemImage: "exclamationmark.shield", text: "Not medical advice. Stop for pain, dizziness, or unusual symptoms, and get professional guidance for injuries or medical conditions.")
                NotesBlock(title: "Substitution", systemImage: "arrow.triangle.2.circlepath", text: "Swap for a similar \(exercise.catalogItem.muscle.displayName.lowercased()) movement using available equipment if this does not fit today.")

                RestTimerBlock(restRemaining: restRemaining, restSeconds: exercise.restSeconds, onStartRest: onStartRest)

                LoggingBlock(
                    draftSet: $draftSet,
                    loggedSets: loggedSets,
                    onLogSet: {
                        onLogSet(draftSet)
                        draftSet = DraftLoggedSet()
                    },
                    onDeleteSet: onDeleteSet
                )

                Button(role: isSkipped ? .cancel : nil, action: onSkip) {
                    Label(isSkipped ? "Undo Skip" : "Skip Exercise", systemImage: isSkipped ? "arrow.uturn.backward" : "forward.end")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 36)
        }
        .background(Color(.systemBackground))
    }
}

private struct PrescriptionBlock: View {
    let exercise: WorkoutExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Prescription", systemImage: "list.clipboard")
                .font(.headline)

            HStack(spacing: 10) {
                MetricPill(title: "Sets", value: "\(exercise.targetSets)")
                MetricPill(title: "Reps", value: exercise.targetReps)
                MetricPill(title: "Muscle", value: exercise.catalogItem.muscle.displayName)
                MetricPill(title: "Rest", value: "\(exercise.restSeconds)s")
            }
        }
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct NotesBlock: View {
    let title: String
    let systemImage: String
    let text: String?

    var body: some View {
        if let text, !text.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                Text(text)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct RestTimerBlock: View {
    let restRemaining: Int?
    let restSeconds: Int
    let onStartRest: () -> Void

    var body: some View {
        HStack {
            Label(restText, systemImage: "timer")
                .font(.headline.monospacedDigit())
            Spacer()
            Button("Start Rest", action: onStartRest)
                .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var restText: String {
        if let restRemaining {
            return "\(restRemaining)s rest"
        }
        return "\(restSeconds)s planned rest"
    }
}

private struct LoggingBlock: View {
    @Binding var draftSet: DraftLoggedSet
    let loggedSets: [LoggedSet]
    let onLogSet: () -> Void
    let onDeleteSet: (LoggedSet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Optional logging", systemImage: "square.and.pencil")
                .font(.headline)

            HStack(spacing: 10) {
                NumberField(title: "Reps", value: $draftSet.reps)
                DecimalField(title: "Kg", value: $draftSet.weightKilograms)
                NumberField(title: "RPE", value: $draftSet.perceivedExertion)
            }

            Button(action: onLogSet) {
                Label("Log Set", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(draftSet.isEmpty)

            ForEach(loggedSets) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(set.summary)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Button(role: .destructive) {
                        onDeleteSet(set)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}

private struct NumberField: View {
    let title: String
    @Binding var value: Int?

    var body: some View {
        TextField(title, value: $value, format: .number)
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
    }
}

private struct DecimalField: View {
    let title: String
    @Binding var value: Double?

    var body: some View {
        TextField(title, value: $value, format: .number)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
    }
}

private struct FinishWorkoutSheet: View {
    let loggedSetCount: Int
    let skippedCount: Int
    let onSaveCompleted: () -> Void
    let onSavePartial: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Finish workout")
                    .font(.title.bold())

                Text("\(loggedSetCount) logged sets • \(skippedCount) skipped")
                    .foregroundStyle(.secondary)

                VStack(spacing: 10) {
                    Button(action: onSaveCompleted) {
                        Label("Save Completed", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: onSavePartial) {
                        Label("Save Partial", systemImage: "tray.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive, action: onDiscard) {
                        Label("Discard", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)

                Spacer()
            }
            .padding(20)
        }
    }
}

private struct DraftLoggedSet {
    var reps: Int?
    var weightKilograms: Double?
    var perceivedExertion: Int?

    var isEmpty: Bool {
        reps == nil && weightKilograms == nil && perceivedExertion == nil
    }
}

private extension LoggedSet {
    var summary: String {
        var parts: [String] = ["\(reps) reps"]
        if let weightKilograms { parts.append("\(weightKilograms.formatted(.number.precision(.fractionLength(0...1)))) kg") }
        if let perceivedExertion { parts.append("RPE \(perceivedExertion)") }
        return parts.joined(separator: " • ")
    }
}

private extension String {
    var displayName: String {
        replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

#Preview {
    WorkoutModeView(workout: .sample)
}
