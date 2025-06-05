import Foundation

let baseURL = "http://f6783e72.natappfree.cc"

struct APIResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: T
}

class APIManager {
    static let shared = APIManager()
    
    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case loginFailed(String)
        case custom(String)
        case apiError(String)
        case invalidData
        case serverError(String)
        case emptyData
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "无效的URL"
            case .invalidResponse: return "无效的响应"
            case .loginFailed(let message): return message
            case .custom(let message): return message
            case .apiError(let message): return message
            case .invalidData: return "无效的数据"
            case .serverError(let message): return "服务器错误: \(message)"
            case .emptyData: return "接口返回数据为空"
            case .unknown: return "未知错误"
            }
        }
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

    private let service = Bundle.main.bundleIdentifier ?? "defaultService"

    func save(_ data: String, for key: String) {
        guard let data = data.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : key
        ]

        // 先删除旧数据
        SecItemDelete(query as CFDictionary)

        // 再添加新数据
        let attributes: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data
        ]

        SecItemAdd(attributes as CFDictionary, nil)
        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain 保存失败，状态码：\(status)")
        } else {
            print("Keychain 保存成功")
        }

    }

    func read(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : true,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        print("Keychain 读取状态：\(status)")

        guard status == errSecSuccess,
              let data = result as? Data else {
            print("没取到数据")
            return nil
        }
        
        if let token = String(data: data, encoding: .utf8) {
            print("成功解析成字符串：\(token)")
            return token
        } else {
            print("数据存在但无法转换为 UTF-8 字符串")
            print("原始数据：\(data as NSData)")
            return nil
        }
    }


    func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

