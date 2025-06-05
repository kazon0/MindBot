//
//  MoodEditorView.swift
//  PhiAI
//
//  Created by 郑金坝 on 2025/6/1.
//

import SwiftUI

struct MoodEditorView: View {
    let date: Date
    let onSave: (String, String) -> Void
    
    @StateObject private var viewModel: MoodEditorViewModel
    
    init(date: Date, initialMood: String? = nil, initialNote: String? = nil, onSave: @escaping (String, String) -> Void) {
        self.date = date
        self.onSave = onSave
        _viewModel = StateObject(wrappedValue: MoodEditorViewModel(initialMood: initialMood, initialNote: initialNote))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("记录 \(date.formattedString()) 的心情")
                .font(.title2)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                ForEach(viewModel.moods, id: \.self) { moodName in
                    Image(moodName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .padding()
                        .background(moodName == viewModel.selectedMood ? Color.blue.opacity(0.3) : Color.clear)
                        .clipShape(Circle())
                        .onTapGesture {
                            viewModel.selectedMood = moodName
                        }
                }
            }
            
            TextEditor(text: $viewModel.noteText)
                .frame(height: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
            
            Button("保存") {
                let result = viewModel.save()
                onSave(result.0, result.1)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
