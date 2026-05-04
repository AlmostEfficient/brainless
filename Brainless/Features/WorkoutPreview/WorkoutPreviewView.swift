import SwiftUI

struct WorkoutPreviewView: View {
    let workout: GeneratedWorkout
    let onStart: () -> Void
    let onRegenerate: () -> Void

    @State private var changeText = ""

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
                    .padding(.bottom, 40)
            }
        }
        .background(BrainlessTheme.bg.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: - Chrome

    private var topChrome: some View {
        HStack {
            Button {
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back")
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

    // MARK: - Stats

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statItem(value: "\(workout.estimatedDurationMinutes)", label: "MIN")
            statDivider
            statItem(value: focusStr, label: "FOCUS")
            statDivider
            statItem(value: "\(workout.exercises.count)", label: "EXERCISES")
        }
        .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
    }

    private var focusStr: String {
        workout.focus.prefix(2).map(\.displayName).joined(separator: "/")
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .semibold).monospacedDigit())
                .foregroundStyle(BrainlessTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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

    // MARK: - Exercise List

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

    // MARK: - Bottom

    private var bottomBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                TextField("Or type changes…", text: $changeText)
                    .font(.system(size: 14))
                    .foregroundStyle(BrainlessTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))

                Button(action: onRegenerate) {
                    Image(systemName: "mic")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(BrainlessTheme.inkDim)
                        .frame(width: 44, height: 44)
                        .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
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

#Preview {
    NavigationStack {
        WorkoutPreviewView(
            workout: .sample,
            onStart: {},
            onRegenerate: {}
        )
    }
}
