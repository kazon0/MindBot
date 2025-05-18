import Foundation
import SwiftUI

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: ErrorMessage? = nil  // 这里改成ErrorMessage?

    @Published var sessions: [ChatSession] = []
    @Published var currentSessionId: Int64? = nil

    // 获取所有会话
    func fetchSessions() async {
        print("⚡️ 调用 fetchSessions()")
        isLoading = true
        errorMessage = nil
        do {
            let fetchedSessions = try await APIManager.shared.getAllChatSessions()
            print("🎯 当前会话列表：\(sessions.map { "\($0.title)(\($0.id))" })")
            print("✅ 当前选中会话ID: \(currentSessionId ?? -1)")
            print("💬 当前消息数量: \(messages.count)")

            if fetchedSessions.isEmpty {
                // 无会话，自动创建新会话
                let newSession = try await APIManager.shared.createChatSession()
                sessions = [newSession]
                currentSessionId = Int64(newSession.id)
                await fetchMessages(sessionId: Int64(newSession.id))
            } else {
                // 正常加载已有会话
                sessions = fetchedSessions
                if let first = fetchedSessions.first {
                    currentSessionId = Int64(first.id)
                    await fetchMessages(sessionId: Int64(first.id))
                }
            }

            isLoading = false
        } catch {
            errorMessage = ErrorMessage(message: "加载会话失败：\(error.localizedDescription)")
            isLoading = false
        }
    }

    // 获取聊天记录
    func fetchMessages(sessionId: Int64) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedMessages = try await APIManager.shared.getChatHistory(sessionId: Int(sessionId))
            messages = fetchedMessages
            isLoading = false
        } catch {
            errorMessage = ErrorMessage(message: "加载聊天记录失败：\(error.localizedDescription)")
            isLoading = false
        }
    }

    // 切换会话
    func selectSession(sessionId: Int64) async {
        currentSessionId = sessionId
        await fetchMessages(sessionId: sessionId)
    }
    
    // 删除对话
    func deleteSession(session: ChatSession) async {
        do {
            let success = try await APIManager.shared.deleteChatSession(sessionId: session.id)
            if success {
                // 本地也移除该会话
                sessions.removeAll { $0.id == session.id }

                // 如果删除的是当前会话，选中下一个或清空
                if currentSessionId == Int64(session.id) {
                    if let newCurrent = sessions.first {
                        await selectSession(sessionId: Int64(newCurrent.id))
                    } else {
                        currentSessionId = nil
                        // 自动创建新会话
                        let newSession = try await APIManager.shared.createChatSession()
                        sessions = [newSession]
                        currentSessionId = Int64(newSession.id)
                        messages = []
                    }
                }
            } else {
                errorMessage = ErrorMessage(message: "删除会话失败")
            }
        } catch {
            errorMessage = ErrorMessage(message: "删除会话出错: \(error.localizedDescription)")
        }
    }


    // 发送消息
    func sendMessage() async {
        guard let sessionId = currentSessionId else {
            errorMessage = ErrorMessage(message: "未选择会话")
            return
        }

        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            print("输入为空，取消发送")
            return
        }

        print("准备发送消息：", trimmedText)

        let userMessage = ChatMessage(id: Int64(Date().timeIntervalSince1970 * 1000),
                                      sessionId: sessionId,
                                      userId: 0,
                                      senderType: "user",
                                      content: trimmedText,
                                      createTime: ISO8601DateFormatter().string(from: Date()))
        messages.append(userMessage)
        inputText = ""

        do {
            let aiReplyText = try await APIManager.shared.sendMessageToChatBot(message: trimmedText, sessionId: Int(sessionId))
            print("AI 回复：", aiReplyText)

            let aiMessage = ChatMessage(id: Int64(Date().timeIntervalSince1970 * 1000 + 1),
                                        sessionId: sessionId,
                                        userId: 0,
                                        senderType: "ai",
                                        content: aiReplyText,
                                        createTime: ISO8601DateFormatter().string(from: Date()))
            messages.append(aiMessage)
        } catch {
            errorMessage = ErrorMessage(message: "AI 回复失败：\(error.localizedDescription)")
            print(errorMessage?.message ?? "未知错误")
        }
    }
}

