//
//  MoodCalendarView.swift
//  PhiAI
//

import SwiftUI
import UserNotifications

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
                    Color.gray.opacity(0.2),
                    Color.white,
                    Color(#colorLiteral(red: 0.7366558313, green: 0.8424485326, blue: 0.5300986767, alpha: 1))
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
                    .padding(.leading)
                    Spacer()
                    Button(action: {
                        activeSheet = .createEntry(date: viewModel.selectedDate)
                    }) {
                        Image(systemName: "pencil")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.accentColor))
                    }
                    .padding(.trailing)
                }
                .padding(.horizontal)
                .padding(.top)
                
                ZStack {
                    if viewModel.isLoading {
                              ProgressView("Loading...")
                                  .progressViewStyle(CircularProgressViewStyle())
                                  .frame(maxWidth: .infinity, maxHeight: .infinity)
                          }
                    else{
                        VStack {
                            HStack{
                                Text(monthYearString(from: currentDate))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .italic()
                                    .padding(8)
                                    .background(
                                        Color.accentColor.opacity(0.7)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .shadow(color: .gray.opacity(0.2), radius: 5)
                                    )
                                    .padding(.leading, 25)
                                Spacer()
                                Image("Line")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 30)
                                Spacer()
                            }
                            TabView(selection: $viewModel.currentMonthIndex) {
                                ForEach(-12...12, id: \.self) { offset in
                                    monthGridView(for: offset)
                                        .tag(offset)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
                        }
                    }
                }
                .padding()
                
                // 心情详情区
                ZStack {
                    Image("NoteBook")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 430)
                        .padding(.bottom)
                        .shadow(color: Color.black.opacity(animate ? 0.2 : 0.05), radius: animate ? 8 : 2, y: animate ? 6 : 2)
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? -20 : 60)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: animate)
                    if viewModel.isLoading {
                              ProgressView("Loading...")
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
                        initialMood: viewModel.moodImageName(for: date) ?? "mood_smile",
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
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(daysInMonth(for: monthDate), id: \.self) { date in
                        let isPlaceholder = Calendar.current.isDate(date, equalTo: Date.distantPast, toGranularity: .day)
                        let isFuture = date > Date()
                        let mood = viewModel.moodImageName(for: date)

                        ZStack(alignment: .top) {
                            if Calendar.current.isDate(date, inSameDayAs: Date()) {
                                Image("HandDrawnCircle1")
                                    .resizable()
                                    .frame(width: 45, height: 45)
                            } else if Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate) {
                                Image("HandDrawnCircle2")
                                    .resizable()
                                    .frame(width: 45, height: 45)
                                    .onAppear {
                                        print(" Circle should show for \(date)")
                                    }
                            }

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
                            .foregroundColor(isFuture ? .gray : .primary)

                            if let mood = mood, !mood.isEmpty, !isPlaceholder, !isFuture {
                                Image(mood)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40)
                                    .offset(y:4)
                                    .allowsHitTesting(false)
                            }
                        }
                        .contentShape(Rectangle())
                        .background(Color.yellow.opacity(0.3)
                            .clipShape(RoundedRectangle(cornerRadius: 10)))
                        .onTapGesture {
                            guard !isPlaceholder && !isFuture else { return }
                            viewModel.selectedDate = date
                            viewModel.currentMonthIndex = monthOffset
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            formatter.timeZone = TimeZone.current
                            print("本地时间：", formatter.string(from: date))
                        }
                    }
            }
        }
        .padding()
    }
    
    func daysInMonth(for date: Date) -> [Date] {
        let calendar = Calendar.current

        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!

        guard let monthInterval = calendar.dateInterval(of: .month, for: firstDayOfMonth) else { return [] }
        
        var dates: [Date] = []
        let startDay = calendar.component(.weekday, from: monthInterval.start)
        let offset = (startDay + 6) % 7

        for _ in 0..<offset {
            dates.append(Date.distantPast)
        }
        var current = calendar.startOfDay(for: monthInterval.start)
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
            let formattedText = entry.description.insertLineBreaks(every: 13)
            ZStack {
                VStack(spacing: 12) {
                    if let entry = viewModel.entry(for: viewModel.selectedDate), entry.moodScore >= 0 {
                        let imageName = viewModel.emojiImageName(for: entry.moodScore)
                        HStack(spacing:0){
                            Text("Date:")
                                .font(.headline)
                                .offset(x: -75, y: -80)
                            Text(monthDayString(from: viewModel.selectedDate))
                                .font(.title3)
                                .fontWeight(.bold)
                                .italic()
                                .foregroundColor(.secondary)
                                .offset(x:-60,y: -80)
                            
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60)
                                .shadow(radius: 5)
                                .offset(x:-30,y:-80)
                        }
                    }
                    
                    HStack {
                        Text("Text:")
                            .font(.headline)
                            .offset(y:-90)
                        ScrollView {
                            DottedUnderlineText(
                                text: formattedText,
                                font: UIFont(name: "PingFang SC Light", size: 20)!
                            )
                            .padding(20)
                        }
                        .frame(width: 270,height: 200)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(12)
                        .shadow(color:.gray.opacity(0.2),radius: 5)
                        .offset(x:10,y:-30)
                        .padding(.bottom,-20)
                    }
                }
                .padding(20)
                Image("Pencil")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                    .rotationEffect(.degrees(40))
                    .offset(x:-120,y:60)
            }
        }else {
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
            .frame(maxHeight: UIScreen.main.bounds.height * 0.45)
        }
    }
    
    func monthDayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: date)
    }
}


struct MoodCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        MoodCalendarView()
    }
}
