import SwiftUI

struct MyView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var userInfo: UserInfo?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isEditing = false
    
    @State private var showLogoutConfirm = false

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
                Task {
                    await loadUserInfo()
                }
            }
            .sheet(isPresented: $isEditing) {
                if let user = userInfo {
                    EditUserInfoView(user: user) { updatedUser in
                        Task {
                            do {
                                try await APIManager.shared.updateUser(userInfo: updatedUser)
                                await loadUserInfo() // 重新加载用户数据
                                isEditing = false    // 自动关闭编辑页
                            } catch {
                                errorMessage = "更新失败"
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

    private func userInfoCard(user: UserInfo) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("个人信息")
                    .font(.headline)
                Spacer()
                Button("编辑") {
                    isEditing = true
                }
            }

            InfoRow(title: "用户名", value: user.username)
            InfoRow(title: "真实姓名", value: user.realName ?? "未填写")
            InfoRow(title: "邮箱", value: user.email ?? "未填写")
            InfoRow(title: "手机号", value: user.phone ?? "未填写")
            InfoRow(title: "性别", value: {
                if user.gender == 1 { return "男" }
                else if user.gender == 2 { return "女" }
                else { return "未知" }
            }())
            InfoRow(title: "账号状态", value: (user.status == 1) ? "正常" : "禁用")
            InfoRow(title: "注册时间", value: formattedDate(user.createTime))
            InfoRow(title: "最近更新时间", value: formattedDate(user.updateTime))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    func formattedDate(_ isoString: String?) -> String {
        guard let isoString = isoString else { return "未知" }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: isoString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return isoString
    }

    private var logoutButton: some View {
        Button("退出登录") {
            showLogoutConfirm = true  // 这里改成显示弹窗
        }
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(10)
        .padding()
    }

    private func loadUserInfo() async {
        isLoading = true
        do {
            let user = try await APIManager.shared.getUserInfo()
            userInfo = user
            errorMessage = nil
        } catch {
            errorMessage = "无法获取用户信息"
        }
        isLoading = false
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

#Preview {
        MyView()
            .environmentObject(AppViewModel())
}

