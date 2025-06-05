//
//  CreateSessionRequest.swift
//  PhiAI
//

import Foundation

extension APIManager {
    
    func getChatHistory(sessionId: Int64) async throws -> [ChatMessage] {
        guard var urlComponents = URLComponents(string: "\(baseURL)/api/chat/history") else {
            throw APIError.invalidURL
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "sessionId", value: String(sessionId))
        ]
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = KeychainHelper.shared.read(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "无正文"
            print("获取历史记录失败（状态码：\(httpResponse.statusCode)）：\(body)")
            throw URLError(.badServerResponse)
        }

        do {
            let decodedResponse = try JSONDecoder().decode(ChatMessageListResponse.self, from: data)
            guard decodedResponse.code == 200 else {
                throw APIError.custom(decodedResponse.message)
            }
            return decodedResponse.data
        } catch {
            print("解析历史记录失败：\(error.localizedDescription)")
            let raw = String(data: data, encoding: .utf8) ?? "非文本响应"
            print("原始返回内容：\(raw)")
            throw error
        }
    }

//    func sendMessageToChatBot(message: String, sessionId: Int, userId: Int) async throws -> String {
//        let endpoint = "/api/chat/text"
//        let urlString = "\(baseURL)\(endpoint)?content=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&sessionId=\(sessionId)&userId=\(userId)"
//        guard let url = URL(string: urlString) else {
//            throw APIError.invalidURL
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//
//        if let token = KeychainHelper.shared.get(for: "authToken") {
//            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        }
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//
//        guard let httpResponse = response as? HTTPURLResponse else {
//            throw APIError.invalidResponse
//        }
//
//        if httpResponse.statusCode == 200 {
//            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//               let dataDict = json["data"] as? [String: Any],
//               let reply = dataDict["reply"] as? String {
//                return reply
//            } else {
//                throw APIError.invalidResponse
//            }
//        } else {
//            throw APIError.serverError("服务器返回状态码: \(httpResponse.statusCode)")
//        }
//    }

}

extension APIManager {
    struct CreateSessionRequest: Codable {
        let userId: Int
    }
    
    struct CreateSessionResponse: Codable {
        let code: Int
        let message: String
        let data: ChatSession?
    }
    
    func createChatSession(userId: Int) async throws -> ChatSession {
        let endpoint = "/api/chat/session?userId=\(userId)"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainHelper.shared.read(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = nil
        let (data, _) = try await URLSession.shared.data(for: request)

        let decoded = try JSONDecoder().decode(CreateSessionResponse.self, from: data)
        guard decoded.code == 200 else {
            throw APIError.serverError(decoded.message)
        }
        guard let session = decoded.data else {
            throw APIError.emptyData
        }
        return session
    }
}

extension APIManager {
    struct ChatSessionsResponse: Codable {
        let code: Int
        let data: [ChatSession]?
        let message: String
    }

    func getAllChatSessions(userId: Int) async throws -> [ChatSession] {
        let urlString = "\(baseURL)/api/chat/sessions?userId=\(userId)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = KeychainHelper.shared.read(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ChatSessionsResponse.self, from: data)

        guard response.code == 200 else {
            throw APIError.custom(response.message)
        }

        guard let sessions = response.data else {
            throw APIError.emptyData
        }
        return sessions
    }

    
    struct GenericResponse<T: Codable>: Codable {
        let code: Int
        let message: String
        let data: T
    }
    
    //删除对话
    func deleteChatSession(sessionId: Int) async throws -> Bool {
        let url = URL(string: "\(baseURL)/api/chat/session/\(sessionId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(GenericResponse<Bool>.self, from: data)
        return decoded.data
    }

}
