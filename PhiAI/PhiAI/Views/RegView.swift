import SwiftUI

struct RegView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appVM: AppViewModel

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var alertTitle: String = ""
    @State private var showAlert: Bool = false
    @State private var animate = false

    var body: some View {
        ZStack(){
                RoundedRectangle(cornerRadius: 0)
                    .foregroundColor(Color(#colorLiteral(red: 0.737, green: 0.842, blue: 0.530, alpha: 1)))
                    .shadow(color: Color.gray.opacity(animate ? 0.4 : 0.2), radius: animate ? 12 : 6, x: 0, y: animate ? 6 : 3)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 40)
                    .animation(.easeOut(duration: 0.6), value: animate)
                    .ignoresSafeArea()
                
                RoundedRectangle(cornerRadius: 40)
                    .foregroundColor(Color(#colorLiteral(red: 0.804, green: 0.926, blue: 0.591, alpha: 1)))
                    .frame(height: 650)
                    .padding()
                    .shadow(color: Color.green.opacity(animate ? 0.2 : 0.05), radius: animate ? 8 : 2, y: animate ? 6 : 2)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 60)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: animate)
            
            ZStack(alignment: .top){
                RoundedRectangle(cornerRadius: 30)
                    .foregroundColor(.white.opacity(animate ? 0.7 : 0.4))
                    .shadow(radius: 10)
                    .padding(.bottom,240)
                    .padding(.top,40)
                    .padding(.horizontal,50)
                    .frame(height:620)
                    .foregroundColor(.white.opacity(animate ? 0.7 : 0.4))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                
                VStack(spacing: 24) {
                    Text("注册新账号")
                        .font(.title)
                        .bold()
                        .foregroundColor(.black)
                        .transition(.move(edge: .top))
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)
                        .padding(.top,60)
                    
                    Group {
                        TextField("请输入用户名", text: $username)
                        SecureField("请输入密码", text: $password)
                        SecureField("请确认密码", text: $confirmPassword)
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal,80)
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                    .transition(.move(edge: .top))
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)
                    
                    if appVM.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        Button(action: {
                            Task { await handleRegister() }
                        }) {
                            Text("注册")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .accentColor.opacity(0.3), radius: 6, x: 0, y: 4)
                                .scaleEffect(animate ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)
                        }
                        .padding(.horizontal,80)
                        .padding(.bottom,30)
                    }
                    
                }
      
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.accentColor)
                        .font(.caption)
                        .padding()
                        .background(Color.white.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(.top,20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("好", role: .cancel) {}
        }
        .onAppear {
            animate = true
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
                dismiss()
            }
        } catch {
            alertTitle = "注册失败: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    struct RegViewPreviewWrapper: View {
        @StateObject var appVM = AppViewModel()
        var body: some View {
            NavigationStack {
                RegView()
                    .environmentObject(appVM)
            }
        }
    }
    return RegViewPreviewWrapper()
}
