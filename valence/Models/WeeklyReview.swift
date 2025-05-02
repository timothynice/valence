import Foundation
import SwiftData

@Model
final class WeeklyReview {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var wins: [String]
    var struggles: [String]
    var insights: [String]
    var nextWeekFocus: String
    var pillarReflections: [PillarReflection]
    var createdAt: Date
    var updatedAt: Date
    
    var isCurrentWeek: Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.isDate(today, equalTo: startDate, toGranularity: .weekOfYear)
    }
    
    init() {
        self.id = UUID()
        self.startDate = Date().startOfWeek
        self.endDate = Date().endOfWeek
        self.wins = []
        self.struggles = []
        self.insights = []
        self.nextWeekFocus = ""
        self.pillarReflections = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class PillarReflection {
    var id: UUID
    var pillarType: PillarType
    var score: Int
    var notes: String
    var weeklyReview: WeeklyReview?
    var createdAt: Date
    var updatedAt: Date
    
    init(pillarType: PillarType = .physical, score: Int = 5) {
        self.id = UUID()
        self.pillarType = pillarType
        self.score = score
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

private extension Date {
    var startOfWeek: Date {
        Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date ?? self
    }
    
    var endOfWeek: Date {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: weekEnd) ?? self
    }
} 