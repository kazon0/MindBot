
import SwiftUI

@main
struct PhiAIApp: App {
    @StateObject var appVM = AppViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationView{
                ControlView()
                    .environmentObject(appVM)
            }
        }
    }
}
