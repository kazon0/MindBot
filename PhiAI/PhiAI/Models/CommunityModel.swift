//
//  CommunityModel.swift
//  PhiAI
//

import Foundation

//帖子和评论数据结构
struct Post: Codable {
    let id: Int
    let title: String
    let content: String
    let coverImage: String?
    let tags: String?
    let resourceType: String?
    let author: String?
    let createTime: String?
    let updateTime: String?
    let likeCount: Int?
    let viewCount: Int?
}


struct CreatePostRequest: Codable {
    let title: String
    let content: String
    let coverImage: String?
    let tags: String?
    let resourceType: String
}

struct PostResponse: Codable {
    let code: Int
    let data: Post
    let message: String
}


