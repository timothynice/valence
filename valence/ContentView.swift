//
//  ContentView.swift
//  valence
//
//  Created by Timothy Nice on 5/1/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DailyFocusView()
                .tabItem {
                    Label("Daily Focus", systemImage: "target")
                }
                .tag(0)
            
            PillarTrackerView()
                .tabItem {
                    Label("Pillars", systemImage: "chart.bar")
                }
                .tag(1)
            
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book")
                }
                .tag(2)
            
            WeeklyReviewView()
                .tabItem {
                    Label("Weekly Review", systemImage: "calendar")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [DailyFocus.self, Pillar.self, WeeklyReview.self, JournalEntry.self], inMemory: true)
        .environmentObject(AppState())
}
