import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel: CommunityViewModel = CommunityViewModel()
    @State private var newPostContent: String = ""
    @State private var isAnonymous: Bool = false
    @State private var commentText: [Int: String] = [:]

    var body: some View {
        NavigationView {
            VStack {
                postInputSection
                // 帖子加载状态
                if viewModel.isLoading {
                    ProgressView("加载中...")
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .padding()
                        .foregroundColor(.red)
                } else {
                    postListView
                        .padding()
                }
               
                Spacer()
            }
            
            .navigationTitle("心灵交流")
            .onAppear {
                fetchPosts()
            }
        }
    }

    private func fetchPosts() {
        Task {
            await viewModel.fetchPosts()
        }
    }

    // 发布新帖输入框
    private var postInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("发布新帖")
                .font(.headline)

            TextEditor(text: $newPostContent)
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

            Toggle("匿名发布", isOn: $isAnonymous)

            Button(action: publishPost) {
                Text("发布")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding()
    }

    // 发布帖子
    private func publishPost() {
        Task {
            let content = newPostContent.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else { return }
            await viewModel.publishPost(content: content, isAnonymous: isAnonymous)
            newPostContent = ""
            isAnonymous = false
        }
    }

    // 帖子列表视图
    private var postListView: some View {
        PostListView(viewModel: viewModel, commentText: $commentText)
    }
}

struct PostListView: View {
    @ObservedObject var viewModel: CommunityViewModel
    @Binding var commentText: [Int: String]

    var body: some View {
        List(viewModel.posts, id: \.id) { post in
            // 确保传递的是 Binding<String>
            PostCardView(post: post, commentText: bindingForPost(postId: post.id), onComment: {
                addComment(postId: post.id)
            })
        }
    }

    private func bindingForPost(postId: Int) -> Binding<String> {
        // 如果字典中没有该 postId，创建一个空字符串绑定
        return Binding(
            get: {
                commentText[postId, default: ""]
            },
            set: {
                commentText[postId] = $0
            }
        )
    }

    private func addComment(postId: Int) {
        Task {
            let text = commentText[postId, default: ""]
            if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                await viewModel.addComment(to: postId, content: text)
                commentText[postId] = ""  // 清空评论输入框
            }
        }
    }
}

struct PostCardView: View {
    let post: Post
    @Binding var commentText: String  // 确保 commentText 是 String 类型
    var onComment: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            userInfoSection
            Text(post.content)
                .font(.body)

            if let comments = post.comments, !comments.isEmpty {
                Divider()
                ForEach(comments) { comment in
                    CommentView(comment: comment)
                }
            }

            // 确保 commentText 是 String 类型
            CommentInputView(commentText: $commentText, onComment: onComment)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }

    private var userInfoSection: some View {
        HStack {
            if post.isAnonymous {
                Image(systemName: "person.fill.questionmark")
                Text("匿名用户")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "person.fill")
                Text(post.user?.username ?? "未知用户")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(post.timestamp)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}


struct CommentView: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.user?.username ?? "匿名")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(comment.timestamp)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Text(comment.content)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

struct CommentInputView: View {
    @Binding var commentText: String
    var onComment: () -> Void

    var body: some View {
        HStack {
            TextField("写评论...", text: $commentText)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: onComment) {
                Image(systemName: "paperplane.fill")
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 4)
    }
}
