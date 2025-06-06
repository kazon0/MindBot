//
//  AppointmentLoginView.swift
//  PhiAI
//

import SwiftUI

struct AppointmentLoginView: View {
    @State private var studentID: String = AppViewModel.shared.currentUser?.username ?? ""
    @State private var password: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoggingIn = false
    @State private var animate = false
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToAppointment = false
    
    @EnvironmentObject var appointmentManager: AppointmentPlatformManager

    var body: some View {
        NavigationStack{
            
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(#colorLiteral(red: 0.8626629114, green: 0.9756165147, blue: 0.7313965559, alpha: 1)).opacity(0.5),
                        Color(#colorLiteral(red: 0.8042530417, green: 0.9252516627, blue: 0.5908532143, alpha: 1)),
                        Color(#colorLiteral(red: 0.4738111496, green: 0.752263248, blue: 0.3751039505, alpha: 1))
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    // 顶部返回按钮
                    HStack {
                        Button(action: {
                            withAnimation {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.accentColor)
                                .font(.caption)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    
                    ZStack {
                        Image("GirlPlayWithCat")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 370)
                            .offset(y: -30)
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)
                            // 应用圆角和遮罩渐变
                            .mask(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.clear, .black]),
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                            )

                        HStack {

                            Spacer()
                        }
                    }
                    
                    Spacer()
                    
                    // 登录卡片动画区域
                    VStack(spacing: 30) {
                        
                        HStack {
                            Text("预约\n登录界面")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.black)
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)
                                .animation(.easeOut(duration: 0.4), value: animate)
                                .padding(.leading,-120)
                        }
                        
                        TextField("请输入学号...", text: $studentID)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.black)
                            .frame(width: 250)
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: animate)
                        
                        SecureField("请输入密码...", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.black)
                            .frame(width: 250)
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)
                        
                        Button(action: {
                            Task { await login() }
                        }) {
                            Text("登录")
                                .frame(width: 250)
                                .frame(height: 48)
                                .background(Color.accent)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.accentColor.opacity(animate ? 0.4 : 0.1), radius: animate ? 10 : 3)
                                .scaleEffect(animate ? 1.06 : 1.0)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)
                        }
                        .disabled(studentID.isEmpty || password.isEmpty || isLoggingIn)
                        .opacity(animate ? 1 : 0)
                    }
                    .offset(y:-100)
                    .padding()
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 340, height: 540)
                                .padding()
                                .offset(y:-40)
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(#colorLiteral(red: 0.9557026029, green: 0.9727001786, blue: 0.8858824372, alpha: 1)).opacity(0.8))
                                .shadow(color: .black.opacity(0.2), radius: 10)
                                .frame(width: 380, height: 680)
                            Image("Check")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .offset(x:95,y:-200)
                        }
                    )
                    .padding()
                    .scaleEffect(animate ? 1 : 0.95)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.4), value: animate)
                    
                    Spacer()

                }
            }
            .overlay(
                Group {
                    if isLoggingIn {
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
                        .offset(y:50)
                        .transition(.opacity)
                    }
                }
            )

        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToAppointment, destination: {
            AppointmentView().environmentObject(appointmentManager)
        })
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animate = true
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertMessage))
        }
    }
        
    }

    func login() async {
        guard (9...9).contains(studentID.count), Int(studentID) != nil else {
            alertMessage = "请输入有效的学号（9位数字）"
            showingAlert = true
            return
        }
        guard password.count >= 6 else {
            alertMessage = "密码长度至少6位"
            showingAlert = true
            return
        }

        isLoggingIn = true
        defer { isLoggingIn = false }

        let request = Request(password: password, schoolName: "福州大学", username: studentID)
        do {
            let response = try await APIManager.shared.loginToPsyPlatform(request: request)
            appointmentManager.token = response
            appointmentManager.isLoggedIn = true
            alertMessage = "登录成功！"
            print("登录成功，准备跳转 AppointmentView")
            showingAlert = true
            navigateToAppointment = true
        } catch {
            alertMessage = "登录失败：\(error.localizedDescription)"
            showingAlert = true
        }

    }
}

struct AppointmentLoginView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentLoginView()
            .environmentObject(AppointmentPlatformManager())
    }
}
