import Foundation

struct APIResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: T
}

class APIManager {
    static let shared = APIManager()
    private let baseURL = "http://qf83b3fd.natappfree.cc"
    
    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case loginFailed(String)
        case apiError(String)
        
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "无效的URL"
            case .invalidResponse: return "无效的响应"
            case .loginFailed(let message): return message
            case .apiError(let message): return message
            case .unknown: return "未知错误"
            }
        }
    }

    
    // 注册API
    func register(username: String, password: String) async throws {
        let endpoint = "/auth/register"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["username": username, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            // 注册成功，直接返回
            return
        } else {
            // 解析服务器返回的错误信息
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["message"] as? String {
                throw APIError.loginFailed(msg)
            } else {
                throw APIError.loginFailed("服务器返回错误，状态码：\(httpResponse.statusCode)")
            }
        }
    }

    
    // 登录
      func login(username: String, password: String) async throws -> UserInfo {
          let endpoint = "/auth/login"
          guard let url = URL(string: baseURL + endpoint) else {
              throw APIError.invalidURL
          }

          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          request.setValue("application/json", forHTTPHeaderField: "Content-Type")

          let body: [String: Any] = [
              "username": username,
              "password": password
          ]
          request.httpBody = try JSONSerialization.data(withJSONObject: body)

          let (data, response) = try await URLSession.shared.data(for: request)

          guard let httpResponse = response as? HTTPURLResponse else {
              throw APIError.invalidResponse
          }

          guard httpResponse.statusCode == 200 else {
              throw APIError.loginFailed("服务器状态异常，状态码：\(httpResponse.statusCode)")
          }

          if let jsonStr = String(data: data, encoding: .utf8) {
              print("登录返回内容：\(jsonStr)")
          }

          let result = try JSONDecoder().decode(LoginResponse.self, from: data)

          guard result.code == 200, let loginData = result.data else {
              throw APIError.loginFailed(result.message)
          }

          // 存储 token
          KeychainHelper.shared.save(loginData.token, for: "authToken")
          UserDefaults.standard.set(loginData.user.id, forKey: "currentUserId")

          return loginData.user
      }
    
    func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.apiError("HTTP错误码：\(httpResponse.statusCode)")
        }
    }

        func logout() async throws {
            guard let url = URL(string: "\(baseURL)/auth/logout") else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            applyAuthHeaders(to: &request)

            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response)

            // 你可以根据服务端是否返回 message 决定是否需要解析
            print("✅ 退出登录成功: \(String(data: data, encoding: .utf8) ?? "")")
        }


      // 获取用户信息
      func getUserInfo() async throws -> UserInfo {
          let endpoint = "/users/\(UserDefaults.standard.integer(forKey: "currentUserId"))"
          guard let url = URL(string: baseURL + endpoint) else {
              throw APIError.invalidURL
          }

          var request = URLRequest(url: url)
          request.httpMethod = "GET"
          if let token = KeychainHelper.shared.get(for: "authToken") {
              request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
          }

          let (data, response) = try await URLSession.shared.data(for: request)

          guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
              throw APIError.invalidResponse
          }

          if let jsonStr = String(data: data, encoding: .utf8) {
              print("获取用户信息返回内容：\(jsonStr)")
          }

          let result = try JSONDecoder().decode(UserInfoResponse.self, from: data)

          guard result.code == 200, let user = result.data else {
              throw APIError.loginFailed(result.message)
          }

          return user
      }
    
    // 更新用户信息
    func updateUser(userInfo: UserInfo) async throws {
        let endpoint = "/users/\(userInfo.id)"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var updateBody: [String: Any] = [
            "id": userInfo.id,
            "username": userInfo.username
        ]

        if let realName = userInfo.realName, !realName.isEmpty {
            updateBody["realName"] = realName
        }
        if let email = userInfo.email, !email.isEmpty {
            updateBody["email"] = email
        }
        if let phone = userInfo.phone, !phone.isEmpty {
            updateBody["phone"] = phone
        }
        if let avatar = userInfo.avatar, !avatar.isEmpty {
            updateBody["avatar"] = avatar
        }
        if let gender = userInfo.gender {
            updateBody["gender"] = gender
        }
        if let status = userInfo.status {
            updateBody["status"] = status
        }
        if let roles = userInfo.roles {
            updateBody["roles"] = roles.map { ["id": $0.id] }
        }


        let bodyData = try JSONSerialization.data(withJSONObject: updateBody, options: [])
        request.httpBody = bodyData

        print("发出 update 请求 JSON：", String(data: bodyData, encoding: .utf8) ?? "")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.loginFailed("更新用户信息失败")
        }
    }



}

extension APIManager {
    
    func getChatHistory(sessionId: Int) async throws -> [ChatMessage] {
        let url = URL(string: "\(baseURL)/api/dialogs/history/\(sessionId)")!
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        // 携带token（如果需要鉴权）
        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "无正文"
            print(" 获取历史记录失败（状态码：\(httpResponse.statusCode)）：\(body)")
            throw URLError(.badServerResponse)
        }

