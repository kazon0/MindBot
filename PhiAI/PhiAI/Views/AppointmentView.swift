//
//  Doctor.swift
//  PhiAI
//


import SwiftUI

extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}


struct AppointmentView: View {
    // 未来7天日期
    let days: [Date] = {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: today)! }
    }()
    
    @State private var selectedDate: Date = Date().startOfDay()
    @State private var selectedDoctorID: String?
      @State private var selectedSlot: String?
    @StateObject private var viewModel = DoctorListViewModel()
    @EnvironmentObject var appointmentManager: AppointmentPlatformManager
    @StateObject private var submitViewModel = AppointmentViewModel()
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @MainActor
    func getAppointmentMessage() -> String {
        if submitViewModel.isSuccess {
            if let status = submitViewModel.appointmentResponse?.status {
                return "预约状态：\(status)"
            } else {
                return "预约成功"
            }
        } else if let err = submitViewModel.errorMessage {
            return err
        } else {
            return "未知状态"
        }
    }
    
    var body: some View {
        let availableDoctors = viewModel.doctors
        NavigationView {
            VStack {
                HStack{
                    Text("预约咨询列表")
                        .font(.title)
                        .padding(.trailing,200)
                }
                .padding(.top,20)
                // 日期横向选择
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(days, id: \.self) { day in
                            dateButton(for: day)
                        }
                    }
                    //.padding(.top,80)
                    .padding(.horizontal)
                }
                Divider()
                    .padding(.vertical, 8)
                
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("正在加载医生列表...")
                        .padding()
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .offset(y: 90)
                    Spacer()
                } else if availableDoctors.isEmpty {
                    Spacer()
                    Text("该日期无可预约医生")
                        .foregroundColor(.secondary)
                        .offset(y: 90)
                    Spacer()
                } else {
                    List(viewModel.doctors) { doctor in
                        DoctorRowView(
                            doctor: doctor,
                            selectedDoctorID: selectedDoctorID,
                            selectedSlot: selectedSlot
                        ) { id, slot in
                            selectedDoctorID = id
                            selectedSlot = slot
                        }
                    }
                    .listStyle(PlainListStyle())
                }

                
                Spacer()
                
                // 预约按钮
                Button(action:{
                    Task {
                        await handleAppointment()
                    }
                }) {
                    Text("确认预约")
                        .font(.title3)
                        .padding()
                        .frame(width: 200, height: 60)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(15)
                        
                }
                .alert("预约结果", isPresented: $showAlert) {
                    Button("确定", role: .cancel) { }
                } message: {
                    Text(getAppointmentMessage())
                }
                .disabled(!canMakeAppointment || submitViewModel.isLoading)
                .padding()
                   
            }
            .task {
                if let token = appointmentManager.token {
                    print(" token 不为空，开始拉取医生列表：\(token)")
                    await viewModel.fetchDoctors(for: selectedDate, sessionId: token)
                } else {
                    print(" token 为空，跳过 fetchDoctors")
                }
            }
            .onChange(of: selectedDate) { newDate in
                Task {
                    if let token = appointmentManager.token {
                        await viewModel.fetchDoctors(for: newDate, sessionId: token)
                    }
                }
            }
        }
    }
    
    var canMakeAppointment: Bool {
        selectedDoctorID != nil && selectedSlot != nil
    }
        
    func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    func weekDayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    func dateDisplayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    func dateButton(for day: Date) -> some View {
        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
        return VStack {
            Text(dayString(day))
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
            Text(weekDayString(day))
                .font(.caption)
                .foregroundColor(isSelected ? .white : .secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
        .cornerRadius(10)
        .onTapGesture {
            selectedDate = day
            selectedDoctorID = nil
            selectedSlot = nil
        }
    }
    
    @MainActor
    func handleAppointment() async {
        guard let token = appointmentManager.token,
              let doc = viewModel.doctors.first(where: { $0.id == selectedDoctorID }),
              let slot = selectedSlot else {
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: selectedDate)

        let request = AppointmentRequest(
            date: dateStr,
            doctorName: doc.name,
            phoneNumber: "17268568903",
            problem: "我最近有些焦虑",
            qqId: "1034961091",
            sessionId: token,
            timeSlot: slot
        )

        await submitViewModel.makeAppointment(request)
        showAlert = true
    }

}

struct DoctorRowView: View {
    let doctor: DoctorInfo
    let selectedDoctorID: String?
    let selectedSlot: String?
    let onSelect: (String, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(doctor.name)
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(doctor.availableTimes, id: \.self) { slot in
                        slotView(slot: slot)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    func slotView(slot: String) -> some View {
        let isSelected = (selectedDoctorID == doctor.id && selectedSlot == slot)
        return Text(slot)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
            .onTapGesture {
                onSelect(doctor.id, slot)
            }
    }
}


struct AppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentView()
            .environmentObject(AppointmentPlatformManager())
    }
}
