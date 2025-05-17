import SwiftUI

struct EditUserInfoView: View {
    @Environment(\.dismiss) var dismiss
    @State var user: UserInfo
    var onSave: (UserInfo) async -> Void

    var body: some View {
        NavigationView {
            Form {
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
            }
            .navigationTitle("编辑信息")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            await onSave(user)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
