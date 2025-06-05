//
//  AppointmentPlatformManager.swift
//  PhiAI
//

import Foundation

@MainActor
class AppointmentPlatformManager: ObservableObject {
    static let shared = AppointmentPlatformManager()
    
    @Published var isLoggedIn = false
    @Published var token: String?
    @Published var errorMessage: String?

    func login(username: String, password: String, schoolName: String) async {
        do {
            let request = Request(password: password, schoolName: schoolName, username: username)
            let result = try await APIManager.shared.loginToPsyPlatform(request: request)
            self.token = result
            self.isLoggedIn = true
        } catch {
            self.errorMessage = "预约平台登录失败: \(error.localizedDescription)"
            self.isLoggedIn = false
        }
    }

    func logout() {
        token = nil
        isLoggedIn = false
    }
}
