import SwiftUI

struct ProfileWrapperView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Binding var showLogin: Bool
    @Binding var guestRefresh : Int
    
    var body: some View {
        ZStack {
            // 确保我们只访问非空的用户
            if let user = appVM.currentUser {
                // 如果是游客
                if user.id == -1 {
                    GuestView(showLogin: $showLogin, guestRefresh: $guestRefresh)
                        .id(guestRefresh)  // 每次刷新强制重新加载 GuestView
                        .animation(.easeOut(duration: 0.4), value: guestRefresh)
                } else {
                    // 如果是已登录用户，显示正常界面
                    MyView()
                }
            } else {
                // 用户信息未加载时，显示登录界面
                Color.clear
                    .onAppear {
                        // 在没有用户的情况下，触发登录界面
                        showLogin = true
                    }
            }
        }
    }
}

struct GuestView: View {
    @Binding var showLogin: Bool
    @Binding var guestRefresh : Int
    @State private var appear = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            // 背景渐变色
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

            VStack {
                ZStack(alignment: .top){
                    RoundedRectangle(cornerRadius: 40)
                        .foregroundColor(Color(#colorLiteral(red: 0.737, green: 0.842, blue: 0.530, alpha: 1)))
                        .shadow(color: Color.gray.opacity(pulse ? 0.4 : 0.2), radius: pulse ? 12 : 6, x: 0, y: pulse ? 6 : 3)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 40)
                        .animation(.easeOut(duration: 0.6), value: appear)

                    RoundedRectangle(cornerRadius: 40)
                        .foregroundColor(Color(#colorLiteral(red: 0.804, green: 0.926, blue: 0.591, alpha: 1)))
                        .frame(height: 700)
                        .padding()
                        .shadow(color: Color.green.opacity(pulse ? 0.2 : 0.05), radius: pulse ? 8 : 2, y: pulse ? 6 : 2)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 60)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: appear)
                    
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 40)
                            .foregroundColor(.white.opacity(pulse ? 0.7 : 0.4))
                            .frame(height: 300)
                            .padding(.horizontal, 50)
                            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)

                        VStack(spacing: 20) {
                            Spacer()
                            Text("您正在以游客身份浏览")
                                .font(.title2)
                                .fontWeight(.bold)
                                .opacity(appear ? 1 : 0)
                                .offset(y: appear ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(0.3), value: appear)

                            Text("登录后可享受以下功能：\n✨ 查看完整内容\n✨ 发帖评论互动\n✨ 与MindBot交流")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .opacity(appear ? 1 : 0)
                                .offset(y: appear ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(0.4), value: appear)

                            Button(action: {
                                showLogin = true
                            }) {
                                Text("立即登录")
                                    .font(.headline)
                                    .frame(width: 200, height: 45)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.accentColor.opacity(pulse ? 0.4 : 0.1), radius: pulse ? 10 : 3)
                                    .scaleEffect(pulse ? 1.06 : 1.0)
                                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
                            }
                            .padding(.top, 10)
                            .padding(.bottom, 100)
                            Spacer()
                        }
                        .padding(.top, 100)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 1.05).combined(with: .opacity),
            removal: .opacity
        ))
        .onAppear {
            appear = true
            pulse = true
        }
    }
}
