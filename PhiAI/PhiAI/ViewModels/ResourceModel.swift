//
//  Resource.swift
//  PhiAI
//

import Foundation

struct Resource: Codable, Identifiable {
    let id: Int64?
    let title: String?
    let description: String?
    let content: String?
    let author: String?
    let categoryId: Int64?
    let resourceType: String?
    let coverImage: String?
    let fileObjectName: String?
    let fileSize: Int64?
    let duration: Int?
    let viewCount: Int?
    let downloadCount: Int?
    let likeCount: Int?
    let status: Int?
    let allowDownload: Int?
    let tags: String?
    let createTime: String?
    let updateTime: String?
    let deleted: Int?
}
