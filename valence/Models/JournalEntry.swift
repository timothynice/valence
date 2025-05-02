import Foundation
import SwiftData

enum Mood: String, Codable {
    case veryNegative = "Very Negative"
    case negative = "Negative"
    case neutral = "Neutral"
    case positive = "Positive"
    case veryPositive = "Very Positive"
}

@Model
final class JournalEntry {
    var id: UUID
    var content: String
    var date: Date
    var mood: Mood
    var tags: [String]
    var pillarTypes: [PillarType]
    var isQuickEntry: Bool
    var needsFollowUp: Bool
    var followUpDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(content: String = "", mood: Mood = .neutral) {
        self.id = UUID()
        self.content = content
        self.date = Date()
        self.mood = mood
        self.tags = []
        self.pillarTypes = []
        self.isQuickEntry = false
        self.needsFollowUp = false
        self.followUpDate = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var requiresFollowUp: Bool {
        followUpDate != nil && !needsFollowUp
    }
    
    var isOverdue: Bool {
        guard let followUpDate = followUpDate else { return false }
        return !needsFollowUp && followUpDate < Date()
    }
} 