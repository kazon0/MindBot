
import Foundation
import SwiftUI

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var title = ""
    @Published var content = ""
    @Published var tags = ""
    @Published var coverImage = ""

    @Published var isSubmitting = false
    @Published var alertMessage = ""
    @Published var showAlert = false

    func submitPost() async {
        guard !title.isEmpty, !content.isEmpty else {
            alertMessage = "标题和内容不能为空"
            showAlert = true
            return
        }

        isSubmitting = true

        let request = CreatePostRequest(
            title: title,
            content: content,
            coverImage: coverImage.isEmpty ? nil : coverImage,
            tags: tags.isEmpty ? nil : tags,
            resourceType: "post"
        )

        do {
            let post = try await APIManager.shared.createPost(requestBody: request)
            alertMessage = "发帖成功：\(post.title)"
        } catch {
            alertMessage = "发帖失败：\(error.localizedDescription)"
        }

        isSubmitting = false
        showAlert = true
    }
}
