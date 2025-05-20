import Foundation

class APIManager {
    static let shared = APIManager()
    private let baseURL = "http://mf52c582.natappfree.cc"
    
    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case loginFailed(String)
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "无效的URL"
            case .invalidResponse: return "无效的响应"
            case .loginFailed(let message): return message
            case .unknown: return "未知错误"
            }
        }
    }
    
    
    // 注册API
    func register(username: String, password: String) async throws {
        let endpoint = "/api/auth/register"
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

    
    // 登录API
    func login(username: String, password: String) async throws -> (String, UserInfo) {
            let endpoint = "/api/auth/login"
            guard let url = URL(string: baseURL + endpoint) else {
                throw APIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            let paramString = "username=\(username)&password=\(password)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            request.httpBody = paramString.data(using: .utf8)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw APIError.loginFailed("服务器状态异常")
            }

            let result = try JSONDecoder().decode(LoginResponse.self, from: data)

            guard result.code == 200, let loginData = result.data else {
                throw APIError.loginFailed(result.message)
            }

            // 保存 token
            KeychainHelper.shared.save(loginData.token, for: "authToken")

            return (loginData.token, loginData.user)
        }


    // 获取用户信息
    func getUserInfo() async throws -> UserInfo {
        let endpoint = "/api/auth/info"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("携带的 token:", token)
        }

        let (data, _) = try await URLSession.shared.data(for: request)

        if let jsonString = String(data: data, encoding: .utf8) {
            print("原始返回 JSON: \(jsonString)")
        }

        let response = try JSONDecoder().decode(UserInfoResponse.self, from: data)

        guard response.code == 200, let user = response.data else {
            throw APIError.loginFailed(response.message)
        }

        return user
    }
    
    // 更新用户信息
    func updateUser(userInfo: UserInfo) async throws {
        let endpoint = "/api/rbac/user"
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
        let url = URL(string: "\(baseURL)/api/api/chat/messages/\(sessionId)")!
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
        let endpoint = "/api/api/chat/send"
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
        let endpoint = "/api/api/chat/sessions"
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



extension APIManager {
    
    // 获取所有帖子
    func getAllPosts() async throws -> [Post] {
        let endpoint = "/api/community/posts"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Post].self, from: data)
    }

    // 发布帖子
    func createPost(content: String, isAnonymous: Bool) async throws {
        let endpoint = "/api/community/posts"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "content": content,
            "isAnonymous": isAnonymous
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }
    }

    // 添加评论
    func addComment(postId: Int, content: String) async throws {
        let endpoint = "/api/community/posts/\(postId)/comments"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = ["content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }
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
    
    
}

// 网络返回的用户数据结构
struct LoginResponse: Codable {
    let code: Int
    let message: String
    let data: LoginData?
}

struct LoginData: Codable {
    let permissions: [String]
    let roles: [String]
    let token: String
    let user: UserInfo
}

// MARK: - UserInfoResponse
struct UserInfoResponse: Codable {
    let code: Int
    let message: String
    let data: UserInfo?
}

// MARK: - UserInfo
struct UserInfo: Codable {
    var id: Int
    var username: String
    var password: String?
    var realName: String?
    var avatar: String?
    var phone: String?
    var email: String?
    var gender: Int?
    var status: Int?
    var createTime: String?
    var updateTime: String?
    var roles: [Role]?
    var permissions: [Permission]?
}

// MARK: - Role
struct Role: Codable {
    let id: Int
    let name: String
    let code: String
    let description: String?
    let status: Int
    let createTime: String
    let updateTime: String
    let permissions: [Permission]?
}

// MARK: - Permission
struct Permission: Codable {
    let id: Int
    let name: String
    let code: String
    let type: Int
    let status: Int
    let parentId: Int
    let sort: Int
    let icon: String?
    let component: String?
    let path: String?
    let createTime: String
    let updateTime: String
    let children: [Permission]?
}

struct ChatMessage: Codable, Identifiable {
    let id: Int64
    let sessionId: Int64
    let userId: Int64
    let senderType: String  // "user" or "ai"
    let content: String
    let createTime: String
}

struct ChatMessageListResponse: Codable {
    let code: Int
    let message: String
    let data: [ChatMessage]
}


struct ChatSession: Identifiable, Codable {
    let id: Int
    let userId: Int
    var title: String
    let createTime: String
    let updateTime: String
}


//帖子和评论数据结构
struct Post: Codable, Identifiable {
    let id: Int
    let content: String
    let isAnonymous: Bool
    let timestamp: String
    let user: UserInfo?
    let comments: [Comment]?
}

struct Comment: Codable, Identifiable {
    let id: Int
    let content: String
    let timestamp: String
    let user: UserInfo?
}