        do {
            let response = try JSONDecoder().decode(ChatMessageListResponse.self, from: data)
            guard response.code == 200 else {
                throw APIError.loginFailed(response.message)
            }
            return response.data
        } catch {
            print(" 解析历史记录失败：\(error.localizedDescription)")
            let raw = String(data: data, encoding: .utf8) ?? "非文本响应"
            print(" 原始返回内容：\(raw)")
            throw error
        }
    }




    // 发送消息到 AI 聊天接口
    func sendMessageToChatBot(message: String, sessionId: Int) async throws -> String {
        let endpoint = "/api/dialogs/text"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 添加 sessionId 到请求体中
        let body: [String: Any] = [
            "message": message,
            "sessionId": sessionId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataDict = json["data"] as? [String: Any],
               let reply = dataDict["reply"] as? String {
                return reply
            } else {
                throw APIError.invalidResponse
            }
        } else {
            throw APIError.loginFailed("服务器返回状态码不是200")
        }
    }


}

extension APIManager {
    struct CreateSessionResponse: Codable {
        let code: Int
        let message: String
        let data: ChatSession
    }

    func createChatSession() async throws -> ChatSession {
        let endpoint = "/api/api/chat/session"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CreateSessionResponse.self, from: data)

        guard response.code == 200 else {
            throw APIError.invalidResponse
        }

        return response.data
    }
}

extension APIManager {
    struct ChatSessionsResponse: Codable {
        let code: Int
        let data: [ChatSession]
        let message: String
    }

    func getAllChatSessions() async throws -> [ChatSession] {
        let endpoint = "/api/dialogs/sessions"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ChatSessionsResponse.self, from: data)

        guard response.code == 200 else {
            throw APIError.invalidResponse
        }

        return response.data
    }
    
    struct GenericResponse<T: Codable>: Codable {
        let code: Int
        let message: String
        let data: T
    }
    
    //删除对话
    func deleteChatSession(sessionId: Int) async throws -> Bool {
        let url = URL(string: "\(baseURL)/api/api/chat/session/\(sessionId)")!
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
extension APIManager{
    func saveMoodRecord(_ record: MoodUploadRequest) async throws {
        let endpoint = "/mood/calendar"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try encoder.encode(record)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["message"] as? String {
                throw APIError.loginFailed(msg)
            } else {
                throw APIError.loginFailed("服务器返回错误，状态码：\(httpResponse.statusCode)")
            }
        }
    }
    
    func fetchMoodRecord(for date: String) async throws -> MoodRecordResponse {
        let endpoint = "/mood/calendar/\(date)"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["message"] as? String {
                throw APIError.loginFailed(msg)
            } else {
                throw APIError.loginFailed("服务器返回错误，状态码：\(httpResponse.statusCode)")
            }
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(APIResponse<MoodRecordResponse>.self, from: data)
        return result.data
    }

    func updateMoodRecord(_ record: UpdateMoodRecordRequest) async throws -> Bool {
          guard let url = URL(string: "\(baseURL)/mood/calendar") else {
              throw URLError(.badURL)
          }
          
          var request = URLRequest(url: url)
          request.httpMethod = "PUT"
          request.addValue("application/json", forHTTPHeaderField: "Content-Type")
          
          let jsonData = try JSONEncoder().encode(record)
          request.httpBody = jsonData
          
          let (data, response) = try await URLSession.shared.data(for: request)
          
          if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
              print(" 心情记录更新成功")
              return true
          } else {
              let responseText = String(data: data, encoding: .utf8) ?? "无响应文本"
              print(" 更新失败: \(responseText)")
              return false
          }
      }

}

//情绪分析接口
extension APIManager {
    func getEmotionAnalysis(for userId: Int) async throws -> EmotionData {
        let urlStr = baseURL + "/api/api/mood-analysis/analyze/\(userId)"
        guard let url = URL(string: urlStr) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(EmotionResponse.self, from: data)
        guard decoded.code == 200 else {
            throw APIError.apiError(decoded.message)
        }
        return decoded.data
    }
}


//社区资源交流
extension APIManager {
    
    func createPost(requestBody: CreatePostRequest) async throws -> Post {
        let urlStr = baseURL + "/api/education/resource/upload"
        guard let url = URL(string: urlStr) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(PostResponse.self, from: data)
        guard decoded.code == 0 else {
            throw APIError.apiError(decoded.message)
        }

        return decoded.data
    }
}

extension APIManager {
    func applyAuthHeaders(to request: inout URLRequest) {
        if let token = KeychainHelper.shared.read(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}


// Keychain帮助类
class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    func save(_ data: String, for key: String) {
        let data = Data(data.utf8)
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ] as CFDictionary
        
        SecItemDelete(query)
        SecItemAdd(query, nil)
    }
    
    func read(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : Bundle.main.bundleIdentifier ?? "defaultService",
            kSecAttrAccount as String : key,
            kSecReturnData as String  : true,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }

    
    func get(for key: String) -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
        ]
        SecItemDelete(query as CFDictionary)
    }
    
}
