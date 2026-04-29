//
//  SelectionChip.swift
//  Brainless
//

import SwiftUI

struct SelectionChip: View {
    let label: String
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                }
                Text(label)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    HStack {
        SelectionChip(label: "Strength", isSelected: true) {}
        SelectionChip(label: "Mobility", isSelected: false) {}
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
