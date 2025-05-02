import Foundation
import SwiftData

enum PillarType: String, Codable {
    case physical = "Physical"
    case mental = "Mental"
    case emotional = "Emotional"
    case spiritual = "Spiritual"
    case social = "Social"
    case professional = "Professional"
}

@Model
final class Pillar {
    var id: UUID
    var type: PillarType
    var score: Int
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    
    init(type: PillarType = .physical, score: Int = 5) {
        self.id = UUID()
        self.type = type
        self.score = score
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func addScoreEntry(score: Int) {
        let entry = ScoreEntry(score: score, date: Date())
        scoreHistory.append(entry)
        self.score = score
        self.updatedAt = Date()
    }
}

@Model
final class ScoreEntry {
    var id: UUID
    var score: Int
    var date: Date
    
    init(score: Int, date: Date) {
        self.id = UUID()
        self.score = score
        self.date = date
    }
} 