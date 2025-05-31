import SwiftUI
import PhotosUI

struct EditUserInfoView: View {
    @Environment(\.dismiss) var dismiss
    @State var user: UserInfo
    var onSave: (UserInfo) async throws -> Void

    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Spacer()
                        avatarView
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        Spacer()
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        Text("选择头像")
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                }

                Section(header: Text("基本信息")) {
                    TextField("用户名", text: $user.username)
                    TextField("真实姓名", text: Binding(get: {
                        user.realName ?? ""
                    }, set: {
                        user.realName = $0
                    }))
                    TextField("邮箱", text: Binding(get: {
                        user.email ?? ""
                    }, set: {
                        user.email = $0
                    }))
                    TextField("手机号", text: Binding(get: {
                        user.phone ?? ""
                    }, set: {
                        user.phone = $0
                    }))
                    Picker("性别", selection: Binding(get: {
                        user.gender ?? 0
                    }, set: {
                        user.gender = $0
                    })) {
                        Text("男").tag(1)
                        Text("女").tag(0)
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }

                if showSuccess {
                    Section {
                        Text("保存成功！").foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("编辑信息")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "保存中…" : "保存") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                // 这里把选中的图片转成 Base64 字符串直接赋给 avatar 字段
                                if let imageData = selectedImageData {
                                    user.avatar = "data:image/jpeg;base64," + imageData.base64EncodedString()
                                }

                                try await onSave(user)
                                showSuccess = true
                                try await Task.sleep(nanoseconds: 1_000_000_000)
                                dismiss()
                            } catch {
                                errorMessage = "保存失败：\(error.localizedDescription)"
                            }
                            isSaving = false
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    @ViewBuilder
    var avatarView: some View {
        if let data = selectedImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if let avatarString = user.avatar, avatarString.starts(with: "data:image"),
                  let data = Data(base64Encoded: avatarString
                    .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")) {
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderImage
            }
        } else if let url = URL(string: user.avatar ?? "") {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                placeholderImage
            }
        } else {
            placeholderImage
        }
    }

    var placeholderImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(.gray)
    }
}

