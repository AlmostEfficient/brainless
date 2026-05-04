import SwiftUI

struct IntensityBars: View {
    @Binding var value: String
    var options: [String] = ["Recovery", "Light", "Moderate", "Hard", "All-out"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.element) { i, option in
                    let isActive = option == value
                    let barH: CGFloat = 28 + CGFloat(i) * 12
                    let skewDeg: Double = -3 - Double(i) * 1.5

                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: isActive ? 999 : 4)
                            .fill(isActive ? BrainlessTheme.accent : BrainlessTheme.inkHair)
                            .frame(height: barH)
                            .transformEffect(
                                isActive
                                    ? .identity
                                    : CGAffineTransform(a: 1, b: 0,
                                                        c: CGFloat(tan(skewDeg * .pi / 180)),
                                                        d: 1, tx: 0, ty: 0)
                            )
                            .animation(.easeInOut(duration: 0.18), value: value)

                        if isActive {
                            Circle()
                                .fill(Color.white.opacity(0.75))
                                .frame(width: 4, height: 4)
                                .padding(.bottom, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .onTapGesture { value = option }
                }
            }
            .frame(height: 80)
            .padding(.horizontal, 4)

            HStack(spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.element) { i, option in
                    let isActive = option == value
                    Text(option)
                        .font(.system(size: isActive ? 12 : 10, weight: isActive ? .semibold : .medium))
                        .foregroundStyle(isActive ? BrainlessTheme.ink : BrainlessTheme.inkFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut(duration: 0.18), value: value)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 10)
        }
    }
}

#Preview {
    @Previewable @State var intensity = "Moderate"
    IntensityBars(value: $intensity)
        .padding(20)
        .background(BrainlessTheme.bg)
}
