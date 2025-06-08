//
//  ChatPetView.swift
//  PhiAI
//


import SwiftUI

// 模拟推荐内容

struct ChatPetView: View {
    let state: ChatAnimationState

    var body: some View {
        let imageName: String

        switch state {
        case .idle:
            imageName = "GirlSleep"
        case .listening:
            imageName = "GirlListen"
        case .thinking:
            imageName = "GirlThink"
        case .speaking:
            imageName = "GirlSay"
        }

        return Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: state)
    }
}

enum AppointmentSheet: Identifiable {
    case login
    case main

    var id: String {
        switch self {
        case .login: return "login"
        case .main: return "main"
        }
    }
}


struct ChatSuggestionBubble: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var appointmentManager: AppointmentPlatformManager

    @Binding var selectedTab: Int
    @Binding var showLogin: Bool
    @Binding var showAppointmentLoginSheet: Bool
    @Binding var showAppointmentMainSheet: Bool

    let onClose: () -> Void

    @State private var navigateToEmotionAnalysis = false

    var body: some View {
        let suggestions = [
            SuggestionItem(title: "去预约", action: {
                print("点击了『去预约』")
                print("当前用户 ID: \(appVM.currentUser?.id ?? -1)")
                print("预约平台登录状态: \(appointmentManager.isLoggedIn)")
                if appVM.currentUser?.id == -1 || appVM.currentUser == nil {
                    showLogin = true
                    selectedTab = 2
                } else if !appointmentManager.isLoggedIn {
                    showAppointmentLoginSheet = true
                } else {
                    showAppointmentMainSheet = true
                }
            }),
            SuggestionItem(title: "写心情日记", action: {
                navigateToEmotionAnalysis = true
            })
        ]

        ZStack {
            Image("Bubble")
                .resizable()
                .scaledToFit()
                .frame(width: 200)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(suggestions) { item in
                    Button(action: {
                        item.action()
                    }) {
                        Text(item.title)
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.7))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    }
                }

                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.black)
                            .font(.title3)
                            .padding(.top, 4)
                    }
                    .offset(x: -30, y: -110)
                }
            }
            .padding(16)
            .offset(x: 35, y: 10)
        }
        .frame(width: 160, height: 160)
        .navigationDestination(isPresented: $navigateToEmotionAnalysis) {
            MoodCalendarView()
                .navigationBarBackButtonHidden(true)
                .environmentObject(appVM)
        }
    }
}
