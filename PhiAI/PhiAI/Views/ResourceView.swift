//
//  ResourceListView.swift
//  PhiAI
//

import SwiftUI

struct ResourceListView: View {
    @StateObject var viewModel = ResourceViewModel()
    @Environment(\.presentationMode) var presentationMode

    @State private var isNavBarHidden: Bool = false
    @State private var dragStartY: CGFloat = 0
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            ZStack(alignment: .top){
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(#colorLiteral(red: 0.8626629114, green: 0.9756165147, blue: 0.7313965559, alpha: 1)).opacity(0.5),
                        Color(#colorLiteral(red: 0.8042530417, green: 0.9252516627, blue: 0.5908532143, alpha: 1)),
                        Color(#colorLiteral(red: 0.4738111496, green: 0.752263248, blue: 0.3751039505, alpha: 1))
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
     
                
                VStack(spacing: 0) {
                    // 返回栏（可隐藏）
                    if !isNavBarHidden {
                        HStack {
                            Button(action: {
                                withAnimation {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.accentColor)
                                    .font(.headline)
                                    .padding()
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            Spacer()
                            HStack(spacing: 0) {
                                Image(systemName: "magnifyingglass")
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color(#colorLiteral(red: 0.7798835635, green: 0.8985179067, blue: 0.5737658143, alpha: 1)))
                            
                                                            
                                Divider()
                                    .frame(width: 1, height: 20)
                                    .background(Color.white.opacity(0.4))
                                                            
                                TextField("搜索资源...", text: $searchText)
                                    .padding(.horizontal, 12)
                                    .frame(height: 40)
                                    .background(Color(.systemGray6))
                            }
                                
                                .frame(height: 40)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                                .padding(.horizontal)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .shadow(color: .gray.opacity(0.3),radius: 5)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // 内容
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if viewModel.isLoading {
                                ProgressView("加载中...")
                            } else if let error = viewModel.errorMessage {
                                Text("错误：\(error)")
                                    .foregroundColor(.red)
                            } else {
//                                ForEach(filteredResources) { resource in
//                                    NavigationLink(destination: ResourceDetailView(resource: resource)) {
//                                        ResourceCardView(resource: resource)
//                                            .padding(.horizontal)
//                                    }
//                                }
                                ForEach(Array(filteredResources.enumerated()), id: \.element.id) { index, resource in
                                    NavigationLink(destination: ResourceDetailView(resource: resource)) {
                                        ResourceCardView(resource: resource, index: index)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.top)
                    }
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                let dragDistance = value.translation.height
                                if dragDistance > 20 {
                                    withAnimation {
                                        isNavBarHidden = false
                                    }
                                } else if dragDistance < -20 {
                                    withAnimation {
                                        isNavBarHidden = true
                                    }
                                }
                            }
                    )
                }
                
                Rectangle()
                    .foregroundColor(Color(#colorLiteral(red: 0.9007616043, green: 0.9708458781, blue: 0.7954522967, alpha: 1)))
                    .frame(height: 65)
                    .ignoresSafeArea(edges:.top)
                   
            }
            .navigationBarBackButtonHidden(true)
        }
        .task {
            await viewModel.loadResources()
        }
    }
    
    private var filteredResources: [Resource] {
        if searchText.isEmpty {
            return viewModel.resources
        } else {
            return viewModel.resources.filter { resource in
                let keyword = searchText.lowercased()
                return (resource.title?.lowercased().contains(keyword) ?? false)
                    || (resource.content?.lowercased().contains(keyword) ?? false)
                    || (resource.tags?.lowercased().contains(keyword) ?? false)
                    || (resource.author?.lowercased().contains(keyword) ?? false)
            }
        }
    }

}


struct ResourceCardView: View {
    let resource: Resource
    let index: Int

    var coverURL: URL? {
        if let cover = resource.coverImage {
            let url = URL(string: "http://f6783e72.natappfree.cc/minio\(cover)")
            //print("封面图 URL：\(url?.absoluteString ?? "无效")")
            return url
        }
        return nil
    }
    
    var localImageName: String {
        return "cover\((index % 11) + 1)"  // 避免越界，循环利用 11 张图
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = coverURL {
                   AsyncImage(url: url) { image in
                       image.resizable()
                           .aspectRatio(16/9, contentMode: .fill)
                           .clipped()
                   } placeholder: {
                       Image(localImageName)
                           .resizable()
                           .aspectRatio(16/9, contentMode: .fill)
                           .clipped()
                   }
                   .frame(height: 180)
                   .cornerRadius(12)
               } else {
                   Image(localImageName)
                       .resizable()
                       .aspectRatio(16/9, contentMode: .fill)
                       .frame(height: 180)
                       .clipped()
                       .cornerRadius(12)
               }


            Text(resource.title ?? "无标题")
                .font(.headline)
                .foregroundColor(.primary)

            if let author = resource.author {
                Text("作者：\(author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let tags = resource.tags {
                Text("标签：\(tags)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            HStack(spacing: 16) {
                Label("\(resource.viewCount ?? 0)", systemImage: "eye")
                Label("\(resource.likeCount ?? 0)", systemImage: "hand.thumbsup")
                Label(resource.resourceType ?? "", systemImage: "doc.text")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.85))
        .cornerRadius(16)
        .shadow(radius: 3)
    }
}


struct ResourceListView_Previews: PreviewProvider {
    static var previews: some View {
        ResourceListView()
    }
}

