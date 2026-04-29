//
//  APITokenProvider.swift
//  Brainless
//
//  Created by Codex on 29/04/2026.
//

import Foundation

protocol APITokenProvider {
    var apiToken: String? { get async }
}

struct EmptyAPITokenProvider: APITokenProvider {
    var apiToken: String? {
        get async { nil }
    }
}
