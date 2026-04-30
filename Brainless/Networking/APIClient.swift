//
//  APIClient.swift
//  Brainless
//
//  Created by Codex on 29/04/2026.
//

import Foundation
import os

struct APIClient {
    let baseURL: URL

    private static let logger = Logger(subsystem: "com.raza.Brainless", category: "APIClient")

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

    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        guard let url = makeURL(path: path, queryItems: []) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let encodedBody = try JSONEncoder.brainless.encode(body)
        request.httpBody = encodedBody
        let requestID = requestID(from: encodedBody)

        if let token = await tokenProvider.apiToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            Self.logger.info("POST \(url.absoluteString, privacy: .public) requestID=\(requestID ?? "none", privacy: .public)")
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                Self.logger.error("POST \(url.absoluteString, privacy: .public) returned a non-HTTP response requestID=\(requestID ?? "none", privacy: .public)")
                throw APIError.invalidResponse
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                Self.logger.error("POST \(url.absoluteString, privacy: .public) failed status=\(httpResponse.statusCode, privacy: .public) requestID=\(requestID ?? "none", privacy: .public) body=\(Self.responsePreview(data), privacy: .public)")
                throw decodeAPIError(data: data, statusCode: httpResponse.statusCode)
            }

            do {
                let decoded = try decoder.decode(Response.self, from: data)
                Self.logger.info("POST \(url.absoluteString, privacy: .public) decoded status=\(httpResponse.statusCode, privacy: .public) bytes=\(data.count, privacy: .public) requestID=\(requestID ?? "none", privacy: .public)")
                return decoded
            } catch {
                Self.logger.error("POST \(url.absoluteString, privacy: .public) decode failed status=\(httpResponse.statusCode, privacy: .public) bytes=\(data.count, privacy: .public) requestID=\(requestID ?? "none", privacy: .public) error=\(error.localizedDescription, privacy: .public) body=\(Self.responsePreview(data), privacy: .public)")
                throw APIError.decodingFailed(error.localizedDescription)
            }
        } catch let error as APIError {
            throw error
        } catch {
            Self.logger.error("POST \(url.absoluteString, privacy: .public) transport failed requestID=\(requestID ?? "none", privacy: .public) error=\(error.localizedDescription, privacy: .public)")
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

    private func requestID(from encodedBody: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: encodedBody) as? [String: Any],
            let requestID = object["clientRequestID"] as? String
        else {
            return nil
        }
        return requestID
    }

    private static func responsePreview(_ data: Data) -> String {
        guard !data.isEmpty else {
            return "<empty>"
        }

        let text = String(decoding: data, as: UTF8.self)
            .replacingOccurrences(of: "\n", with: "\\n")
        let maxLength = 1_500
        guard text.count > maxLength else {
            return text
        }
        return "\(text.prefix(maxLength))..."
    }
}
