import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var showSessionsSheet = false

    var body: some View {
        VStack {
            if viewModel.isLoading {
                Spacer()
                ProgressView("加载中...")
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            } else {
                // 顶部工具栏
                HStack(spacing: 16) {
                    Button {
                        showSessionsSheet = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }

                    Button {
                        Task {
                            do {
                                let newSession = try await APIManager.shared.createChatSession()
                                viewModel.sessions.append(newSession)
                                await viewModel.selectSession(sessionId: Int64(newSession.id))
                            } catch {
                                viewModel.errorMessage = ErrorMessage(message: "创建新会话失败: \(error.localizedDescription)")
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color.green.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Group {
                        if let currentSession = viewModel.sessions.first(where: { Int64($0.id) == viewModel.currentSessionId }) {
                            Text(currentSession.title)
                        } else {
                            Text("无会话")
                                .foregroundColor(.gray)
                        }
                    }
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                }
                .padding()

                Divider()

                // 消息列表
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if viewModel.messages.isEmpty {
                                Text("暂无消息")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(viewModel.messages, id: \.id) { message in
                                    HStack {
                                        if message.senderType == "user" {
                                            Spacer()
                                            Text(message.content)
                                                .padding()
                                                .background(Color.accentColor)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        } else {
                                            Text(message.content)
                                                .padding()
                                                .background(Color.gray.opacity(0.3))
                                                .cornerRadius(8)
                                            Spacer()
                                        }
                                    }
                                    .id(message.id)
                                }
                            }
                        }
                        .padding()
                        .onChange(of: viewModel.messages.count) { _ in
                            guard !viewModel.messages.isEmpty, let last = viewModel.messages.last else {
                                return
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollView.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                // 输入框
                HStack {
                    TextField("输入消息...", text: $viewModel.inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button {
                        Task {
                            await viewModel.sendMessage()
                        }
                    } label: {
                        Text("发送")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.5) : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showSessionsSheet) {
            NavigationView {
                List {
                    Section(header: Text("历史会话")) {
                        ForEach(viewModel.sessions) { session in
                            HStack {
                                Text(session.title)
                                if viewModel.currentSessionId == Int64(session.id) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Task {
                                    await viewModel.selectSession(sessionId: Int64(session.id))
                                    await MainActor.run {
                                        showSessionsSheet = false
                                    }
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task {
                                        await deleteSafely(session: session)
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("选择会话")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") {
                            showSessionsSheet = false
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.fetchSessions()
        }
        .alert(item: $viewModel.errorMessage) { errorMsg in
            Alert(title: Text("错误"), message: Text(errorMsg.message), dismissButton: .default(Text("确定")))
        }
    }

    private func deleteSafely(session: ChatSession) async {
        let sessionsCopy = viewModel.sessions
        guard sessionsCopy.contains(where: { $0.id == session.id }) else {
            print("⚠️ 会话已不存在")
            return
        }
        await viewModel.deleteSession(session: session)
    }
}
