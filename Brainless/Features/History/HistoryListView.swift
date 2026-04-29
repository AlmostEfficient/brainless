import SwiftUI

struct HistoryListView: View {
    var historyService: WorkoutHistoryService

    @State private var sessions: [WorkoutSession] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    init(historyService: WorkoutHistoryService) {
        self.historyService = historyService
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let errorMessage {
                    ContentUnavailableView("History Unavailable", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                } else if sessions.isEmpty {
                    ContentUnavailableView("No Workout History", systemImage: "clock.arrow.circlepath")
                } else {
                    List(sessions) { session in
                        NavigationLink {
                            HistoryDetailView(sessionID: session.id, historyService: historyService)
                        } label: {
                            HistoryRow(session: session)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
        }
        .task {
            loadSessions()
        }
    }

    @MainActor
    private func loadSessions() {
        isLoading = true
        errorMessage = nil
        do {
            sessions = try historyService.loadSessions(limit: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct HistoryRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.workout.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(session.status.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(session.status == .completed ? .green : .orange)
            }

            HStack(spacing: 12) {
                Label((session.startedAt ?? session.completedAt ?? Date()).formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                Label("\(session.loggedSets.count) sets", systemImage: "checklist")
                Label("\(session.workout.exercises.count) exercises", systemImage: "figure.strengthtraining.traditional")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

extension WorkoutCompletionStatus {
    var displayName: String {
        switch self {
        case .planned: "Planned"
        case .inProgress: "Partial"
        case .completed: "Completed"
        case .skipped: "Skipped"
        }
    }
}

#Preview {
    HistoryListView(historyService: PreviewWorkoutHistoryService())
}

struct PreviewWorkoutHistoryService: WorkoutHistoryService {
    var storedSessions: [WorkoutSession] = [.sample]

    func loadSessions(limit: Int?) throws -> [WorkoutSession] {
        let sorted = storedSessions.sorted { ($0.completedAt ?? $0.startedAt ?? .distantPast) > ($1.completedAt ?? $1.startedAt ?? .distantPast) }
        guard let limit else { return sorted }
        return Array(sorted.prefix(limit))
    }

    func saveSession(_ session: WorkoutSession) throws {}
    func deleteSession(id: UUID) throws {}
    func historySummary(referenceDate: Date) throws -> WorkoutHistorySummary {
        WorkoutHistorySummary(totalCompletedWorkouts: 1, workoutsThisWeek: 1, currentStreakDays: 1, recentWorkouts: [])
    }
}
