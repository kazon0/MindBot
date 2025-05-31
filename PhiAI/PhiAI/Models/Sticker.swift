//
//  Sticker.swift
//  PhiAI
//


import SwiftUI

struct Sticker: Identifiable, Codable {
    let id: UUID
    let imageName: String
    let message: String
    let author: String
    let timestamp: Date
    
    // 新增的展示属性（不参与编码，可以用 CodingKeys 控制）
    var color: Color = .green
    var width: CGFloat = 160
    var height: CGFloat = 180
    
    // 让 Codable 忽略这几个属性
    enum CodingKeys: String, CodingKey {
        case id, imageName, message, author, timestamp
    }
}
