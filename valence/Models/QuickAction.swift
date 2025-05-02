import Foundation
import SwiftData

enum QuickActionType: String, Codable {
    case setDailyFocus = "Set Daily Focus"
    case updatePillarScore = "Update Pillar Score"
    case addWeeklyReviewItem = "Add Weekly Review Item"
    case addJournalEntry = "Add Journal Entry"
}

@Model
final class QuickAction {
    var id: UUID
    var type: QuickActionType
    var title: String
    var isEnabled: Bool
    var order: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(type: QuickActionType, title: String = "", order: Int = 0) {
        self.id = UUID()
        self.type = type
        self.title = title.isEmpty ? type.rawValue : title
        self.isEnabled = true
        self.order = order
        self.createdAt = Date()
        self.updatedAt = Date()
    }
} 