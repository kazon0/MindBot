import SwiftUI

struct ControlView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State var selectedTab = 0
    @State var showLogin = false
    @State private var guestRefresh = 0

    var body: some View {
        ZStack {
            if appVM.isUserLoaded {
                TabView(selection: $selectedTab) {
                    MainView(selectedTab: $selectedTab, showLogin: $showLogin)
                        .tabItem { Label("主页", systemImage: "house") }
                        .tag(0)

                    CommunityView()
                        .tabItem { Label("社区", systemImage: "message.fill") }
                        .tag(1)
                    
                    ProfileWrapperView(showLogin: $showLogin, guestRefresh: $guestRefresh)
                                   .tabItem { Label("我的", systemImage: "person") }
                                   .tag(2)
                }
                .onChange(of: selectedTab) { newTab in
                    if newTab == 2 {
                        guestRefresh += 1
                    }
                }
                .fullScreenCover(isPresented: $showLogin) {
                    NavigationStack {
                        LogView(onLogin: { user in
                            appVM.currentUser = user
                            showLogin = false
                        }, onCancel: {
                            showLogin = false
                            selectedTab = 0
                        })
                    }
                }
            } else {
                ProgressView("正在加载...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
        }
        .task {
            await appVM.autoLoginOrGuest()  //主动调用，开始加载用户
        }
    }
}



#Preview {
    NavigationView {
        ControlView()
            .environmentObject(AppViewModel())
    }
}
