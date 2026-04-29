//
//  RemoteExerciseCatalogService.swift
//  Brainless
//
//  Created by Codex on 29/04/2026.
//

import Foundation

struct RemoteExerciseCatalogService: ExerciseCatalogService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func exercises(matching query: ExerciseCatalogQuery) async throws -> ExerciseCatalogResponse {
        try await apiClient.get("/exercises", queryItems: query.queryItems)
    }
}
