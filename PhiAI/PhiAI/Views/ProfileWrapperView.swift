import SwiftUI

struct ProfileWrapperView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Binding var showLogin: Bool

    var body: some View {
        ZStack {
            // 确保我们只访问非空的用户
            if let user = appVM.currentUser {
                // 如果是游客
                if user.id == -1 {
                    VStack{
                        Text("您正在以游客身份浏览")
                            .font(.title)
                            .padding()
                        
                        // 提供游客功能或限制功能
                        Text("游客功能：查看社区")
                            .padding()

                        Button("登录") {
                            showLogin = true
                        }
                    }
                    .padding()
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

struct ProfileWrapperView_Previews: PreviewProvider {
    static var previews: some View {
        WrapperPreview()
    }

    struct WrapperPreview: View {
        @State var showLogin = false
        @StateObject var appVM = AppViewModel()

        var body: some View {
            ProfileWrapperView(showLogin: $showLogin)
                .environmentObject(appVM)
        }
    }
}
