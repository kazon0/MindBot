import SwiftUI

struct CommunityUIPlaceholderView: View {
    @State private var posts: [Post] = Post.mockPosts()
    @State private var searchText = ""
    @State private var animate = false
    
    var filteredPosts: [Post] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return posts
        } else {
            return posts.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                ($0.tags?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(#colorLiteral(red: 0.824, green: 0.814, blue: 0.811, alpha: 1)),
                        Color(#colorLiteral(red: 0.7366558313, green: 0.8424485326, blue: 0.5300986767, alpha: 1)),
                        Color(#colorLiteral(red: 0.7366558313, green: 0.8424485326, blue: 0.5300986767, alpha: 1))
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 40)
                        .foregroundColor(Color(#colorLiteral(red: 0.737, green: 0.842, blue: 0.530, alpha: 1)))
                        .shadow(color: Color.gray.opacity(animate ? 0.1 : 0.2), radius: animate ? 20 : 30, x: 0, y: -40)
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? 0 : 40)
                        .animation(.easeOut(duration: 0.6), value: animate)
                    Image("GirlBackground")
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width * 0.9,
                               height: UIScreen.main.bounds.height * 0.7)
                        .clipped()
                        .cornerRadius(30) // 圆角
                        .compositingGroup() // 允许混合模式生效
                        .opacity(0.6) // 整体透明
                        .mask(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.black,
                                    Color.black.opacity(0.8),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: UIScreen.main.bounds.width * 0.8
                            )
                        )
                        .offset(x: -20, y: -60)

                    VStack {
                        // 搜索框
                        HStack(spacing: 0) {
                            Text("心灵交流")
                                .font(.system(size: 32, weight: .semibold, design: .rounded))
                            Spacer()
                            HStack(spacing: 0) {
                                Button(action: {
                                    // 搜索动作
                                    print("点击搜索：\(searchText)")
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 35)
                                        .background(Color.accentColor)
                                }
                                
                                Divider()
                                    .frame(width: 1, height: 20)
                                    .background(Color.white.opacity(0.4))
                                
                                TextField("搜索帖子、标签...", text: $searchText)
                                    .padding(.horizontal, 12)
                                    .frame(height: 35)
                                    .background(Color(.systemGray6))
                            }
    
                            .frame(height: 35)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                            .padding(.horizontal)
                        }
                        .padding(.top,20)
                        .padding(.horizontal)
                        
                        // 帖子列表
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredPosts, id: \.id) { post in
                                    PostCard(post: post)
                                        .shadow(color: Color.gray.opacity(animate ? 0.4 : 0.2), radius: animate ? 12 : 6, x: 0, y: animate ? 6 : 3)
                                        .opacity(animate ? 1 : 0)
                                        .offset(y: animate ? 0 : 40)
                                        .animation(.easeOut(duration: 0.6), value: animate)
                                }
                            }
                            .padding()
                            .padding(.horizontal,10)
                        }
                    }
                    // 发布按钮
                    NavigationLink(destination: CreatePostView()) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .padding()
                            .background(animate ? Color.accentColor : Color(#colorLiteral(red: 0, green: 0.886633575, blue: 0.7161186934, alpha: 1)))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(color: Color.blue.opacity(animate ? 0.4 : 0.1), radius: animate ? 10 : 3)
                            .scaleEffect(animate ? 1.06 : 1.0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)
                    }
                    .offset(x:-20,y:-100)
                }
                .onAppear(){
                    animate = true
                }
            }
    }
}

struct PostCard: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading) {
                    Text(post.author ?? "匿名用户")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text(post.createTime ?? "刚刚")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }

            Text(post.title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(post.content)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.primary)

            if let tags = post.tags {
                Text("#\(tags)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            HStack {
                Button(action: {}) {
                    Label("评论", systemImage: "bubble.left")
                }
                Spacer()
                Label("\(post.likeCount ?? 0)", systemImage: "heart")
                    .foregroundColor(.pink)
            }
            .font(.footnote)
        }
        
        .padding()
        .background(Color.white.opacity(0.7)) // 白色带透明度
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

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

// MARK: - Mock 数据模型
extension Post {
    static func mockPosts() -> [Post] {
        [
            Post(id: 1, title: "第一次尝试冥想", content: "今天尝试了 10 分钟冥想，感觉好多了～", coverImage: nil, tags: "冥想,减压", resourceType: "post", author: "小明", createTime: "2小时前", updateTime: nil, likeCount: 8, viewCount: 120),
            Post(id: 2, title: "和辅导员聊了一次", content: "真的建议大家不要憋着，有时候倾诉比什么都重要。", coverImage: nil, tags: "心理咨询", resourceType: "post", author: "匿名", createTime: "昨天", updateTime: nil, likeCount: 12, viewCount: 88),
            Post(id: 3, title: "考研压力好大", content: "复习进度总是落后，每天都感觉喘不过气...", coverImage: nil, tags: "考试,压力", resourceType: "post", author: "小李", createTime: "3天前", updateTime: nil, likeCount: 25, viewCount: 300)
        ]
    }
}

#Preview {
    CommunityUIPlaceholderView()
}

