import SwiftUI

struct IntensityBars: View {
    @Binding var value: String
    var options: [String] = ["Recovery", "Light", "Moderate", "Hard", "All-out"]

    private let barSpacing: CGFloat = 6
    private let rampMinHeight: CGFloat = 24
    private let rampMaxHeight: CGFloat = 83

    private func rampHeight(at x: CGFloat, totalWidth: CGFloat) -> CGFloat {
        guard totalWidth > 0 else { return rampMinHeight }

        let progress = max(0, min(1, x / totalWidth))
        return rampMinHeight + (rampMaxHeight - rampMinHeight) * progress
    }

    private func optionIndex(at x: CGFloat, width: CGFloat) -> Int {
        guard options.isEmpty == false else { return 0 }

        let clamped = max(0, min(width, x))
        let i = Int(clamped / (width / CGFloat(options.count)))
        return min(options.count - 1, i)
    }

    private func selectOption(at x: CGFloat, width: CGFloat) {
        guard options.isEmpty == false else { return }

        let i = optionIndex(at: x, width: width)
        let option = options[i]
        if option != value {
            value = option
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let slotWidth = max(
                    0,
                    (geo.size.width - barSpacing * CGFloat(max(0, options.count - 1))) / CGFloat(max(1, options.count))
                )

                HStack(alignment: .bottom, spacing: barSpacing) {
                    ForEach(Array(options.enumerated()), id: \.element) { index, option in
                        let isSelected = option == value
                        let leftX = CGFloat(index) * (slotWidth + barSpacing)
                        let rightX = leftX + slotWidth
                        let leftHeight = rampHeight(at: leftX, totalWidth: geo.size.width)
                        let rightHeight = rampHeight(at: rightX, totalWidth: geo.size.width)

                        ZStack(alignment: .bottom) {
                            SlantedRoundedBar(leftHeight: leftHeight, rightHeight: rightHeight, cornerRadius: 4)
                                .fill(isSelected ? BrainlessTheme.ink : BrainlessTheme.surface2)
                                .frame(width: slotWidth, height: rampMaxHeight)

                            Circle()
                                .fill(isSelected ? Color.white.opacity(0.55) : BrainlessTheme.inkHairStrong)
                                .frame(width: 4, height: 4)
                                .padding(.bottom, 8)
                        }
                        .frame(width: slotWidth, height: rampMaxHeight, alignment: .bottom)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.72), value: value)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { tap in
                            selectOption(at: tap.location.x, width: geo.size.width)
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { drag in
                            guard abs(drag.translation.width) > abs(drag.translation.height) else { return }
                            selectOption(at: drag.location.x, width: geo.size.width)
                        }
                )
            }
            .frame(height: 74)
            .padding(.horizontal, 4)
            .sensoryFeedback(.selection, trigger: value)

            HStack(spacing: barSpacing) {
                ForEach(Array(options.enumerated()), id: \.element) { _, option in
                    let isSelected = option == value
                    Text(option)
                        .font(.system(size: isSelected ? 11 : 10, weight: isSelected ? .semibold : .regular, design: .monospaced))
                        .foregroundStyle(isSelected ? BrainlessTheme.ink : BrainlessTheme.inkFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
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
    @Previewable @State var intensity = "Hard"
    IntensityBars(value: $intensity)
        .padding(20)
        .background(BrainlessTheme.bg)
}

private struct SlantedRoundedBar: Shape {
    let leftHeight: CGFloat
    let rightHeight: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let bottom = rect.maxY
        let leftTop = bottom - leftHeight
        let rightTop = bottom - rightHeight
        
        var path = Path()
        
        // Start bottom-left
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: bottom))
        
        // Bottom edge to bottom-right
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: bottom), control: CGPoint(x: rect.maxX, y: bottom))
        path.addLine(to: CGPoint(x: rect.maxX, y: rightTop + cornerRadius))
        
        // Top-right corner
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadius, y: rightTop), control: CGPoint(x: rect.maxX, y: rightTop))
        
        // Top-left corner
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: leftTop))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: leftTop + cornerRadius), control: CGPoint(x: rect.minX, y: leftTop))
        
        // Left side to bottom-left
        path.addLine(to: CGPoint(x: rect.minX, y: bottom - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + cornerRadius, y: bottom), control: CGPoint(x: rect.minX, y: bottom))
        
        path.closeSubpath()
        return path
    }
}
