//
//  MoodAnalysis.swift
//  PhiAI
//

import Foundation

struct MoodAnalysisResponse: Codable {
    let code: Int
    let message: String
    let data: MoodAnalysis
}

struct MoodAnalysis: Codable {
    let id: Int
    let sessionId: Int64
    let userId: Int
    let role: String
    let content: String
    let audioUrl: String?
    let createTime: String
    let updateTime: String
    let deleted: Int
    let analyzedMood: Int
    let moodConfidence: Double
    let userSelectedMood: Int?
    let moodDescription: String
    let analyzed: Bool
}

struct SessionMoodAnalysisResponse: Codable {
    let code: Int
    let message: String
    let data: SessionMoodAnalysisData?
}

struct SessionMoodAnalysisData: Codable {
    let sessionId: Int
    let userId: Int
    let sessionTitle: String
    let messageCount: Int
    let userMessageCount: Int
    let analysisTime: String
    let earliestMessageTime: String
    let latestMessageTime: String
    let primaryMood: Int
    let moodDistribution: [String: Int]
    let moodPercentages: [String: Double]
    let averageConfidence: Double
    let trendDescription: String
    let analysisDescription: String
    let suggestion: String
    let keywords: [String]
    let analyzedMessages: [AnalyzedMessage]
    let moodTimeSeries: [String: Int]
}

struct AnalyzedMessage: Codable, Identifiable {
    let id: Int
    let sessionId: Int
    let userId: Int
    let role: String
    let content: String
    let audioUrl: String?
    let createTime: String
    let updateTime: String
    let deleted: Int
    let analyzedMood: Int
    let moodConfidence: Double
    let userSelectedMood: Int?
    let moodDescription: String?
    let analyzed: Bool
}


