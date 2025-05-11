
import SwiftUI

struct ControlView: View {
    
    @EnvironmentObject var appVM: AppViewModel //当前用户
    @EnvironmentObject var vm: CoreDataViewModel
    @State private var selectedTab = 0
    @State private var showLogin = false
    
    var body: some View {
        
        ZStack{
            TabView(selection: $selectedTab) {
                 MainView()
                     .tabItem { Label("主页", systemImage: "house")}
                     .tag(0)
                CommunityView()
                     .tabItem { Label("社区", systemImage: "house")}
                     .tag(1)
                 ProfileWrapperView(showLogin: $showLogin)
                     .tabItem { Label("我的", systemImage: "person")}
                     .tag(2)
             }
            .fullScreenCover(isPresented: $showLogin) {
                NavigationStack {
                    LogView(onLogin: { user in
                        appVM.currentUser = user
                        showLogin = false
                    },onCancel: {
                        showLogin = false
                        selectedTab = 0 //切回主页
                        }
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationView{
        ControlView()
            .environmentObject(AppViewModel())
            .environmentObject(CoreDataViewModel())
    }
}
