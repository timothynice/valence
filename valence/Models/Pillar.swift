import Foundation
import SwiftData

// Updated PillarType enum
enum PillarType: String, Codable, CaseIterable {
    case faith = "Faith"
    case family = "Family"
    case fitness = "Fitness"
    case finances = "Finances"
    case freedom = "Freedom"
    case fun = "Fun"
    
    // Adding a simple iconName, can be expanded later
    var iconName: String {
        switch self {
        case .faith: return "hands.sparkles.fill"
        case .family: return "person.3.fill"
        case .fitness: return "figure.run" // Changed from figure.walk
        case .finances: return "dollarsign.circle.fill"
        case .freedom: return "airplane" // Changed from briefcase
        case .fun: return "gamecontroller.fill"
        }
    }
}

@Model
final class Pillar {
    var id: UUID
    var type: PillarType
    var score: Int // Current score
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var weeklyTarget: Int = 5 // Default to 5 check-ins/actions per week
    
    // Assuming scoreHistory is a property that was missing in the read_files output for Pillar
    @Relationship(deleteRule: .cascade, inverse: \ScoreEntry.pillar) var scoreHistory: [ScoreEntry]? = []

    var currentStreak: Int {
        guard let history = scoreHistory, !history.isEmpty else { return 0 }

        let sortedEntries = history.filter { $0.score > 0 } // Consider only positive scores as check-ins
                                  .sorted { $0.date > $1.date }

        guard !sortedEntries.isEmpty else { return 0 }

        var streak = 0
        var expectedDate = Date() // Today

        // Check if the most recent check-in is today
        if let mostRecentEntry = sortedEntries.first, Calendar.current.isDate(mostRecentEntry.date, inSameDayAs: expectedDate) {
            streak += 1
            expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate)!
        } else if let mostRecentEntry = sortedEntries.first, mostRecentEntry.date < Calendar.current.startOfDay(for: Date()) {
            // If the most recent entry is before today, current streak is 0
            return 0
        } else {
             // No positive score entries, or most recent is not today
            return 0
        }
        
        // Iterate through the rest of the entries, starting from the second one
        for entry in sortedEntries.dropFirst() {
            if Calendar.current.isDate(entry.date, inSameDayAs: expectedDate) {
                streak += 1
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if entry.date < expectedDate { // Entry is older than expected, streak broken
                break
            }
            // If entry.date is later than expectedDate (e.g. multiple entries on one day),
            // we just continue to the next expectedDate, which is correct for consecutive day counting.
        }
        return streak
    }

    // Updated default type in init
    init(type: PillarType = .faith, score: Int = 5, notes: String = "", createdAt: Date = Date(), updatedAt: Date = Date(), weeklyTarget: Int = 5) {
        self.id = UUID()
        self.type = type
        self.score = score
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.weeklyTarget = weeklyTarget
    }
    
    func addScoreEntry(score: Int, date: Date = Date()) { // Allow passing date for testing/backfilling
        let entry = ScoreEntry(score: score, date: date, pillar: self)
        // entry.pillar = self // This line is now done in ScoreEntry init with inverse relationship
        scoreHistory?.append(entry)
        self.score = score // Update current pillar score to the latest entry
        self.updatedAt = Date()
    }
}

@Model
final class ScoreEntry {
    var id: UUID
    var score: Int
    var date: Date
    var pillar: Pillar? // Added reference back to Pillar for relationship

    init(score: Int, date: Date, pillar: Pillar? = nil) {
        self.id = UUID()
        self.score = score
        self.date = date
        self.pillar = pillar
    }
} 