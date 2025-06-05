import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var appVM: AppViewModel
    @State private var showSessionsSheet = false
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    
    
    private var currentSessionTitle: String {
        if let session = viewModel.sessions.first(where: { Int64($0.id) == viewModel.currentSessionId }) {
            return session.title
        }
        return "无会话"
    }
    
    private var isCurrentSessionAvailable: Bool {
        return currentSessionTitle != "无会话"
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView(size: geometry.size)
                
                VStack {
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    } else {
                        topToolbar
                        messagesList
                        inputArea
                    }
                }
                .onAppear {
                    //KeychainHelper.shared.save("test-token", for: "authToken")
                    if let token = KeychainHelper.shared.read(for: "authToken") {
                        viewModel.connectWebSocket(token: token)
                    }
                    if let userId = appVM.currentUser?.id {
                        viewModel.userId = Int64(userId)
                    }
                }

                .toolbar(.hidden, for: .tabBar)
                .toolbarBackground(.hidden, for: .tabBar)
                .sheet(isPresented: $showSessionsSheet) {
                    sessionsSheet
                }
                .task {
                    await viewModel.fetchSessions()
                }
                .alert(item: $viewModel.errorMessage) { errorMsg in
                    Alert(title: Text("错误"), message: Text(errorMsg.message), dismissButton: .default(Text("确定")))
                }
                .onReceive(speechRecognizer.$transcribedText) { text in
                    viewModel.inputText = text
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Subviews
    
    private func backgroundView(size: CGSize) -> some View {
        ZStack {
            Image("ChatBackground")
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
                .ignoresSafeArea()
                .offset(y: 20)
            
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .blur(radius: 10)
                .ignoresSafeArea()
        }
    }
    
    private var topToolbar: some View {
        ZStack {
            HStack(spacing: 16) {
                Button {
                    withAnimation {
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .bold()
                }
                
                Text(currentSessionTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(isCurrentSessionAvailable ? .primary : .gray)
                
                Spacer()
                
                Button {
                    showSessionsSheet = true
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.blue.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                
                Button {
                    Task {
                        await viewModel.createNewSessionAndSelect()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.green.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 5)
        .background(.ultraThinMaterial)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(#colorLiteral(red: 0.824, green: 0.814, blue: 0.811, alpha: 1)).opacity(0.2), Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var messagesList: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty {
                        Text("暂无消息")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(viewModel.messages, id: \.id) { message in
                            MessageRow(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding()
                .onChange(of: viewModel.messages.count) { _ in
                    guard let last = viewModel.messages.last else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollView.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.messages.last?.content) { _ in
                    guard let last = viewModel.messages.last else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation {
                            scrollView.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onAppear {
                // 首次加载时滚动到底部
                if let last = viewModel.messages.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollView.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

        }
        
    }
    
    private var inputArea: some View {
        HStack {
            Button {
                Task {
                    if isRecording {
                        speechRecognizer.stopRecording()
                        isRecording = false
                    } else {
                        let granted = await speechRecognizer.requestAuthorization()
                        if granted {
                            do {
                                try speechRecognizer.startRecording()
                                isRecording = true
                            } catch {
                                print("语音识别启动失败：\(error.localizedDescription)")
                            }
                        } else {
                            print("用户拒绝语音识别权限")
                        }
                    }
                }
            } label: {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(isRecording ? Color.red : Color(#colorLiteral(red: 0, green: 0.886633575, blue: 0.7161186934, alpha: 1)))
                    .clipShape(Circle())
            }

            TextField("聊一聊吧...", text: $viewModel.inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    let trimmed = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }
                }
            
            Button {
                Task {
                    await viewModel.sendMessage()
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color(#colorLiteral(red: 0, green: 0.886633575, blue: 0.7161186934, alpha: 1)))
                    .clipShape(Circle())
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .offset(y: 10)
        .ignoresSafeArea()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(#colorLiteral(red: 0.824, green: 0.814, blue: 0.811, alpha: 1)).opacity(0.2)]),
                startPoint: .top, endPoint: .bottom
            )
        )
    }
    
    private var sessionsSheet: some View {
        NavigationView {
            List {
                Section(header: Text("历史会话")) {
                    ForEach(viewModel.sessions) { session in
                        SessionRow(session: session,
                                   isSelected: Int64(session.id) == viewModel.currentSessionId) {
                            Task {
                                await viewModel.selectSession(sessionId: Int64(session.id))
                                await MainActor.run {
                                    showSessionsSheet = false
                                }
                            }
                        } onDelete: {
                            Task {
                                await deleteSafely(session: session)
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
    
    private func formatTime(_ isoTime: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: isoTime) {
            let output = DateFormatter()
            output.dateFormat = "HH:mm"
            return output.string(from: date)
        }
        return ""
    }
    
    private func deleteSafely(session: ChatSession) async {
        let sessionsCopy = viewModel.sessions
        guard sessionsCopy.contains(where: { $0.id == session.id }) else {
            print("会话已不存在")
            return
        }
        await viewModel.deleteSession(session: session)
    }
}

// MARK: - 小组件拆分

struct MessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.senderType == "assistant" {
                AssistantMessageView(message: message)
                Spacer()
            } else {
                Spacer()
                UserMessageView(message: message)
            }
        }
        
    }
}

struct AssistantMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top){
            Image("Avatar")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(radius: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.content)
                    .padding()
                    .background(Color.white.opacity(0.75))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                
                Text(formatTime(message.createTime))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func formatTime(_ isoTime: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: isoTime) {
            let output = DateFormatter()
            output.dateFormat = "HH:mm"
            return output.string(from: date)
        }
        return ""
    }
}

struct UserMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top){
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.content)
                    .padding()
                    .background(Color.accentColor.opacity(0.75))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                
                Text(formatTime(message.createTime))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Image("avatar1")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(radius: 2)
        }
    }
    
    private func formatTime(_ isoTime: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: isoTime) {
            let output = DateFormatter()
            output.dateFormat = "HH:mm"
            return output.string(from: date)
        }
        return ""
    }
}

struct SessionRow: View {
    let session: ChatSession
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(session.title)
            if isSelected {
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .swipeActions {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}
