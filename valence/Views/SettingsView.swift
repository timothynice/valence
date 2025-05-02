import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @State private var showingNotificationPermissionAlert = false
    @State private var showingThemePreview = false
    
    private var currentSettings: Settings {
        if let existing = settings.first {
            return existing
        }
        let newSettings = Settings()
        modelContext.insert(newSettings)
        return newSettings
    }
    
    var body: some View {
        Form {
            Section("Daily Focus") {
                Toggle("Enable Daily Focus Reminder", isOn: $currentSettings.focusReminderEnabled)
                
                if currentSettings.focusReminderEnabled {
                    DatePicker("Reminder Time", selection: $currentSettings.focusReminderTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section("Weekly Review") {
                Toggle("Enable Weekly Review Reminder", isOn: $currentSettings.weeklyReviewReminderEnabled)
                
                if currentSettings.weeklyReviewReminderEnabled {
                    Picker("Reminder Day", selection: $currentSettings.weeklyReviewReminderDay) {
                        Text("Sunday").tag(1)
                        Text("Monday").tag(2)
                        Text("Tuesday").tag(3)
                        Text("Wednesday").tag(4)
                        Text("Thursday").tag(5)
                        Text("Friday").tag(6)
                        Text("Saturday").tag(7)
                    }
                    
                    DatePicker("Reminder Time", selection: $currentSettings.weeklyReviewReminderTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section("Menu Bar Widget") {
                Toggle("Show Pillar Scores", isOn: $currentSettings.showPillarScoresInMenuBar)
                Toggle("Show Recent Wins", isOn: $currentSettings.showRecentWinsInMenuBar)
                Toggle("Show Quick Actions", isOn: $currentSettings.showQuickActionsInMenuBar)
                
                Picker("Theme", selection: $currentSettings.menuBarWidgetTheme) {
                    Text("System").tag(WidgetTheme.system)
                    Text("Light").tag(WidgetTheme.light)
                    Text("Dark").tag(WidgetTheme.dark)
                    Text("Minimal").tag(WidgetTheme.minimal)
                }
                
                Button("Preview Theme") {
                    showingThemePreview = true
                }
            }
            
            Section("Notifications") {
                Toggle("Enable Quick Actions", isOn: $currentSettings.notificationActionsEnabled)
                Toggle("Enable Sound", isOn: $currentSettings.notificationSoundEnabled)
                Toggle("Enable Vibration", isOn: $currentSettings.notificationVibrationEnabled)
                
                Button("Request Notification Permission") {
                    requestNotificationPermission()
                }
            }
        }
        .padding()
        .frame(width: 400, height: 500)
        .alert("Notification Permission Required", isPresented: $showingNotificationPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in System Settings to receive reminders.")
        }
        .sheet(isPresented: $showingThemePreview) {
            ThemePreviewView(theme: currentSettings.menuBarWidgetTheme)
        }
        .onChange(of: currentSettings.notificationSoundEnabled) { _ in
            updateNotificationSettings()
        }
        .onChange(of: currentSettings.notificationVibrationEnabled) { _ in
            updateNotificationSettings()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if !granted {
                showingNotificationPermissionAlert = true
            } else {
                scheduleNotifications()
            }
        }
    }
    
    private func updateNotificationSettings() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                scheduleNotifications()
            }
        }
    }
    
    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        if currentSettings.focusReminderEnabled {
            let focusContent = UNMutableNotificationContent()
            focusContent.title = "Daily Focus Reminder"
            focusContent.body = "Don't forget to set your focus for today!"
            
            if currentSettings.notificationSoundEnabled {
                focusContent.sound = .default
            }
            
            if currentSettings.notificationActionsEnabled {
                let addFocusAction = UNNotificationAction(
                    identifier: "ADD_FOCUS",
                    title: "Add Focus",
                    options: [.foreground]
                )
                let skipAction = UNNotificationAction(
                    identifier: "SKIP",
                    title: "Skip",
                    options: [.destructive]
                )
                focusContent.categoryIdentifier = "FOCUS_REMINDER"
                center.setNotificationCategories([
                    UNNotificationCategory(
                        identifier: "FOCUS_REMINDER",
                        actions: [addFocusAction, skipAction],
                        intentIdentifiers: [],
                        options: []
                    )
                ])
            }
            
            let focusComponents = Calendar.current.dateComponents([.hour, .minute], from: currentSettings.focusReminderTime)
            let focusTrigger = UNCalendarNotificationTrigger(dateMatching: focusComponents, repeats: true)
            let focusRequest = UNNotificationRequest(identifier: "dailyFocus", content: focusContent, trigger: focusTrigger)
            
            center.add(focusRequest)
        }
        
        if currentSettings.weeklyReviewReminderEnabled {
            let reviewContent = UNMutableNotificationContent()
            reviewContent.title = "Weekly Review Reminder"
            reviewContent.body = "Time to reflect on your week and plan for the next!"
            
            if currentSettings.notificationSoundEnabled {
                reviewContent.sound = .default
            }
            
            if currentSettings.notificationActionsEnabled {
                let startReviewAction = UNNotificationAction(
                    identifier: "START_REVIEW",
                    title: "Start Review",
                    options: [.foreground]
                )
                let postponeAction = UNNotificationAction(
                    identifier: "POSTPONE",
                    title: "Postpone",
                    options: [.destructive]
                )
                reviewContent.categoryIdentifier = "WEEKLY_REVIEW"
                center.setNotificationCategories([
                    UNNotificationCategory(
                        identifier: "WEEKLY_REVIEW",
                        actions: [startReviewAction, postponeAction],
                        intentIdentifiers: [],
                        options: []
                    )
                ])
            }
            
            var reviewComponents = Calendar.current.dateComponents([.hour, .minute], from: currentSettings.weeklyReviewReminderTime)
            reviewComponents.weekday = currentSettings.weeklyReviewReminderDay
            let reviewTrigger = UNCalendarNotificationTrigger(dateMatching: reviewComponents, repeats: true)
            let reviewRequest = UNNotificationRequest(identifier: "weeklyReview", content: reviewContent, trigger: reviewTrigger)
            
            center.add(reviewRequest)
        }
    }
}

struct ThemePreviewView: View {
    let theme: WidgetTheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Theme Preview")
                .font(.headline)
                .padding()
            
            MenuBarWidgetView()
                .environment(\.colorScheme, theme == .dark ? .dark : .light)
                .frame(width: 300, height: 400)
                .background(theme == .minimal ? Color.clear : Color(.systemBackground))
                .cornerRadius(8)
                .padding()
            
            Button("Close") {
                dismiss()
            }
            .padding()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Settings.self], inMemory: true)
} 