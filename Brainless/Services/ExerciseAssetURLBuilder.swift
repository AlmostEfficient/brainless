//
//  ExerciseAssetURLBuilder.swift
//  Brainless
//
//  Created by Codex on 29/04/2026.
//

import Foundation

struct ExerciseAssetURLBuilder {
    let assetsBaseURL: URL

    init(assetsBaseURL: URL = URL(string: "https://assets.raza.run")!) {
        self.assetsBaseURL = assetsBaseURL
    }

    func gifURL(for assetID: String?) -> URL? {
        guard let assetID, !assetID.isEmpty,
              assetID.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil else { return nil }
        return assetsBaseURL.appending(path: "exercises/gifs/\(assetID).gif")
    }
}
