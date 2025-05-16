import SwiftUI

struct MyView: View {
    @State private var userInfo: UserInfo?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("加载中...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text("加载失败：\(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else if let user = userInfo {
                    userProfileSection(user: user)
                    userInfoCard(user: user)
                    logoutButton
                }

                Spacer()
            }
            .navigationTitle("我的")
            .onAppear {
                loadUserInfo()
            }
        }
    }

    // MARK: - 用户头像与基本信息
    private func userProfileSection(user: UserInfo) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(user.username)
                    .font(.headline)
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

    // MARK: - 用户信息卡片
    private func userInfoCard(user: UserInfo) -> some View {
        VStack(spacing: 12) {
            InfoRow(title: "真实姓名", value: user.realName ?? "未填写")
            InfoRow(title: "手机号", value: user.phone ?? "未填写")
            InfoRow(title: "邮箱", value: user.email ?? "未填写")
            InfoRow(title: "心理状态", value: "良好")
            InfoRow(title: "最近咨询", value: "2025-05-02")
            InfoRow(title: "情绪记录", value: "查看历史 >")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - 登出按钮
    private var logoutButton: some View {
        Button("退出登录") {
            KeychainHelper.shared.save("", for: "authToken")
            // 此处可添加跳转到登录界面等操作
        }
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(10)
        .padding()
    }

    // MARK: - 加载用户信息
    private func loadUserInfo() {
        Task {
            do {
                isLoading = true
                userInfo = try await APIManager.shared.getUserInfo()
                errorMessage = nil
            } catch {
                errorMessage = "无法获取用户信息"
            }
            isLoading = false
        }
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
