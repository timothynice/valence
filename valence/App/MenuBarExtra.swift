import SwiftUI
import SwiftData

@main
struct MenuBarExtra: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra("Everyline", systemImage: "target") {
            MenuBarWidgetView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppState: ObservableObject {
    @Published var isMainWindowOpen = false
    
    func openMainWindow() {
        isMainWindowOpen = true
    }
} 