//
//  ExerciseVisualView.swift
//  Brainless
//
//  Created by Codex on 29/04/2026.
//

import SwiftUI

struct ExerciseVisualView: View {
    let exerciseID: String
    var assetURLBuilder: ExerciseAssetURLBuilder

    init(
        exerciseID: String,
        assetURLBuilder: ExerciseAssetURLBuilder = ExerciseAssetURLBuilder()
    ) {
        self.exerciseID = exerciseID
        self.assetURLBuilder = assetURLBuilder
    }

    var body: some View {
        AsyncImage(url: assetURLBuilder.gifURL(for: exerciseID)) { phase in
            switch phase {
            case .empty:
                placeholder
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
    ExerciseVisualView(exerciseID: "0001")
        .padding()
}
