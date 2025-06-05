//
//  AppointmentViewModel.swift
//  PhiAI
//


import Foundation

@MainActor
class AppointmentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isSuccess = false
    @Published var errorMessage: String?
    @Published var appointmentResponse: AppointmentResponseData?

    func makeAppointment(_ request: AppointmentRequest) async {
        isLoading = true
        isSuccess = false
        errorMessage = nil
        print(" 开始预约请求，请求参数：\(request)")

        do {
            let response = try await APIManager.shared.makeAppointment(request)
            appointmentResponse = response
            isSuccess = true
            print(" 预约成功：\(response)")
        } catch {
            errorMessage = error.localizedDescription
            print(" 预约失败：\(error.localizedDescription)")
        }

        isLoading = false
        print(" 预约流程结束")
    }
}

