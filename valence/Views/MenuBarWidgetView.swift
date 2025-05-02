import SwiftUI
import SwiftData

struct MenuBarWidgetView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @Query private var dailyFocuses: [DailyFocus]
    @Query private var pillars: [Pillar]
    @Query private var weeklyReviews: [WeeklyReview]
    @Query private var quickActions: [QuickAction]
    @Query private var settings: [Settings]
    @Query private var journalEntries: [JournalEntry]
    @State private var showingActionSheet = false
    @State private var selectedAction: QuickAction?
    @State private var showingQuickJournal = false
    
    private var todayFocus: DailyFocus? {
        dailyFocuses.first { Calendar.current.isDateInToday($0.date) }
    }
    
    private var currentReview: WeeklyReview? {
        weeklyReviews.first { $0.isCurrentWeek }
    }
    
    private var todayEntries: [JournalEntry] {
        journalEntries.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    private var enabledQuickActions: [QuickAction] {
        quickActions
            .filter { $0.isEnabled }
            .sorted { $0.order < $1.order }
    }
    
    private var currentSettings: Settings {
        if let existing = settings.first {
            return existing
        }
        let newSettings = Settings()
        modelContext.insert(newSettings)
        return newSettings
    }
    
    private var effectiveTheme: WidgetTheme {
        if currentSettings.menuBarWidgetTheme == .system {
            return colorScheme == .dark ? .dark : .light
        }
        return currentSettings.menuBarWidgetTheme
    }
    
    private var backgroundColor: Color {
        switch effectiveTheme {
        case .light:
            return Color(.systemBackground)
        case .dark:
            return Color(.systemBackground)
        case .minimal:
            return .clear
        case .system:
            return Color(.systemBackground)
        }
    }
    
    private var textColor: Color {
        switch effectiveTheme {
        case .light:
            return .primary
        case .dark:
            return .primary
        case .minimal:
            return .primary
        case .system:
            return .primary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Today's Focus Section
            if let focus = todayFocus {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Focus")
                        .font(.headline)
                        .foregroundColor(textColor)
                    Text(focus.focusText)
                        .font(.subheadline)
                        .foregroundColor(textColor.opacity(0.8))
                }
            }
            
            // Today's Journal Entries Section
            if !todayEntries.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Journal")
                        .font(.headline)
                        .foregroundColor(textColor)
                    ForEach(todayEntries.prefix(2)) { entry in
                        HStack {
                            Text(entry.mood.rawValue)
                            Text(entry.content)
                                .lineLimit(1)
                                .foregroundColor(textColor.opacity(0.8))
                        }
                        .font(.subheadline)
                    }
                    if todayEntries.count > 2 {
                        Text("+\(todayEntries.count - 2) more entries")
                            .font(.caption)
                            .foregroundColor(textColor.opacity(0.6))
                    }
                }
            }
            
            // Pillar Scores Section
            if currentSettings.showPillarScoresInMenuBar {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pillar Scores")
                        .font(.headline)
                        .foregroundColor(textColor)
                    ForEach(pillars) { pillar in
                        HStack {
                            Text(pillar.type.rawValue)
                                .foregroundColor(textColor)
                            Spacer()
                            Text("\(pillar.score)/10")
                                .foregroundColor(textColor.opacity(0.8))
                        }
                        .font(.subheadline)
                    }
                }
            }
            
            // Weekly Review Section
            if let review = currentReview {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Review")
                        .font(.headline)
                        .foregroundColor(textColor)
                    if currentSettings.showRecentWinsInMenuBar && !review.wins.isEmpty {
                        Text("Recent Wins:")
                            .font(.subheadline)
                            .foregroundColor(textColor)
                        ForEach(review.wins.suffix(3), id: \.self) { win in
                            Text("• \(win)")
                                .font(.subheadline)
                                .foregroundColor(textColor.opacity(0.8))
                        }
                    }
                }
            }
            
            // Quick Actions Section
            if currentSettings.showQuickActionsInMenuBar && !enabledQuickActions.isEmpty {
                Divider()
                    .foregroundColor(textColor.opacity(0.2))
                ForEach(enabledQuickActions) { action in
                    Button(action: {
                        selectedAction = action
                        showingActionSheet = true
                    }) {
                        HStack {
                            Image(systemName: iconName(for: action.type))
                                .foregroundColor(textColor)
                            Text(action.title)
                                .foregroundColor(textColor)
                        }
                    }
                }
            }
            
            Divider()
                .foregroundColor(textColor.opacity(0.2))
            
            // Quick Actions
            HStack {
                Button("Quick Journal") {
                    showingQuickJournal = true
                }
                .foregroundColor(textColor)
                
                Spacer()
                
                Button("Open App") {
                    appState.openMainWindow()
                }
                .foregroundColor(textColor)
                
                NavigationLink("Settings") {
                    SettingsView()
                }
                .foregroundColor(textColor)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(effectiveTheme == .minimal ? 0 : 8)
        .sheet(isPresented: $showingActionSheet) {
            if let action = selectedAction {
                QuickActionSheet(action: action)
            }
        }
        .sheet(isPresented: $showingQuickJournal) {
            QuickJournalView()
        }
        .onAppear {
            initializeQuickActions()
        }
    }
    
    private func iconName(for type: QuickActionType) -> String {
        switch type {
        case .addFocus:
            return "target"
        case .addPillarScore:
            return "chart.bar"
        case .addWin:
            return "star"
        case .addStruggle:
            return "exclamationmark.triangle"
        case .addInsight:
            return "lightbulb"
        }
    }
    
    private func initializeQuickActions() {
        guard quickActions.isEmpty else { return }
        
        let defaultActions = [
            QuickAction(type: .addFocus, title: "Add Today's Focus", order: 0),
            QuickAction(type: .addPillarScore, title: "Update Pillar Score", order: 1),
            QuickAction(type: .addWin, title: "Add a Win", order: 2),
            QuickAction(type: .addStruggle, title: "Add a Struggle", order: 3),
            QuickAction(type: .addInsight, title: "Add an Insight", order: 4)
        ]
        
        for action in defaultActions {
            modelContext.insert(action)
        }
    }
}

#Preview {
    MenuBarWidgetView()
        .modelContainer(for: [DailyFocus.self, Pillar.self, WeeklyReview.self, QuickAction.self, Settings.self, JournalEntry.self], inMemory: true)
        .environmentObject(AppState())
} 