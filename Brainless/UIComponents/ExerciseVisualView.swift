//
//  ExerciseVisualView.swift
//  Brainless
//
//  Created by Codex on 29/04/2026.
//

import SwiftUI

struct ExerciseVisualView: View {
    let assetID: String?
    var assetURLBuilder: ExerciseAssetURLBuilder

    init(
        assetID: String?,
        assetURLBuilder: ExerciseAssetURLBuilder = ExerciseAssetURLBuilder()
    ) {
        self.assetID = assetID
        self.assetURLBuilder = assetURLBuilder
    }

    var body: some View {
        AsyncImage(url: assetURLBuilder.gifURL(for: assetID)) { phase in
            switch phase {
            case .empty:
                if assetURLBuilder.gifURL(for: assetID) == nil { fallback } else { placeholder }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                fallback
            @unknown default:
                fallback
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel("Exercise visual")
    }

    private var placeholder: some View {
        ZStack {
            Color(.secondarySystemBackground)
            ProgressView()
        }
    }

    private var fallback: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ExerciseVisualView(assetID: "I4hDWkc")
        .padding()
}
