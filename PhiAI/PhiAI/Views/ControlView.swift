import SwiftUI

struct ControlView: View {
    @EnvironmentObject var appVM: AppViewModel // 当前用户
    @EnvironmentObject var vm: CoreDataViewModel
    @State var selectedTab = 0
    @State var showLogin = false
    @State private var isUserInfoLoaded = false  // 用来确保用户信息加载完成

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                MainView(selectedTab: $selectedTab, showLogin: $showLogin)
                    .tabItem { Label("主页", systemImage: "house") }
                    .tag(0)
                
                CommunityView()
                    .tabItem { Label("社区", systemImage: "message.fill") }
                    .tag(1)
                
                ProfileWrapperView(showLogin: $showLogin)
                    .tabItem { Label("我的", systemImage: "person") }
                    .tag(2)
            }
            .fullScreenCover(isPresented: $showLogin) {
                NavigationStack {
                    LogView(onLogin: { user in
                        appVM.currentUser = user
                        showLogin = false
                    }, onCancel: {
                        showLogin = false
                        selectedTab = 0 // 切回主页
                    })
                }
            }
            .onAppear {
                // 异步初始化操作，确保用户信息加载完毕
                Task {
                    await appVM.autoLoginOrGuest()
                    isUserInfoLoaded = true // 完成异步加载
                }
            }
            
            // 显示加载指示器，直到用户信息加载完成
            if !isUserInfoLoaded {
                ProgressView("正在加载...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
        }
    }
}

#Preview {
    NavigationView {
        ControlView()
            .environmentObject(AppViewModel())
            .environmentObject(CoreDataViewModel())
    }
}
