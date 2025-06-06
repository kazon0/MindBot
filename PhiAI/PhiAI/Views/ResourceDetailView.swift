//
//  ResourceDetailView.swift
//  PhiAI
//

import SwiftUI

struct ResourceDetailView: View {
    let resource: Resource

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let cover = resource.coverImage,
                   let url = URL(string: "http://f6783e72.natappfree.cc/minio/\(cover)") {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .cornerRadius(15)
                            
                    } placeholder: {
                        Color.gray.frame(height: 200)
                            .cornerRadius(15)
                    }
                }

                Text(resource.title ?? "无标题")
                    .font(.largeTitle)
                    .bold()

                if let author = resource.author {
                    Text("作者：\(author)").font(.subheadline).foregroundColor(.secondary)
                }

                if let createTime = resource.createTime {
                    Text("创建时间：\(createTime)").font(.caption).foregroundColor(.gray)
                }

                Divider()

                Text(resource.content ?? "暂无内容")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("资源详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}
