//
//  MoodCalendarView.swift
//  PhiAI
//

import SwiftUI
import UserNotifications

struct IdentifiableDate: Identifiable, Equatable {
    let id = UUID()
    let date: Date
}

struct MoodCalendarView: View {
    @State private var currentMonthIndex = 0
    @State private var selectedDate: Date = Date()
    @State private var animate = false

    struct MoodEntry: Codable, Identifiable {
        var id = UUID()
        var mood: String
        var note: String
    }
    
    @State private var moodData: [String: MoodEntry] = [:]
    
    enum MoodSheetType: Identifiable {
        case createEntry(date: Date)
        var id: String {
            switch self {
            case .createEntry(let date): return "create-\(MoodCalendarView.dateString(from: date))"
            }
        }
    }
    
    @State private var activeSheet: MoodSheetType? = nil
    
    private var currentDate: Date {
        Calendar.current.date(byAdding: .month, value: currentMonthIndex, to: Date()) ?? Date()
    }
    
    var body: some View {
        
        ZStack(alignment: .top){
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
                // 顶部带按钮的月份切换栏
                HStack {
                    Button {
                        withAnimation {
                            if currentMonthIndex > -12 { currentMonthIndex -= 1 }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .bold()
                    }
                    Spacer()
                    Text(monthYearString(from: currentDate))
                        .font(.title)
                        .italic()
                        .bold()
                    Spacer()
                    Button {
                        withAnimation {
                            if currentMonthIndex < 12 { currentMonthIndex += 1 }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .bold()
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // TabView：支持滑动切换月份
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
                    
                    TabView(selection: $currentMonthIndex) {
                        ForEach(-12...12, id: \.self) { offset in
                            monthGridView(for: offset)
                                .tag(offset)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                    .padding(.bottom, 40)
                }
                .padding()
                
                ZStack{
                    RoundedRectangle(cornerRadius: 40)
                        .foregroundColor(Color(#colorLiteral(red: 0.737, green: 0.842, blue: 0.530, alpha: 1)))
                        .shadow(color:.gray.opacity(0.5),radius: 20)
                        .offset(y:10)
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(Color.white.opacity(0.7))
                        .shadow(color:.gray.opacity(0.5),radius: 20)
                        .frame(width: 300,height: 200)
                        .padding()
                    moodDetailView()
                }
               
                Spacer()
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .createEntry(let date):
                    let key = MoodCalendarView.dateString(from: date)
                    let entry = moodData[key]
                    MoodEditorView(date: date, initialMood: entry?.mood, initialNote: entry?.note) { mood, note in
                        moodData[key] = MoodEntry(id: UUID(), mood: mood, note: note)
                        activeSheet = nil
                    }
                }
            }
            
        }
        .ignoresSafeArea(edges:.bottom)
        .onAppear {
            animate = true
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
                    let mood = moodData[MoodCalendarView.dateString(from: date)]?.mood ?? ""

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
                                if Calendar.current.isDate(date, inSameDayAs: selectedDate) {
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
                        selectedDate = date
                        currentMonthIndex = monthOffset
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

    static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func weekdays() -> [String] {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }

    @ViewBuilder
    func moodDetailView() -> some View {
        let key = MoodCalendarView.dateString(from: selectedDate)
        if let entry = moodData[key] {
            VStack(spacing: 12) {
                Text("已记录的心情 - \(key)")
                    .font(.headline)
                Text(entry.mood)
                    .font(.system(size: 60))
                ScrollView {
                    Text(entry.note)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                Button("编辑记录") {
                    activeSheet = .createEntry(date: selectedDate)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
        } else {
            VStack(spacing: 12) {
                Text("暂未记录")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Button(action:{
                    activeSheet = .createEntry(date: selectedDate)
                }) {
                    Text("添加心情与日记")
                        .frame(width: 150,height: 48)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                        .shadow(color: Color.gray.opacity(animate ? 0.4 : 0.1), radius: animate ? 10 : 3)
                        .scaleEffect(animate ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)
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

    @State private var selectedMood: String = "😊"
    @State private var noteText: String = ""

    let moods = ["😊", "😐", "😢", "😠", "😴", "🥳"]

    init(date: Date, initialMood: String? = nil, initialNote: String? = nil, onSave: @escaping (String, String) -> Void) {
        self.date = date
        self._selectedMood = State(initialValue: initialMood ?? "😊")
        self._noteText = State(initialValue: initialNote ?? "")
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("记录 \(MoodCalendarView.dateString(from: date)) 的心情")
                .font(.title2)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                ForEach(moods, id: \.self) { mood in
                    Text(mood)
                        .font(.system(size: 40))
                        .padding()
                        .background(mood == selectedMood ? Color.blue.opacity(0.3) : Color.clear)
                        .clipShape(Circle())
                        .onTapGesture {
                            selectedMood = mood
                        }
                }
            }

            TextEditor(text: $noteText)
                .frame(height: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))

            Button("保存") {
                onSave(selectedMood, noteText)
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
