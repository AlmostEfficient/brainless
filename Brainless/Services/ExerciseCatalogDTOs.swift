//
//  ExerciseCatalogDTOs.swift
//  Brainless
//
//  Created by Codex on 29/04/2026.
//

import Foundation

struct ExerciseCatalogResponse: Decodable, Equatable {
    let data: [ExerciseCatalogExercise]
    let meta: ExerciseCatalogMeta
}

struct ExerciseCatalogExercise: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let muscle: String
    let equipment: String
}

struct ExerciseCatalogMeta: Decodable, Equatable {
    let total: Int
    let limit: Int
    let offset: Int
    let nextOffset: Int?
}
