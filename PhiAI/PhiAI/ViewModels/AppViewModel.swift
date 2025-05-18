import CoreData
import Foundation

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
            if let token = KeychainHelper.shared.get(for: "authToken"), !token.isEmpty {
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
            let (_, userInfo) = try await APIManager.shared.login(username: username, password: password)
            currentUser = userInfo
        } catch {
            errorMessage = error.localizedDescription
            currentUser = nil
        }
        isLoading = false
    }

    func logout() {
        KeychainHelper.shared.save("", for: "authToken")
        setGuestUser()
        errorMessage = nil
        isUserLoaded = false

        Task {
            await autoLoginOrGuest()
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
            roles: []
        )
    }
}
