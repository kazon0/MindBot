import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages, id: \.id) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    Text(message.text ?? "")
                                        .padding()
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .frame(maxWidth: 250, alignment: .trailing)
                                } else {
                                    Text(message.text ?? "")
                                        .padding()
                                        .background(Color(#colorLiteral(red: 0.8661221862, green: 0.8661221862, blue: 0.8661221862, alpha: 0.8470588235)))
                                        .cornerRadius(10)
                                        .frame(maxWidth: 250, alignment: .leading)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let last = viewModel.messages.last {
                        scrollView.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            HStack {
                TextField("输入你的心情...", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("发送") {
                    viewModel.sendMessage()
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .navigationTitle("AI 聊天室")
    }
}

#Preview {
    let mockUser = UserEntites(context: CoreDataViewModel.shared.container.viewContext)
    mockUser.id = "12345"
    mockUser.name = "Mock User"
    mockUser.isGuest = false

    let mockMessages: [ChatEntites] = [
        ChatEntites(context: CoreDataViewModel.shared.container.viewContext),
        ChatEntites(context: CoreDataViewModel.shared.container.viewContext)
    ]
    
    mockMessages[0].id = UUID()
    mockMessages[0].text = "你好！我感觉有点压力大。"
    mockMessages[0].isUser = true
    mockMessages[0].timestamp = Date()

    mockMessages[1].id = UUID()
    mockMessages[1].text = "你提到压力，想聊聊吗？"
    mockMessages[1].isUser = false
    mockMessages[1].timestamp = Date()

    let chatViewModel = ChatViewModel(context: CoreDataViewModel.shared.container.viewContext, user: mockUser)
    chatViewModel.messages = mockMessages
    
    return ChatView(viewModel: chatViewModel)
}

