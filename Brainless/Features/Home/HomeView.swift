import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(
        service: WorkoutGenerationService,
        catalogService: ExerciseCatalogService,
        assetURLBuilder: ExerciseAssetURLBuilder = ExerciseAssetURLBuilder(),
        userProfileStore: UserProfileStore,
        trainingPreferencesStore: TrainingPreferencesStore,
        equipmentProfileStore: EquipmentProfileStore,
        historyService: WorkoutHistoryService
    ) {
        _viewModel = State(initialValue: HomeViewModel(
            service: service,
            catalogService: catalogService,
            assetURLBuilder: assetURLBuilder,
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
                    if let workout = viewModel.generatedWorkout {
                        generatedWorkoutCard(workout)
                    }
                    recentHistory
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .alert("Generation failed", isPresented: $viewModel.isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .fullScreenCover(item: $viewModel.startedWorkout) { _ in
                WorkoutModeView(
                    workout: Binding(
                        get: { viewModel.startedWorkout! },
                        set: { viewModel.startedWorkout = $0 }
                    ),
                    assetURLBuilder: viewModel.assetURLBuilder,
                    onRegenerate: { viewModel.regenerate() },
                    isRegenerating: viewModel.isGenerating,
                    onSaveCompleted: viewModel.saveSessionAndClose,
                    onSavePartial: viewModel.saveSessionAndClose,
                    onDiscard: { viewModel.startedWorkout = nil }
                )
            }
            .onAppear {
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

    private func generatedWorkoutCard(_ workout: GeneratedWorkout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ready to go")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(workout.title)
                .font(.title3.bold())

            Text("\(workout.estimatedDurationMinutes) min · \(workout.intensity) · \(workout.exercises.count) moves")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    viewModel.start(workout)
                } label: {
                    Label("Start workout", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    viewModel.regenerate()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isGenerating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(viewModel.isGenerating ? "Regenerating…" : "Regenerate")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isGenerating)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
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
    private let catalogService: ExerciseCatalogService
    let assetURLBuilder: ExerciseAssetURLBuilder
    private let userProfileStore: UserProfileStore
    private let trainingPreferencesStore: TrainingPreferencesStore
    private let equipmentProfileStore: EquipmentProfileStore
    private let historyService: WorkoutHistoryService
    private var lastRequest: WorkoutGenerationRequest?

    private var cachedBodyContext: UserBodyContext?
    private var cachedTrainingPreferences: TrainingPreferences?
    private var cachedEquipmentProfile: EquipmentProfile?

    init(
        service: WorkoutGenerationService,
        catalogService: ExerciseCatalogService,
        assetURLBuilder: ExerciseAssetURLBuilder,
        userProfileStore: UserProfileStore,
        trainingPreferencesStore: TrainingPreferencesStore,
        equipmentProfileStore: EquipmentProfileStore,
        historyService: WorkoutHistoryService
    ) {
        self.service = service
        self.catalogService = catalogService
        self.assetURLBuilder = assetURLBuilder
        self.userProfileStore = userProfileStore
        self.trainingPreferencesStore = trainingPreferencesStore
        self.equipmentProfileStore = equipmentProfileStore
        self.historyService = historyService
    }

    func generate() {
        guard !isGenerating else { return }
        isGenerating = true
        isShowingError = false
        errorMessage = ""

        Task {
            do {
                let request = try await makeRequest()
                lastRequest = request
                generatedWorkout = try await service.generateWorkout(for: request)
            } catch {
                show(error)
            }
            isGenerating = false
        }
    }

    func regenerate() {
        guard !isGenerating else { return }
        isGenerating = true
        isShowingError = false
        errorMessage = ""

        Task {
            do {
                let request: WorkoutGenerationRequest
                if let lastRequest {
                    request = lastRequest
                } else {
                    request = try await makeRequest()
                }
                lastRequest = request
                let workout = try await service.generateWorkout(for: request)
                generatedWorkout = workout
                if startedWorkout != nil {
                    startedWorkout = workout
                }
            } catch {
                show(error)
            }
            isGenerating = false
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
            cachedBodyContext = try userProfileStore.loadBodyContext()
            cachedTrainingPreferences = try trainingPreferencesStore.loadTrainingPreferences()
            cachedEquipmentProfile = try equipmentProfileStore.loadEquipmentProfile()
            let summary = try historyService.historySummary(referenceDate: Date())
            recentHistorySummary = Self.formattedHistory(summary)
            recentHistoryLine = Self.formattedOneLiner(summary)
            updateWorkoutType(from: cachedTrainingPreferences, history: summary)
        } catch {
            recentHistorySummary = "Recent history is unavailable."
        }
    }

    private func updateWorkoutType(from prefs: TrainingPreferences?, history: WorkoutHistorySummary) {
        guard let prefs else { return }
        switch prefs.preferredSplit {
        case .pushPullLegs: workoutType = nextPPLDay(from: history)
        case .upperLower:   workoutType = nextUpperLowerDay(from: history)
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

    private func makeRequest() async throws -> WorkoutGenerationRequest {
        let bodyContext: UserBodyContext
        if let cachedBodyContext {
            bodyContext = cachedBodyContext
        } else {
            bodyContext = try userProfileStore.loadBodyContext()
        }

        let trainingPreferences: TrainingPreferences
        if let cachedTrainingPreferences {
            trainingPreferences = cachedTrainingPreferences
        } else {
            trainingPreferences = try trainingPreferencesStore.loadTrainingPreferences()
        }

        let equipmentProfile: EquipmentProfile
        if let cachedEquipmentProfile {
            equipmentProfile = cachedEquipmentProfile
        } else {
            equipmentProfile = try equipmentProfileStore.loadEquipmentProfile()
        }
        let history = try historyService.historySummary(referenceDate: Date())
        let catalog = try await loadCatalogCandidates(
            trainingPreferences: trainingPreferences,
            equipmentProfile: equipmentProfile
        )

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
            exerciseCatalog: catalog,
            recentHistory: history
        )
    }

    private func loadCatalogCandidates(
        trainingPreferences: TrainingPreferences,
        equipmentProfile: EquipmentProfile
    ) async throws -> [ExerciseCatalogItem] {
        let equipment = equipmentProfile.availableEquipment
            .map(\.catalogQueryValue)
            .joined(separator: ",")
        let preferredMuscles = preferredCatalogMuscles(from: trainingPreferences)
            .joined(separator: ",")

        var response = try await catalogService.exercises(
            matching: ExerciseCatalogQuery(
                muscle: preferredMuscles.isEmpty ? nil : preferredMuscles,
                equipment: equipment.isEmpty ? nil : equipment,
                limit: 100
            )
        )

        if response.data.count < 12, !preferredMuscles.isEmpty {
            response = try await catalogService.exercises(
                matching: ExerciseCatalogQuery(
                    equipment: equipment.isEmpty ? nil : equipment,
                    limit: 100
                )
            )
        }

        let catalog = response.data.map {
            ExerciseCatalogItem(
                id: $0.id,
                name: $0.name,
                muscle: $0.muscle,
                equipment: $0.equipment
            )
        }

        guard !catalog.isEmpty else {
            throw WorkoutGenerationError.missingExerciseCatalogItem
        }

        return catalog
    }

    private func preferredCatalogMuscles(from preferences: TrainingPreferences) -> [String] {
        let selected = preferences.preferredMuscles.filter { $0 != .fullBody && $0 != .cardio }
        if !selected.isEmpty {
            return selected.map(\.catalogQueryValue)
        }

        switch workoutType {
        case "Push":
            return ["pectorals", "delts", "triceps"]
        case "Pull":
            return ["lats", "upper back", "biceps"]
        case "Legs", "Lower":
            return ["quads", "hamstrings", "glutes", "calves"]
        case "Upper":
            return ["pectorals", "lats", "delts", "biceps", "triceps"]
        case "Mobility", "Cardio":
            return []
        default:
            return []
        }
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
        catalogService: MockExerciseCatalogService(),
        assetURLBuilder: ExerciseAssetURLBuilder(),
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

private extension EquipmentType {
    var catalogQueryValue: String {
        switch self {
        case .bodyweight:
            "body weight"
        case .dumbbells:
            "dumbbell"
        case .barbell:
            "barbell"
        case .kettlebell:
            "kettlebell"
        case .resistanceBands:
            "band"
        case .cableMachine:
            "cable"
        case .machine:
            "machine"
        case .bench:
            "body weight"
        case .pullUpBar:
            "body weight"
        case .cardioMachine:
            "stationary bike"
        }
    }
}

private extension MuscleGroup {
    var catalogQueryValue: String {
        switch self {
        case .chest:
            "pectorals"
        case .back:
            "lats"
        case .shoulders:
            "delts"
        case .core:
            "abs"
        default:
            rawValue
        }
    }
}
