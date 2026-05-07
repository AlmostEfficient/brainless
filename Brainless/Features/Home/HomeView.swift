import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    private let historyService: WorkoutHistoryService
    private let settingsViewModel: SettingsViewModel

    init(
        service: WorkoutGenerationService,
        mockService: WorkoutGenerationService = MockWorkoutGenerationService(),
        catalogService: ExerciseCatalogService,
        assetURLBuilder: ExerciseAssetURLBuilder = ExerciseAssetURLBuilder(),
        userProfileStore: UserProfileStore,
        trainingPreferencesStore: TrainingPreferencesStore,
        equipmentProfileStore: EquipmentProfileStore,
        historyService: WorkoutHistoryService,
        settingsViewModel: SettingsViewModel
    ) {
        self.historyService = historyService
        self.settingsViewModel = settingsViewModel
        _viewModel = State(initialValue: HomeViewModel(
            service: service,
            mockService: mockService,
            catalogService: catalogService,
            assetURLBuilder: assetURLBuilder,
            userProfileStore: userProfileStore,
            trainingPreferencesStore: trainingPreferencesStore,
            equipmentProfileStore: equipmentProfileStore,
            historyService: historyService
        ))
    }

    private var durationBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.durationMinutes) },
            set: { viewModel.durationMinutes = Int($0) }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    greetingSection
                    weekStripSection
                    sessionSection
                    beginSection
                    notesSection
                }
            }
            .background(BrainlessTheme.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .alert("Generation failed", isPresented: $viewModel.isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .fullScreenCover(item: $viewModel.startedWorkout) { item in
                WorkoutModeView(
                    workout: Binding(
                        get: { viewModel.startedWorkout ?? item },
                        set: { viewModel.startedWorkout = $0 }
                    ),
                    assetURLBuilder: viewModel.assetURLBuilder,
                    onRegenerate: { viewModel.regenerate(guidance: $0) },
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

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(BrainlessTheme.surface2)
                    .frame(width: 36, height: 36)
                Image(systemName: "person.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(BrainlessTheme.inkDim)
            }
            Spacer()
            HStack(spacing: 10) {
                topBarLink(
                    systemName: "clock.arrow.circlepath",
                    destination: HistoryListView(historyService: historyService, wrapsInNavigationStack: false)
                )

                topBarLink(
                    systemName: "gearshape",
                    destination: SettingsView(viewModel: settingsViewModel, wrapsInNavigationStack: false)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func topBarLink<Destination: View>(systemName: String, destination: Destination) -> some View {
        NavigationLink {
            destination
        } label: {
            ZStack {
                Circle()
                    .fill(BrainlessTheme.surface2)
                    .frame(width: 36, height: 36)
                Image(systemName: systemName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(BrainlessTheme.inkDim)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(dateOverline)
                .font(.system(size: 11, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(BrainlessTheme.inkFaint)

            Text("Today is\n\(Text(viewModel.workoutType + ".").foregroundStyle(BrainlessTheme.accent))")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(BrainlessTheme.ink)
                .lineSpacing(2)

            if !viewModel.recentHistoryLine.isEmpty {
                Text(viewModel.recentHistoryLine)
                    .font(.system(size: 14))
                    .foregroundStyle(BrainlessTheme.inkFaint)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 24)
    }

    private var dateOverline: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE"
        let weekday = fmt.string(from: Date()).uppercased()
        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "MMM d"
        let dayStr = dayFmt.string(from: Date()).uppercased()
        return "\(weekday) · \(dayStr)"
    }

    // MARK: - Week Strip

    private var weekStripSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(weekDays) { day in
                    WeekDayCard(day: day)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 28)
    }

    private var weekDays: [WeekDay] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let monday = cal.date(byAdding: .day, value: -(weekday - 2 + 7) % 7, to: today)!
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "d"
        return (0..<7).map { offset in
            let date = cal.date(byAdding: .day, value: offset, to: monday)!
            let isToday = cal.isDate(date, inSameDayAs: today)
            let isPast = date < today
            return WeekDay(
                id: offset,
                abbreviation: fmt.string(from: date).uppercased(),
                dayNumber: dayFmt.string(from: date),
                isToday: isToday,
                isPast: isPast,
                hasWorkout: viewModel.weekWorkoutDates.contains(cal.startOfDay(for: date))
            )
        }
    }

    // MARK: - Session Section

    private var sessionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            durationSection
            intensitySection
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("DURATION")
            RulerPicker(value: durationBinding, minValue: 15, maxValue: 90, step: 5, unit: "min")
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("INTENSITY")
            IntensityBars(
                value: $viewModel.intensity,
                options: HomeViewModel.intensities
            )
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("NOTES")
            TextField(
                "Sore spots, energy level, anything specific…",
                text: $viewModel.notes,
                axis: .vertical
            )
            .lineLimit(2...4)
            .font(.system(size: 14))
            .foregroundStyle(BrainlessTheme.ink)
            .padding(14)
            .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Begin

    private var beginSection: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.generate()
            } label: {
                ZStack {
                    if viewModel.isGenerating {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("Generating…")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    } else {
                        Text("Begin \u{2192}")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(BrainlessTheme.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isGenerating)

            Text("\(viewModel.durationMinutes) MIN · \(viewModel.intensity.uppercased()) · \(viewModel.workoutType.uppercased())")
                .font(.system(size: 11, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(BrainlessTheme.inkFaint)

            mockGenerateButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var mockGenerateButton: some View {
        Button {
            viewModel.generateMock()
        } label: {
            HStack(spacing: 8) {
                if viewModel.isGeneratingMock {
                    ProgressView()
                        .controlSize(.small)
                        .tint(BrainlessTheme.inkDim)
                } else {
                    Image(systemName: "testtube.2")
                        .font(.system(size: 15))
                }
                Text(viewModel.isGeneratingMock ? "Loading mock…" : "Use Mock Workout")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(BrainlessTheme.inkDim)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(BrainlessTheme.surface2, in: Capsule())
            .overlay(Capsule().stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isGenerating)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, design: .monospaced))
            .tracking(1.2)
            .foregroundStyle(BrainlessTheme.inkFaint)
            .padding(.horizontal, 20)
    }
}

// MARK: - WeekDay model + card

private struct WeekDay: Identifiable {
    let id: Int
    let abbreviation: String
    let dayNumber: String
    let isToday: Bool
    let isPast: Bool
    let hasWorkout: Bool
}

private struct WeekDayCard: View {
    let day: WeekDay

    private var ringColor: Color {
        if day.hasWorkout { return BrainlessTheme.accent }
        if day.isToday { return BrainlessTheme.inkDim }
        return .clear
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(day.abbreviation)
                .font(.system(size: 10, weight: day.isToday ? .semibold : .regular, design: .monospaced))
                .foregroundStyle(day.isToday ? BrainlessTheme.ink : BrainlessTheme.inkFaint)

            ZStack {
                Circle()
                    .strokeBorder(ringColor, lineWidth: 1.5)
                    .frame(width: 40, height: 40)

                if day.hasWorkout {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BrainlessTheme.accent)
                } else {
                    Text(day.dayNumber)
                        .font(.system(size: 15, weight: day.isToday ? .semibold : .regular).monospacedDigit())
                        .foregroundStyle(day.isToday ? BrainlessTheme.ink : BrainlessTheme.inkFaint)
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class HomeViewModel {
    static let durations = [20, 30, 45, 60, 75, 90]
    static let intensities = ["Recovery", "Light", "Moderate", "Hard", "All-out"]

    var workoutType = "Full Body"
    var durationMinutes = 45
    var intensity = "Moderate"
    var notes = ""

    var recentHistorySummary = ""
    var recentHistoryLine = ""
    var weekWorkoutDates: Set<Date> = []
    var generatedWorkout: GeneratedWorkout?
    var isGenerating = false
    var isGeneratingMock = false
    var isShowingError = false
    var errorMessage = ""
    var startedWorkout: GeneratedWorkout?

    private let service: WorkoutGenerationService
    private let mockService: WorkoutGenerationService
    private let catalogService: ExerciseCatalogService
    let assetURLBuilder: ExerciseAssetURLBuilder
    let userProfileStore: UserProfileStore
    let trainingPreferencesStore: TrainingPreferencesStore
    let equipmentProfileStore: EquipmentProfileStore
    private let historyService: WorkoutHistoryService
    private var lastRequest: WorkoutGenerationRequest?

    private var cachedBodyContext: UserBodyContext?
    private var cachedTrainingPreferences: TrainingPreferences?
    private var cachedEquipmentProfile: EquipmentProfile?

    init(
        service: WorkoutGenerationService,
        mockService: WorkoutGenerationService,
        catalogService: ExerciseCatalogService,
        assetURLBuilder: ExerciseAssetURLBuilder,
        userProfileStore: UserProfileStore,
        trainingPreferencesStore: TrainingPreferencesStore,
        equipmentProfileStore: EquipmentProfileStore,
        historyService: WorkoutHistoryService
    ) {
        self.service = service
        self.mockService = mockService
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
                let workout = try await service.generateWorkout(for: request)
                generatedWorkout = workout
                startedWorkout = workout
            } catch {
                show(error)
            }
            isGenerating = false
        }
    }

    func generateMock() {
        guard !isGenerating else { return }
        isGenerating = true
        isGeneratingMock = true
        isShowingError = false
        errorMessage = ""

        Task {
            do {
                let request = try await makeRequest()
                lastRequest = request
                let workout = try await mockService.generateWorkout(for: request)
                generatedWorkout = workout
                startedWorkout = workout
            } catch {
                show(error)
            }
            isGeneratingMock = false
            isGenerating = false
        }
    }

    func regenerate(guidance: String = "") {
        guard !isGenerating else { return }
        isGenerating = true
        isShowingError = false
        errorMessage = ""

        Task {
            do {
                var request: WorkoutGenerationRequest
                if let lastRequest {
                    request = lastRequest
                } else {
                    request = try await makeRequest()
                }
                let trimmedGuidance = guidance.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedGuidance.isEmpty {
                    request.todayNotes = [request.todayNotes, trimmedGuidance]
                        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        .joined(separator: "\nRegeneration guidance: ")
                    request.clientRequestID = UUID()
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
            let cal = Calendar.current
            weekWorkoutDates = Set(summary.recentWorkouts.map { cal.startOfDay(for: $0.completedAt) })
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
        historyService: HomePreviewWorkoutHistoryService(),
        settingsViewModel: SettingsViewModel(
            loadSettings: { .empty },
            saveSettings: { _ in }
        )
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
