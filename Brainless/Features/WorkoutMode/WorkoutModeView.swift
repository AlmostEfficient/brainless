import SwiftUI
import Combine

struct WorkoutModeView: View {
    @Binding var workout: GeneratedWorkout
    var assetURLBuilder: ExerciseAssetURLBuilder = ExerciseAssetURLBuilder()
    var onRegenerate: (String) -> Void = { _ in }
    var isRegenerating: Bool = false
    var onSaveCompleted: (WorkoutSession) -> Void = { _ in }
    var onSavePartial: (WorkoutSession) -> Void = { _ in }
    var onDiscard: () -> Void = {}

    @State private var startedAt = Date()
    @State private var skippedExerciseIDs: Set<UUID> = []
    @State private var loggedSetsByExercise: [UUID: [LoggedSet]] = [:]
    @State private var restEndsAt: Date?
    @State private var restNow = Date()
    @State private var isFinishSheetPresented = false
    @State private var regenerationGuidance = ""
    @State private var currentTab: WorkoutHorizontalTab = .exercises

    private let restTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let pageHeight = geo.size.height
            ZStack(alignment: .top) {
                if workout.exercises.isEmpty {
                    ContentUnavailableView("No Exercises", systemImage: "figure.strengthtraining.traditional")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical) {
                            VStack(spacing: 0) {
                                OverviewPage(
                                    workout: workout,
                                    isRegenerating: isRegenerating,
                                    regenerationGuidance: $regenerationGuidance,
                                    onRegenerate: { onRegenerate(regenerationGuidance) },
                                    onStart: {
                                        if let firstID = workout.exercises.first?.id {
                                            withAnimation(.easeInOut(duration: 0.35)) {
                                                proxy.scrollTo(firstID, anchor: .top)
                                            }
                                        }
                                    }
                                )
                                .frame(width: geo.size.width, height: pageHeight)
                                .id(WorkoutScrollTarget.overview)

                                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                                    ExercisePage(
                                        exercise: exercise,
                                        assetURLBuilder: assetURLBuilder,
                                        position: index + 1,
                                        total: workout.exercises.count,
                                        isSkipped: skippedExerciseIDs.contains(exercise.id),
                                        loggedSets: loggedSetsByExercise[exercise.id, default: []],
                                        restRemaining: restRemaining,
                                        onLogSet: { logSet(for: exercise, draft: $0) },
                                        onDeleteSet: { deleteSet($0, from: exercise) },
                                        onSkip: { skip(exercise, scrollProxy: proxy) },
                                        onStartRest: { startRest(seconds: exercise.restSeconds) }
                                    )
                                    .frame(width: geo.size.width, height: pageHeight)
                                    .id(exercise.id)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.paging)
                        .scrollIndicators(.hidden)
                        .scrollBounceBehavior(.basedOnSize)
                        .ignoresSafeArea(edges: .bottom)
                    }
                }

