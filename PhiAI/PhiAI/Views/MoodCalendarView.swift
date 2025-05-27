//
//  MoodCalendarView.swift
//  PhiAI
//

import SwiftUI
import UserNotifications

extension Date {
    func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
}


struct IdentifiableDate: Identifiable, Equatable {
    let id = UUID()
    let date: Date
}

struct MoodCalendarView: View {
    @StateObject private var viewModel = MoodCalendarViewModel()
    @State private var animate = false
    @Environment(\.presentationMode) var presentationMode
    
    enum MoodSheetType: Identifiable {
        case createEntry(date: Date)
        var id: String {
            switch self {
            case .createEntry(let date): return "create-\(MoodCalendarViewModel.dateString(from: date))"
            }
        }
    }
    
    @State private var activeSheet: MoodSheetType? = nil
    
    private var currentDate: Date {
        Calendar.current.date(byAdding: .month, value: viewModel.currentMonthIndex, to: Date()) ?? Date()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                          gradient: Gradient(colors: [
                              Color(#colorLiteral(red: 0.8348818421, green: 0.8151340485, blue: 0.7915056944, alpha: 1)),
                              Color.white.opacity(0)
                          ]),
                          startPoint: .top,
                          endPoint: .bottom
                      )
                      .frame(height: 180) // 调整这个值控制渐变覆盖范围
                      .edgesIgnoringSafeArea(.top)
            
            VStack(spacing: 0) {
                HStack {
                    Button {
                        withAnimation {
                            presentationMode.wrappedValue.dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .bold()
                    }
                    Spacer()
                    Text(monthYearString(from: currentDate))
                        .font(.custom("SFRounded-Regular", size: 24))
                    Spacer()
                    Button(action:{
                        activeSheet = .createEntry(date: viewModel.selectedDate)
                    }) {
                        Text("编辑")
                            .foregroundColor(.accentColor)
                            .font(.headline)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // TabView 月份切换视图，注意用 viewModel.currentMonthIndex 绑定
                ZStack {
                    Image("GirlBackground")
                        .resizable()
                        .scaledToFill()
                        .frame(height: UIScreen.main.bounds.height * 0.3)
                        .clipped()
                        .cornerRadius(30) // 圆角
                        .compositingGroup() // 允许混合模式生效
                        .opacity(0.4) // 整体透明
                        .mask(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.black,
                                    Color.black.opacity(0.5),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: UIScreen.main.bounds.width * 0.8
                            )
                        )
                    if viewModel.isLoading {
                              ProgressView("加载中...")
                                  .progressViewStyle(CircularProgressViewStyle())
                                  .frame(maxWidth: .infinity, maxHeight: .infinity)
                          }
                    else{
                        TabView(selection: $viewModel.currentMonthIndex) {
                            ForEach(-12...12, id: \.self) { offset in
                                monthGridView(for: offset)
                                    .tag(offset)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                        .padding(.bottom, 40)
                    }
                }
                .padding()
                
                // 心情详情区
                ZStack {
                    Image("NoteBook")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400)
                        .padding(.bottom)
                        .shadow(color: Color.black.opacity(animate ? 0.2 : 0.05), radius: animate ? 8 : 2, y: animate ? 6 : 2)
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? 0 : 60)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: animate)
                    if viewModel.isLoading {
                              ProgressView("加载中...")
                                  .progressViewStyle(CircularProgressViewStyle())
                                  .frame(maxWidth: .infinity, maxHeight: .infinity)
                          }
                    else{
                        moodDetailView()
                    }
                }
                
                Spacer()
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .createEntry(let date):
                    let entry = viewModel.entry(for: date)
                    MoodEditorView(
                        date: date,
                        initialMood: viewModel.moodEmoji(for: date),
                        initialNote: entry?.description ?? ""
                    ) { mood, note in
                        viewModel.updateEntry(for: date, mood: mood, note: note)
                        activeSheet = nil
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .tabBar)
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            animate = true
        }
        .onAppear {
            Task {
                let currentMonthDate = Calendar.current.date(byAdding: .month, value: viewModel.currentMonthIndex, to: Date()) ?? Date()
                await viewModel.fetchMoodRecordsConcurrently(for: currentMonthDate)
            }
        }
        .onChange(of: viewModel.currentMonthIndex) { newValue in
            Task {
                let newMonthDate = Calendar.current.date(byAdding: .month, value: newValue, to: Date()) ?? Date()
                await viewModel.fetchMoodRecordsConcurrently(for: newMonthDate)
            }
        }
    }
    
    func monthGridView(for monthOffset: Int) -> some View {
        let monthDate = Calendar.current.date(byAdding: .month, value: monthOffset, to: Date())!
        return VStack(spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(weekdays(), id: \.self) { day in
                    Text(day)
                        .font(.headline)
                        .foregroundColor(.gray)
                        .italic()
                }
                
                ForEach(daysInMonth(for: monthDate), id: \.self) { date in
                    let isPlaceholder = Calendar.current.isDate(date, equalTo: Date.distantPast, toGranularity: .day)
                    let isFuture = date > Date()
                    let mood = viewModel.moodEmoji(for: date)

                    ZStack(alignment: .top) {
                        VStack {
                            if isPlaceholder {
                                Text("")
                                    .frame(height: 30)
                            } else {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.body)
                                    .italic()
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 16)
                                    .padding(.bottom,10)
                            }
                        }
                        .frame(height: 40)
                        .background(
                            ZStack {
                                if Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate) {
                                    Image("HandDrawnCircle2")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                }
                                if Calendar.current.isDate(date, inSameDayAs: Date()) {
                                    Image("HandDrawnCircle1")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                }
                            }
                        )
                        .foregroundColor(isFuture ? .gray : .primary)

                        if !mood.isEmpty && !isPlaceholder && !isFuture {
                            Text(mood)
                                .font(.system(size: 32))
                                .offset(y: -14)
                                .allowsHitTesting(false)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isPlaceholder && !isFuture else { return }
                        viewModel.selectedDate = date
                        viewModel.currentMonthIndex = monthOffset
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    func daysInMonth(for date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }

        var dates: [Date] = []

        let startDay = calendar.component(.weekday, from: monthInterval.start)
        let offset = (startDay + 6) % 7

        for _ in 0..<offset {
            dates.append(Date.distantPast)
        }

        var current = monthInterval.start
        while current < monthInterval.end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        return dates
    }
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func weekdays() -> [String] {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
    
    @ViewBuilder
    func moodDetailView() -> some View {
        
        let key = MoodCalendarViewModel.dateString(from: viewModel.selectedDate)
        if let entry = viewModel.moodData[key] {
            
            VStack(spacing: 12) {
                HStack{
                    Text("\(key) 的心情:  ")
                        .font(.custom("PingFang SC Light", size: 18))
                    Text(viewModel.moodEmoji(for: viewModel.selectedDate))
                        .font(.system(size: 30))
                }
                .padding()
                .offset(y:10)
                ScrollView {
                    Text(entry.description)
                        .font(.custom("PingFang SC Light", size: 18))
                        .lineSpacing(8)
                        .frame(maxWidth: 300, alignment: .topLeading)
                        .padding()
                        .cornerRadius(8)
                }
                .offset(x:10,y:-35)
                .padding(.bottom,-20)
            }
            .padding(20)
        } else {
            VStack(spacing: 12) {
                Text("暂未记录")
                    .font(.custom("PingFang SC Light", size: 20))
                    .foregroundColor(.secondary)
                Button(action:{
                    activeSheet = .createEntry(date: viewModel.selectedDate)
                }) {
                    Text("添加心情与日记")
                        .frame(width: 150,height: 48)
                        .font(.custom("PingFang SC Light", size: 17))
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                        .shadow(color: Color.gray.opacity(animate ? 0.4 : 0.1), radius: animate ? 10 : 3)
                        .scaleEffect(animate ? 1.06 : 1.0)
                }
            }
            .padding()
            .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
        }
    }
}



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
                ForEach(viewModel.moods, id: \.self) { mood in
                    Text(mood)
                        .font(.system(size: 40))
                        .padding()
                        .background(mood == viewModel.selectedMood ? Color.blue.opacity(0.3) : Color.clear)
                        .clipShape(Circle())
                        .onTapGesture {
                            viewModel.selectedMood = mood
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



struct MoodCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        MoodCalendarView()
    }
}
