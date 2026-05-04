import SwiftUI

struct RulerPicker: View {
    @Binding var value: Double
    var minValue: Double = 10
    var maxValue: Double = 90
    var step: Double = 5
    var unit: String = "min"

    @State private var gestureStartValue: Double?
    private let pxPerUnit: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(Int(value).formatted())
                    .font(.system(size: 32, weight: .semibold).monospacedDigit())
                    .foregroundStyle(BrainlessTheme.ink)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.system(size: 13))
                    .foregroundStyle(BrainlessTheme.inkFaint)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 6)

            GeometryReader { geo in
                ZStack {
                    Canvas { ctx, size in
                        let cx = size.width / 2
                        for vi in Int(minValue)...Int(maxValue) {
                            let v = Double(vi)
                            let isMajor = vi % 10 == 0
                            let isMid   = vi % 5 == 0 && !isMajor
                            let tickH: CGFloat = isMajor ? 26 : (isMid ? 18 : 10)
                            let x = cx + CGFloat(v - value) * pxPerUnit
                            guard x > -8, x < size.width + 8 else { continue }
                            let alpha: Double = isMajor ? 0.18 : (isMid ? 0.153 : 0.099)
                            ctx.fill(
                                Path(CGRect(x: x - 0.5, y: size.height - tickH - 8, width: 1, height: tickH)),
                                with: .color(Color(red: 0.102, green: 0.090, blue: 0.078).opacity(alpha))
                            )
                            if isMajor {
                                ctx.draw(
                                    Text(String(vi))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(BrainlessTheme.inkDim),
                                    at: CGPoint(x: x, y: size.height - tickH - 10),
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
                            .frame(width: 2, height: 38)
                            .padding(.bottom, 4)
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(height: 56)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { g in
                    if gestureStartValue == nil { gestureStartValue = value }
                    let start = gestureStartValue ?? value
                    let raw = start - Double(g.translation.width / pxPerUnit)
                    let snapped = (raw / step).rounded() * step
                    value = Swift.max(minValue, Swift.min(maxValue, snapped))
                }
                .onEnded { _ in gestureStartValue = nil }
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
