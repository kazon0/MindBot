import Foundation

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // 加载聊天记录
    func fetchMessages() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await APIManager.shared.getChatHistory()
            DispatchQueue.main.async {
                self.messages = fetched
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "加载聊天记录失败：\(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // 发送消息 + 获取 AI 回复
    func sendMessage() async {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let userMessage = ChatMessage(id: UUID(), text: trimmedText, timestamp: ISO8601DateFormatter().string(from: Date()), isUser: true)

        DispatchQueue.main.async {
            self.messages.append(userMessage)
            self.inputText = ""
        }

        do {
            let aiReplyText = try await APIManager.shared.sendMessageToChatBot(message: trimmedText)
            let aiMessage = ChatMessage(id: UUID(), text: aiReplyText, timestamp: ISO8601DateFormatter().string(from: Date()), isUser: false)

            DispatchQueue.main.async {
                self.messages.append(aiMessage)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "AI 回复失败：\(error.localizedDescription)"
            }
        }
    }
}
