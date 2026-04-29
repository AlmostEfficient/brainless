import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(
        service: WorkoutGenerationService = MockWorkoutGenerationService(),
        userProfileStore: UserProfileStore,
        trainingPreferencesStore: TrainingPreferencesStore,
        equipmentProfileStore: EquipmentProfileStore,
        historyService: WorkoutHistoryService
    ) {
        _viewModel = State(initialValue: HomeViewModel(
            service: service,
            userProfileStore: userProfileStore,
            trainingPreferencesStore: trainingPreferencesStore,
            equipmentProfileStore: equipmentProfileStore,
            historyService: historyService
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    greeting
                    controls
                    generateButton
                    recentHistory
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .navigationDestination(item: $viewModel.generatedWorkout) { workout in
                WorkoutPreviewView(
                    workout: workout,
                    onStart: { viewModel.start(workout) },
                    onRegenerate: { viewModel.regenerate() }
                )
            }
            .alert("Generation failed", isPresented: $viewModel.isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .fullScreenCover(item: $viewModel.startedWorkout) { workout in
                WorkoutModeView(
                    workout: workout,
                    onSaveCompleted: viewModel.saveSessionAndClose,
                    onSavePartial: viewModel.saveSessionAndClose,
                    onDiscard: { viewModel.startedWorkout = nil }
                )
            }
            .task {
                viewModel.loadRecentHistorySummary()
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.largeTitle.bold())
            if !viewModel.recentHistoryLine.isEmpty {
                Text(viewModel.recentHistoryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning."
        case 12..<17: return "Good afternoon."
        case 17..<21: return "Good evening."
        default: return "Ready when you are."
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                SwipeCyclePill(
                    options: HomeViewModel.workoutTypes,
                    selection: $viewModel.workoutType,
                    label: { $0 }
                )
                SwipeCyclePill(
                    options: HomeViewModel.durations,
                    selection: $viewModel.durationMinutes,
                    label: { "\($0) min" }
                )
                SwipeCyclePill(
                    options: HomeViewModel.intensities,
                    selection: $viewModel.intensity,
                    label: { $0 }
                )
            }

            TextField(
                "Anything specific? sore spots, energy, what you're feeling...",
                text: $viewModel.notes,
                axis: .vertical
            )
            .lineLimit(2...5)
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var generateButton: some View {
        Button {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            viewModel.generate()
        } label: {
            HStack(spacing: 8) {
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(viewModel.isGenerating ? "Generating…" : "Generate Workout")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(viewModel.isGenerating)
    }

    private var recentHistory: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent history")
                .font(.headline)

            Text(viewModel.recentHistorySummary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

@MainActor
@Observable
final class HomeViewModel {
    static let workoutTypes = ["Full Body", "Push", "Pull", "Legs", "Upper", "Lower", "Cardio", "Mobility"]
    static let durations = [20, 30, 45, 60, 75, 90]
    static let intensities = ["Easy", "Moderate", "Hard"]

    var workoutType = "Full Body"
    var durationMinutes = 45
    var intensity = "Moderate"
    var notes = ""

    var recentHistorySummary = ""
    var recentHistoryLine = ""
    var generatedWorkout: GeneratedWorkout?
    var isGenerating = false
    var isShowingError = false
    var errorMessage = ""
    var startedWorkout: GeneratedWorkout?

    private let service: WorkoutGenerationService
    private let userProfileStore: UserProfileStore
    private let trainingPreferencesStore: TrainingPreferencesStore
    private let equipmentProfileStore: EquipmentProfileStore
    private let historyService: WorkoutHistoryService
    private var lastRequest: WorkoutGenerationRequest?

    init(
        service: WorkoutGenerationService,
        userProfileStore: UserProfileStore,
        trainingPreferencesStore: TrainingPreferencesStore,
        equipmentProfileStore: EquipmentProfileStore,
        historyService: WorkoutHistoryService
    ) {
        self.service = service
        self.userProfileStore = userProfileStore
        self.trainingPreferencesStore = trainingPreferencesStore
        self.equipmentProfileStore = equipmentProfileStore
        self.historyService = historyService
    }

    func generate() {
        do {
            let request = try makeRequest()
            lastRequest = request
            generate(request)
        } catch {
            show(error)
        }
    }

    func regenerate() {
        do {
            generate(try lastRequest ?? makeRequest())
        } catch {
            show(error)
        }
    }

    func start(_ workout: GeneratedWorkout) {
        startedWorkout = workout
    }

    func saveSessionAndClose(_ session: WorkoutSession) {
        do {
            try historyService.saveSession(session)
            startedWorkout = nil
            loadRecentHistorySummary()
        } catch {
            show(error)
        }
    }

    func loadRecentHistorySummary() {
        do {
            let summary = try historyService.historySummary(referenceDate: Date())
            recentHistorySummary = Self.formattedHistory(summary)
            recentHistoryLine = Self.formattedOneLiner(summary)
            updateDefaultsFromProfile(summary: summary)
        } catch {
            recentHistorySummary = "Recent history is unavailable."
        }
    }

    private func updateDefaultsFromProfile(summary: WorkoutHistorySummary) {
        guard let prefs = try? trainingPreferencesStore.loadTrainingPreferences() else { return }
        switch prefs.preferredSplit {
        case .pushPullLegs: workoutType = nextPPLDay(from: summary)
        case .upperLower:   workoutType = nextUpperLowerDay(from: summary)
        case .fullBody:     workoutType = "Full Body"
        default:            workoutType = "Full Body"
        }
    }

    private func nextPPLDay(from summary: WorkoutHistorySummary) -> String {
        let last = summary.recentWorkouts.first?.title.lowercased() ?? ""
        if last.contains("push") { return "Pull" }
        if last.contains("pull") { return "Legs" }
        return "Push"
    }

    private func nextUpperLowerDay(from summary: WorkoutHistorySummary) -> String {
        let last = summary.recentWorkouts.first?.title.lowercased() ?? ""
        return last.contains("upper") ? "Lower" : "Upper"
    }

    private func generate(_ request: WorkoutGenerationRequest) {
        guard !isGenerating else { return }
        isGenerating = true
        isShowingError = false
        errorMessage = ""

        Task {
            do {
                generatedWorkout = try await service.generateWorkout(for: request)
            } catch {
                show(error)
            }
            isGenerating = false
        }
    }

    private func makeRequest() throws -> WorkoutGenerationRequest {
        let bodyContext = try userProfileStore.loadBodyContext()
        let trainingPreferences = try trainingPreferencesStore.loadTrainingPreferences()
        let equipmentProfile = try equipmentProfileStore.loadEquipmentProfile()
        let history = try historyService.historySummary(referenceDate: Date())

        recentHistorySummary = Self.formattedHistory(history)
        recentHistoryLine = Self.formattedOneLiner(history)

        let intent = [workoutType, intensity != "Moderate" ? "\(intensity) intensity" : nil]
            .compactMap { $0 }
            .joined(separator: ", ")

        return WorkoutGenerationRequest(
            bodyContext: bodyContext,
            trainingPreferences: trainingPreferences,
            equipmentProfile: equipmentProfile,
            workoutIntent: intent,
            todayNotes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            requestedDurationMinutes: durationMinutes,
            historySummary: history,
            exerciseCatalog: ExerciseCatalogItem.samples,
            recentHistory: history
        )
    }

    private static func formattedOneLiner(_ summary: WorkoutHistorySummary) -> String {
        guard !summary.recentWorkouts.isEmpty else { return "" }
        let streak = summary.currentStreakDays
        let week = summary.workoutsThisWeek
        if streak > 1 {
            return "\(streak)-day streak · \(week) this week"
        }
        return "\(week) workout\(week == 1 ? "" : "s") this week"
    }

    private static func formattedHistory(_ summary: WorkoutHistorySummary) -> String {
        guard !summary.recentWorkouts.isEmpty else {
            return "No completed workouts yet."
        }
        let recentLines = summary.recentWorkouts.map { workout in
            let focus = workout.focus.map(\.displayName).joined(separator: ", ")
            let duration = workout.durationMinutes.map { ", \($0) min" } ?? ""
            return "\(workout.title) — \(workout.completedAt.formatted(date: .abbreviated, time: .omitted))\(duration) — \(focus)"
        }
        return """
        \(summary.totalCompletedWorkouts) completed · \(summary.workoutsThisWeek) this week · \(summary.currentStreakDays)-day streak
        \(recentLines.joined(separator: "\n"))
        """
    }

    private func show(_ error: Error) {
        errorMessage = error.localizedDescription
        isShowingError = true
    }
}

#Preview {
    HomeView(
        service: MockWorkoutGenerationService(delayNanoseconds: 0),
        userProfileStore: HomePreviewUserProfileStore(),
        trainingPreferencesStore: HomePreviewTrainingPreferencesStore(),
        equipmentProfileStore: HomePreviewEquipmentProfileStore(),
        historyService: HomePreviewWorkoutHistoryService()
    )
}

private struct HomePreviewUserProfileStore: UserProfileStore {
    func loadBodyContext() throws -> UserBodyContext { .sample }
    func saveBodyContext(_ bodyContext: UserBodyContext) throws {}
}

private struct HomePreviewTrainingPreferencesStore: TrainingPreferencesStore {
    func loadTrainingPreferences() throws -> TrainingPreferences { .sample }
    func saveTrainingPreferences(_ preferences: TrainingPreferences) throws {}
}

private struct HomePreviewEquipmentProfileStore: EquipmentProfileStore {
    func loadEquipmentProfile() throws -> EquipmentProfile { .sample }
    func saveEquipmentProfile(_ profile: EquipmentProfile) throws {}
}

private struct HomePreviewWorkoutHistoryService: WorkoutHistoryService {
    func loadSessions(limit: Int?) throws -> [WorkoutSession] { [.sample] }
    func saveSession(_ session: WorkoutSession) throws {}
    func deleteSession(id: UUID) throws {}

    func historySummary(referenceDate: Date) throws -> WorkoutHistorySummary {
        WorkoutHistorySummary(
            totalCompletedWorkouts: 7,
            workoutsThisWeek: 3,
            currentStreakDays: 3,
            recentWorkouts: [
                RecentWorkoutSummary(
                    id: UUID(),
                    title: "Push Day",
                    completedAt: Date().addingTimeInterval(-86_400),
                    durationMinutes: 45,
                    focus: [.chest, .shoulders]
                )
            ]
        )
    }
}
