import SwiftUI

struct WeightTuner: View {
    @Binding var value: Double
    var minValue: Double = 0
    var maxValue: Double = 200
    var step: Double = 2.5

    @State private var gestureStartValue: Double?
    private let pxPerStep: CGFloat = 18

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value.formatted(.number.precision(.fractionLength(0...1))))
                    .font(.system(size: 44, weight: .semibold).monospacedDigit())
                    .foregroundStyle(BrainlessTheme.ink)
                    .contentTransition(.numericText())
                Text("kg")
                    .font(.system(size: 13))
                    .foregroundStyle(BrainlessTheme.inkFaint)
            }
            .frame(maxWidth: .infinity)

            GeometryReader { geo in
                ZStack {
                    Canvas { ctx, size in
                        let cx = size.width / 2
                        var v = minValue
                        while v <= maxValue + 0.001 {
                            let isMajor = abs(v.truncatingRemainder(dividingBy: 10)) < 0.01
                            let isHalf  = abs(v.truncatingRemainder(dividingBy: 5)) < 0.01 && !isMajor
                            let tickH: CGFloat = isMajor ? 30 : (isHalf ? 22 : 14)
                            let topY:  CGFloat = isMajor ? 18 : (isHalf ? 24 : 28)
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
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(BrainlessTheme.inkDim),
                                    at: CGPoint(x: x, y: 14),
                                    anchor: .center
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
                            .frame(width: 2, height: 38)
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(height: 60)
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

            HStack(spacing: 8) {
                stepperBtn(icon: "minus") { value = Swift.max(minValue, ((value - step) / step).rounded() * step) }
                stepperBtn(icon: "plus")  { value = Swift.min(maxValue, ((value + step) / step).rounded() * step) }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 10)
        }
    }

    private func stepperBtn(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(BrainlessTheme.inkDim)
                .frame(width: 36, height: 32)
                .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var w: Double = 60
    WeightTuner(value: $w)
        .padding(20)
        .background(BrainlessTheme.bg)
}
