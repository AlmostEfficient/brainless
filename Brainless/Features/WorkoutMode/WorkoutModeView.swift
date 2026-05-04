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
            TabView(selection: $currentTab) {
                ZStack {
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
                                        },
                                        onDiscard: onDiscard
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
                                            onStartRest: { startRest(seconds: exercise.restSeconds) },
                                            onFinish: { isFinishSheetPresented = true }
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
                }
                .tag(WorkoutHorizontalTab.exercises)

                WorkoutManagementView(
                    workout: workout,
                    onFinish: { isFinishSheetPresented = true },
                    isRegenerating: isRegenerating,
                    regenerationGuidance: $regenerationGuidance,
                    onRegenerate: { onRegenerate(regenerationGuidance) },
                    onDismiss: { currentTab = .exercises }
                )
                .tag(WorkoutHorizontalTab.management)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(BrainlessTheme.bg.ignoresSafeArea())
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

// MARK: - OverviewPage

private struct OverviewPage: View {
    let workout: GeneratedWorkout
    let isRegenerating: Bool
    @Binding var regenerationGuidance: String
    let onRegenerate: () -> Void
    let onStart: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topChrome
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                overline
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)

                Text(workout.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(BrainlessTheme.ink)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                if let ctx = workout.generationContextSummary, !ctx.isEmpty {
                    contextBlock(ctx)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }

                statsStrip
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                exerciseList
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                bottomBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .background(BrainlessTheme.bg.ignoresSafeArea())
    }

    private var topChrome: some View {
        HStack {
            Button(action: onDiscard) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Close")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(BrainlessTheme.inkDim)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(BrainlessTheme.bgCard, in: Capsule())
                .overlay(Capsule().stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("PREVIEW")
                .font(.system(size: 11, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(BrainlessTheme.inkFaint)

            Spacer()

            Button {
            } label: {
                Text("···")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(BrainlessTheme.inkDim)
                    .frame(width: 36, height: 36)
                    .background(BrainlessTheme.bgCard, in: Circle())
                    .overlay(Circle().stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
    }

    private var overline: some View {
        Text("\(workout.intensity.uppercased()) · \(workout.exercises.count) EXERCISES")
            .font(.system(size: 11, design: .monospaced))
            .tracking(1.0)
            .foregroundStyle(BrainlessTheme.accent)
    }

    private func contextBlock(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(BrainlessTheme.accent)
                .frame(width: 3)
                .cornerRadius(2)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(BrainlessTheme.inkDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(BrainlessTheme.accentSoft, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.accent.opacity(0.15), lineWidth: 0.5))
    }

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statItem(value: "\(workout.estimatedDurationMinutes)", label: "MIN")
            statDivider
            statItem(value: "\(workout.exercises.count)", label: "EXERCISES")
            statDivider
            statItem(value: workout.intensity.uppercased().prefix(3).description, label: "EFFORT")
        }
        .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .semibold).monospacedDigit())
                .foregroundStyle(BrainlessTheme.ink)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(BrainlessTheme.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(BrainlessTheme.inkHair)
            .frame(width: 0.5)
            .padding(.vertical, 12)
    }

    private var exerciseList: some View {
        VStack(spacing: 8) {
            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                HStack(spacing: 12) {
                    Text(String(format: "%02d", index + 1))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(BrainlessTheme.accent)
                        .frame(width: 24, alignment: .leading)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(exercise.catalogItem.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BrainlessTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text("\(exercise.targetSets)× \(exercise.targetReps)  ·  \(exercise.restSeconds)s rest")
                            .font(.system(size: 11))
                            .foregroundStyle(BrainlessTheme.inkFaint)
                    }

                    Spacer(minLength: 8)

                    Text(exercise.catalogItem.equipment.uppercased().prefix(8).description)
                        .font(.system(size: 9, design: .monospaced))
                        .tracking(0.5)
                        .foregroundStyle(BrainlessTheme.inkFaint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(BrainlessTheme.surface2, in: Capsule())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                TextField("Or type changes…", text: $regenerationGuidance)
                    .font(.system(size: 14))
                    .foregroundStyle(BrainlessTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))

                Button(action: onRegenerate) {
                    ZStack {
                        if isRegenerating {
                            ProgressView().tint(BrainlessTheme.inkDim)
                        } else {
                            Image(systemName: "mic")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(BrainlessTheme.inkDim)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .disabled(isRegenerating)
            }

            Button(action: onStart) {
                HStack(spacing: 8) {
                    Text("Start Workout")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(BrainlessTheme.accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - ExercisePage

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
    let onFinish: () -> Void

    @State private var draftWeight: Double = 20.0
    @State private var draftReps: Int = 8

    var nextSetNumber: Int { loggedSets.count + 1 }

    var body: some View {
        GeometryReader { geo in
            let visualH = min(geo.size.width * 0.65, geo.size.height * 0.24)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 56)

                    ExerciseVisualView(exerciseID: exercise.catalogItem.id, assetURLBuilder: assetURLBuilder)
                        .frame(height: visualH)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 16)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(String(format: "%02d / %02d", position, total))
                                .font(.system(size: 11, design: .monospaced))
                                .tracking(0.8)
                                .foregroundStyle(BrainlessTheme.accent)

                            Text(exercise.catalogItem.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(BrainlessTheme.ink)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer(minLength: 8)
                        if isSkipped {
                            Image(systemName: "forward.end.fill")
                                .foregroundStyle(BrainlessTheme.accent.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)

                    Text(prescriptionLine)
                        .font(.system(size: 13))
                        .foregroundStyle(BrainlessTheme.inkFaint)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)

                    restTimerBlock
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)

                    if let note = primaryNote, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 13))
                            .foregroundStyle(BrainlessTheme.inkDim)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 14)
                    }

                    loggingCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)

                    if !loggedSets.isEmpty {
                        loggedSetsList
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                    }

                    HStack(spacing: 10) {
                        Button(role: isSkipped ? .cancel : nil, action: onSkip) {
                            Label(isSkipped ? "Undo Skip" : "Skip", systemImage: isSkipped ? "arrow.uturn.backward" : "forward.end")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(BrainlessTheme.inkDim)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)

                        Button(action: onFinish) {
                            Label("Finish", systemImage: "checkmark.circle")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(BrainlessTheme.inkDim)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                    Text("Not medical advice — stop for pain or dizziness.")
                        .font(.system(size: 11))
                        .foregroundStyle(BrainlessTheme.inkFaint.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(BrainlessTheme.bg.ignoresSafeArea())
    }

    private var prescriptionLine: String {
        "\(exercise.targetSets)\u{00D7} · \(exercise.targetReps) · \(exercise.restSeconds)s rest"
    }

    private var primaryNote: String? {
        if let c = exercise.coachingNote, !c.isEmpty { return c }
        return exercise.notes
    }

    private var restTimerBlock: some View {
        HStack {
            Image(systemName: "timer")
                .font(.system(size: 13))
                .foregroundStyle(restRemaining != nil ? BrainlessTheme.accent : BrainlessTheme.inkFaint)
            Text(restRemaining != nil ? "\(restRemaining!)s remaining" : "\(exercise.restSeconds)s rest")
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(restRemaining != nil ? BrainlessTheme.accent : BrainlessTheme.inkFaint)
            Spacer()
            Button("Start rest", action: onStartRest)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(BrainlessTheme.inkDim)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(BrainlessTheme.bgCard, in: Capsule())
                .overlay(Capsule().stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                .buttonStyle(.plain)
        }
        .padding(12)
        .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
    }

    private var loggingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(String(format: "SET %02d", nextSetNumber))
                    .font(.system(size: 11, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(BrainlessTheme.accent)
                Spacer()
                if let last = loggedSets.last {
                    Text("LAST: \(last.weightKilograms.map { "\($0.formatted(.number.precision(.fractionLength(0...1)))) kg" } ?? "BW") × \(last.reps)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(BrainlessTheme.inkFaint)
                } else {
                    Text("TAP A NUMBER TO ADJUST")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(BrainlessTheme.inkFaint)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            WeightTuner(value: $draftWeight)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

            Rectangle()
                .fill(BrainlessTheme.inkHair)
                .frame(height: 0.5)
                .padding(.horizontal, 16)

            HStack {
                Text("REPS")
                    .font(.system(size: 11, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(BrainlessTheme.inkFaint)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            RepsPicker(value: $draftReps)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

            Button {
                onLogSet(DraftLoggedSet(reps: draftReps, weightKilograms: draftWeight))
            } label: {
                HStack(spacing: 8) {
                    Text("Log set")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(BrainlessTheme.accent, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
        .shadow(color: BrainlessTheme.ink.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var loggedSetsList: some View {
        VStack(spacing: 6) {
            ForEach(loggedSets.suffix(4)) { set in
                HStack {
                    Text("#\(set.setNumber)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(BrainlessTheme.accent)
                    Spacer()
                    Text(set.summary)
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(BrainlessTheme.inkDim)
                    Button(role: .destructive) {
                        onDeleteSet(set)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(BrainlessTheme.inkFaint)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
            }
            if loggedSets.count > 4 {
                Text("+\(loggedSets.count - 4) more sets")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(BrainlessTheme.inkFaint)
            }
        }
    }
}

// MARK: - Finish Sheet

private struct FinishWorkoutSheet: View {
    let loggedSetCount: Int
    let skippedCount: Int
    let onSaveCompleted: () -> Void
    let onSavePartial: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(loggedSetCount) logged sets · \(skippedCount) skipped")
                    .font(.system(size: 14))
                    .foregroundStyle(BrainlessTheme.inkFaint)

                VStack(spacing: 10) {
                    Button(action: onSaveCompleted) {
                        Label("Save Completed", systemImage: "checkmark.circle.fill")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(BrainlessTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    Button(action: onSavePartial) {
                        Label("Save Partial", systemImage: "tray.and.arrow.down")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                            .foregroundStyle(BrainlessTheme.ink)
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive, action: onDiscard) {
                        Label("Discard", systemImage: "trash")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(20)
            .background(BrainlessTheme.bgElev.ignoresSafeArea())
            .navigationTitle("Finish")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Management View

private struct WorkoutManagementView: View {
    let workout: GeneratedWorkout
    let onFinish: () -> Void
    let isRegenerating: Bool
    @Binding var regenerationGuidance: String
    let onRegenerate: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)

            VStack(spacing: 4) {
                Text(workout.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(BrainlessTheme.ink)
                    .multilineTextAlignment(.center)

                Text(managementDetail)
                    .font(.system(size: 13))
                    .foregroundStyle(BrainlessTheme.inkFaint)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 16)

            Button(action: onFinish) {
                Label("Finish Workout", systemImage: "checkmark.circle.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(BrainlessTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            VStack(spacing: 8) {
                TextField("Change anything?", text: $regenerationGuidance, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundStyle(BrainlessTheme.ink)
                    .lineLimit(1...3)
                    .padding(12)
                    .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))

                Button(action: onRegenerate) {
                    HStack(spacing: 8) {
                        if isRegenerating {
                            ProgressView().tint(BrainlessTheme.ink)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isRegenerating ? "Regenerating\u{2026}" : "Regenerate")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                    .foregroundStyle(BrainlessTheme.ink)
                }
                .buttonStyle(.plain)
                .disabled(isRegenerating)
            }

            Spacer()

            Button(action: onDismiss) {
                Label("Resume Workout", systemImage: "arrow.left")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                    .foregroundStyle(BrainlessTheme.inkDim)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrainlessTheme.bg.ignoresSafeArea())
    }

    private var managementDetail: String {
        let focus = workout.focus.prefix(2).map(\.displayName).joined(separator: ", ")
        let meta = "\(workout.exercises.count) moves \u{00B7} \(workout.estimatedDurationMinutes) min"
        return focus.isEmpty ? meta : "\(meta) \u{00B7} \(focus)"
    }
}

// MARK: - Shared types

private struct DraftLoggedSet {
    var reps: Int?
    var weightKilograms: Double?
    var perceivedExertion: Int?

    init(reps: Int? = nil, weightKilograms: Double? = nil, perceivedExertion: Int? = nil) {
        self.reps = reps
        self.weightKilograms = weightKilograms
        self.perceivedExertion = perceivedExertion
    }

    var isEmpty: Bool {
        reps == nil && weightKilograms == nil && perceivedExertion == nil
    }
}

private extension LoggedSet {
    var summary: String {
        var parts: [String] = ["\(reps) reps"]
        if let weightKilograms { parts.append("\(weightKilograms.formatted(.number.precision(.fractionLength(0...1)))) kg") }
        if let perceivedExertion { parts.append("RPE \(perceivedExertion)") }
        return parts.joined(separator: " · ")
    }
}

private enum WorkoutHorizontalTab: Hashable {
    case management
    case exercises
}

private enum WorkoutScrollTarget: Hashable {
    case overview
}

#Preview {
    WorkoutModeView(workout: .constant(.sample))
}
