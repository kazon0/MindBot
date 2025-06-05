//
//  MoodRecord.swift
//  PhiAI

import Foundation


struct MoodUploadRequest: Codable {
    var recordDate: String
    var moodScore: Int
    var moodType: Int
    var description: String
    var tags: String
    var imageUrl: String?
    var isPrivate: Bool
}

struct MoodRecordResponse: Codable {
    let id: Int
    let userId: Int
    let recordDate: String
    let moodScore: Int
    let moodType: Int
    let description: String
    let tags: String
    let imageUrl: String?
    let isPrivate: Bool
    let createTime: String
    let updateTime: String
    let deleted: Int
}

struct UpdateMoodRecordRequest: Codable {
    var recordDate: String
    var moodScore: Int
    var moodType: Int
    var description: String
    var tags: String
    var imageUrl: String?
    var isPrivate: Bool
}

struct MoodStatisticsResponse: Codable {
    let code: Int
    let message: String
    let data: MoodStatistics
}

struct MoodStatistics: Codable {
    let avgScore: Double
    let scoreDistribution: [String: Int]
    let tagStatistics: [String: Int] 
}

