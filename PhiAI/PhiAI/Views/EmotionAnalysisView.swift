//
//  EmotionAnalysisView.swift
//  PhiAI
//

import SwiftUI

struct EmotionAnalysisView: View {
    @StateObject private var vm = EmotionViewModel()
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        NavigationView {
            VStack {
                if vm.isLoading {
                    ProgressView("加载中...")
                }
                if let emotion = vm.emotion {
                    VStack(alignment: .leading) {
                        Text("描述: \(emotion.description)")
                        Text("快乐度: \(emotion.happinessScore)")
                            .foregroundColor(emotion.happinessScore > 50 ? .green : .red)
                    }
                    .padding(4)
                } else {
                    Text("暂无情绪数据")
                }

            }
            .navigationTitle("情绪分析")
            .task {
                let userId = appVM.currentUser?.id ?? -1
                await vm.fetchEmotionAnalysis(userId: userId)
            }
        }
    }
}

struct EmotionAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            EmotionAnalysisView()
                .environmentObject(AppViewModel())
        }
    }
}
