//
//  ContentView.swift
//  valence
//
//  Created by Timothy Nice on 5/1/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // modelContext and appState are inherited from valenceApp.swift
    // No need to declare them here if ContentView itself doesn't directly use them,
    // but TodayView will need them from the environment.
    // @Environment(\.modelContext) private var modelContext // Retain if ContentView needs it
    // @EnvironmentObject private var appState: AppState // Retain if ContentView needs it

    var body: some View {
        TodayView() 
        // TodayView will pick up modelContext and appState from the environment
        // set by valenceApp.swift.
    }
}

#Preview {
    // ContentView now displays TodayView.
    // TodayView's preview already includes the necessary models (Pillar, ScoreEntry, JournalEntry, DailyFocus)
    // So, we align ContentView's preview with what TodayView requires.
    ContentView()
        .modelContainer(for: [
            Pillar.self, 
            ScoreEntry.self, 
            JournalEntry.self, 
            DailyFocus.self 
            // Add any other models TodayView or its subviews might need.
            // WeeklyReview.self might not be directly needed by TodayView,
            // but including it if other parts of the app (previously in TabView) might be reintroduced.
            // For this specific change, focusing on TodayView's direct needs.
        ], inMemory: true)
        .environmentObject(AppState()) // AppState is provided by valenceApp
}
