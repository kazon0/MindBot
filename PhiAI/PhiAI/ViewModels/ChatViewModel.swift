import Foundation
import SwiftUI

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct WSResponse: Decodable {
    let data: WSData
    let type: String
}

enum WSData: Decodable {
    case string(String)
    case int(Int)

    var stringValue: String {
        switch self {
        case .string(let str): return str
        case .int(let i): return String(i)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else {
            throw DecodingError.typeMismatch(WSData.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "WSData must be String or Int"))
        }
    }
}

struct SuggestionItem: Identifiable {
    let id = UUID()
    let title: String
    let action: () -> Void
}

enum ChatAnimationState {
    case idle         // 静止
    case listening    // 倾听中（用户输入中）
    case thinking     // AI 正在思考
    case speaking     // AI 正在说话
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: ErrorMessage? = nil

    @Published var sessions: [ChatSession] = []
    @Published var currentSessionId: Int64? = nil
    @Published var userId: Int64? = nil
    
    private var webSocketClient = AIWebSocketClientStarscream()
    private var currentAIContent = ""
    @Published var isReceivingMessage: Bool = false
    private var placeholderMessageId: Int64?
    
    @Published var animationState: ChatAnimationState = .idle
    
    @Published var showSuggestionBubble = false
    
    @Published var suggestions: [SuggestionItem] = []


    func fetchSessions() async {
        isLoading = true
        errorMessage = nil
        
        guard let userId = userId, userId > 0 else {
            errorMessage = ErrorMessage(message: "用户未登录或无效用户ID")
            isLoading = false
            print("[fetchSessions] 无效用户ID，无法获取会话")
            return
        }
        
        do {
            print("[fetchSessions] 开始获取会话列表，userId: \(userId)")
            let fetchedSessions = try await APIManager.shared.getAllChatSessions(userId: Int(userId))
            print("[fetchSessions] 当前会话列表：\(fetchedSessions.map { "\($0.title)(\($0.id))" })")

            if fetchedSessions.isEmpty {
                print("[fetchSessions] 无会话，准备创建新会话")
                let newSession = try await APIManager.shared.createChatSession(userId: Int(userId))
                sessions = [newSession]
                await MainActor.run {
                    self.sessions = [newSession]
                }
                await selectSession(sessionId: Int64(newSession.id))
            } else {
                print("[fetchSessions] 加载已有会话")
                await MainActor.run {
                    self.sessions = fetchedSessions
                }
                if let first = fetchedSessions.first {
                    await selectSession(sessionId: Int64(first.id))
                }
            }

            isLoading = false
            print("[fetchSessions] 完成")
        } catch {
            errorMessage = ErrorMessage(message: "加载会话失败：\(error.localizedDescription)")
            isLoading = false
            print("[fetchSessions] 失败：\(error.localizedDescription)")
        }
    }


    func fetchMessages(sessionId: Int64) async {
        print(" 调用 fetchMessages(sessionId: \(sessionId))")
        isLoading = true
        errorMessage = nil
        do {
            let fetchedMessages = try await APIManager.shared.getChatHistory(sessionId: sessionId)
            await MainActor.run {
                self.messages = fetchedMessages
            }
            isLoading = false
            print(" fetchMessages 完成，消息数：\(fetchedMessages.count)")
        } catch {
            errorMessage = ErrorMessage(message: "加载聊天记录失败：\(error.localizedDescription)")
            isLoading = false
            print(" fetchMessages 失败：\(error.localizedDescription)")
        }
    }

    func selectSession(sessionId: Int64) async {
        print(" 选择会话 sessionId: \(sessionId)")
        do {
            let fetched = try await APIManager.shared.getChatHistory(sessionId: sessionId)
            await MainActor.run {
                self.messages = fetched
                self.currentSessionId = sessionId
            }
            print(" 会话选择完成，消息数：\(fetched.count)")
        } catch {
            errorMessage = ErrorMessage(message: "加载会话消息失败：\(error.localizedDescription)")
            print(" selectSession 失败：\(error.localizedDescription)")
        }
    }
    
