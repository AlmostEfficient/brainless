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
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    intentPicker
                    requestFields
                    generateButton
                    recentHistory
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Brainless")
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

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.largeTitle.bold())

            Text("Generate a practical workout from your intent, notes, and recent training.")
                .foregroundStyle(.secondary)
        }
    }

    private var intentPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intent")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(viewModel.intentOptions, id: \.self) { intent in
                    Button {
                        viewModel.selectedIntent = intent
                    } label: {
                        Text(intent)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(viewModel.selectedIntent == intent ? .white : .primary)
                            .background(
                                viewModel.selectedIntent == intent ? Color.accentColor : Color(.secondarySystemGroupedBackground),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var requestFields: some View {
        VStack(spacing: 14) {
            textField(
                title: "Custom request",
                prompt: "Example: dumbbells only, no jumping",
                text: $viewModel.customRequest
            )

            textField(
                title: "Today notes",
                prompt: "Energy, soreness, time available",
                text: $viewModel.todayNotes
            )
        }
    }

    private func textField(title: String, prompt: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            TextField(prompt, text: text, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var generateButton: some View {
        Button {
            viewModel.generate()
        } label: {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                } else {
                    Image(systemName: "sparkles")
                }

                Text(viewModel.isGenerating ? "Generating" : "Generate Workout")
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
    let intentOptions = ["Balanced", "Strength", "Mobility", "Quick sweat", "Low impact"]

    var selectedIntent = "Balanced"
    var customRequest = ""
    var todayNotes = ""
    var recentHistorySummary = "No completed workouts yet."
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
    private var lastHistorySummary: WorkoutHistorySummary = .empty

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
            lastHistorySummary = try historyService.historySummary(referenceDate: Date())
            recentHistorySummary = Self.formattedHistory(lastHistorySummary)
        } catch {
            recentHistorySummary = "Recent history is unavailable."
            show(error)
        }
    }

    private func generate(_ request: WorkoutGenerationRequest) {
        guard isGenerating == false else { return }

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

        lastHistorySummary = history
        recentHistorySummary = Self.formattedHistory(history)

        return WorkoutGenerationRequest(
            bodyContext: bodyContext,
            trainingPreferences: trainingPreferences,
            equipmentProfile: equipmentProfile,
            workoutIntent: workoutIntent,
            todayNotes: todayNotes.trimmedForHomeRequest,
            requestedDurationMinutes: requestedDuration(from: trainingPreferences),
            historySummary: history,
            exerciseCatalog: ExerciseCatalogItem.samples,
            recentHistory: history
        )
    }

    private var workoutIntent: String {
        [selectedIntent, customRequest.trimmedForHomeRequest]
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
    }

    private func requestedDuration(from preferences: TrainingPreferences) -> Int? {
        if selectedIntent == "Quick sweat" {
            return min(preferences.sessionLengthMinutes, 25)
        }
        return preferences.sessionLengthMinutes
    }

    private static func formattedHistory(_ summary: WorkoutHistorySummary) -> String {
        guard !summary.recentWorkouts.isEmpty else {
            return "No completed workouts yet."
        }

        let recentLines = summary.recentWorkouts.map { workout in
            let focus = workout.focus.map(\.displayName).joined(separator: ", ")
            let duration = workout.durationMinutes.map { ", \($0) min" } ?? ""
            return "\(workout.title) - \(workout.completedAt.formatted(date: .abbreviated, time: .omitted))\(duration) - \(focus)"
        }

        return """
        \(summary.totalCompletedWorkouts) completed total. \(summary.workoutsThisWeek) this week. \(summary.currentStreakDays)-day streak.
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

private extension String {
    var trimmedForHomeRequest: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct HomePreviewUserProfileStore: UserProfileStore {
    func loadBodyContext() throws -> UserBodyContext {
        .sample
    }

    func saveBodyContext(_ bodyContext: UserBodyContext) throws {}
}

private struct HomePreviewTrainingPreferencesStore: TrainingPreferencesStore {
    func loadTrainingPreferences() throws -> TrainingPreferences {
        .sample
    }

    func saveTrainingPreferences(_ preferences: TrainingPreferences) throws {}
}

private struct HomePreviewEquipmentProfileStore: EquipmentProfileStore {
    func loadEquipmentProfile() throws -> EquipmentProfile {
        .sample
    }

    func saveEquipmentProfile(_ profile: EquipmentProfile) throws {}
}

private struct HomePreviewWorkoutHistoryService: WorkoutHistoryService {
    func loadSessions(limit: Int?) throws -> [WorkoutSession] {
        [.sample]
    }

    func saveSession(_ session: WorkoutSession) throws {}
    func deleteSession(id: UUID) throws {}

    func historySummary(referenceDate: Date) throws -> WorkoutHistorySummary {
        WorkoutHistorySummary(
            totalCompletedWorkouts: 1,
            workoutsThisWeek: 1,
            currentStreakDays: 1,
            recentWorkouts: [
                RecentWorkoutSummary(
                    id: UUID(),
                    title: "Balanced Strength",
                    completedAt: Date().addingTimeInterval(-86_400),
                    durationMinutes: 45,
                    focus: [.fullBody]
                )
            ]
        )
    }
}
