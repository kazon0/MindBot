//
//  ResourceAPI.swift
//  PhiAI
//

import Foundation

extension APIManager {
    func fetchResources() async throws -> [Resource] {
        guard let url = URL(string: "\(baseURL)/api/education/resources") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuthHeaders(to: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(APIResponse<[Resource]>.self, from: data)

        return decoded.data
    }
}