    func renameSession(session: ChatSession, newTitle: String) async {
        do {
            try await APIManager.shared.renameChatSession(sessionId: session.id, newTitle: newTitle)
            if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                await MainActor.run {
                    sessions[index].title = newTitle
                }
            }
            print(" 会话重命名成功：\(newTitle)")
        } catch {
            errorMessage = ErrorMessage(message: "重命名失败：\(error.localizedDescription)")
            print(" 重命名失败：\(error.localizedDescription)")
        }
    }

    func createNewSessionAndSelect() async {
        do {
            guard let userId = userId else { return }
            let newSession = try await APIManager.shared.createChatSession(userId: Int(userId))
            await MainActor.run {
                self.sessions.insert(newSession, at: 0)
                self.currentSessionId = Int64(newSession.id)
                self.messages = []
            }
        } catch {
            errorMessage = ErrorMessage(message: "新建会话失败：\(error.localizedDescription)")
            print(" 创建新会话失败：\(error.localizedDescription)")
        }
    }

    
    func deleteSession(session: ChatSession) async {
        print(" 删除会话 id:\(session.id) 标题:\(session.title)")
        do {
            let success = try await APIManager.shared.deleteChatSession(sessionId: session.id)
            if success {
                print(" 删除成功，更新会话列表")
                sessions.removeAll { $0.id == session.id }

                if currentSessionId == Int64(session.id) {
                    await MainActor.run {
                        self.currentSessionId = nil
                        self.messages = []
                    }
                    print(" 当前会话被删，清空消息")

                    if let newCurrent = sessions.first {
                        print(" 切换到新会话 id: \(newCurrent.id)")
                        await selectSession(sessionId: Int64(newCurrent.id))
                    } else {
                        print(" 无会话，创建新会话")
                        guard let userId = userId else { return }
                        let newSession = try await APIManager.shared.createChatSession(userId: Int(userId))
                        sessions = [newSession]
                        await selectSession(sessionId: Int64(newSession.id))
                    }
                }
            } else {
                errorMessage = ErrorMessage(message: "删除会话失败")
                print(" 删除会话返回失败")
            }
        } catch {
            errorMessage = ErrorMessage(message: "删除会话出错: \(error.localizedDescription)")
            print(" 删除会话异常: \(error.localizedDescription)")
        }
    }
    
    init() {
         // 在初始化时绑定 WebSocket 回调
         webSocketClient.onReceiveMessage = { [weak self] text in
             Task { @MainActor in
                 await self?.handleWebSocketMessage(text)
             }
         }
     }
     
     func connectWebSocket(token: String) {
         webSocketClient.connect(token: token)
     }
     
     func sendMessage() async {
         guard let sessionId = currentSessionId else { return }
         let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
         guard !trimmedText.isEmpty else { return }
         
         // 1. 先添加用户消息
         let nowString = Self.currentTimeString()
         let currentUserId = Int64(userId ?? 0)
         let userMessage = ChatMessage(
             id: Int64.random(in: Int64.min...Int64.max),
             sessionId: sessionId,
             userId: currentUserId,
             senderType: "user",
             content: trimmedText,
             audioUrl: nil,
             createTime: nowString,
             updateTime: nowString
         )
         messages.append(userMessage)
         inputText = ""
         
         // 2. 插入“AI 正在思考...”的占位消息，保存它的 ID
         let placeholderId = Int64.random(in: Int64.min...Int64.max)
         let placeholderMessage = ChatMessage(
             id: placeholderId,
             sessionId: sessionId,
             userId: 0,
             senderType: "assistant",
             content: "MindBot正在思考...",
             audioUrl: nil,
             createTime: nowString,
             updateTime: nowString
         )
         messages.append(placeholderMessage)
         placeholderMessageId = placeholderId
         currentAIContent = ""
         
         // 3. 通过 WebSocket 发送用户输入
         animationState = .thinking
         webSocketClient.send(message: trimmedText, sessionId: currentSessionId)
         
 

     }
     
     // 处理 WebSocket 分片消息
     private func handleWebSocketMessage(_ text: String) async {
         guard let data = text.data(using: .utf8),
               let response = try? JSONDecoder().decode(WSResponse.self, from: data) else {
             return
         }
         
         switch response.type {
         case "CONTENT":
             // 收到首个 CONTENT 分片，将占位消息内容替换为首个片段；后续分片追加
             if let placeholderId = placeholderMessageId,
                let index = messages.firstIndex(where: { $0.id == placeholderId }) {
                 if currentAIContent.isEmpty {
                    animationState = .speaking // 首次收到，开始“说话”
                     // 首次CONTENT：用第一个片段替换占位消息内容
                     messages[index].content = response.data.stringValue
                 } else {
                     // 后续片段：追加到已有内容末尾
                     messages[index].content += response.data.stringValue
                 }
                 currentAIContent += response.data.stringValue
             } else {
                 // 如果没有占位消息（可能超时或替换失败），直接追加
                 let nowString = Self.currentTimeString()
                 let aiSegment = ChatMessage(
                     id: Int64.random(in: Int64.min...Int64.max),
                     sessionId: currentSessionId ?? 0,
                     userId: 0,
                     senderType: "assistant",
                     content: response.data.stringValue,
                     audioUrl: nil,
                     createTime: nowString,
                     updateTime: nowString
                 )
                 messages.append(aiSegment)
             }
             
         case "DONE":
             // 收到 DONE 表示本次回复结束，清空临时状态
             
             placeholderMessageId = nil
             currentAIContent = ""
             // 延迟2秒后再设置为idle
             Task { @MainActor in
                 try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
                 self.animationState = .idle
             }
             
             showSuggestionBubble = true
             
         default:
             break
         }
     }
     

    private static func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }

}
