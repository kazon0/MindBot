//
//  Appointment.swift
//  PhiAI
//

import Foundation

struct Request: Codable {
    let password: String
    let schoolName: String
    let username: String
}

struct PsyLoginResponse: Codable {
    let code: Int
    let message: String
    let data: String?
}

struct DoctorInfo: Identifiable, Codable {
    var id: String { name } // 用 name 作为唯一标识符
    let name: String
    let availableTimes: [String]
    let status: String
}

struct DoctorAvailabilityResponse: Codable {
    let code: Int
    let message: String
    let data: [DoctorInfo]
}

struct AppointmentRequest: Codable {
    let date: String
    let doctorName: String
    let phoneNumber: String
    let problem: String
    let qqId: String
    let sessionId: String
    let timeSlot: String
}

struct AppointmentResponseData: Codable {
    let id: Int
    let qqId: String
    let doctorName: String
    let problem: String
    let appointmentTime: String // or Date if you decode with `.iso8601`
    let status: String
    let createTime: String
    let updateTime: String
}


