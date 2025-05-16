import Foundation

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var task: Task<Void, Never>?

    func fetchPosts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPosts = try await APIManager.shared.getAllPosts()
            await MainActor.run {
                self.posts = fetchedPosts
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载帖子失败: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }


    func publishPost(content: String, isAnonymous: Bool) async {
        do {
            try await APIManager.shared.createPost(content: content, isAnonymous: isAnonymous)
            await fetchPosts()
        } catch {
            self.errorMessage = "发布失败: \(error.localizedDescription)"
        }
    }

    func addComment(to postId: Int, content: String) async {
        do {
            try await APIManager.shared.addComment(postId: postId, content: content)
            await fetchPosts()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "评论失败: \(error.localizedDescription)"
            }
        }
    }

    deinit {
        task?.cancel()
    }
}
