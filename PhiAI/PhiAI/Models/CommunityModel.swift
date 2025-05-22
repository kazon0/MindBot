//
//  CommunityModel.swift
//  PhiAI
//

import Foundation

//帖子和评论数据结构
struct Post: Codable, Identifiable {
    let id: Int
    let content: String
    let isAnonymous: Bool
    let timestamp: String
    let user: UserInfo?
    let comments: [Comment]?
}

struct Comment: Codable, Identifiable {
    let id: Int
    let content: String
    let timestamp: String
    let user: UserInfo?
}

