//
//  ChatModel.swift
//  PhiAI
//

import Foundation

struct ChatMessage: Codable, Identifiable {
    let id: Int64
    let sessionId: Int64
    let userId: Int64
    let senderType: String
    let content: String
    let createTime: String
}

struct ChatMessageListResponse: Codable {
    let code: Int
    let message: String
    let data: [ChatMessage]
}


struct ChatSession: Identifiable, Codable {
    let id: Int
    let userId: Int
    var title: String
    let createTime: String
    let updateTime: String
}
