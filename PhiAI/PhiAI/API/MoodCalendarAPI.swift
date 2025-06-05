//
//  MoodCalendarAPI.swift
//  PhiAI
//
//  Created by 郑金坝 on 2025/6/3.
//

import Foundation

extension APIManager{
    func saveMoodRecord(_ record: MoodUploadRequest) async throws {
        let endpoint = "/mood/calendar"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainHelper.shared.read(for: "authToken") {
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

        if let token = KeychainHelper.shared.read(for: "authToken") {
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

extension APIManager {
    func fetchMoodStatistics(year: Int, month: Int) async throws -> MoodStatistics {
        let endpoint = "/mood/calendar/statistics/\(year)/\(month)"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = KeychainHelper.shared.read(for: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        
        let jsonString = String(data: data, encoding: .utf8) ?? "nil"
        print("接口返回JSON: \(jsonString)")

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(MoodStatisticsResponse.self, from: data)

        return decoded.data
    }
}
