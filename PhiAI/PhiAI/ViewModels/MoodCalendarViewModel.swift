//
//  MoodCalendarViewModel.swift
//  PhiAI
//

import Foundation
import SwiftUI

@MainActor
class MoodCalendarViewModel: ObservableObject {
    @Published var moodData: [String: MoodRecordResponse] = [:]
    @Published var selectedDate: Date = Date()
    @Published var currentMonthIndex: Int = 0
    @Published var isLoading = false

    nonisolated static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func emoji(for score: Int) -> String {
        switch score {
        case 5: return "🥳"
        case 4: return "😊"
        case 3: return "😐"
        case 2: return "😢"
        case 1: return "😠"
        case 0: return "😭"
        default: return ""
        }
    }

    func moodEmoji(for date: Date) -> String {
        guard let score = moodData[Self.dateString(from: date)]?.moodScore else {
            return ""
        }
        return emoji(for: score)
    }

    func fetchMoodRecord(for date: Date) async {
        let dateStr = Self.dateString(from: date)
        do {
            let record = try await APIManager.shared.fetchMoodRecord(for: dateStr)
            moodData[dateStr] = record
        } catch {
        }
    }
    
    func fetchMoodRecordsConcurrently(for monthDate: Date) async {
        isLoading = true
        defer { isLoading = false }
        
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else { return }
        
        var dates: [Date] = []
        var date = monthInterval.start
        while date < monthInterval.end {
            dates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        await withTaskGroup(of: Void.self) { group in
            for date in dates {
                group.addTask {
                    await self.fetchMoodRecord(for: date)
                }
            }
        }
    }

    func saveMoodRecord(for date: Date, mood: String, note: String) async {
        let dateStr = Self.dateString(from: date)
        let moodScore = moodScoreMapping[mood] ?? 0
        let existingRecord = entry(for: date)

        if let _ = existingRecord {
            await updateMoodRecord(
                for: date,
                moodScore: moodScore,
                moodType: 0,
                description: note,
                tags: "",
                imageUrl: nil,
                isPrivate: false
            )
        } else {
            let record = MoodUploadRequest(
                recordDate: dateStr,
                moodScore: moodScore,
                moodType: 0,
                description: note,
                tags: "",
                imageUrl: nil,
                isPrivate: false
            )
            do {
                print(" 开始上传日期 \(dateStr) 的心情记录：moodScore=\(moodScore), note=\(note)")
                try await APIManager.shared.saveMoodRecord(record)
                print(" 上传成功")
                await fetchMoodRecord(for: date) // 上传后再拉一次，保持同步
            } catch {
                print(" 上传记录失败：\(error.localizedDescription)")
            }
        }
    }


    func updateEntry(for date: Date, mood: String, note: String) {
        Task {
            await saveMoodRecord(for: date, mood: mood, note: note)
        }
        objectWillChange.send()
    }
    
    //  更新已有的心情记录
      func updateMoodRecord(
          for date: Date,
          moodScore: Int,
          moodType: Int,
          description: String,
          tags: String,
          imageUrl: String? = nil,
          isPrivate: Bool = false
      ) async {
          isLoading = true
          let dateStr = Self.dateString(from: date)

          let updateRequest = UpdateMoodRecordRequest(
              recordDate: dateStr,
              moodScore: moodScore,
              moodType: moodType,
              description: description,
              tags: tags,
              imageUrl: imageUrl,
              isPrivate: isPrivate
          )

          do {
              let success = try await APIManager.shared.updateMoodRecord(updateRequest)
              if success {
                  // 更新成功后重新拉取当天记录，确保同步显示
                  await fetchMoodRecord(for: date)
              }
          } catch {
              print(" 更新失败：\(error.localizedDescription)")
          }
          isLoading = false
      }

    func entry(for date: Date) -> MoodRecordResponse? {
        let key = Self.dateString(from: date)
        return moodData[key]
    }

    let moodScoreMapping: [String: Int] = [
        "🥳": 5,
        "😊": 4,
        "😐": 3,
        "😢": 2,
        "😠": 1,
        "😭": 0
    ]
}


class MoodEditorViewModel: ObservableObject {
    @Published var selectedMood: String
    @Published var noteText: String

    let moods = ["😊", "😐", "😢", "😠", "😭", "🥳"]

    init(initialMood: String? = nil, initialNote: String? = nil) {
        self.selectedMood = initialMood ?? "😊"
        self.noteText = initialNote ?? ""
    }

    func save() -> (String, String) {
        return (selectedMood, noteText)
    }
}
