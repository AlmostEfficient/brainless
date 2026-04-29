//
//  APIClient.swift
//  Brainless
//
//  Created by Codex on 29/04/2026.
//

import Foundation

struct APIClient {
    let baseURL: URL

    private let session: URLSession
    private let tokenProvider: APITokenProvider
    private let decoder: JSONDecoder

    init(
        baseURL: URL = URL(string: "https://nexus.raza.run/v1")!,
        session: URLSession = .shared,
        tokenProvider: APITokenProvider = EmptyAPITokenProvider(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
        self.decoder = decoder
    }

    func get<Response: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        guard let url = makeURL(path: path, queryItems: queryItems) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = await tokenProvider.apiToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw decodeAPIError(data: data, statusCode: httpResponse.statusCode)
            }

            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw APIError.decodingFailed(error.localizedDescription)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
    }

    private func makeURL(path: String, queryItems: [URLQueryItem]) -> URL? {
        let pathComponent = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appending(path: pathComponent)

        guard !queryItems.isEmpty else {
            return url
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.filter { item in
            guard let value = item.value else { return false }
            return !value.isEmpty
        }
        return components?.url
    }

    private func decodeAPIError(data: Data, statusCode: Int) -> APIError {
        if let apiError = try? decoder.decode(APIErrorResponse.self, from: data) {
            return .requestFailed(
                statusCode: statusCode,
                code: apiError.error.code,
                message: apiError.error.message
            )
        }

        let fallbackMessage = HTTPURLResponse.localizedString(forStatusCode: statusCode)
        return .requestFailed(statusCode: statusCode, code: nil, message: fallbackMessage)
    }
}
