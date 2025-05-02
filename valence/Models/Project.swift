import Foundation
import SwiftData

enum ProjectStatus: String, Codable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
    case onHold = "On Hold"
    case cancelled = "Cancelled"
}

enum ProjectPriority: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

@Model
final class Project {
    var id: UUID
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date
    var status: ProjectStatus
    var priority: ProjectPriority
    var progress: Double
    var tasks: [ProjectTask]
    var goals: [ProfessionalGoal]
    var skills: [Skill]
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String = "", description: String = "") {
        self.id = UUID()
        self.title = title
        self.description = description
        self.startDate = Date()
        self.endDate = Calendar.current.date(byAddingMonth: 1, to: Date()) ?? Date()
        self.status = .notStarted
        self.priority = .medium
        self.progress = 0
        self.tasks = []
        self.goals = []
        self.skills = []
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isActive: Bool {
        status == .inProgress || status == .notStarted
    }
    
    var isCompleted: Bool {
        status == .completed
    }
    
    var isOverdue: Bool {
        status != .completed && status != .cancelled && endDate < Date()
    }
    
    var daysUntilEndDate: Int {
        Calendar.current.numberOfDaysBetween(Date(), and: endDate)
    }
    
    func updateProgress() {
        if tasks.isEmpty {
            progress = status == .completed ? 1.0 : 0.0
            return
        }
        
        let completedTasks = tasks.filter { $0.isCompleted }
        progress = Double(completedTasks.count) / Double(tasks.count)
    }
}

@Model
final class ProjectTask {
    var id: UUID
    var title: String
    var description: String
    var dueDate: Date?
    var isCompleted: Bool
    var completedDate: Date?
    var priority: ProjectPriority
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String = "", description: String = "") {
        self.id = UUID()
        self.title = title
        self.description = description
        self.dueDate = Calendar.current.date(byAddingWeek: 1, to: Date())
        self.isCompleted = false
        self.completedDate = nil
        self.priority = .medium
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        return Calendar.current.numberOfDaysBetween(Date(), and: dueDate)
    }
} 