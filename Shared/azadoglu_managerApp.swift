import SwiftUI

@main
struct azadoglu_managerApp: App {

    @StateObject private var store = AppStore()

    var body: some Scene {

        WindowGroup {

            LoginGateView()
                .environmentObject(store)
                .frame(
                    minWidth: 1000,
                    minHeight: 650
                )
        }
    }
}


// MARK: - GİRİŞ KAPISI

struct LoginGateView: View {

    @EnvironmentObject var store: AppStore

    @State private var isLoggedIn = false
    @State private var loggedInUser = ""

    var body: some View {

        Group {

            if isLoggedIn {

                ContentView()
                    .environmentObject(store)

            } else {

                LoginView(
                    onLogin: { username, password in

                        loggedInUser = username
                        isLoggedIn = true
                    }
                )
            }
        }
    }
}
