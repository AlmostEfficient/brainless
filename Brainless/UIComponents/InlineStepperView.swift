//
//  InlineStepperView.swift
//  Brainless
//

import SwiftUI

struct InlineStepperView: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
            Spacer()
            HStack(spacing: 8) {
                Button { value -= 1 } label: {
                    Image(systemName: "minus")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(.body.monospacedDigit())
                    .frame(minWidth: 32, alignment: .center)

                Button { value += 1 } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .disabled(value >= range.upperBound)
            }
        }
    }
}

#Preview {
    @Previewable @State var value = 3
    InlineStepperView(label: "Days per week", value: $value, range: 2...7)
        .padding()
}
