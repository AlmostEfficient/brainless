//
//  APIError.swift
//  Brainless
//
//  Created by Codex on 29/04/2026.
//

import Foundation

enum APIError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int, code: String?, message: String)
    case decodingFailed(String)
    case transport(String)
}

struct APIErrorResponse: Decodable, Equatable {
    let error: APIErrorBody
}

struct APIErrorBody: Decodable, Equatable {
    let code: String
    let message: String
}
