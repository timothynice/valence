import Foundation
import SwiftData

enum GoalStatus: String, Codable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
    case onHold = "On Hold"
    case cancelled = "Cancelled"
}

enum GoalPriority: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

@Model
final class ProfessionalGoal {
    var id: UUID
    var title: String
    var description: String
    var startDate: Date
    var targetDate: Date
    var status: GoalStatus
    var priority: GoalPriority
    var progress: Double
    var milestones: [GoalMilestone]
    var projects: [Project]
    var skills: [Skill]
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String = "", description: String = "") {
        self.id = UUID()
        self.title = title
        self.description = description
        self.startDate = Date()
        self.targetDate = Calendar.current.date(byAddingMonth: 1, to: Date()) ?? Date()
        self.status = .notStarted
        self.priority = .medium
        self.progress = 0
        self.milestones = []
        self.projects = []
        self.skills = []
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isOverdue: Bool {
        status != .completed && status != .cancelled && targetDate < Date()
    }
    
    var daysUntilTargetDate: Int {
        Calendar.current.numberOfDaysBetween(Date(), and: targetDate)
    }
    
    func updateProgress() {
        if milestones.isEmpty {
            progress = status == .completed ? 1.0 : 0.0
            return
        }
        
        let completedMilestones = milestones.filter { $0.isCompleted }
        progress = Double(completedMilestones.count) / Double(milestones.count)
    }
}

@Model
final class GoalMilestone {
    var id: UUID
    var title: String
    var description: String
    var dueDate: Date
    var isCompleted: Bool
    var completedDate: Date?
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String = "", description: String = "") {
        self.id = UUID()
        self.title = title
        self.description = description
        self.dueDate = Calendar.current.date(byAddingWeek: 1, to: Date()) ?? Date()
        self.isCompleted = false
        self.completedDate = nil
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }
    
    var daysUntilDue: Int {
        Calendar.current.numberOfDaysBetween(Date(), and: dueDate)
    }
}

private extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
        return numberOfDays.day ?? 0
    }
    
    func date(byAddingMonth months: Int, to date: Date) -> Date? {
        self.date(byAdding: .month, value: months, to: date)
    }
    
    func date(byAddingWeek weeks: Int, to date: Date) -> Date? {
        self.date(byAdding: .weekOfYear, value: weeks, to: date)
    }
} 