
import SwiftUI

@main
struct PhiAIApp: App {
    @StateObject var vm = CoreDataViewModel()
    @StateObject var appVM = AppViewModel()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            NavigationView{
                ControlView()
                    .environmentObject(appVM)
                    .environmentObject(vm)
            }
        }
    }
}
