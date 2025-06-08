//
//  MoodBubbleView.swift
//  PhiAI
//


import SwiftUI

struct MoodBubbleView: View {
    let fullText: String
    @Binding var isVisible: Bool
    @State private var displayedText: String = ""
    @State private var scaleY: CGFloat = 0 // 纵向缩放
    
    var body: some View {
        ZStack {
            if isVisible {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isVisible = false
                            scaleY = 0
                        }
                    }
                
                VStack(alignment: .leading) {
                    Text(displayedText)
                        .font(.body)
                        .padding()
                        .background(Color(#colorLiteral(red: 0.9662302136, green: 1, blue: 0.9660263658, alpha: 1)))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .frame(maxWidth: 250, alignment: .leading)
                        .scaleEffect(x: 1, y: scaleY, anchor: .bottom) // 只纵向缩放，锚点底部
                        .onAppear {
                            displayedText = ""
                            withAnimation(.easeOut(duration: 0.3)) {
                                scaleY = 1
                            }
                            Task {
                                for (index, _) in fullText.enumerated() {
                                    try? await Task.sleep(nanoseconds: 30_000_000)
                                    displayedText = String(fullText.prefix(index + 1))
                                }
                            }
                        }
                }
                .padding(.horizontal)
            }
        }
        .animation(.easeInOut, value: isVisible)
    }
}
