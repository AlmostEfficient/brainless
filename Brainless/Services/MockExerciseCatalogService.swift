//
//  MockExerciseCatalogService.swift
//  Brainless
//
//  Created by Codex on 29/04/2026.
//

import Foundation

struct MockExerciseCatalogService: ExerciseCatalogService {
    var response: ExerciseCatalogResponse
    var delayNanoseconds: UInt64

    init(
        response: ExerciseCatalogResponse = .mock,
        delayNanoseconds: UInt64 = 0
    ) {
        self.response = response
        self.delayNanoseconds = delayNanoseconds
    }

    func exercises(matching query: ExerciseCatalogQuery) async throws -> ExerciseCatalogResponse {
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        return response
    }
}

extension ExerciseCatalogResponse {
    static let mock = ExerciseCatalogResponse(
        data: [
            ExerciseCatalogExercise(id: "0001", name: "Push Up", muscle: "chest", equipment: "body weight"),
            ExerciseCatalogExercise(id: "0002", name: "Squat", muscle: "quadriceps", equipment: "body weight"),
            ExerciseCatalogExercise(id: "0003", name: "Pull Up", muscle: "lats", equipment: "body weight")
        ],
        meta: ExerciseCatalogMeta(total: 3, limit: 20, offset: 0, nextOffset: nil)
    )
}
