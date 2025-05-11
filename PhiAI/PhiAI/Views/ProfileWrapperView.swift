

import SwiftUI

struct ProfileWrapperView: View {
    @EnvironmentObject var appVM: AppViewModel
      @Binding var showLogin: Bool

      var body: some View {
          if let user = appVM.currentUser {
              MyView(user: user)
          } else {
              Color.clear
                  .onAppear {
                      showLogin = true
                  }
          }
      }
}

struct ProfileWrapperView_Previews: PreviewProvider {
    static var previews: some View {
        WrapperPreview()
    }

    struct WrapperPreview: View {
        @State var showLogin = false
        @StateObject var appVM = AppViewModel()

        var body: some View {
            ProfileWrapperView(showLogin: $showLogin)
                .environmentObject(appVM)
        }
    }
}
