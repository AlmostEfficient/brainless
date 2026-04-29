import SwiftUI

struct SwipeCyclePill<T: Equatable>: View {
    let options: [T]
    @Binding var selection: T
    let label: (T) -> String

    @State private var startIndex: Int? = nil
    private let stepThreshold: CGFloat = 55

    private var currentIndex: Int {
        options.firstIndex(where: { $0 == selection }) ?? 0
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "chevron.left")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
            Text(label(selection))
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.5), trigger: currentIndex)
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    if startIndex == nil { startIndex = currentIndex }
                    let steps = Int(value.translation.width / stepThreshold)
                    let newIndex = max(0, min(options.count - 1, (startIndex ?? 0) + steps))
                    if newIndex != currentIndex {
                        selection = options[newIndex]
                    }
                }
                .onEnded { _ in
                    startIndex = nil
                }
        )
    }
}

#Preview {
    @Previewable @State var duration = 45
    @Previewable @State var intensity = "Moderate"
    VStack(spacing: 12) {
        HStack(spacing: 8) {
            SwipeCyclePill(options: [20, 30, 45, 60, 75, 90], selection: $duration, label: { "\($0) min" })
            SwipeCyclePill(options: ["Easy", "Moderate", "Hard"], selection: $intensity, label: { $0 })
        }
        .padding(.horizontal, 20)
        Text("Duration: \(duration)  Intensity: \(intensity)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
