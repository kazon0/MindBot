//
//  MoodStatisticsCard.swift
//  PhiAI
//

import SwiftUI

struct PieSliceData {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let label: String
    let value: Int
    let scale: CGFloat
}

struct MoodStatisticsCard: View {
    @StateObject private var calendarVM = MoodCalendarViewModel()
    @State private var currentMonth = Date()

    var moodCounts: [Int] {
        guard let stats = calendarVM.statistics else { return [] }
        return [
            stats.scoreDistribution["5"] ?? 0, // 开心
            stats.scoreDistribution["4"] ?? 0, // 微笑
            stats.scoreDistribution["3"] ?? 0, // 平静
            stats.scoreDistribution["2"] ?? 0, // 伤心
            stats.scoreDistribution["1"] ?? 0, // 生气
            stats.scoreDistribution["0"] ?? 0  // 哭泣
        ]
    }

    let moodColors: [Color] = [
        Color(#colorLiteral(red: 0.9749456048, green: 0.5896526575, blue: 0.4137764573, alpha: 1)), // mood_happy
        Color(#colorLiteral(red: 0.9795940518, green: 0.8665113449, blue: 0.4789200425, alpha: 1)),  // mood_smile
        Color(#colorLiteral(red: 0.652449429, green: 0.8205555081, blue: 0.5900995731, alpha: 1)),   // mood_neutral
        Color(#colorLiteral(red: 0.5526278019, green: 0.7586465478, blue: 0.9422392249, alpha: 1)),   // mood_sad
        Color(#colorLiteral(red: 0.7202700973, green: 0.6075922251, blue: 0.9231736064, alpha: 1)), // mood_angry
        Color(#colorLiteral(red: 0.5414883494, green: 0.5614325404, blue: 0.5696870089, alpha: 1))     // mood_cry
    ]

    let moodLabels = ["开心", "微笑", "平静", "伤心", "生气", "哭泣"]
    
    let moodIcons = [
        "mood_happy",
        "mood_smile",
        "mood_neutral",
        "mood_sad",
        "mood_angry",
        "mood_cry"
    ]


    var totalCount: Int {
        moodCounts.reduce(0, +)
    }
    
    var pieData: [PieSliceData] {
        var slices: [PieSliceData] = []
        let nonZeroCounts = moodCounts.enumerated().filter { $0.element > 0 }
        let anglePerSlice = 360.0 / Double(nonZeroCounts.count)
        var startDeg: Double = 0
        let maxCount = nonZeroCounts.map { $0.element }.max() ?? 1

        for (i, value) in nonZeroCounts {
            let normalizedValue = Double(value) / Double(maxCount)
            let scale = 0.8 + 0.2 * sqrt(normalizedValue) // √比例，视觉面积更均衡
            let endDeg = startDeg + anglePerSlice

            slices.append(
                PieSliceData(
                    startAngle: .degrees(startDeg),
                    endAngle: .degrees(endDeg),
                    color: moodColors[i],
                    label: moodLabels[i],
                    value: value,
                    scale: CGFloat(scale)
                )
            )
            startDeg = endDeg
        }

        return slices
    }


    var body: some View {
        VStack(spacing: 16) {
            // 顶部月份切换同之前

            HStack {
                Button(action: {
                    withAnimation {
                        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                        Task {
                            await calendarVM.loadMoodStatistics(for: currentMonth)
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(currentMonth, formatter: monthFormatter)
                    .font(.headline)

                Spacer()

                Button(action: {
                    withAnimation {
                        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                        Task {
                            await calendarVM.loadMoodStatistics(for: currentMonth)
                        }
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .frame(width: 330)

            Divider()
                .frame(width: 330)

            if let _ = calendarVM.statistics, totalCount > 0 {
                HStack {
                    VStack {
                        ZStack {
                            ForEach(pieData.indices, id: \.self) { index in
                                let slice = pieData[index]
                                PieSlice(startAngle: slice.startAngle, endAngle: slice.endAngle, scale: slice.scale)
                                    .fill(slice.color)
                            }
                        }
                        .frame(width: 120, height: 120)
                        .padding(.bottom,10)
                        if let stats = calendarVM.statistics {
                            Text(String(format: "平均得分：%.2f", stats.avgScore))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading)
                    Spacer()
                    // 图例
                    VStack(spacing: 8) {
                        ForEach(pieData.indices, id: \.self) { index in
                            let slice = pieData[index]
                            HStack {
                                Image(moodIcons[moodLabels.firstIndex(of: slice.label) ?? 0])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("\(slice.label)：\(slice.value)")
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                    }
                    .padding(.leading,70)
                    Spacer()
                }
                .frame(width: 330,height: 160)
            }else {
                Text("暂无统计数据")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .frame(width: 200)
        .onAppear {
            Task {
                await calendarVM.loadMoodStatistics(for: currentMonth)
            }
        }
    }

    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter
    }
}

//玫瑰图
struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var scale: CGFloat = 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * scale  // 乘以比例

        path.move(to: center)
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle - Angle(degrees: 90),
                    endAngle: endAngle - Angle(degrees: 90),
                    clockwise: false)
        path.closeSubpath()

        return path
    }
}


#Preview {
    MoodStatisticsCard()
}
