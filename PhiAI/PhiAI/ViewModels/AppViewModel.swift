
import Foundation
import CoreData

class AppViewModel: ObservableObject {
    @Published var currentUser: UserEntites? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var isLoggedIn: Bool {
        return currentUser != nil
    }
    
    // 新登录方法
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let success = try await APIManager.shared.login(username: username, password: password)
            
            if success {
                let userInfo = try await APIManager.shared.getUserInfo()
                await MainActor.run {
                    // 同步到CoreData
                    if let context = currentUser?.managedObjectContext {
                        let newUser = UserEntites(context: context)
                        newUser.id = String(userInfo.id)
                        newUser.name = userInfo.username
                        newUser.pwd = password // 注意：实际应用中不应存储明文密码
                        try? context.save()
                        currentUser = newUser
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func logout() {
        KeychainHelper.shared.save("", for: "authToken")
        currentUser = nil
    }
}
