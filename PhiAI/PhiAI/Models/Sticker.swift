//
//  Sticker.swift
//  PhiAI
//


import SwiftUI

struct Sticker: Identifiable {
    let id: UUID = UUID()  // 本地唯一 ID，用于 SwiftUI 显示
    let postId: Int
    let userId: Int
    let imageName: String
    let message: String
    let author: String
    let timestamp: Date

    // 展示属性
    var color: Color = .green
    var width: CGFloat = 160
    var height: CGFloat = 180
}

struct PostMessageRequest: Codable {
    let content: String
    let moodType: Int
    let nickname: String?
}

// 留言发布响应（返回留言ID）
struct PostMessageResponse: Codable {
    let data: Int64?
    let code: Int
    let message: String
}

struct GetMessageRequest {
    let page: Int
    let size: Int
}

// 单条留言
struct StickerMessage: Codable, Identifiable {
    let id: Int
    let userId: Int64
    let nickname: String
    let moodType: Int
    let content: String
    let moodImageUrl: String
    let likeCount: Int
    let createTime: String
    let isLiked: Bool
}

// 分页内容
struct StickerPageData: Codable {
    let records: [StickerMessage]
    let total: Int
    let size: Int
    let current: Int
    let pages: Int
}

// 总响应
struct GetStickerMessagesResponse: Codable {
    let code: Int
    let message: String
    let data: StickerPageData
}

