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
                                    Text(message.text)
                                        .padding()
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .frame(maxWidth: 250, alignment: .trailing)
                                } else {
                                    Text(message.text)
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
                .onChange(of: viewModel.messages.count) {
                    if let last = viewModel.messages.last {
                        scrollView.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            HStack {
                TextField("输入你的心情...", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("发送") {
                    // Wrap the async call inside a Task
                    Task {
                        await viewModel.sendMessage()
                    }
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .navigationTitle("AI 聊天室")
        .task {
            await viewModel.fetchMessages()
        }
    }
}

#Preview {
    let mockMessages: [ChatMessage] = [
        ChatMessage(id: UUID(), text: "你好！我感觉有点压力大。", timestamp: ISO8601DateFormatter().string(from: Date()), isUser: true),
        ChatMessage(id: UUID(), text: "你提到压力，想聊聊吗？", timestamp: ISO8601DateFormatter().string(from: Date()), isUser: false)
    ]

    let chatViewModel = ChatViewModel()
    chatViewModel.messages = mockMessages

    return ChatView(viewModel: chatViewModel)
}
