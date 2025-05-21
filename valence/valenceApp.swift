import SwiftUI
import SwiftData

@main
struct valenceApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.openWindow) var openWindow // Added for programmatic window opening

    // Removed init(), as AppState.isMainWindowOpen is now initialized to true
    
    var body: some Scene {
        // Changed from WindowGroup to Window with a specific ID
        Window("Valence", id: "main-content") { 
            ContentView()
                .environmentObject(appState)
        }
        .modelContainer(AppState.modelContainer) // For ContentView and its hierarchy

        // Add the MenuBar scene here
        ValenceMenuBar()
            .environmentObject(appState) // Pass the same appState
            .modelContainer(AppState.modelContainer) // For MenuBarWidgetView and its hierarchy
            .onChange(of: appState.isMainWindowOpen) { oldValue, newValue in
                if newValue { // If isMainWindowOpen becomes true
                    openWindow(id: "main-content") // Open the main window
                }
                // Note: This doesn't handle programmatically closing the window.
                // The subtask focuses on opening.
            }
    }
}
