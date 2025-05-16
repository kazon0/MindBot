import SwiftUI

struct LogView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    var onLogin: (UserInfo) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { onCancel() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                }
                Spacer()
            }
            .padding()

            TextField("请输入用户名", text: $username)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            SecureField("请输入密码", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if appVM.isLoading {
                ProgressView().padding()
            } else {
                Button("登录") {
                    Task {
                        await handleLogin()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }

            NavigationLink("没有账号？点此注册", destination: RegView())

            Spacer()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle))
        }
        .onAppear {
            // 清空输入框
            username = ""
            password = ""
        }
    }

    private func handleLogin() async {
        await appVM.login(username: username, password: password)
        if appVM.isLoggedIn {
            alertTitle = "登录成功 🥳"
            showAlert = true
            // 直接调用 onLogin
            if let user = appVM.currentUser {
                onLogin(user)
            }
        } else if let error = appVM.errorMessage {
            alertTitle = "登录失败: \(error)"
            showAlert = true
        }
    }
}
