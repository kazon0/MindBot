//
//  StickerWallViewModel.swift
//  PhiAI
//

import SwiftUI

@MainActor
class StickerWallViewModel: ObservableObject {
    @Published var stickers: [Sticker] = []
    @Published var isPosting = false
    @Published var errorMessage: String? = nil
    
    @Published var currentUserId: Int? = nil
    @Published var showPermissionAlert: Bool = false
    
    func imageNameFromMood(_ mood: Int) -> String {
        switch mood {
        case 1: return "猫开心"
        case 2: return "猫伤心"
        case 3: return "猫生气"
        case 4: return "猫困惑"
        case 5: return "猫睡觉"
        default: return "猫开心"
        }
    }

    func date(from string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")  // 确保不受地区设置影响
        return formatter.date(from: string) ?? Date()
    }

    func fetchStickers() {
        Task {
            do {
                let messages = try await APIManager.shared.fetchStickerMessages()
                let mapped = messages.map { msg in
                    var sticker = Sticker(
                        postId: Int(msg.id),
                        userId: Int(msg.userId),
                        imageName: imageNameFromMood(msg.moodType),
                        message: msg.content,
                        author: msg.nickname,
                        timestamp: ISO8601DateFormatter().date(from: msg.createTime) ?? Date()
                    )
                    sticker.color = randomColor()
                    sticker.width = CGFloat.random(in: 140...180)
                    sticker.height = CGFloat.random(in: 160...200)
                    return sticker
                }
                self.stickers = mapped
            } catch {
                print("拉取留言失败：\(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
        }
    }


    func postStickerToBackend(imageName: String, message: String, author: String, moodType: Int) async {
        isPosting = true
        errorMessage = nil
        let request = PostMessageRequest(
            content: message,
            moodType: moodType,
            nickname: author.isEmpty ? nil : author
        )

        do {
            let messageId = try await APIManager.shared.postMessageToWall(request: request)

            var newSticker = Sticker(
                postId: Int(messageId),
                userId: currentUserId ?? 0,
                imageName: imageName,
                message: message,
                author: author.isEmpty ? "匿名" : author,
                timestamp: Date()
            )
            newSticker.color = randomColor()
            newSticker.width = CGFloat.random(in: 140...180)
            newSticker.height = CGFloat.random(in: 160...200)
            stickers.append(newSticker)

            print("贴纸上传成功，留言ID：\(messageId)")
            fetchStickers()

        } catch {
            print("上传失败：\(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isPosting = false
    }

    func deleteSticker(_ sticker: Sticker) async {
        guard let currentUserId = currentUserId else {
            print(" 当前用户 ID 不存在，无法校验权限")
            errorMessage = "请先登录"
            return
        }

        // 如果不是自己发的贴纸，禁止删除
        if sticker.userId != currentUserId {
            print(" 无权限删除别人的贴纸")
            await MainActor.run {
                self.showPermissionAlert = true
            }
            fetchStickers()
            return
        }

        print(" 正在删除贴纸，postId: \(sticker.postId)")

        do {
            try await APIManager.shared.deletePost(postId: Int(sticker.postId))
            if let index = stickers.firstIndex(where: { $0.postId == sticker.postId }) {
                stickers.remove(at: index)
                print(" 本地贴纸列表中已移除 index: \(index)")
            } else {
                print(" 本地找不到对应的贴纸，无法移除")
            }
        } catch {
            print(" 删除失败：\(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    
    private func randomColor() -> Color {
        let colors: [Color] = [.green, .blue, .orange, .pink, .purple, .yellow]
        return colors.randomElement() ?? .green
    }
}
