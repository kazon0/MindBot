import SwiftUI

struct MainView: View {
    @State var animate: Bool = false
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var vm: CoreDataViewModel
    @State private var navigateToChat = false
    
    @Binding var selectedTab: Int
    @Binding var showLogin: Bool
    
    private var chatDestination: some View {
            if let user = appVM.currentUser, !user.isGuest {
                return AnyView(ChatView(viewModel: ChatViewModel(context: vm.container.viewContext, user: user)))
            }
        else{
            return AnyView(EmptyView())
        }
    }


    var body: some View {
        ZStack {
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
                ZStack(alignment: .topLeading) {
                    Image("GirlStudy")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(30)
                }

                Button(action: {
                      if appVM.currentUser?.isGuest ?? true {
                          showLogin = true  // 如果是游客，显示登录界面
                          selectedTab = 2  // 切换到"我的"标签
                      } else {
                          NavigationLink(
                              destination: chatDestination,
                              isActive: $navigateToChat,
                              label: {
                                  EmptyView()
                              }
                          )
                          .hidden()
                      }
                  }) {
                      buttonView
                  }
                
                .padding(.bottom,20)

                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 40)
                        .foregroundColor(Color(#colorLiteral(red: 0.737, green: 0.842, blue: 0.530, alpha: 1)))
                    RoundedRectangle(cornerRadius: 40)
                        .foregroundColor(Color(#colorLiteral(red: 0.804, green: 0.926, blue: 0.591, alpha: 1)))
                        .frame(height: 320)
                        .padding()

                    VStack {
                        HStack(spacing: 40) {
                            TabBarView(iconName: "情绪日志", action: {})
                            TabBarView(iconName: "心灵鸡汤", action: {})
                            TabBarView(iconName: "预约咨询", action: {})
                        }
                        planView(animate: $animate)
                    }
                }
            }
        }
        .onAppear(perform: addAnimation)
        .ignoresSafeArea(edges: .bottom)
    }

    var buttonView: some View {
        HStack(spacing: 0) {
            Text("有什么想说的...(^_^)")
                .font(.title3)
                .frame(maxWidth: .infinity)
                .frame(width: 250, height: 55)
                .background(animate ? Color(#colorLiteral(red: 0.960, green: 1, blue: 0.962, alpha: 1)) : Color.white)
                .foregroundColor(Color(#colorLiteral(red: 0.787, green: 0.775, blue: 0.790, alpha: 1)))

            Text("Press")
                .font(.title3)
                .fontWeight(.heavy)
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(animate ? Color(#colorLiteral(red: 0.531, green: 0.863, blue: 0.577, alpha: 1)) : Color(#colorLiteral(red: 0.750, green: 0.858, blue: 0, alpha: 1)))
                .foregroundColor(.white)
        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.2), radius: animate ? 10 : 5, x: 0, y: 6)
    }

    func addAnimation() {
        guard !animate else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(Animation.easeOut(duration: 2).repeatForever()) {
                animate.toggle()
            }
        }
    }
}


struct TabBarView: View {
    var iconName: String
    var action: () -> Void

    var body: some View {
        VStack {
            Button(action: action) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70)
                    .shadow(radius: 10)
            }
            Text(iconName)
                .fontWeight(.heavy)
        }
    }
}

struct planView: View {
    @Binding var animate: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(animate ? Color(#colorLiteral(red: 0.960, green: 1, blue: 0.962, alpha: 1)) : Color.white)
                .frame(height: 160)
                .padding(.horizontal, 50)
                .padding(.vertical, 20)
                .shadow(color: .black.opacity(0.1), radius: animate ? 10 : 5)

            VStack(spacing: 10) {
                HStack {
                    Text("我的疗愈计划✨")
                        .font(.title2)
                        .fontWeight(.heavy)
                    Spacer()
                }
                .padding(.horizontal, 70)

                Text("输入困惑，MindBot就可以生成最适合你的疗愈计划!")
                    .font(.body)
                    .foregroundColor(.gray)
                    .lineLimit(nil)
                    .padding(.horizontal, 60)

                Button(action: {}) {
                    Text("去生成")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 30)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                }
            }
        }
    }
}



#Preview {
    // 为预览创建临时状态变量
    struct PreviewWrapper: View {
        @State private var selectedTab = 2
        @State private var showLogin = true
        
        var body: some View {
            NavigationView {
                MainView(selectedTab: $selectedTab, showLogin: $showLogin)
                    .environmentObject(AppViewModel())
                    .environmentObject(CoreDataViewModel())
            }
        }
    }
    
    return PreviewWrapper()
}
