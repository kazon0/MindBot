//
//  MoodAnalysisAPI.swift
//  PhiAI
//

import Foundation

extension APIManager {
    
    func fetchMoodAnalysis(messageId: Int) async throws -> MoodAnalysis {
        let endpoint = "/api/mood-analysis/chat/\(messageId)/analyze"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = KeychainHelper.shared.read(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(MoodAnalysisResponse.self, from: data)

        guard decoded.code == 200 else {
            throw APIError.serverError(decoded.message)
        }

        return decoded.data
    }
}

extension APIManager {
    func fetchSessionMoodAnalysis(sessionId: Int) async throws -> SessionMoodAnalysisData {
        let endpoint = "/api/mood-analysis/chat/session/\(sessionId)/analyze"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = KeychainHelper.shared.read(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(SessionMoodAnalysisResponse.self, from: data)

        guard decoded.code == 200, let result = decoded.data else {
            throw APIError.serverError(decoded.message)
        }

        return result
    }
}


