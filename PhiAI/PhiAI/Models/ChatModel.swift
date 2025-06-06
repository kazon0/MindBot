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
    var content: String
    let audioUrl: String?
    let createTime: String
    let updateTime: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId
        case userId
        case senderType = "role"  
        case content
        case audioUrl
        case createTime
        case updateTime
    }
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
    let deleted: Int
}

struct RequestParams {
    let sessionId, userId: Int
}

struct AudioRequestBody: Codable {
    let audio: String
}

struct RenameSessionResponse: Codable {
    let code: Int
    let message: String
    let data: Bool
}