                header
            }
        }
        .background(Color(.systemBackground))
        .onChange(of: workout.id) { _, _ in
            startedAt = Date()
            skippedExerciseIDs = []
            loggedSetsByExercise = [:]
            restEndsAt = nil
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
            .presentationDragIndicator(.visible)
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

    private func skip(_ exercise: WorkoutExercise, scrollProxy: ScrollViewProxy) {
        if skippedExerciseIDs.contains(exercise.id) {
            skippedExerciseIDs.remove(exercise.id)
        } else {
            skippedExerciseIDs.insert(exercise.id)
            scrollToNext(after: exercise, proxy: scrollProxy)
        }
    }

    private func scrollToNext(after exercise: WorkoutExercise, proxy: ScrollViewProxy) {
        guard let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        let nextIndex = workout.exercises.index(after: index)
        guard workout.exercises.indices.contains(nextIndex) else { return }
        let nextID = workout.exercises[nextIndex].id
        withAnimation(.easeInOut(duration: 0.25)) {
            proxy.scrollTo(nextID, anchor: .top)
        }
    }

    private func startRest(seconds: Int) {
        restNow = Date()
        restEndsAt = Date().addingTimeInterval(TimeInterval(max(seconds, 1)))
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

private struct OverviewPage: View {
    let workout: GeneratedWorkout
    let isRegenerating: Bool
    @Binding var regenerationGuidance: String
    let onRegenerate: () -> Void
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 56)

            Text(workout.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.85)

            Text(metaLine)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let line = workout.generationContextSummary, !line.isEmpty {
                Text(line)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            exercisePreviewList

            TextField("Change anything?", text: $regenerationGuidance, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...3)
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))

            Button(action: onStart) {
                Label("Start Workout", systemImage: "play.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(action: onRegenerate) {
                HStack(spacing: 8) {
                    if isRegenerating {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isRegenerating ? "Regenerating…" : "Regenerate")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(isRegenerating)

            Spacer()
            Label("Not medical advice", systemImage: "exclamationmark.shield.fill")
                .font(.caption2)
                .foregroundStyle(.orange.opacity(0.9))
                .padding(.bottom, 28)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var metaLine: String {
        "\(workout.exercises.count) moves · \(workout.estimatedDurationMinutes) min · \(workout.intensity)"
    }

    private var exercisePreviewList: some View {
        VStack(spacing: 8) {
            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 20, alignment: .trailing)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(exercise.catalogItem.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text("\(exercise.targetSets)x \(exercise.targetReps) · \(exercise.catalogItem.equipment)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ExercisePage: View {
    let exercise: WorkoutExercise
    let assetURLBuilder: ExerciseAssetURLBuilder
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
        GeometryReader { geo in
            let visualH = min(geo.size.width * 0.75, geo.size.height * 0.28)
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 68)

                ExerciseVisualView(exerciseID: exercise.catalogItem.id, assetURLBuilder: assetURLBuilder)
                    .frame(height: visualH)
                    .frame(maxWidth: .infinity)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(exercise.catalogItem.name)
                        .font(.title2.weight(.bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 8)
                    Text("\(position)/\(total)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if isSkipped {
                        Image(systemName: "forward.end.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.top, 8)

                Text(prescriptionLine)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.top, 2)

                RestTimerBlock(restRemaining: restRemaining, restSeconds: exercise.restSeconds, onStartRest: onStartRest)
                    .padding(.top, 6)

                if let note = primaryNote, !note.isEmpty {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }

                Spacer(minLength: 4)

                CompactLoggingBlock(
                    draftSet: $draftSet,
                    loggedSets: loggedSets,
                    onLogSet: {
                        onLogSet(draftSet)
                        draftSet = DraftLoggedSet()
                    },
                    onDeleteSet: onDeleteSet
                )

                Button(role: isSkipped ? .cancel : nil, action: onSkip) {
                    Label(isSkipped ? "Undo Skip" : "Skip", systemImage: isSkipped ? "arrow.uturn.backward" : "forward.end")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .padding(.top, 6)

                Text("Not medical advice — stop for pain or dizziness.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(Color(.systemBackground))
    }

    private var prescriptionLine: String {
        "\(exercise.targetSets)× · \(exercise.targetReps) · \(exercise.restSeconds)s rest"
    }

    private var primaryNote: String? {
        if let c = exercise.coachingNote, !c.isEmpty { return c }
        return exercise.notes
    }
}

private struct RestTimerBlock: View {
    let restRemaining: Int?
    let restSeconds: Int
    let onStartRest: () -> Void

    var body: some View {
        HStack {
            Label(restText, systemImage: "timer")
                .font(.subheadline.weight(.semibold).monospacedDigit())
            Spacer()
            Button("Rest", action: onStartRest)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var restText: String {
        if let restRemaining {
            return "\(restRemaining)s"
        }
        return "\(restSeconds)s"
    }
}

private struct CompactLoggingBlock: View {
    @Binding var draftSet: DraftLoggedSet
    let loggedSets: [LoggedSet]
    let onLogSet: () -> Void
    let onDeleteSet: (LoggedSet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                NumberField(title: "Reps", value: $draftSet.reps)
                DecimalField(title: "Kg", value: $draftSet.weightKilograms)
                NumberField(title: "RPE", value: $draftSet.perceivedExertion)

                Button(action: onLogSet) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(draftSet.isEmpty)
                .accessibilityLabel("Log set")
            }

            ForEach(loggedSets) { set in
                HStack {
                    Text("#\(set.setNumber)")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text(set.summary)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Button(role: .destructive) {
                        onDeleteSet(set)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
            }
            if loggedSets.count > 4 {
                Text("+\(loggedSets.count - 4) more")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
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
            .frame(maxWidth: 68)
    }
}

private struct DecimalField: View {
    let title: String
    @Binding var value: Double?

    var body: some View {
        TextField(title, value: $value, format: .number)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 68)
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
            .navigationTitle("Finish")
            .navigationBarTitleDisplayMode(.large)
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

private enum WorkoutScrollTarget: Hashable {
    case overview
}

#Preview {
    WorkoutModeView(workout: .constant(.sample))
}
