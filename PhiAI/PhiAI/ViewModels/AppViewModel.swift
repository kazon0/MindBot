import Foundation
import CoreData

class AppViewModel: ObservableObject {
    @Published var currentUser: UserEntites? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isLoggedIn: Bool {
        return currentUser != nil && !(currentUser?.isGuest ?? false)
    }

    init() {
        // 在初始化时调用异步方法
        Task {
            await autoLoginOrGuest()
        }
    }

    func autoLoginOrGuest() async {
        if let token = KeychainHelper.shared.get(for: "authToken"), !token.isEmpty {
            do {
                try await fetchUserInfoAndSync()
            } catch {
                print("自动登录失败：\(error)")
                setGuestUser()  // 出现错误时也进入游客模式
            }
        } else {
            setGuestUser()
        }
    }

    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let success = try await APIManager.shared.login(username: username, password: password)

            if success {
                try await fetchUserInfoAndSync(password: password)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    private func fetchUserInfoAndSync(password: String = "") async throws {
        let userInfo = try await APIManager.shared.getUserInfo()

        await MainActor.run {
            let context = CoreDataViewModel.shared.container.viewContext
            let newUser = UserEntites(context: context)
            newUser.id = String(userInfo.id)
            newUser.name = userInfo.username
            newUser.pwd = password
            newUser.isGuest = false
            do {
                try context.save()
                self.currentUser = newUser
            } catch {
                print("保存用户信息失败: \(error.localizedDescription)")
                // 处理保存失败的情况，可能需要向用户显示错误信息
            }
        }
    }

    func logout() {
        KeychainHelper.shared.save("", for: "authToken")
        currentUser = nil
        setGuestUser()
    }

    func setGuestUser() {
        if let user = currentUser, user.isGuest {
            return // 已经是游客用户了，避免重复设置
        }

        let context = CoreDataViewModel.shared.container.viewContext
        let guest = UserEntites(context: context)
        guest.id = "guest"
        guest.name = "游客"
        guest.pwd = ""
        guest.isGuest = true

        DispatchQueue.main.async {
            self.currentUser = guest
        }
    }
}
