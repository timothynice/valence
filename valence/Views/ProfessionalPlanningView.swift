import SwiftUI
import SwiftData
import Charts

struct ProfessionalPlanningView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [ProfessionalGoal]
    @Query private var projects: [Project]
    @Query private var skills: [Skill]
    @Query private var weeklyReviews: [WeeklyReview]
    @Query private var pillars: [Pillar]
    
    @State private var selectedTab = 0
    @State private var showingNewGoal = false
    @State private var showingNewProject = false
    @State private var showingNewSkill = false
    @State private var showingWeeklyReview = false
    @State private var showingPillarTracker = false
    
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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard
            ProfessionalPlanningDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            // Goals
            GoalsListView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
                .tag(1)
            
            // Projects
            ProjectsListView()
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }
                .tag(2)
            
            // Skills
            SkillsListView()
                .tabItem {
                    Label("Skills", systemImage: "brain")
                }
                .tag(3)
            
            // Relationships
            RelationshipManagerView()
                .tabItem {
                    Label("Relationships", systemImage: "link")
                }
                .tag(4)
            
            // Dependency Graph
            DependencyGraphView()
                .tabItem {
                    Label("Graph", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                }
                .tag(5)
            
            // Progress Impact
            ProgressImpactView()
                .tabItem {
                    Label("Impact", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(6)
        }
        .navigationTitle("Professional Planning")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingNewGoal = true
                    } label: {
                        Label("New Goal", systemImage: "target")
                    }
                    
                    Button {
                        showingNewProject = true
                    } label: {
                        Label("New Project", systemImage: "folder")
                    }
                    
                    Button {
                        showingNewSkill = true
                    } label: {
                        Label("New Skill", systemImage: "brain")
                    }
                    
                    Divider()
                    
                    Button {
                        showingWeeklyReview = true
                    } label: {
                        Label("Weekly Review", systemImage: "calendar")
                    }
                    
                    Button {
                        showingPillarTracker = true
                    } label: {
                        Label("Pillar Tracker", systemImage: "chart.bar.xaxis")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewGoal) {
            GoalDetailView()
        }
        .sheet(isPresented: $showingNewProject) {
            ProjectDetailView()
        }
        .sheet(isPresented: $showingNewSkill) {
            SkillDetailView()
        }
        .sheet(isPresented: $showingWeeklyReview) {
            WeeklyReviewView()
        }
        .sheet(isPresented: $showingPillarTracker) {
            PillarTrackerView()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
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

#Preview {
    NavigationView {
        ProfessionalPlanningView()
            .modelContainer(for: [
                ProfessionalGoal.self,
                Project.self,
                Skill.self,
                WeeklyReview.self,
                Pillar.self
            ], inMemory: true)
    }
} 