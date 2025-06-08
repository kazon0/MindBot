//
//  MessageMoodViewModel.swift
//  PhiAI
//

import Foundation
import SwiftUI

@MainActor
class MessageMoodViewModel: ObservableObject {
    @Published var moodDescription: String?
    @Published var showMoodBubble: Bool = false
    @Published var isLoading: Bool = false

    func fetchMood(for messageId: Int) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let mood = try await APIManager.shared.fetchMoodAnalysis(messageId: messageId)
            
            //  打印完整返回体，确认内容
            print(" 获取情绪分析成功：messageId=\(messageId)")
            print(" content: \(mood.content)")
            print(" analyzedMood: \(mood.analyzedMood)")
            print(" confidence: \(mood.moodConfidence)")

            self.moodDescription = mood.moodDescription
            self.showMoodBubble = true

            // 自动隐藏气泡
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.showMoodBubble = false
            }
        } catch {
            print(" 情绪分析失败: \(error)")
        }
    }

}

@MainActor
class SessionMoodViewModel: ObservableObject {
    @Published var analysis: SessionMoodAnalysisData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var showMoodPopup: Bool = false
    @Published var moodTextToDisplay: String = ""  // 用于打字动画

    func fetchAnalysis(for sessionId: Int) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await APIManager.shared.fetchSessionMoodAnalysis(sessionId: sessionId)
            self.analysis = result
            print(" 分析描述: \(result.analysisDescription)")
            print(" 建议: \(result.suggestion)")
        } catch {
            self.errorMessage = "分析失败：\(error.localizedDescription)"
            print(" 情绪会话分析失败: \(error)")
        }
    }
}
