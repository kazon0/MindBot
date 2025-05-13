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


//class ChatViewModel: ObservableObject {
//    @Published var messages: [ChatEntites] = []
//    @Published var inputText: String = ""
//    @Published var user: UserEntites
//
//    private let context: NSManagedObjectContext
//
//    init(context: NSManagedObjectContext, user: UserEntites) {
//        self.context = context
//        self.user = user
//        fetchMessages()
//    }
//
//    // 获取聊天记录
//    func fetchMessages() {
//        let request: NSFetchRequest<ChatEntites> = ChatEntites.fetchRequest()
//        request.predicate = NSPredicate(format: "user == %@", user)
//        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
//        do {
//            messages = try context.fetch(request)
//        } catch {
//            print("❌ Failed to fetch messages: \(error)")
//        }
//    }
//
//    // 发送消息
//    func sendMessage() async {
//        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmedText.isEmpty else { return }
//
//        let userMessage = ChatEntites(context: context)
//        userMessage.id = UUID()
//        userMessage.text = trimmedText
//        userMessage.timestamp = Date()
//        userMessage.isUser = true
//        userMessage.conversationID = UUID()
//        userMessage.user = user
//
//        inputText = ""
//        save()
//
//        // 向 API 发送用户消息并获取 AI 回复
//        do {
//            let aiResponse = try await APIManager.shared.sendMessageToChatBot(message: trimmedText)
//
//            let aiMessage = ChatEntites(context: self.context)
//            aiMessage.id = UUID()
//            aiMessage.text = aiResponse
//            aiMessage.timestamp = Date()
//            aiMessage.isUser = false
//            aiMessage.conversationID = userMessage.conversationID
//            aiMessage.user = self.user
//
//            save()
//        } catch {
//            print("❌ Failed to send message to API: \(error)")
//        }
//    }
//
//    // 保存消息到 Core Data
//    private func save() {
//        do {
//            try context.save()
//            fetchMessages()
//        } catch {
//            print("❌ Failed to save: \(error)")
//        }
//    }
//}
