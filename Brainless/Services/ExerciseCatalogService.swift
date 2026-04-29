//
//  ExerciseCatalogService.swift
//  Brainless
//
//  Created by Codex on 29/04/2026.
//

import Foundation

protocol ExerciseCatalogService {
    func exercises(matching query: ExerciseCatalogQuery) async throws -> ExerciseCatalogResponse
}

struct ExerciseCatalogQuery: Equatable {
    var muscle: String?
    var equipment: String?
    var bodyPart: String?
    var excludeTags: [String]
    var q: String?
    var limit: Int?
    var offset: Int?

    init(
        muscle: String? = nil,
        equipment: String? = nil,
        bodyPart: String? = nil,
        excludeTags: [String] = [],
        q: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.muscle = muscle
        self.equipment = equipment
        self.bodyPart = bodyPart
        self.excludeTags = excludeTags
        self.q = q
        self.limit = limit
        self.offset = offset
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.appendIfPresent(name: "muscle", value: muscle)
        items.appendIfPresent(name: "equipment", value: equipment)
        items.appendIfPresent(name: "bodyPart", value: bodyPart)
        items.appendIfPresent(name: "excludeTags", value: excludeTags.isEmpty ? nil : excludeTags.joined(separator: ","))
        items.appendIfPresent(name: "q", value: q)
        items.appendIfPresent(name: "limit", value: limit.map(String.init))
        items.appendIfPresent(name: "offset", value: offset.map(String.init))
        return items
    }
}

private extension Array where Element == URLQueryItem {
    mutating func appendIfPresent(name: String, value: String?) {
        guard let value, !value.isEmpty else { return }
        append(URLQueryItem(name: name, value: value))
    }
}
