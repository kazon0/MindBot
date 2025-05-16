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
    func login(username: String, password: String) async throws -> Bool {
         let endpoint = "/api/auth/login?username=\(username)&password=\(password)"
         guard let url = URL(string: baseURL + endpoint) else {
             throw APIError.invalidURL
         }

         var request = URLRequest(url: url)
         request.httpMethod = "POST"
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")

         let (data, response) = try await URLSession.shared.data(for: request)

         guard let httpResponse = response as? HTTPURLResponse else {
             throw APIError.invalidResponse
         }

         // HTTP状态码不是200直接抛错
         guard httpResponse.statusCode == 200 else {
             throw APIError.loginFailed("服务器返回状态码：\(httpResponse.statusCode)")
         }

         // 解析JSON，判断code字段
         guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
             throw APIError.unknown
         }

         if let code = json["code"] as? Int, code == 200 {
             // 登录成功，保存token
             if let dataDict = json["data"] as? [String: Any],
                let token = dataDict["token"] as? String {
                 KeychainHelper.shared.save(token, for: "authToken")
             }
             return true
         } else {
             // 读取错误信息
             let msg = json["message"] as? String ?? "登录失败"
             throw APIError.loginFailed(msg)
         }
     }



    // 获取用户信息
    func getUserInfo() async throws -> UserInfo {
        let endpoint = "/auth/info"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(UserInfo.self, from: data)
    }
    
}

extension APIManager {
    
    // 获取聊天记录
    func getChatHistory() async throws -> [ChatMessage] {
        let endpoint = "/api/chat/history"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = KeychainHelper.shared.get(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ChatMessage].self, from: data)
    }

    // 发送消息到 AI 聊天接口
     func sendMessageToChatBot(message: String) async throws -> String{
        let endpoint = "/api/chat/sendMessage"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["message": message]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 200 {
            // 假设 API 返回的是 AI 回复的消息
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let aiMessage = json["response"] as? String {
                return aiMessage
            } else {
                throw APIError.invalidResponse
            }
        } else {
            throw APIError.loginFailed("服务器返回状态码不是200")
        }
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
struct UserInfo: Codable {
    let id: Int
    let username: String
    let realName: String?
    let avatar: String?
    let email: String?
    let phone: String?
    let gender: Int?
    let status: Int?
}

struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let text: String
    let timestamp: String  // 或 Date，如果 API 返回是 ISO 格式
    let isUser: Bool
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
