import SwiftUI

struct WeightTuner: View {
    @Binding var value: Double
    var minValue: Double = 0
    var maxValue: Double = 200
    var step: Double = 2.5

    @State private var gestureStartValue: Double?
    private let pxPerStep: CGFloat = 18

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value.formatted(.number.precision(.fractionLength(0...1))))
                    .font(.system(size: 28, weight: .semibold).monospacedDigit())
                    .foregroundStyle(BrainlessTheme.ink)
                    .contentTransition(.numericText())
                Text("kg")
                    .font(.system(size: 12))
                    .foregroundStyle(BrainlessTheme.inkFaint)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)

            GeometryReader { geo in
                ZStack {
                    Canvas { ctx, size in
                        let cx = size.width / 2
                        var v = minValue
                        while v <= maxValue + 0.001 {
                            let isMajor = abs(v.truncatingRemainder(dividingBy: 10)) < 0.01
                            let isHalf  = abs(v.truncatingRemainder(dividingBy: 5)) < 0.01 && !isMajor
                            let tickH: CGFloat = isMajor ? 18 : (isHalf ? 12 : 7)
                            let topY:  CGFloat = size.height - tickH - 6
                            let x = cx + CGFloat((v - value) / step) * pxPerStep
                            guard x > -8, x < size.width + 8 else { v += step; continue }
                            let alpha: Double = (isMajor ? 0.9 : (isHalf ? 0.6 : 0.4)) * 0.18
                            ctx.fill(
                                Path(CGRect(x: x - 0.5, y: topY, width: 1, height: tickH)),
                                with: .color(Color(red: 0.102, green: 0.090, blue: 0.078).opacity(alpha))
                            )
                            if isMajor {
                                ctx.draw(
                                    Text(String(Int(v)))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(BrainlessTheme.inkDim),
                                    at: CGPoint(x: x, y: size.height - tickH - 8),
                                    anchor: .bottom
                                )
                            }
                            v += step
                        }
                    }
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 0.18),
                                .init(color: .black, location: 0.82),
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
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { g in
                        if gestureStartValue == nil { gestureStartValue = value }
                        let start = gestureStartValue ?? value
                        let raw = start - Double(g.translation.width / pxPerStep) * step
                        let snapped = (raw / step).rounded() * step
                        value = Swift.max(minValue, Swift.min(maxValue, snapped))
                    }
                    .onEnded { _ in gestureStartValue = nil }
            )

        }
    }
}

#Preview {
    @Previewable @State var w: Double = 60
    WeightTuner(value: $w)
        .padding(20)
        .background(BrainlessTheme.bg)
}
