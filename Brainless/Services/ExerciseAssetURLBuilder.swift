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

    func gifURL(for exerciseID: String) -> URL {
        assetsBaseURL.appending(path: "exercises/gifs/\(exerciseID).gif")
    }

    func posterURL(for exerciseID: String) -> URL {
        assetsBaseURL.appending(path: "exercises/posters/\(exerciseID).jpg")
    }
}
