import Foundation

class APIManager {
    static let shared = APIManager()
    private let baseURL = "http://127.0.0.1:4523/m1/6346875-6042456-default"
    
    
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

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode != 201 && httpResponse.statusCode != 200 {
            throw APIError.loginFailed
        }
    }

    
    // 登录API
    func login(username: String, password: String) async throws -> Bool {
        let endpoint = "/api/auth/login?username=\(username)&password=\(password)"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        print("正在尝试登录：\(username), \(password)")
        print("请求 URL: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let jsonStr = String(data: data, encoding: .utf8) {
            print("返回结果：\(jsonStr)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["token"] as? String {
                KeychainHelper.shared.save(token, for: "authToken")
            }
            return true
        } else {
            throw APIError.loginFailed
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
    
    enum APIError: Error {
        case invalidURL
        case invalidResponse
        case loginFailed
        case unauthorized
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
