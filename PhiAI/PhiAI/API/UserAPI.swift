//
//  UserAPI.swift
//  PhiAI
//

import Foundation

extension APIManager{
    
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
          print("登录成功，token已保存：\(loginData.token)")
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
          if let token = KeychainHelper.shared.read(for: "authToken") {
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
        if let token = KeychainHelper.shared.read(for: "authToken") {
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
