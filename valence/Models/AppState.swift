import SwiftUI
import SwiftData

@Observable
class AppState {
    var selectedTab: Int = 0
    
    // MARK: - Model Container
    static var modelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            DailyFocus.self,
            Pillar.self,
            WeeklyReview.self,
            PillarReflection.self,
            QuickAction.self,
            Settings.self,
            JournalEntry.self,
            ProfessionalGoal.self,
            GoalMilestone.self,
            Project.self,
            ProjectTask.self,
            Skill.self,
            SkillResource.self,
            ScoreEntry.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {}
} 