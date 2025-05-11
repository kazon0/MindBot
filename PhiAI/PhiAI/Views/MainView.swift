

import SwiftUI
import CoreData


struct MainView: View {
    @State var animate :Bool = false
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var vm : CoreDataViewModel
    @State private var navigateToChat = false
    var body: some View {
        ZStack {
                  LinearGradient(
                    gradient: Gradient(colors: [Color(#colorLiteral(red: 0.8243927956, green: 0.8143479228, blue: 0.8116865754, alpha: 1)), Color(#colorLiteral(red: 0.983543694, green: 0.9193384051, blue: 0.8205929399, alpha: 1)),Color(#colorLiteral(red: 0.8366191387, green: 0.976777494, blue: 0.6015968323, alpha: 1))]),
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                  )
                  .ignoresSafeArea() // 让背景填满整个屏幕
            
                  // 主页的内容
                  VStack {
                      ZStack(alignment: .topLeading){
                          Image("GirlStudy")
                              .resizable()
                              .scaledToFit()
                              .cornerRadius(30)
                          //放标题mindbot
                      }
                      if let user = appVM.currentUser {
                          Button(action: {
                              navigateToChat = true
                          }) {
                              buttonView
                          }
                          .padding(.bottom, 20)

                          // 真正的跳转在这里发生
                          NavigationLink(
                              destination: ChatView(viewModel: ChatViewModel(context: vm.container.viewContext, user: user)),
                              isActive: $navigateToChat,
                              label: {
                                  EmptyView()
                              })
                              .hidden() // 不显示链接 UI
                      } else {
                          Text("请先登录")
                      }
                      ZStack(alignment: .top){
                          RoundedRectangle(cornerRadius: 40)
                              .foregroundColor(Color(#colorLiteral(red: 0.7366558313, green: 0.8424485326, blue: 0.5300986767, alpha: 1)))
                          RoundedRectangle(cornerRadius: 40)
                              .foregroundColor(Color(#colorLiteral(red: 0.8039464355, green: 0.9262456298, blue: 0.5914456248, alpha: 1)))
                              .frame(height: 320)
                              .padding()
                          VStack {
                              HStack(spacing: 40){
                                  TabBarView(iconName: "情绪日志", action:{
                                      
                                  })
                                  TabBarView(iconName: "心灵鸡汤", action:{
                                      
                                  })
                                  TabBarView(iconName: "预约咨询", action:{
                                      
                                  })
                              }
                              planView(animate: $animate)
                          }
                      }
                  }
              }
        .onAppear(perform: addAnimation)
        .ignoresSafeArea(edges:.bottom)
        
    }
    
    var buttonView :some View{//必须是一个视图
        HStack(spacing: 0) {
              // 左边部分
              Text("有什么想说的...(^_^)")
                .font(.title3)
                  .frame(maxWidth: .infinity)
                  .frame(width: 250,height: 55)
                  .background(
                    animate ? Color(#colorLiteral(red: 0.960406363, green: 1, blue: 0.9624858499, alpha: 1)) : Color.white
                  )
                  .foregroundColor(Color(#colorLiteral(red: 0.7874389887, green: 0.7748765349, blue: 0.7903142571, alpha: 1)))
              // 右边部分
              Text("Press")
                .font(.title3)
                .fontWeight(.heavy)
                  .frame(maxWidth: .infinity)
                  .frame(height: 55)
                  .background(
                    animate ? Color(#colorLiteral(red: 0.5306600928, green: 0.8630978465, blue: 0.5769880414, alpha: 1)) : Color(#colorLiteral(red: 0.750221312, green: 0.8579488397, blue: 0, alpha: 1))
                  )
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
    
    func addAnimation(){
        guard !animate else { return }
        DispatchQueue.main.asyncAfter(deadline: .now()+1.5){
            withAnimation(
                Animation.easeOut(duration: 2)
                    .repeatForever()
            ){
                animate.toggle()
            }
        }
    }
}

struct TabBarView: View {
    var iconName :String
    var action: () -> Void
    var body: some View {
        VStack{
            Button(action : action){
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
    @Binding var animate :Bool
    var body: some View {
        ZStack(){
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(animate ? Color(#colorLiteral(red: 0.960406363, green: 1, blue: 0.9624858499, alpha: 1)) : Color.white
                )
                .frame(height: 160)
                .padding(.horizontal,50)
                .padding(.vertical,20)
                .shadow(color: .black.opacity(0.1),radius:animate ?10 : 5)
            VStack(spacing: 10){
                HStack {
                    Text("我的疗愈计划✨")
                        .font(.title2)
                        .fontWeight(.heavy)
                    Spacer()
                }
                .padding(.horizontal,70)
                Text("输入困惑，MindBot就可以生成最适合你的疗愈计划!")
                    .font(.body)
                    .foregroundColor(.gray)
                    .lineLimit(nil)
                    .padding(.horizontal, 60)
                    Button(action:{
                        
                    }){
                        Text("去生成")
                            .foregroundColor(.white)
                            .frame(width: 200,height: 30)
                            .background(Color.accentColor)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    }
            }
        }
    }
}

#Preview {
    NavigationView{
        MainView()
            .environmentObject(AppViewModel())
            .environmentObject(CoreDataViewModel())
    }
}


