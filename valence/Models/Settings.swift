import Foundation
import SwiftData

@Model
final class Settings {
    var id: UUID
    var notificationsEnabled: Bool
    var dailyFocusReminder: Bool
    var dailyFocusReminderTime: Date
    var weeklyReviewReminder: Bool
    var weeklyReviewReminderDay: Int // 1 = Sunday, 7 = Saturday
    var weeklyReviewReminderTime: Date
    var createdAt: Date
    var updatedAt: Date
    
    init() {
        self.id = UUID()
        self.notificationsEnabled = true
        self.dailyFocusReminder = true
        self.dailyFocusReminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        self.weeklyReviewReminder = true
        self.weeklyReviewReminderDay = 7 // Saturday
        self.weeklyReviewReminderTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum WidgetTheme: String, Codable {
    case system
    case light
    case dark
    case minimal
} 