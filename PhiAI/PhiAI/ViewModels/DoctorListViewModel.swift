//
//  DoctorListViewModel.swift
//  PhiAI
//

import Foundation

@MainActor
class DoctorListViewModel: ObservableObject {
    @Published var doctors: [DoctorInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func fetchDoctors(for date: Date, sessionId: String) async {
        isLoading = true
        errorMessage = nil

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        print(" fetchDoctors 请求开始 → 日期: \(dateString), sessionId: \(sessionId)")

        do {
            let doctors = try await APIManager.shared.fetchAvailableDoctors(date: dateString, sessionId: sessionId)

            print(" fetchDoctors 成功返回医生数：\(doctors.count)")
            self.doctors = doctors
        }  catch {
            if let nsError = error as NSError?,
               nsError.domain == "FetchDoctorsError" {
                self.errorMessage = nsError.localizedDescription
            } else {
                self.errorMessage = "网络错误：\(error.localizedDescription)"
            }
        }

        isLoading = false
        print(" fetchDoctors 请求结束")
    }
}
