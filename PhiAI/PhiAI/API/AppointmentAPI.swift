//
//  AppointmentAPI.swift
//  PhiAI
//

import Foundation

extension APIManager {
    func loginToPsyPlatform(request: Request) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/psy/appointment/login") else {
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

        let decodedResponse = try JSONDecoder().decode(PsyLoginResponse.self, from: data)

        if let token = decodedResponse.data {
            return token
        } else {
            throw NSError(domain: "", code: decodedResponse.code, userInfo: [NSLocalizedDescriptionKey: decodedResponse.message])
        }
    }
}

extension APIManager {
    func fetchAvailableDoctors(date: String, sessionId: String) async throws -> [DoctorInfo] {
        guard var urlComponents = URLComponents(string: "\(baseURL)/api/psy/appointment/doctors") else {
            throw URLError(.badURL)
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "date", value: date),
            URLQueryItem(name: "sessionId", value: sessionId)
        ]

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        if let jsonString = String(data: data, encoding: .utf8) {
            print("接口返回的原始数据：\n\(jsonString)")
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // 解码结构
        struct DoctorListResponse: Codable {
            let code: Int
            let message: String
            let data: [DoctorInfo]?
        }

        let decoded = try JSONDecoder().decode(DoctorListResponse.self, from: data)

        guard decoded.code == 200 else {
            throw NSError(domain: "FetchDoctorsError", code: decoded.code, userInfo: [
                NSLocalizedDescriptionKey: decoded.message
            ])
        }

        guard let doctors = decoded.data else {
            throw NSError(domain: "FetchDoctorsError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "服务器未返回医生数据"
            ])
        }

        return doctors
    }
}


extension APIManager {
    func makeAppointment(_ request: AppointmentRequest) async throws -> AppointmentResponseData {
        var components = URLComponents(string: "\(baseURL)/api/psy/appointment/create")!
        components.queryItems = [
            URLQueryItem(name: "doctorName", value: request.doctorName),
            URLQueryItem(name: "date", value: request.date),
            URLQueryItem(name: "timeSlot", value: request.timeSlot),
            URLQueryItem(name: "problem", value: request.problem),
            URLQueryItem(name: "phoneNumber", value: request.phoneNumber),
            URLQueryItem(name: "qqId", value: request.qqId),
            URLQueryItem(name: "sessionId", value: request.sessionId)
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        if let str = String(data: data, encoding: .utf8) {
            print("预约 API 返回：\(str)")
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let result = try JSONDecoder().decode(APIResponse<AppointmentResponseData?>.self, from: data)

        guard result.code == 200 else {
            throw NSError(domain: "AppointmentError", code: result.code, userInfo: [
                NSLocalizedDescriptionKey: result.message
            ])
        }

        guard let appointment = result.data else {
            throw NSError(domain: "AppointmentError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "预约失败：响应数据为空"
            ])
        }

        return appointment
    }
}

