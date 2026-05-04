import SwiftUI

struct RepsPicker: View {
    @Binding var value: Int
    var presets: [Int] = [4, 6, 8, 10, 12]

    var isCustom: Bool { !presets.contains(value) }

    var body: some View {
        VStack(spacing: 8) {
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
            }

            HStack(spacing: 8) {
                Text("CUSTOM")
                    .font(.system(size: 11, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(BrainlessTheme.inkFaint)
                Spacer()
                Button(action: { if value > 1 { value -= 1 } }) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(BrainlessTheme.inkDim)
                        .frame(width: 28, height: 28)
                        .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                Text(String(value))
                    .font(.system(size: 15, weight: .semibold).monospacedDigit())
                    .foregroundStyle(BrainlessTheme.ink)
                    .frame(minWidth: 36, alignment: .center)
                Button(action: { value += 1 }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(BrainlessTheme.inkDim)
                        .frame(width: 28, height: 28)
                        .background(BrainlessTheme.bgCard, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(BrainlessTheme.inkHair, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(isCustom ? BrainlessTheme.bgCard : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isCustom ? BrainlessTheme.inkHairStrong : BrainlessTheme.inkHair, lineWidth: 0.5)
            )
            .animation(.easeInOut(duration: 0.12), value: isCustom)
        }
    }
}

#Preview {
    @Previewable @State var reps = 8
    RepsPicker(value: $reps)
        .padding(20)
        .background(BrainlessTheme.bg)
}
