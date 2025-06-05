//
//  StickerWallViewModel.swift
//  PhiAI
//

import SwiftUI

class StickerWallViewModel: ObservableObject {
    @Published var stickers: [Sticker] = []

    func fetchStickers() {
        let baseStickers = [
            Sticker(id: UUID(), imageName: "猫开心", message: "气排球及格了哟！", author: "小美", timestamp: Date()),
            Sticker(id: UUID(), imageName: "猫困惑", message: "为啥她不理我了", author: "阿星", timestamp: Date()),
            Sticker(id: UUID(), imageName: "猫生气", message: "小人速速退散", author: "沙耶", timestamp: Date()),
            Sticker(id: UUID(), imageName: "猫伤心", message: "呜呜呜挂科了，到底要怎么办🥺", author: "123", timestamp: Date()),
            Sticker(id: UUID(), imageName: "猫睡觉", message: "今晚早睡啦明天有早八", author: "千花", timestamp: Date()),
            Sticker(id: UUID(), imageName: "猫伤心", message: "复习进度总是落后，每天都感觉喘不过气...！", author: "Kazon", timestamp: Date()),
            Sticker(id: UUID(), imageName: "猫生气", message: "爱你哟", author: "小美", timestamp: Date()),
            Sticker(id: UUID(), imageName: "猫开心", message: "继续闪耀！", author: "", timestamp: Date()),
            Sticker(id: UUID(), imageName: "猫睡觉", message: "我也爱你", author: "阿星", timestamp: Date()),
            Sticker(id: UUID(), imageName: "猫伤心", message: "考研压力好大", author: "小飞飞", timestamp: Date())
        ]
        
        // 给每个贴纸随机赋值颜色和尺寸
        stickers = baseStickers.map { sticker in
            var s = sticker
            s.color = randomColor()
            s.width = CGFloat.random(in: 140...180)
            s.height = CGFloat.random(in: 160...200)
            return s
        }
    }
    
    private func randomColor() -> Color {
        let colors: [Color] = [.green, .blue, .orange, .pink, .purple, .yellow]
        return colors.randomElement() ?? .green
    }

    func postSticker(imageName: String, message: String, author: String) {
        var newSticker = Sticker(
            id: UUID(),
            imageName: imageName,
            message: message,
            author: author.isEmpty ? "匿名" : author,
            timestamp: Date()
        )
        newSticker.color = randomColor()
        newSticker.width = CGFloat.random(in: 140...180)
        newSticker.height = CGFloat.random(in: 160...200)
        stickers.append(newSticker)
        // TODO: 上传到后端
    }
}
