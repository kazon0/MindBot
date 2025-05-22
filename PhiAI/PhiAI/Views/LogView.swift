import SwiftUI

struct LogView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var animate = false
    @State private var showRegister = false

    var onLogin: (UserInfo) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(#colorLiteral(red: 0.824, green: 0.814, blue: 0.811, alpha: 1)),
                    Color(#colorLiteral(red: 0.984, green: 0.919, blue: 0.821, alpha: 1)),
                    Color(#colorLiteral(red: 0.837, green: 0.977, blue: 0.602, alpha: 1))
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ZStack(alignment: .topLeading){
                RoundedRectangle(cornerRadius: 40)
                    .foregroundColor(Color(#colorLiteral(red: 0.737, green: 0.842, blue: 0.530, alpha: 1)))
                    .shadow(color: Color.gray.opacity(animate ? 0.4 : 0.2), radius: animate ? 12 : 6, x: 0, y: animate ? 6 : 3)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 40)
                    .animation(.easeOut(duration: 0.6), value: animate)
                
                RoundedRectangle(cornerRadius: 40)
                    .foregroundColor(Color(#colorLiteral(red: 0.804, green: 0.926, blue: 0.591, alpha: 1)))
                    .frame(height: 700)
                    .padding()
                    .padding(.top,60)
                    .shadow(color: Color.green.opacity(animate ? 0.2 : 0.05), radius: animate ? 8 : 2, y: animate ? 6 : 2)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 60)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: animate)
                
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                            .padding()
                            .background(Color.white.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical,20)
                
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("欢迎回来")
                            .font(.title)
                            .bold()
                            .foregroundColor(.black)
                            .transition(.move(edge: .top))
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)
                        Text("请登录以继续使用 MindBot ✨")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)
                    }
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
                    .animation(.easeOut(duration: 0.4), value: animate)
                    
                    VStack(spacing: 16) {
                        TextField("请输入用户名", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.black)
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)
                        
                        SecureField("请输入密码", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.black)
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)
                    }
                    .padding(.horizontal)
                    
                    if appVM.isLoading {
                        ProgressView().padding(.top)
                    } else {
                        Button(action: {
                            Task { await handleLogin() }
                        }) {
                            Text("登录")
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 3)
                                .shadow(color: Color.accentColor.opacity(animate ? 0.4 : 0.1), radius: animate ? 10 : 3)
                                .scaleEffect(animate ? 1.06 : 1.0)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)
                        }
                        .padding(.horizontal)
                    }
                    
                    Button("没有账号？点此注册") {
                        showRegister = true
                    }
                    .sheet(isPresented: $showRegister) {
                        NavigationView {
                            RegView()
                        }
                    }
                    .foregroundColor(.blue)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.4),value: animate)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white.opacity(0.9))
                        .shadow(radius: 10)
                )
                .padding(50)
                .padding(.top,80)
                .foregroundColor(.white.opacity(animate ? 0.7 : 0.4))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                GirlWithButterflyView()
                
            }
            .ignoresSafeArea(edges: .bottom)
            
        }
        .onAppear {
            animate = true
            username = ""
            password = ""
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("好", role: .cancel) {}
        }
    }

    private func handleLogin() async {
        await appVM.login(username: username, password: password)
        if appVM.isLoggedIn {
            alertTitle = "登录成功 🎉"
            showAlert = true
            if let user = appVM.currentUser {
                onLogin(user)
            }
        } else {
            alertTitle = "登录失败：\(appVM.errorMessage ?? "未知错误")"
            showAlert = true
        }
    }
}


struct GirlWithButterflyView: View {
    @State private var flyPhase: CGFloat = 0

    var body: some View {
        ZStack {
            // 小女孩
            Image("GirlStand")
                .resizable()
                .scaledToFit()
                .frame(width: 130)
                .offset(x: 240, y: 550)

            // 蝴蝶围绕飞舞
            Image("Butterfly")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .offset(
                    x: -10+CGFloat(sin(Double(flyPhase)) * 5),
                    y: 530 + CGFloat(cos(Double(flyPhase * 1.2)) * 12)
                )
                .scaleEffect(0.9 + CGFloat(sin(Double(flyPhase * 1))) * 0.08) // 微微缩放模拟拍翅
                .rotationEffect(.degrees(-20 + sin(Double(flyPhase * 1.5)) * 2))
                .animation(.linear(duration: 0.02), value: flyPhase)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
                flyPhase += 0.07
            }
        }
    }
}



#Preview {
    struct LogViewPreviewWrapper: View {
        @StateObject var appVM = AppViewModel()
        var body: some View {
            LogView(onLogin: { _ in }, onCancel: {})
                .environmentObject(appVM)
        }
    }
    return LogViewPreviewWrapper()
}
