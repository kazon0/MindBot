import Foundation
import CoreData

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatEntites] = []
    @Published var inputText: String = ""

    private let context: NSManagedObjectContext
    private let currentUser: UserEntites

    init(context: NSManagedObjectContext, user: UserEntites) {
        self.context = context
        self.currentUser = user
        fetchMessages()
    }

    func fetchMessages() {
        let request: NSFetchRequest<ChatEntites> = ChatEntites.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", currentUser)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        do {
            messages = try context.fetch(request)
        } catch {
            print("❌ Failed to fetch messages: \(error)")
        }
    }

    func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let userMessage = ChatEntites(context: context)
        userMessage.id = UUID()
        userMessage.text = trimmedText
        userMessage.timestamp = Date()
        userMessage.isUser = true
        userMessage.conversationID = UUID()
        userMessage.user = currentUser

        inputText = ""
        save()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let aiMessage = ChatEntites(context: self.context)
            aiMessage.id = UUID()
            aiMessage.text = "AI 回复：你说的是“\(trimmedText)”对吗？"
            aiMessage.timestamp = Date()
            aiMessage.isUser = false
            aiMessage.conversationID = UUID()
            aiMessage.user = self.currentUser

            self.save()
        }
    }

    private func save() {
        do {
            try context.save()
            fetchMessages()
        } catch {
            print("❌ Failed to save: \(error)")
        }
    }
}
