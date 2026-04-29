//
//  APIError.swift
//  Brainless
//
//  Created by Codex on 29/04/2026.
//

import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int, code: String?, message: String)
    case decodingFailed(String)
    case transport(String)
}

extension APIError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The backend URL is invalid."
        case .invalidResponse:
            "The backend returned an invalid response."
        case .requestFailed(_, _, let message):
            message
        case .decodingFailed(let message):
            "The backend response could not be decoded: \(message)"
        case .transport(let message):
            message
        }
    }
}

struct APIErrorResponse: Decodable, Equatable {
    let error: APIErrorBody
}

struct APIErrorBody: Decodable, Equatable {
    let code: String
    let message: String
}
