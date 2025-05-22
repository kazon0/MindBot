import SwiftUI

struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()

    var body: some View {
        Form {
            Section(header: Text("标题")) {
                TextField("请输入标题", text: $viewModel.title)
            }

            Section(header: Text("内容")) {
                TextEditor(text: $viewModel.content)
                    .frame(height: 120)
            }

            Section(header: Text("标签（逗号分隔）")) {
                TextField("心理,校园", text: $viewModel.tags)
            }

            Section(header: Text("封面图URL")) {
                TextField("https://example.com/image.jpg", text: $viewModel.coverImage)
            }

            Button(action: {
                Task {
                    await viewModel.submitPost()
                }
            }) {
                if viewModel.isSubmitting {
                    ProgressView()
                } else {
                    Text("发布帖子")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("发布新帖子")
        .alert("提示", isPresented: $viewModel.showAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}
