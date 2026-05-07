import SwiftUI

struct RulerPicker: View {
    @Binding var value: Double
    var minValue: Double = 10
    var maxValue: Double = 90
    var step: Double = 5
    var unit: String = "min"

    @State private var gestureStartValue: Double?
    @State private var lastSnapped: Double = .nan
    private let pxPerUnit: CGFloat = 6
    private let feedbackLight = UIImpactFeedbackGenerator(style: .light)
    private let feedbackMedium = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(Int(value).formatted())
                    .font(.system(size: 28, weight: .semibold).monospacedDigit())
                    .foregroundStyle(BrainlessTheme.ink)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundStyle(BrainlessTheme.inkFaint)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)

            GeometryReader { geo in
                ZStack {
                    Canvas { ctx, size in
                        let cx = size.width / 2
                        for vi in Int(minValue)...Int(maxValue) {
                            let v = Double(vi)
                            let isMajor = vi % 10 == 0
                            let isMid   = vi % 5 == 0 && !isMajor
                            let tickH: CGFloat = isMajor ? 18 : (isMid ? 12 : 7)
                            let x = cx + CGFloat(v - value) * pxPerUnit
                            guard x > -8, x < size.width + 8 else { continue }
                            let alpha: Double = isMajor ? 0.18 : (isMid ? 0.13 : 0.08)
                            ctx.fill(
                                Path(CGRect(x: x - 0.5, y: size.height - tickH - 6, width: 1, height: tickH)),
                                with: .color(Color(red: 0.102, green: 0.090, blue: 0.078).opacity(alpha))
                            )
                            if isMajor {
                                ctx.draw(
                                    Text(String(vi))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(BrainlessTheme.inkDim),
                                    at: CGPoint(x: x, y: size.height - tickH - 8),
                                    anchor: .bottom
                                )
                            }
                        }
                    }
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 0.14),
                                .init(color: .black, location: 0.86),
                                .init(color: .clear, location: 1),
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )

                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(BrainlessTheme.accent)
                            .frame(width: 2, height: 21)
                            .padding(.bottom, 3)
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(height: 40)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { g in
                    guard abs(g.translation.width) > abs(g.translation.height) else { return }

                    if gestureStartValue == nil {
                        gestureStartValue = value
                        lastSnapped = value
                        feedbackMedium.prepare()
                        feedbackLight.prepare()
                    }
                    let start = gestureStartValue ?? value
                    let raw = start - Double(g.translation.width / pxPerUnit)
                    let snapped = (raw / step).rounded() * step
                    let clamped = Swift.max(minValue, Swift.min(maxValue, snapped))
                    if clamped != lastSnapped {
                        lastSnapped = clamped
                        let isEdge = clamped == minValue || clamped == maxValue
                        if isEdge {
                            feedbackMedium.impactOccurred()
                        } else {
                            feedbackLight.impactOccurred(intensity: 0.6)
                        }
                    }
                    value = clamped
                }
                .onEnded { _ in
                    gestureStartValue = nil
                    lastSnapped = .nan
                }
        )
    }
}

#Preview {
    @Previewable @State var val: Double = 45
    VStack {
        RulerPicker(value: $val, minValue: 10, maxValue: 90, step: 5, unit: "min")
    }
    .padding(20)
    .background(BrainlessTheme.bg)
}
