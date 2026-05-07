import SwiftUI

struct RepsPicker: View {
    @Binding var value: Int
    private let presets: [Int] = [4, 6, 8, 10]

    @State private var customValue: Int = 12
    @State private var dragStartValue: Int?
    @State private var lastSnapped: Int = 0
    private let pxPerRep: CGFloat = 7
    private let feedback = UIImpactFeedbackGenerator(style: .light)

    private var isCustomSelected: Bool { !presets.contains(value) }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(presets, id: \.self) { n in
                let on = n == value
                Button(action: { value = n }) {
                    Text(String(n))
                        .font(.system(size: 16, weight: .semibold).monospacedDigit())
                        .foregroundStyle(on ? BrainlessTheme.bgCard : BrainlessTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(on ? BrainlessTheme.ink : BrainlessTheme.bgCard,
                                    in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(on ? BrainlessTheme.ink : BrainlessTheme.inkHair, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.12), value: value)
            }

            customDrumPicker
        }
    }

    private var customDrumPicker: some View {
        let isOn = isCustomSelected
        let displayed = isOn ? value : customValue

        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isOn ? BrainlessTheme.ink : BrainlessTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOn ? BrainlessTheme.ink : BrainlessTheme.inkHair, lineWidth: 0.5)
                )

            VStack(spacing: 2) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(isOn ? Color.white.opacity(0.5) : BrainlessTheme.inkFaint)
                Text(String(displayed))
                    .font(.system(size: 16, weight: .semibold).monospacedDigit())
                    .foregroundStyle(isOn ? BrainlessTheme.bgCard : BrainlessTheme.ink)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.08), value: displayed)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(isOn ? Color.white.opacity(0.5) : BrainlessTheme.inkFaint)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { g in
                    if dragStartValue == nil {
                        let start = isCustomSelected ? value : customValue
                        dragStartValue = start
                        lastSnapped = start
                        feedback.prepare()
                    }
                    let start = Double(dragStartValue ?? (isCustomSelected ? value : customValue))
                    // drag up (negative height) → increase
                    let raw = start - Double(g.translation.height / pxPerRep)
                    let snapped = max(1, min(99, Int(raw.rounded())))
                    if snapped != lastSnapped {
                        lastSnapped = snapped
                        feedback.impactOccurred(intensity: 0.5)
                    }
                    customValue = snapped
                    value = snapped
                }
                .onEnded { _ in dragStartValue = nil }
        )
    }
}

#Preview {
    @Previewable @State var reps = 8
    RepsPicker(value: $reps)
        .padding(20)
        .background(BrainlessTheme.bg)
}
