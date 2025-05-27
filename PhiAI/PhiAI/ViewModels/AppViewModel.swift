import CoreData
import Foundation
import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @Published var currentUser: UserInfo? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isUserLoaded = false
    
    
    // 用户是否登录
    var isLoggedIn: Bool {
        currentUser != nil && currentUser?.id != -1
    }

    func autoLoginOrGuest() async {
        do {
            let userId = UserDefaults.standard.integer(forKey: "currentUserId")
            if userId > 0 {
                currentUser = try await APIManager.shared.getUserInfo()
            } else {
                setGuestUser()
            }
        } catch {
            setGuestUser()
        }
        isUserLoaded = true
    }

    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let userInfo = try await APIManager.shared.login(username: username, password: password)
            currentUser = userInfo
        } catch {
            errorMessage = error.localizedDescription
            currentUser = nil
        }
        isLoading = false
    }

    @MainActor
    func logout() async {
        do {
            try await APIManager.shared.logout()
            KeychainHelper.shared.delete(for: "authToken") // 删除 token
            setGuestUser()  // 设置成游客状态
            isUserLoaded = true
            errorMessage = nil
        } catch {
            errorMessage = "退出登录失败: \(error.localizedDescription)"
        }
    }

    func setGuestUser() {
        currentUser = UserInfo(
            id: -1,
            username: "游客",
            realName: nil,
            avatar: nil,
            phone: nil,
            email: nil,
            gender: nil,
            status: nil,
            createTime: nil,
            updateTime: nil,
            roles: [],
            permissions: []
        )
    }
}
