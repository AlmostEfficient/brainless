import SwiftUI

struct HistoryDetailView: View {
    let sessionID: WorkoutSession.ID
    var historyService: WorkoutHistoryService

    @State private var session: WorkoutSession?
    @State private var isLoading = true
    @State private var errorMessage: String?

    init(sessionID: WorkoutSession.ID, historyService: WorkoutHistoryService) {
        self.sessionID = sessionID
        self.historyService = historyService
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                ContentUnavailableView("Session Unavailable", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
            } else if let session {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        summary(for: session)

                        if session.loggedSets.isEmpty {
                            ContentUnavailableView("No Logged Sets", systemImage: "square.and.pencil")
                                .padding(.top, 28)
                        } else {
                            loggedSetsList(session)
                        }
                    }
                    .padding(18)
                }
            } else {
                ContentUnavailableView("Session Not Found", systemImage: "questionmark.folder")
            }
        }
        .navigationTitle(session?.workout.title ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadSession()
        }
    }

    private func summary(for session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(session.workout.title)
                .font(.title.bold())
                .lineLimit(2)

            HStack(spacing: 10) {
                DetailMetric(title: "Status", value: session.status.displayName)
                DetailMetric(title: "Sets", value: "\(session.loggedSets.count)")
                DetailMetric(title: "Exercises", value: "\(session.workout.exercises.count)")
            }

            VStack(alignment: .leading, spacing: 6) {
                if let startedAt = session.startedAt {
                    Label(startedAt.formatted(date: .complete, time: .shortened), systemImage: "play.circle")
                }
                if let completedAt = session.completedAt {
                    Label(completedAt.formatted(date: .omitted, time: .shortened), systemImage: "stop.circle")
                }
                if let notes = session.notes, !notes.isEmpty {
                    Label(notes, systemImage: "note.text")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private func loggedSetsList(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Logged Sets")
                .font(.headline)

            ForEach(groupedSets(from: session), id: \.exerciseID) { group in
                VStack(alignment: .leading, spacing: 10) {
                    Text(group.exerciseName)
                        .font(.subheadline.weight(.semibold))

                    ForEach(group.sets) { set in
                        HStack {
                            Text("Set \(set.setNumber)")
                            Spacer()
                            Text(set.historySummary)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline.monospacedDigit())
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func groupedSets(from session: WorkoutSession) -> [LoggedSetGroup] {
        let exerciseNames = Dictionary(uniqueKeysWithValues: session.workout.exercises.map { ($0.id, $0.catalogItem.name) })
        let grouped = Dictionary(grouping: session.loggedSets) { $0.workoutExerciseID }
        return grouped.map { exerciseID, sets in
            LoggedSetGroup(
                exerciseID: exerciseID,
                exerciseName: exerciseNames[exerciseID] ?? "Exercise",
                sets: sets.sorted { $0.setNumber < $1.setNumber }
            )
        }
        .sorted { $0.exerciseName < $1.exerciseName }
    }

    @MainActor
    private func loadSession() {
        isLoading = true
        errorMessage = nil
        do {
            session = try historyService.loadSessions(limit: nil).first { $0.id == sessionID }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct DetailMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct LoggedSetGroup {
    let exerciseID: UUID
    let exerciseName: String
    let sets: [LoggedSet]
}

private extension LoggedSet {
    var historySummary: String {
        var parts: [String] = ["\(reps) reps"]
        if let weightKilograms { parts.append("\(weightKilograms.formatted(.number.precision(.fractionLength(0...1)))) kg") }
        if let perceivedExertion { parts.append("RPE \(perceivedExertion)") }
        return parts.joined(separator: " • ")
    }
}

#Preview {
    NavigationStack {
        HistoryDetailView(sessionID: WorkoutSession.sample.id, historyService: PreviewWorkoutHistoryService())
    }
}
