//
//  StickerWallView.swift
//  PhiAI
//


import SwiftUI
import WaterfallGrid


struct StickerWallView: View {
    @StateObject private var viewModel = StickerWallViewModel()
    @State private var showPostSheet = false
    @State private var animate = false
    @Binding var guestRefresh1 : Int
    
    var body: some View {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(#colorLiteral(red: 0.824, green: 0.814, blue: 0.811, alpha: 1)),
                        Color(#colorLiteral(red: 0.7366558313, green: 0.8424485326, blue: 0.5300986767, alpha: 1))
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // 绿色背景卡片
                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .foregroundColor(Color(#colorLiteral(red: 0.737, green: 0.842, blue: 0.530, alpha: 1)))
                        .frame(maxHeight: .infinity)
                        .shadow(color: Color.gray.opacity(animate ? 0.1 : 0.2), radius: animate ? 20 : 30, x: 0, y: -40)
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? 0 : 40)
                        .animation(.easeOut(duration: 0.6), value: animate)

                    ZStack {
                        RoundedRectangle(cornerRadius: 40)
                            .foregroundColor(Color(#colorLiteral(red: 0.804, green: 0.926, blue: 0.591, alpha: 1)))
                            .shadow(color: Color.green.opacity(animate ? 0.2 : 0.05), radius: animate ? 8 : 2, y: animate ? 6 : 2)
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 60)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: animate)
                            .padding(.bottom,10)
                     
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
                            .offset(x: -20, y: -80)
                        
                        // 主界面内容
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(){
                                Spacer()
                                Text("留言板")
                                    .font(.custom("PingFang SC heavy", size: 32))
                                    .foregroundColor(.white)
                                    .shadow(radius: 5)
                                Spacer()
                                Image("Paperplane")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200)
                                Spacer()
                            }
                            .padding(.bottom,10)
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                WaterfallGrid(viewModel.stickers) { sticker in
                                    CollageBlockView(sticker: sticker)
                                        .padding(.bottom, 5)
                                }
                                .gridStyle(
                                    columnsInPortrait: 2,
                                    columnsInLandscape: 3,
                                    spacing: 4
                                )
                                .padding(.horizontal, 4)
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 50)) // 内容裁剪在圆角卡片内
                        .padding(.vertical)
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: animate)

                    }
                }

                Button(action:{
                    showPostSheet = true
                }){
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
                .offset(x:130,y:300)
            }
            .sheet(isPresented: $showPostSheet) {
                NavigationView {
                    StickerPostView(viewModel: viewModel)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animate = true
                }
                viewModel.fetchStickers()
            }
    }
    
    func pseudoRandomValue(id: String, range: ClosedRange<CGFloat>) -> CGFloat {
        let hash = abs(id.hashValue)
        let normalized = CGFloat(hash % 1000) / 1000.0
        return range.lowerBound + normalized * (range.upperBound - range.lowerBound)
    }

}


//白色网格线
struct GridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let gridSize: CGFloat = 30
                var path = Path()
                for x in stride(from: 0, through: size.width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0, through: size.height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(.gray.opacity(0.5)), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
        .clipShape(RoundedRectangle(cornerRadius: 40)) // 保持圆角
    }
}

struct StickerPostView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: StickerWallViewModel

    @State private var selectedImageName: String = "sticker_heart"
    @State private var message = ""
    @State private var author = ""

    let availableStickers = ["猫生气", "猫伤心", "猫开心", "猫困惑","猫睡觉"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("选择一个贴纸")) {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(availableStickers, id: \.self) { name in
                                Image(name)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .padding(4)
                                    .background(selectedImageName == name ? Color.blue.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedImageName = name
                                    }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }

                Section(header: Text("内容")) {
                    TextField("想说的话...", text: $message)
                        .onChange(of: message) { newValue in
                            if newValue.count > 25 {
                                message = String(newValue.prefix(25))
                            }
                        }

                    TextField("署名（可不填）", text: $author)
                        .onChange(of: author) { newValue in
                            if newValue.count > 10 {
                                author = String(newValue.prefix(10))
                            }
                        }
                }            }
            .navigationTitle("发布留言")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") {
                        viewModel.postSticker(imageName: selectedImageName, message: message, author: author)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

struct CollageBlockView: View {
    let sticker: Sticker

    var pseudoRandomOffset: CGFloat {
        let hash = abs(sticker.id.hashValue)
        return CGFloat(hash % 60)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                GridOverlay() //  网格放最底层
                
                VStack(alignment: .leading,spacing: 10) {
                    HStack(alignment: .center) {
                        Text("Mood:")
                            .font(.headline)
                        Image(sticker.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Text:")
                            .font(.headline)
                        Text(sticker.message)
                            .font(.custom("PingFang SC light", size: 20))
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(10)
                    }
                }
                .padding()

            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 白色底栏
            HStack {
                Text(sticker.author.isEmpty ? "匿名" : sticker.author)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(sticker.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(10)
            .background(Color.white.opacity(0.9))
            .cornerRadius(6)
        }
        .background(Color.white.opacity(0.75))
        .cornerRadius(12)
        .shadow(radius: 3)
        .padding(4)
        .frame(minHeight: 120, maxHeight: 250 + pseudoRandomOffset)
    }
}


struct StickerWallPreviewWrapper: View {
    @State private var guestRefresh1 = 0
    
    var body: some View {
        StickerWallView(guestRefresh1: $guestRefresh1)
    }
}

struct StickerWallView_Previews: PreviewProvider {
    static var previews: some View {
        StickerWallPreviewWrapper()
    }
}
