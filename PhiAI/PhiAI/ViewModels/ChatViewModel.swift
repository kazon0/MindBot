import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func fetchMessages() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await APIManager.shared.getChatHistory()
            messages = fetched
            isLoading = false
        } catch {
            errorMessage = "加载聊天记录失败：\(error.localizedDescription)"
            isLoading = false
        }
    }

    func sendMessage() async {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let userMessage = ChatMessage(id: UUID(), text: trimmedText, timestamp: ISO8601DateFormatter().string(from: Date()), isUser: true)

        messages.append(userMessage)
        inputText = ""

        do {
            let aiReplyText = try await APIManager.shared.sendMessageToChatBot(message: trimmedText)
            let aiMessage = ChatMessage(id: UUID(), text: aiReplyText, timestamp: ISO8601DateFormatter().string(from: Date()), isUser: false)

            messages.append(aiMessage)
        } catch {
            errorMessage = "AI 回复失败：\(error.localizedDescription)"
        }
    }
}
