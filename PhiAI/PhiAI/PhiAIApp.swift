
import SwiftUI

@main
struct PhiAIApp: App {
    @StateObject var appVM = AppViewModel()
    @StateObject private var appointmentManager = AppointmentPlatformManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationView{
                ControlView()
                    .environmentObject(appVM)
                    .environmentObject(appointmentManager)
            }
        }
    }
}
