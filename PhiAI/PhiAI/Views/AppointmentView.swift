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
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showInputSheet = false
    @State private var inputPhoneNumber = ""
    @State private var inputQQ = ""
    @State private var inputProblem = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @MainActor
    func getAppointmentMessage() -> String {
        if submitViewModel.isSuccess {
            if let status = submitViewModel.appointmentResponse?.status {
                return "预约状态：\(status)"
            } else {
                return "预约成功，等待处理。"
            }
        } else if let err = submitViewModel.errorMessage {
            return err
        } else {
            return "未知状态"
        }
    }

    @MainActor
    func getAppointmentAlertTitle() -> String {
        submitViewModel.isSuccess ? "预约成功" : "预约失败"
    }

    
    var body: some View {
        let availableDoctors = viewModel.doctors
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(#colorLiteral(red: 0.8626629114, green: 0.9756165147, blue: 0.7313965559, alpha: 1)).opacity(0.5),
                        Color(#colorLiteral(red: 0.8042530417, green: 0.9252516627, blue: 0.5908532143, alpha: 1)),
                        Color(#colorLiteral(red: 0.4738111496, green: 0.752263248, blue: 0.3751039505, alpha: 1)).opacity(0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                VStack {
                    HStack{
                        // 顶部返回按钮
                        Button(action: {
                            withAnimation {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.accentColor)
                                .font(.headline)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .padding(.leading)
                        Spacer()
                        
                        Text("预约咨询列表")
                            .font(.title)
                            .bold()
                            .padding(.trailing,90)
                        
                        Image("Check")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                            .padding(.trailing,20)
                            .shadow(radius: 3)
                    }
                    .padding(.top,20)
                    // 日期横向选择
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(days, id: \.self) { day in
                                dateButton(for: day)
                            }
                        }
                    }
                    .padding()
                    Divider()
                        .padding(.vertical, 8)
                    
                    ZStack{
                        Image("List")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 400)
                            .shadow(radius: 5)
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
                            Spacer()
                        } else if availableDoctors.isEmpty {
                            Spacer()
                            Text("该日期无可预约医生")
                                .foregroundColor(.secondary)
                            Spacer()
                        } else {
                            GeometryReader { geometry in
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.doctors) { doctor in
                                        DoctorRowView(
                                            doctor: doctor,
                                            selectedDoctorID: selectedDoctorID,
                                            selectedSlot: selectedSlot
                                        ) { id, slot in
                                            selectedDoctorID = id
                                            selectedSlot = slot
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 500)
                            .offset(x:0,y:30)
                        }
                            .frame(width: 300)
                        }
                    }
    
                    Spacer()
                    
                    // 预约按钮
                    Button(action: {
                        showInputSheet = true // 弹出表单
                    }) {
                        Text("确认预约")
                            .font(.title3)
                            .padding()
                            .frame(width: 160, height: 50)
                            .foregroundColor(.white)
                            .background(Color.accentColor)
                            .cornerRadius(15)
                    }
                    .shadow(color: .gray.opacity(0.5),radius: 5)
                    .disabled(!canMakeAppointment || submitViewModel.isLoading)
                    .padding()
                    .sheet(isPresented: $showInputSheet) {
                        inputSheetView()
                    }
                    
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
            .alert(isPresented: $showAlert) {
                Alert(title: Text(getAppointmentAlertTitle()), message: Text(getAppointmentMessage()), dismissButton: .default(Text("确定")))
            }

        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
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
        .background(isSelected ? Color.accentColor :  Color.white.opacity(0.8))
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
            phoneNumber: inputPhoneNumber,
            problem: inputProblem,
            qqId: inputQQ,
            sessionId: token,
            timeSlot: slot
        )

        await submitViewModel.makeAppointment(request)
        
        DispatchQueue.main.async {
            self.showAlert = true
        }
    }
    
    @ViewBuilder
    func inputSheetView() -> some View {
        NavigationView {
            Form {
                Section(header: Text("联系方式")) {
                    TextField("手机号", text: $inputPhoneNumber)
                        .keyboardType(.phonePad)
                    TextField("QQ号", text: $inputQQ)
                        .keyboardType(.numberPad)
                }
                Section(header: Text("问题描述")) {
                    TextField("请简要描述您的问题", text: $inputProblem)
                }
            }
            .navigationTitle("填写预约信息")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("提交") {
                        Task {
                            await handleAppointment()
                            showInputSheet = false
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showInputSheet = false
                    }
                }
            }
        }
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
                .foregroundColor(.primary) // 保持字体颜色正常
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
            .background(isSelected ? Color.accentColor.opacity(0.8) : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
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
