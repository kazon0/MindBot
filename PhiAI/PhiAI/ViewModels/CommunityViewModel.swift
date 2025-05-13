

import Foundation

import Foundation

class CommunityViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // 用于取消正在进行的任务
    private var task: Task<Void, Never>?

    // 获取帖子列表
    func fetchPosts() {
        isLoading = true
        errorMessage = nil
        
        task = Task {
            do {
                let fetchedPosts = try await APIManager.shared.getAllPosts()
                DispatchQueue.main.async {
                    self.posts = fetchedPosts
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "加载帖子失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    // 发布新帖
    func publishPost(content: String, isAnonymous: Bool) {
        Task {
            do {
                try await APIManager.shared.createPost(content: content, isAnonymous: isAnonymous)
                await fetchPosts()  // 发布后刷新帖子列表
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "发布失败: \(error.localizedDescription)"
                }
            }
        }
    }

    // 添加评论
    func addComment(to postId: Int, content: String) {
        Task {
            do {
                try await APIManager.shared.addComment(postId: postId, content: content)
                await fetchPosts()  // 评论后刷新帖子
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "评论失败: \(error.localizedDescription)"
                }
            }
        }
    }

    // 在视图销毁时取消任务
    deinit {
        task?.cancel()
    }
}


//class CommunityViewModel: ObservableObject {
//    @Published var posts: [PostEntites] = []
//    @Published var comments: [CommentEntites] = []
//
//    private let context: NSManagedObjectContext
//
//    init(context: NSManagedObjectContext = CoreDataViewModel.shared.container.viewContext) {
//        self.context = context
//        fetchPosts()
//        fetchComments()
//    }
//
//    func fetchPosts() {
//        let request: NSFetchRequest<PostEntites> = PostEntites.fetchRequest()
//        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
//        do {
//            posts = try context.fetch(request)
//        } catch {
//            print("❌ 获取帖子失败: \(error)")
//        }
//    }
//
//    func fetchComments() {
//        let request: NSFetchRequest<CommentEntites> = CommentEntites.fetchRequest()
//        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
//        do {
//            comments = try context.fetch(request)
//        } catch {
//            print("❌ 获取评论失败: \(error)")
//        }
//    }
//
//    func addPost(content: String, user: UserEntites, isAnonymous: Bool = false) {
//        let newPost = PostEntites(context: context)
//        newPost.content = content
//        newPost.timestamp = Date()
//        newPost.user = user
//        newPost.isAnonymous = isAnonymous
//        saveData()
//        fetchPosts()
//    }
//
//    func addComment(to post: PostEntites, content: String, user: UserEntites) {
//        let newComment = CommentEntites(context: context)
//        newComment.content = content
//        newComment.timestamp = Date()
//        newComment.user = user
//        newComment.post = post
//        saveData()
//        fetchComments()
//    }
//
//    private func saveData() {
//        do {
//            try context.save()
//        } catch {
//            print("❌ 保存数据失败: \(error)")
//        }
//    }
//}
