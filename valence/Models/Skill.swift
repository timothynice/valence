import Foundation
import SwiftData

@Model
final class Skill {
    var id: UUID
    var name: String
    var description: String
    var category: SkillCategory
    var proficiency: SkillProficiency
    var goals: [ProfessionalGoal]
    var projects: [Project]
    var developmentPlan: String
    var resources: [SkillResource]
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String = "", description: String = "") {
        self.id = UUID()
        self.name = name
        self.description = description
        self.category = .other
        self.proficiency = .beginner
        self.goals = []
        self.projects = []
        self.developmentPlan = ""
        self.resources = []
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var progressToNextLevel: Double {
        let completedResources = resources.filter { $0.status == .completed }
        let totalResources = resources.count
        
        if totalResources == 0 {
            return 0.0
        }
        
        return Double(completedResources.count) / Double(totalResources)
    }
    
    var nextProficiencyLevel: SkillProficiency? {
        switch proficiency {
        case .beginner: return .intermediate
        case .intermediate: return .advanced
        case .advanced: return .expert
        case .expert: return nil
        }
    }
}

enum SkillCategory: String, Codable {
    case technical = "Technical"
    case softSkills = "Soft Skills"
    case leadership = "Leadership"
    case management = "Management"
    case communication = "Communication"
    case design = "Design"
    case business = "Business"
    case other = "Other"
}

enum SkillProficiency: String, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
}

@Model
final class SkillResource {
    var id: UUID
    var title: String
    var url: String
    var type: ResourceType
    var status: ResourceStatus
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String = "", url: String = "") {
        self.id = UUID()
        self.title = title
        self.url = url
        self.type = .other
        self.status = .notStarted
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum ResourceType: String, Codable {
    case course = "Course"
    case book = "Book"
    case article = "Article"
    case video = "Video"
    case project = "Project"
    case other = "Other"
}

enum ResourceStatus: String, Codable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
} 