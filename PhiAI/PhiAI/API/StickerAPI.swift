//
//  StickerAPI.swift
//  PhiAI
//


import Foundation

extension APIManager {
    func postMessageToWall(request: PostMessageRequest) async throws -> Int64 {
        guard let url = URL(string: "\(baseURL)/community/post") else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decodedResponse = try JSONDecoder().decode(PostMessageResponse.self, from: data)

        if let id = decodedResponse.data {
            return id
        } else {
            throw NSError(domain: "", code: decodedResponse.code, userInfo: [NSLocalizedDescriptionKey: decodedResponse.message])
        }
    }
}

extension APIManager {
    func fetchStickerMessages(page: Int = 1, size: Int = 50) async throws -> [StickerMessage] {
        var components = URLComponents(string: "\(baseURL)/community/post/page")!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        if let json = String(data: data, encoding: .utf8) {
            print("Response JSON: \(json)")
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(GetStickerMessagesResponse.self, from: data)
        return decoded.data.records
    }
}

extension APIManager {
    func deletePost(postId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/community/post/\(postId)") else {
            print(" 无效的 URL")
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = KeychainHelper.shared.read(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        print(" 正在发送 DELETE 请求到：\(url.absoluteString)")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print(" 收到响应状态码：\(httpResponse.statusCode)")
                if (200..<300).contains(httpResponse.statusCode) {
                    print(" 删除成功")
                } else {
                    print(" 删除失败，状态码：\(httpResponse.statusCode)")
                    throw URLError(.badServerResponse)
                }
            } else {
                print(" 无法解析 HTTP 响应")
                throw URLError(.badServerResponse)
            }

        } catch {
            print(" 网络请求失败：\(error.localizedDescription)")
            throw error
        }
    }
}


