
import SwiftUI

struct MyView: View {
    let user: UserEntites
    
    var body: some View {
        let username = user.name ?? "未知用户"
        VStack(spacing: 20) {
            // 头像和基本信息
            HStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.accentColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(username)
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

//            // 院系和学号
//            HStack {
//                Text("计算机与大数据学院")
//                Spacer()
//                Text("学号：102300307")
//            }
//            .font(.subheadline)
//            .foregroundColor(.gray)
//            .padding(.horizontal)

            // 其他信息卡片
            VStack(spacing: 12) {
                InfoRow(title: "出生日期", value: "2003-09-15")
                InfoRow(title: "心理状态", value: "良好")
                InfoRow(title: "最近咨询", value: "2025-05-02")
                InfoRow(title: "情绪记录", value: "查看历史 >")
                InfoRow(title: "偏好设置", value: "偏好安静、睡眠指导")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

           

            // 退出或编辑按钮
            HStack {
                Button("退出登录") {
                    // 处理退出逻辑
                }
                .foregroundColor(.white)
            }
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .cornerRadius(10)
            .padding()
            
            Spacer()
        }
        .navigationTitle("我的")
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
        .padding(.vertical)
    }
}

#Preview {
        let vm = CoreDataViewModel()
        let context = vm.container.viewContext
        let user = UserEntites(context: context)
        user.name = "测试用户"
        user.id = 1001
        user.pwd = "123456"

        return NavigationView {
            MyView(user: user)
        }
}
