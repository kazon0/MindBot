import Foundation
import SwiftUI

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [] {
        didSet {
            print("📝 messages 更新，当前数量: \(messages.count)")
        }
    }
    @Published var inputText: String = "" {
        didSet {
            print("✍️ inputText 更新: \(inputText)")
        }
    }
    @Published var isLoading: Bool = false {
        didSet {
            print("⏳ isLoading 状态: \(isLoading)")
        }
    }
    @Published var errorMessage: ErrorMessage? = nil {
        didSet {
            if let error = errorMessage {
                print("⚠️ errorMessage 更新: \(error.message)")
            }
        }
    }

    @Published var sessions: [ChatSession] = [] {
        didSet {
            print("📂 sessions 更新，当前数量: \(sessions.count)")
        }
    }
    @Published var currentSessionId: Int64? = nil {
        didSet {
            print("🔑 currentSessionId 更新: \(String(describing: currentSessionId))")
        }
    }

    func fetchSessions() async {
        print("⚡️ 调用 fetchSessions()")
        isLoading = true
        errorMessage = nil
        do {
            let fetchedSessions = try await APIManager.shared.getAllChatSessions()
            print("🎯 当前会话列表：\(fetchedSessions.map { "\($0.title)(\($0.id))" })")

            if fetchedSessions.isEmpty {
                print("📭 无会话，准备创建新会话")
                let newSession = try await APIManager.shared.createChatSession()
                sessions = [newSession]
                await selectSession(sessionId: Int64(newSession.id))
            } else {
                print("📂 加载已有会话")
                sessions = fetchedSessions
                if let first = fetchedSessions.first {
                    await selectSession(sessionId: Int64(first.id))
                }
            }

            isLoading = false
            print("✅ fetchSessions() 完成")
        } catch {
            errorMessage = ErrorMessage(message: "加载会话失败：\(error.localizedDescription)")
            isLoading = false
            print("❌ fetchSessions() 失败：\(error.localizedDescription)")
        }
    }

    func fetchMessages(sessionId: Int64) async {
        print("⚡️ 调用 fetchMessages(sessionId: \(sessionId))")
        isLoading = true
        errorMessage = nil
        do {
            let fetchedMessages = try await APIManager.shared.getChatHistory(sessionId: Int(sessionId))
            await MainActor.run {
                self.messages = fetchedMessages
            }
            isLoading = false
            print("✅ fetchMessages 完成，消息数：\(fetchedMessages.count)")
        } catch {
            errorMessage = ErrorMessage(message: "加载聊天记录失败：\(error.localizedDescription)")
            isLoading = false
            print("❌ fetchMessages 失败：\(error.localizedDescription)")
        }
    }

    func selectSession(sessionId: Int64) async {
        print("⚡️ 选择会话 sessionId: \(sessionId)")
        do {
            let fetched = try await APIManager.shared.getChatHistory(sessionId: Int(sessionId))
            await MainActor.run {
                self.messages = fetched
                self.currentSessionId = sessionId
            }
            print("✅ 会话选择完成，消息数：\(fetched.count)")
        } catch {
            errorMessage = ErrorMessage(message: "加载会话消息失败：\(error.localizedDescription)")
            print("❌ selectSession 失败：\(error.localizedDescription)")
        }
    }

    func deleteSession(session: ChatSession) async {
        print("⚡️ 删除会话 id:\(session.id) 标题:\(session.title)")
        do {
            let success = try await APIManager.shared.deleteChatSession(sessionId: session.id)
            if success {
                print("✅ 删除成功，更新会话列表")
                sessions.removeAll { $0.id == session.id }

                if currentSessionId == Int64(session.id) {
                    await MainActor.run {
                        self.currentSessionId = nil
                        self.messages = []
                    }
                    print("🔄 当前会话被删，清空消息")

                    if let newCurrent = sessions.first {
                        print("📂 切换到新会话 id: \(newCurrent.id)")
                        await selectSession(sessionId: Int64(newCurrent.id))
                    } else {
                        print("📭 无会话，创建新会话")
                        let newSession = try await APIManager.shared.createChatSession()
                        sessions = [newSession]
                        await selectSession(sessionId: Int64(newSession.id))
                    }
                }
            } else {
                errorMessage = ErrorMessage(message: "删除会话失败")
                print("❌ 删除会话返回失败")
            }
        } catch {
            errorMessage = ErrorMessage(message: "删除会话出错: \(error.localizedDescription)")
            print("❌ 删除会话异常: \(error.localizedDescription)")
        }
    }

    @MainActor
    func sendMessage() async {
        print("⚡️ 发送消息")
        guard let sessionId = currentSessionId else {
            errorMessage = ErrorMessage(message: "未选择会话")
            print("❌ 未选择会话，取消发送")
            return
        }

        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            print("❌ 输入为空，取消发送")
            return
        }

        print("💬 用户消息: \(trimmedText)")

        let userMessage = ChatMessage(
            id: Int64.random(in: Int64.min...Int64.max),
            sessionId: sessionId,
            userId: 0,
            senderType: "user",
            content: trimmedText,
            createTime: ISO8601DateFormatter().string(from: Date())
        )

        messages.append(userMessage)
        inputText = ""

        do {
            let aiReplyText = try await APIManager.shared.sendMessageToChatBot(message: trimmedText, sessionId: Int(sessionId))
            print("🤖 AI 回复: \(aiReplyText)")
            let aiMessage = ChatMessage(
                id: Int64.random(in: Int64.min...Int64.max),
                sessionId: sessionId,
                userId: 0,
                senderType: "ai",
                content: aiReplyText,
                createTime: ISO8601DateFormatter().string(from: Date())
            )
            messages.append(aiMessage)
        } catch {
            let fallbackMessage = ChatMessage(
                id: Int64.random(in: Int64.min...Int64.max),
                sessionId: sessionId,
                userId: 0,
                senderType: "ai",
                content: "（AI回复失败）",
                createTime: ISO8601DateFormatter().string(from: Date())
            )
            messages.append(fallbackMessage)
            errorMessage = ErrorMessage(message: "AI 回复失败：\(error.localizedDescription)")
            print("❌ AI 回复失败：\(error.localizedDescription)")
        }
    }
}
