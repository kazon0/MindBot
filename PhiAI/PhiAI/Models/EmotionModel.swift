//
//  EmotionModel.swift
//  PhiAI
//

import Foundation

//情绪分析
struct EmotionResponse: Codable {
    let code: Int
    let data: EmotionData   // 单条数据
    let message: String
}

struct EmotionData: Codable, Identifiable {
    let id: Int
    let analysisTime: String
    let anxietyScore: Int
    let calmScore: Int
    let createTime: String
    let dataTimeRange: Int
    let description: String
    let fatigueScore: Int
    let happinessScore: Int
    let primaryMood: Int
    let secondaryMood: Int
    let stressScore: Int
    let suggestion: String
    let userId: Int
}
