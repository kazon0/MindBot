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
                                        .background(Color.blue.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .frame(maxWidth: 250, alignment: .trailing)
                                } else {
                                    Text(message.text ?? "")
                                        .padding()
                                        .background(Color.gray.opacity(0.3))
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
