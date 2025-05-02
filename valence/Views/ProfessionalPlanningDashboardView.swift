import SwiftUI
import SwiftData
import Charts

struct ProfessionalPlanningDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [ProfessionalGoal]
    @Query private var projects: [Project]
    @Query private var skills: [Skill]
    @Query private var weeklyReviews: [WeeklyReview]
    @Query private var pillars: [Pillar]
    
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedPillar: PillarType?
    
    private var activeGoals: [ProfessionalGoal] {
        goals.filter { $0.status == .inProgress }
    }
    
    private var activeProjects: [Project] {
        projects.filter { $0.isActive }
    }
    
    private var upcomingMilestones: [GoalMilestone] {
        goals.flatMap { $0.milestones }
            .filter { !$0.isCompleted }
            .sorted { $0.dueDate < $1.dueDate }
            .prefix(5)
    }
    
    private var upcomingTasks: [ProjectTask] {
        projects.flatMap { $0.tasks }
            .filter { !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(5)
    }
    
    private var skillProgress: [(skill: Skill, progress: Double)] {
        skills.map { ($0, $0.progressToNextLevel) }
            .sorted { $0.progress > $1.progress }
    }
    
    private var currentReview: WeeklyReview? {
        weeklyReviews.first { $0.isCurrentWeek }
    }
    
    private var pillarProgress: [(pillar: PillarType, score: Double)] {
        if let review = currentReview {
            return review.pillarReflections.map { ($0.pillarType, Double($0.score) / 10) }
        }
        return []
    }
    
    private var goalCompletionRate: Double {
        let completedGoals = goals.filter { $0.status == .completed }.count
        return goals.isEmpty ? 0 : Double(completedGoals) / Double(goals.count)
    }
    
    private var projectCompletionRate: Double {
        let completedProjects = projects.filter { $0.status == .completed }.count
        return projects.isEmpty ? 0 : Double(completedProjects) / Double(projects.count)
    }
    
    private var skillDevelopmentRate: Double {
        let totalProgress = skills.reduce(0) { $0 + $1.progressToNextLevel }
        return skills.isEmpty ? 0 : totalProgress / Double(skills.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range and Pillar Filters
                HStack {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Pillar", selection: $selectedPillar) {
                        Text("All Pillars").tag(Optional<PillarType>.none)
                        ForEach(PillarType.allCases, id: \.self) { pillar in
                            Text(pillar.rawValue).tag(Optional(pillar))
                        }
                    }
                }
                .padding(.horizontal)
                
                // Quick Stats
                HStack(spacing: 16) {
                    StatCard(
                        title: "Goals",
                        value: "\(activeGoals.count)",
                        subtitle: "\(Int(goalCompletionRate * 100))% Complete",
                        icon: "target",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Projects",
                        value: "\(activeProjects.count)",
                        subtitle: "\(Int(projectCompletionRate * 100))% Complete",
                        icon: "folder",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Skills",
                        value: "\(skills.count)",
                        subtitle: "\(Int(skillDevelopmentRate * 100))% Progress",
                        icon: "brain",
                        color: .purple
                    )
                }
                .padding(.horizontal)
                
                // Progress Charts
                VStack(spacing: 16) {
                    Text("Progress Overview")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Chart {
                        BarMark(
                            x: .value("Type", "Goals"),
                            y: .value("Progress", goalCompletionRate)
                        )
                        .foregroundStyle(.blue)
                        
                        BarMark(
                            x: .value("Type", "Projects"),
                            y: .value("Progress", projectCompletionRate)
                        )
                        .foregroundStyle(.green)
                        
                        BarMark(
                            x: .value("Type", "Skills"),
                            y: .value("Progress", skillDevelopmentRate)
                        )
                        .foregroundStyle(.purple)
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                }
                
                // Upcoming Items
                VStack(alignment: .leading, spacing: 12) {
                    Text("Upcoming Items")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(upcomingMilestones) { milestone in
                            UpcomingItemRow(
                                title: milestone.title,
                                dueDate: milestone.dueDate,
                                type: "Milestone",
                                isOverdue: milestone.isOverdue
                            )
                        }
                        
                        ForEach(upcomingTasks) { task in
                            UpcomingItemRow(
                                title: task.title,
                                dueDate: task.dueDate,
                                type: "Task",
                                isOverdue: task.isOverdue
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Skill Development
                VStack(alignment: .leading, spacing: 12) {
                    Text("Skill Development")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(skillProgress, id: \.skill.id) { item in
                        SkillProgressRow(skill: item.skill, progress: item.progress)
                    }
                    .padding(.horizontal)
                }
                
                // Weekly Review Integration
                if let review = currentReview {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This Week's Progress")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(review.pillarReflections) { reflection in
                            PillarProgressRow(reflection: reflection)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Pillar Progress
                if !pillarProgress.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pillar Progress")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(pillarProgress, id: \.pillar) { item in
                                BarMark(
                                    x: .value("Pillar", item.pillar.rawValue),
                                    y: .value("Score", item.score)
                                )
                                .foregroundStyle(by: .value("Pillar", item.pillar.rawValue))
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2)
                .bold()
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct UpcomingItemRow: View {
    let title: String
    let dueDate: Date?
    let type: String
    let isOverdue: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                Text(type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let dueDate = dueDate {
                Text(dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(isOverdue ? .red : .secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct SkillProgressRow: View {
    let skill: Skill
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(skill.name)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .tint(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct PillarProgressRow: View {
    let reflection: PillarReflection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(reflection.pillarType.rawValue)
                    .font(.subheadline)
                Spacer()
                Text("\(reflection.score)/10")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(reflection.score) / 10)
                .tint(.green)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
}

#Preview {
    NavigationView {
        ProfessionalPlanningDashboardView()
            .modelContainer(for: [
                ProfessionalGoal.self,
                Project.self,
                Skill.self,
                WeeklyReview.self,
                Pillar.self
            ], inMemory: true)
    }
} 