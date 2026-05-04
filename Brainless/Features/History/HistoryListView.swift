import SwiftUI

struct HistoryListView: View {
    var historyService: WorkoutHistoryService

    @State private var sessions: [WorkoutSession] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    init(historyService: WorkoutHistoryService) {
        self.historyService = historyService
    }

    private var thisMonthCount: Int {
        let cal = Calendar.current
        let now = Date()
        return sessions.filter {
            let date = $0.completedAt ?? $0.startedAt ?? .distantPast
            return cal.isDate(date, equalTo: now, toGranularity: .month)
        }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.top, 60)
                    } else if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 14))
                            .foregroundStyle(BrainlessTheme.inkFaint)
                            .padding(.horizontal, 20)
                            .padding(.top, 40)
                    } else if sessions.isEmpty {
                        emptyState
                    } else {
                        statsStripSection
                        sessionListSection
                    }
                }
            }
            .background(BrainlessTheme.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            loadSessions()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HISTORY")
                .font(.system(size: 11, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(BrainlessTheme.inkFaint)

            if sessions.isEmpty && !isLoading {
                Text("No sessions\nrecorded yet.")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(BrainlessTheme.ink)
                    .lineSpacing(2)
            } else {
                Text("\(thisMonthCount) session\(thisMonthCount == 1 ? "" : "s")\n\(Text("this month.").foregroundStyle(BrainlessTheme.accent))")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(BrainlessTheme.ink)
                    .lineSpacing(2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 24)
    }

    private var statsStripSection: some View {
        HStack(spacing: 0) {
            statItem(value: "\(sessions.count)", label: "SESSIONS")
            statDivider
            statItem(value: totalActiveTimeStr, label: "ACTIVE")
            statDivider
            statItem(value: currentStreakStr, label: "STREAK")
        }
        .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    private var sessionListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("ALL SESSIONS")
                    .font(.system(size: 11, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(BrainlessTheme.inkFaint)
                Spacer()
                Button {
                } label: {
                    Text("FILTER")
                        .font(.system(size: 10, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(BrainlessTheme.inkFaint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(BrainlessTheme.bgCard, in: Capsule())
                        .overlay(Capsule().stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                    NavigationLink {
                        HistoryDetailView(sessionID: session.id, historyService: historyService)
                    } label: {
                        HistoryRow(session: session)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    if index < sessions.count - 1 {
                        Rectangle()
                            .fill(BrainlessTheme.inkHair)
                            .frame(height: 0.5)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 36))
                .foregroundStyle(BrainlessTheme.inkFaint)
            Text("Complete your first workout\nto see it here.")
                .font(.system(size: 14))
                .foregroundStyle(BrainlessTheme.inkFaint)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Stat helpers

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

    private var totalActiveTimeStr: String {
        let total = sessions.compactMap { session -> Int? in
            guard let start = session.startedAt, let end = session.completedAt else { return nil }
            return Int(end.timeIntervalSince(start) / 60)
        }.reduce(0, +)
        if total >= 60 {
            return "\(total / 60)h"
        }
        return "\(total)m"
    }

    private var currentStreakStr: String {
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())
        let sortedDates = sessions
            .compactMap { $0.completedAt ?? $0.startedAt }
            .map { cal.startOfDay(for: $0) }
            .sorted(by: >)

        for date in sortedDates {
            if date == checkDate || date == cal.date(byAdding: .day, value: -1, to: checkDate)! {
                streak += 1
                checkDate = date
            } else if date < checkDate {
                break
            }
        }
        return "\(streak)d"
    }

    // MARK: - Load

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

// MARK: - Row

private struct HistoryRow: View {
    let session: WorkoutSession

    private var vibeTag: (label: String, color: Color) {
        switch session.status {
        case .completed:  return ("SOLID", BrainlessTheme.accent)
        case .inProgress: return ("PARTIAL", Color.orange)
        case .skipped:    return ("SKIPPED", BrainlessTheme.inkFaint)
        case .planned:    return ("PLANNED", BrainlessTheme.inkFaint)
        }
    }

    private var sessionDate: Date {
        session.completedAt ?? session.startedAt ?? Date()
    }

    private var durationMins: Int? {
        guard let start = session.startedAt, let end = session.completedAt else { return nil }
        return max(1, Int(end.timeIntervalSince(start) / 60))
    }

    private var volumeStr: String? {
        let totalKg = session.loggedSets.compactMap(\.weightKilograms).reduce(0, +)
        guard totalKg > 0 else { return nil }
        return "\(Int(totalKg)) kg"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(session.workout.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BrainlessTheme.ink)
                        .lineLimit(1)

                    Text(vibeTag.label)
                        .font(.system(size: 9, design: .monospaced))
                        .tracking(0.6)
                        .foregroundStyle(vibeTag.color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(vibeTag.color.opacity(0.1), in: Capsule())
                }

                HStack(spacing: 10) {
                    metaChip(sessionDate.formatted(date: .abbreviated, time: .omitted))
                    if let dur = durationMins {
                        metaChip("\(dur) min")
                    }
                    metaChip("\(session.workout.exercises.count) ex")
                    if let vol = volumeStr {
                        metaChip(vol)
                    }
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(BrainlessTheme.inkFaint)
        }
    }

    private func metaChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(BrainlessTheme.inkFaint)
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
