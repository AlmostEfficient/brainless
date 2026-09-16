import SwiftUI

struct TextWorkoutModeView: View {
    let workout: TextWorkoutPlan
    let onRegenerate: (String) -> Void
    let isRegenerating: Bool
    let onClose: () -> Void

    @State private var selection = 0
    @State private var guidance = ""

    private var steps: [TextWorkoutStep] {
        workout.sections.flatMap { section in
            section.exercises.map { exercise in
                TextWorkoutStep(section: section, exercise: exercise)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if steps.isEmpty {
                emptyState
            } else {
                TabView(selection: $selection) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        TextWorkoutStepView(
                            workout: workout,
                            step: step,
                            index: index,
                            total: steps.count
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            footer
        }
        .background(BrainlessTheme.bg.ignoresSafeArea())
        .onChange(of: workout.id) { _, _ in selection = 0 }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BrainlessTheme.inkDim)
                    .frame(width: 40, height: 40)
                    .background(BrainlessTheme.bgCard, in: Circle())
                    .overlay(Circle().stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BrainlessTheme.ink)
                    .lineLimit(1)
                Text("\(workout.estimatedDurationMinutes) min · \(workout.intensity)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(BrainlessTheme.inkFaint)
            }

            Spacer()

            Text(steps.isEmpty ? "0/0" : "\(selection + 1)/\(steps.count)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(BrainlessTheme.inkDim)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(BrainlessTheme.surface2, in: Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.page")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(BrainlessTheme.inkFaint)
            Text("No exercises returned.")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(BrainlessTheme.ink)
            Text(workout.message)
                .font(.system(size: 14))
                .foregroundStyle(BrainlessTheme.inkDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    selection = max(0, selection - 1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(BrainlessTheme.inkDim)
                .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                .disabled(selection == 0)

                TextField("Ask for a change…", text: $guidance, axis: .vertical)
                    .lineLimit(1...3)
                    .font(.system(size: 14))
                    .foregroundStyle(BrainlessTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))

                Button {
                    submitGuidance()
                } label: {
                    if isRegenerating {
                        ProgressView()
                            .controlSize(.small)
                            .tint(BrainlessTheme.inkDim)
                            .frame(width: 44, height: 44)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(BrainlessTheme.inkDim)
                .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                .disabled(isRegenerating || guidance.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    selection = min(max(steps.count - 1, 0), selection + 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(BrainlessTheme.inkDim)
                .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                .disabled(selection >= steps.count - 1)
            }

            Text(workout.safetyNote)
                .font(.system(size: 11))
                .foregroundStyle(BrainlessTheme.inkFaint)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(BrainlessTheme.bgElev)
    }

    private func submitGuidance() {
        let trimmed = guidance.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guidance = ""
        onRegenerate(trimmed)
    }
}

private struct TextWorkoutStep: Identifiable {
    let section: TextWorkoutSection
    let exercise: TextWorkoutExercise

    var id: UUID { exercise.id }
}

private struct TextWorkoutStepView: View {
    let workout: TextWorkoutPlan
    let step: TextWorkoutStep
    let index: Int
    let total: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(step.section.title.uppercased())
                    .font(.system(size: 11, design: .monospaced))
                    .tracking(1.0)
                    .foregroundStyle(BrainlessTheme.accent)
                    .padding(.bottom, 8)

                Text(step.exercise.name)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(BrainlessTheme.ink)
                    .lineSpacing(2)
                    .padding(.bottom, 14)

                Text(step.exercise.prescription)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BrainlessTheme.ink)
                    .padding(.bottom, 20)

                detailBlock(title: "Do This", text: step.exercise.instructions)
                    .padding(.bottom, 12)

                detailBlock(title: "Rest", text: step.exercise.rest)
                    .padding(.bottom, 12)

                if !step.exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    detailBlock(title: "Note", text: step.exercise.notes)
                        .padding(.bottom, 12)
                }

                detailBlock(title: "Why", text: step.section.purpose)
                    .padding(.bottom, 22)

                Text(workout.message)
                    .font(.system(size: 13))
                    .foregroundStyle(BrainlessTheme.inkDim)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .background(BrainlessTheme.accentSoft, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.accent.opacity(0.16), lineWidth: 0.5))
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 28)
        }
    }

    private func detailBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.system(size: 10, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(BrainlessTheme.inkFaint)
            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(BrainlessTheme.inkDim)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
    }
}

#Preview {
    TextWorkoutModeView(
        workout: .sample,
        onRegenerate: { _ in },
        isRegenerating: false,
        onClose: {}
    )
}
