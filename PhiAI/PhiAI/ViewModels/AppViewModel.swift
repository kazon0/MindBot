
import Foundation

@MainActor
class AppViewModel: ObservableObject {
    @Published var currentUser: UserInfo? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isUserLoaded = false

    var isLoggedIn: Bool {
        return currentUser != nil
    }

    init() {
        Task {
            await autoLoginOrGuest()
        }
    }

    func autoLoginOrGuest() async {
        do {
            if let token = KeychainHelper.shared.get(for: "authToken"), !token.isEmpty {
                self.currentUser = try await APIManager.shared.getUserInfo()
            } else {
                self.currentUser = UserInfo(id: -1, username: "游客", realName: nil, avatar: nil, email: nil, phone: nil, gender: nil, status: nil)
            }
        } catch {
            self.currentUser = UserInfo(id: -1, username: "游客", realName: nil, avatar: nil, email: nil, phone: nil, gender: nil, status: nil)
        }
        self.isUserLoaded = true
    }

    func login(username: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let success = try await APIManager.shared.login(username: username, password: password)
            if success {
                try await fetchUserInfo()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private func fetchUserInfo() async throws {
        let userInfo = try await APIManager.shared.getUserInfo()
        await MainActor.run {
            self.currentUser = userInfo
        }
    }

    func logout() {
        KeychainHelper.shared.save("", for: "authToken")
        Task {
            await setGuestUser()
        }
    }

    func setGuestUser() async {
        await MainActor.run {
            self.currentUser = nil
        }
    }
}
