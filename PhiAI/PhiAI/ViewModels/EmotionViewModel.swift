//
//  EmotionViewModel.swift
//  PhiAI

import Foundation

@MainActor
class EmotionViewModel: ObservableObject {
    @Published var emotion: EmotionData? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchEmotionAnalysis(userId :Int) async {
        guard userId != -1 else {
            errorMessage = "用户未登录"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await APIManager.shared.getEmotionAnalysis(for: userId)
            emotion = result
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
