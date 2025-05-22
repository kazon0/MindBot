import SwiftUI

struct MainView: View {
    @State var animate: Bool = false
    
    @EnvironmentObject var appVM: AppViewModel
    @State private var navigateToChat = false
    @State private var navigateToEmotionAnalysis = false
    
    @Binding var selectedTab: Int
    @Binding var showLogin: Bool

    var body: some View {
        NavigationStack{
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
                    
                    AnimatedImageView()
                    
                    Button(action: {
                        if  appVM.currentUser?.id == -1 || appVM.currentUser == nil {
                            showLogin = true  // 如果是游客，显示登录界面
                            selectedTab = 2  // 切换到"我的"标签
                        } else {
                            navigateToChat = true
                        }
                    }) {
                        buttonView
                    }
                    .shadow(color: Color.black.opacity(0.05), radius: animate ? 12 : 6, x: 0, y: 6)
                    .scaleEffect(animate ? 1.03 : 1.0)
                    .padding(.bottom,20)
                    
                    .navigationDestination(isPresented: $navigateToChat) {
                        ChatView(viewModel: ChatViewModel())
                        
                    }
                    
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 40)
                            .foregroundColor(Color(#colorLiteral(red: 0.737, green: 0.842, blue: 0.530, alpha: 1)))
                        RoundedRectangle(cornerRadius: 40)
                            .foregroundColor(Color(#colorLiteral(red: 0.804, green: 0.926, blue: 0.591, alpha: 1)))
                            .frame(height: 320)
                            .padding()
                        
                        VStack {
                            HStack(spacing: 40) {
                                TabBarView(iconName: "情绪日志", action: {
                                    //跳转到情绪分析界面
                                    if  appVM.currentUser?.id == -1 || appVM.currentUser == nil {
                                        showLogin = true
                                        selectedTab = 2
                                    } else {
                                        navigateToEmotionAnalysis = true
                                    }
                                }, animate: $animate)
                                
                                TabBarView(iconName: "心灵鸡汤", action: {}, animate: $animate)
                                TabBarView(iconName: "预约咨询", action: {}, animate: $animate)
                            }
                            
                            planView(animate: $animate)
                        }
                        
                    }
                    .navigationDestination(isPresented: $navigateToEmotionAnalysis) {
                        EmotionAnalysisView()
                            .environmentObject(appVM)
                    }

                }
            }
            .onAppear(perform: addAnimation)
            .ignoresSafeArea(edges: .bottom)
            .padding(.bottom, -10)
        }
    }

    var buttonView: some View {
        HStack(spacing: 0) {
            TypingText(texts: ["有什么想说的...(^_^)", "请告诉MindBot..."])
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

struct AnimatedImageView: View {
    let imageNames = ["GirlStudy1", "GirlStudy3", "GirlStudy2", "GirlGame1", "GirlGame2", "GirlGame3"]
    @State private var currentIndex = 0
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(imageNames[currentIndex])
                .resizable()
                .scaledToFit()
                .cornerRadius(30)
                .animation(.easeInOut(duration: 3), value: currentIndex)
        }
        .onReceive(timer) { _ in
            currentIndex = (currentIndex + 1) % imageNames.count
        }
    }
}



struct TabBarView: View {
    var iconName: String
    var action: () -> Void
    @Binding var animate: Bool
    var body: some View {
        VStack {
            Button(action: action) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70)
                    .shadow(radius: 10)
            }
            .shadow(color: Color.black.opacity(0.05), radius: animate ? 12 : 6, x: 0, y: 6)
            .scaleEffect(animate ? 1.03 : 1.0)
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
        .shadow(color: .green.opacity(animate ? 0.2 : 0.05), radius: animate ? 15 : 6)
        .scaleEffect(animate ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
    }
}

//打字机动画效果
struct TypingText: View {
    let texts: [String]
    @State private var displayedText = ""
    @State private var charIndex = 0
    @State private var isDeleting = false
    @State private var currentTextIndex = 0
    
    @State private var timer: Timer? = nil
    
    let typingInterval: Double = 0.12
    let pauseInterval: Double = 0.8
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
                displayedText = ""
                charIndex = 0
                isDeleting = false
                currentTextIndex = 0
            }
    }
    
    func startTyping() {
        timer?.invalidate() // 先停掉旧计时器
        timer = Timer.scheduledTimer(withTimeInterval: typingInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                let currentText = texts[currentTextIndex]
                if !isDeleting {
                    if charIndex < currentText.count {
                        let index = currentText.index(currentText.startIndex, offsetBy: charIndex)
                        displayedText.append(currentText[index])
                        charIndex += 1
                    } else {
                        // 打完了，暂停并准备退字
                        timer?.invalidate()
                        DispatchQueue.main.asyncAfter(deadline: .now() + pauseInterval) {
                            isDeleting = true
                            startTyping() // 重新开始计时器，退字阶段
                        }
                    }
                } else {
                    if !displayedText.isEmpty {
                        displayedText.removeLast()
                    } else {
                        // 退字完毕，切换下一句，重置状态
                        charIndex = 0
                        isDeleting = false
                        currentTextIndex = (currentTextIndex + 1) % texts.count
                        timer?.invalidate()
                        startTyping() // 重新开始计时器，开始打字下一句
                    }
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
            }
        }
    }
    
    return PreviewWrapper()
}
