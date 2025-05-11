import SwiftUI

struct RegView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appVM: AppViewModel

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var alertTitle: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            TextField("请输入用户名", text: $username)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            SecureField("请输入密码", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            SecureField("请确认密码", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if appVM.isLoading {
                ProgressView()
            } else {
                Button("注册") {
                    Task {
                        await handleRegister()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("注册")
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle))
        }
    }

    private func handleRegister() async {
        guard !username.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            alertTitle = "请填写完整信息"
            showAlert = true
            return
        }

        guard password == confirmPassword else {
            alertTitle = "两次密码不一致"
            showAlert = true
            return
        }

        do {
            try await APIManager.shared.register(username: username, password: password)
            alertTitle = "注册成功 🎉"
            showAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            alertTitle = "注册失败: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
