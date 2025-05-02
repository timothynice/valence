import Foundation
import SwiftData

@Model
final class DailyFocus {
    var id: UUID
    var title: String
    var description: String
    var date: Date
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String = "", description: String = "") {
        self.id = UUID()
        self.title = title
        self.description = description
        self.date = Date()
        self.isCompleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
} 