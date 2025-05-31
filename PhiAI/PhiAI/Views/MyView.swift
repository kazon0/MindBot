import SwiftUI

struct MyView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var isEditing = false
    @State private var animate = false
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(#colorLiteral(red: 0.824, green: 0.814, blue: 0.811, alpha: 1)),
                        Color(#colorLiteral(red: 0.7366558313, green: 0.8424485326, blue: 0.5300986767, alpha: 1)),
                        Color(#colorLiteral(red: 0.7366558313, green: 0.8424485326, blue: 0.5300986767, alpha: 1))
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .foregroundColor(Color(#colorLiteral(red: 0.737, green: 0.842, blue: 0.530, alpha: 1)))
                        .shadow(color: Color.gray.opacity(animate ? 0.1 : 0.2), radius: animate ? 20 : 30, x: 0, y: -40)
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? 0 : 40)
                        .animation(.easeOut(duration: 0.6), value: animate)

                    VStack(spacing: 20) {
                        if appVM.isLoading {
                            ProgressView("加载中...")
                        } else if let error = appVM.errorMessage {
                            Text("加载失败：\(error)")
                                .foregroundColor(.red)
                        } else if let user = appVM.currentUser {
                            userProfileSection(user: user)
                            userInfoCard(user: user)
                            logoutButton
                        }
                        Spacer()
                    }
                    .offset(y: 50)
                    .onAppear {
                        animate = true
                        if !appVM.isUserLoaded {
                            Task {
                                await appVM.autoLoginOrGuest()
                            }
                        }
                    }
                    .sheet(isPresented: $isEditing) {
                        if let user = appVM.currentUser {
                            EditUserInfoView(user: user) { updatedUser in
                                Task {
                                    do {
                                        try await appVM.updateUser(userInfo: updatedUser)
                                        isEditing = false
                                    } catch {
                                        appVM.errorMessage = "更新失败"
                                    }
                                }
                            }
                        }
                    }
                    .alert("确认退出登录？", isPresented: $showLogoutConfirm) {
                        Button("取消", role: .cancel) {}
                        Button("退出") {
                            Task {
                                await appVM.logout()
                            }
                        }
                    }
                }
            }
        }
    }

    private func userProfileSection(user: UserInfo) -> some View {
        HStack(spacing: 10) {
            userAvatarView(user.avatar)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(user.username)
                        .font(.headline)
                    Button {
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil.line")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                Text("这是一条签名")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func userInfoCard(user: UserInfo) -> some View {
        VStack(spacing: 12) {
            InfoRow(title: "真实姓名", value: user.realName ?? "未填写")
            InfoRow(title: "邮箱", value: user.email ?? "未填写")
            InfoRow(title: "手机号", value: user.phone ?? "未填写")
            InfoRow(title: "性别", value: {
                if user.gender == 1 { return "男" }
                else if user.gender == 0 { return "女" }
                else { return "未知" }
            }())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var logoutButton: some View {
        Button("退出登录") {
            showLogoutConfirm = true
        }
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(10)
        .padding()
    }
    
    @ViewBuilder
    private func userAvatarView(_ avatar: String?) -> some View {
        if let avatarString = avatar,
           let commaIndex = avatarString.firstIndex(of: ",") {
            let base64String = String(avatarString.suffix(from: avatarString.index(after: commaIndex)))
            if let data = Data(base64Encoded: base64String),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            } else {
                placeholderAvatar
            }
        } else {
            placeholderAvatar
        }
    }

    private var placeholderAvatar: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .frame(width: 60, height: 60)
            .foregroundColor(.accentColor)
    }

}

struct InfoRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
        .font(.subheadline)
        .padding(.vertical, 6)
    }
}
