import SwiftUI

struct ControlView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var appointmentManager: AppointmentPlatformManager
    @State var selectedTab = 0
    @State var showLogin = false
    @State private var guestRefresh = 0
    @State private var guestRefresh1 = 0
    @State private var showContent = false

    var body: some View {
        ZStack {
            if showContent {
                TabView(selection: $selectedTab) {
                    MainView(selectedTab: $selectedTab, showLogin: $showLogin)
                        .tabItem { Label("主页", systemImage: "house") }
                        .tag(0)

                    StickerWallView(guestRefresh1: $guestRefresh1)
                        .id(guestRefresh1)
                        .tabItem { Label("社区", systemImage: "ellipsis.message.fill") }
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
                .onChange(of: selectedTab) { newTab in
                    if newTab == 1 {
                        guestRefresh1 += 1
                    }
                }
                .fullScreenCover(isPresented: $showLogin) {
                    LogView(onLogin: { user in
                        appVM.currentUser = user
                        showLogin = false
                    }, onCancel: {
                        showLogin = false
                        selectedTab = 0
                    })
                }
                .onAppear {
                    let tabBarAppearance = UITabBarAppearance()
                    tabBarAppearance.configureWithOpaqueBackground()
                    tabBarAppearance.backgroundColor = UIColor(Color(#colorLiteral(red: 0.7366558313, green: 0.8424485326, blue: 0.5300986767, alpha: 1)))
                    tabBarAppearance.shadowColor = .clear
                    UITabBar.appearance().standardAppearance = tabBarAppearance
                    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                }
                // 加载动画
                .overlay(
                    Group {
                        if !appVM.isUserLoaded {
                            ZStack {
                                HStack(spacing: 16) {
                                    Text("Loading...")
                                        .font(.headline)
                                        .italic()
                                        .foregroundColor(.gray)
                                    ProgressView() // 系统加载圈
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                        .scaleEffect(1.4)
                                }
                                .padding(24)
                                .background(.ultraThinMaterial) // 半透明磨砂背景
                                .cornerRadius(20)
                                .shadow(radius: 10)
                            }
                            .offset(y:20)
                            .transition(.opacity)
                        }
                    }
                )

            }
        }
        .onAppear {
            showContent = true
            if !appVM.isUserLoaded {
                Task {
                    await appVM.autoLoginOrGuest()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ControlView()
            .environmentObject(AppViewModel())
            .environmentObject(AppointmentPlatformManager())
    }
}
