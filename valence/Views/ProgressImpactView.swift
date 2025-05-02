import SwiftUI
import SwiftData
import Charts

struct ProgressImpactView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [ProfessionalGoal]
    @Query private var projects: [Project]
    @Query private var skills: [Skill]
    
    @State private var selectedItem: AnyHashable?
    @State private var selectedItemType: ItemType = .goal
    @State private var searchText = ""
    
    enum ItemType: String, CaseIterable {
        case goal = "Goal"
        case project = "Project"
        case skill = "Skill"
    }
    
    private var filteredItems: [AnyHashable] {
        let searchPredicate = { (item: Any) -> Bool in
            if let goal = item as? ProfessionalGoal {
                return searchText.isEmpty || 
                    goal.title.localizedCaseInsensitiveContains(searchText) ||
                    goal.description.localizedCaseInsensitiveContains(searchText)
            } else if let project = item as? Project {
                return searchText.isEmpty || 
                    project.title.localizedCaseInsensitiveContains(searchText) ||
                    project.description.localizedCaseInsensitiveContains(searchText)
            } else if let skill = item as? Skill {
                return searchText.isEmpty || 
                    skill.name.localizedCaseInsensitiveContains(searchText) ||
                    skill.description.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
        
        switch selectedItemType {
        case .goal:
            return goals.filter(searchPredicate)
        case .project:
            return projects.filter(searchPredicate)
        case .skill:
            return skills.filter(searchPredicate)
        }
    }
    
    private var impactAnalysis: ImpactAnalysis? {
        guard let selected = selectedItem else { return nil }
        
        if let goal = selected as? ProfessionalGoal {
            return analyzeGoalImpact(goal)
        } else if let project = selected as? Project {
            return analyzeProjectImpact(project)
        } else if let skill = selected as? Skill {
            return analyzeSkillImpact(skill)
        }
        return nil
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 16) {
                // Item Type Picker
                Picker("Item Type", selection: $selectedItemType) {
                    ForEach(ItemType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Items List
                List(filteredItems, id: \.self, selection: $selectedItem) { item in
                    if let goal = item as? ProfessionalGoal {
                        GoalRow(goal: goal)
                    } else if let project = item as? Project {
                        ProjectRow(project: project)
                    } else if let skill = item as? Skill {
                        SkillRow(skill: skill)
                    }
                }
            }
        } detail: {
            if let analysis = impactAnalysis {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Impact Summary
                        ImpactSummaryView(analysis: analysis)
                        
                        // Direct Impact
                        if !analysis.directImpact.isEmpty {
                            ImpactSectionView(
                                title: "Direct Impact",
                                items: analysis.directImpact
                            )
                        }
                        
                        // Indirect Impact
                        if !analysis.indirectImpact.isEmpty {
                            ImpactSectionView(
                                title: "Indirect Impact",
                                items: analysis.indirectImpact
                            )
                        }
                        
                        // Progress Recommendations
                        if !analysis.recommendations.isEmpty {
                            RecommendationsView(recommendations: analysis.recommendations)
                        }
                    }
                    .padding()
                }
            } else {
                Text("Select an item to view impact analysis")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Progress Impact")
    }
    
    private func analyzeGoalImpact(_ goal: ProfessionalGoal) -> ImpactAnalysis {
        var analysis = ImpactAnalysis()
        
        // Direct impact on projects
        for project in goal.projects {
            analysis.directImpact.append(ImpactItem(
                title: project.title,
                type: .project,
                impact: calculateProjectImpact(project, basedOn: goal)
            ))
        }
        
        // Direct impact on skills
        for skill in goal.skills {
            analysis.directImpact.append(ImpactItem(
                title: skill.name,
                type: .skill,
                impact: calculateSkillImpact(skill, basedOn: goal)
            ))
        }
        
        // Indirect impact through projects
        for project in goal.projects {
            for skill in project.skills {
                if !goal.skills.contains(skill) {
                    analysis.indirectImpact.append(ImpactItem(
                        title: skill.name,
                        type: .skill,
                        impact: calculateSkillImpact(skill, basedOn: project)
                    ))
                }
            }
        }
        
        // Generate recommendations
        analysis.recommendations = generateRecommendations(for: goal)
        
        return analysis
    }
    
    private func analyzeProjectImpact(_ project: Project) -> ImpactAnalysis {
        var analysis = ImpactAnalysis()
        
        // Direct impact on goals
        for goal in project.goals {
            analysis.directImpact.append(ImpactItem(
                title: goal.title,
                type: .goal,
                impact: calculateGoalImpact(goal, basedOn: project)
            ))
        }
        
        // Direct impact on skills
        for skill in project.skills {
            analysis.directImpact.append(ImpactItem(
                title: skill.name,
                type: .skill,
                impact: calculateSkillImpact(skill, basedOn: project)
            ))
        }
        
        // Indirect impact through goals
        for goal in project.goals {
            for skill in goal.skills {
                if !project.skills.contains(skill) {
                    analysis.indirectImpact.append(ImpactItem(
                        title: skill.name,
                        type: .skill,
                        impact: calculateSkillImpact(skill, basedOn: goal)
                    ))
                }
            }
        }
        
        // Generate recommendations
        analysis.recommendations = generateRecommendations(for: project)
        
        return analysis
    }
    
    private func analyzeSkillImpact(_ skill: Skill) -> ImpactAnalysis {
        var analysis = ImpactAnalysis()
        
        // Direct impact on goals
        for goal in skill.goals {
            analysis.directImpact.append(ImpactItem(
                title: goal.title,
                type: .goal,
                impact: calculateGoalImpact(goal, basedOn: skill)
            ))
        }
        
        // Direct impact on projects
        for project in skill.projects {
            analysis.directImpact.append(ImpactItem(
                title: project.title,
                type: .project,
                impact: calculateProjectImpact(project, basedOn: skill)
            ))
        }
        
        // Indirect impact through goals
        for goal in skill.goals {
            for project in goal.projects {
                if !skill.projects.contains(project) {
                    analysis.indirectImpact.append(ImpactItem(
                        title: project.title,
                        type: .project,
                        impact: calculateProjectImpact(project, basedOn: goal)
                    ))
                }
            }
        }
        
        // Generate recommendations
        analysis.recommendations = generateRecommendations(for: skill)
        
        return analysis
    }
    
    private func calculateGoalImpact(_ goal: ProfessionalGoal, basedOn item: Any) -> ImpactLevel {
        // Simplified impact calculation
        if goal.status == .completed {
            return .high
        } else if goal.status == .inProgress {
            return .medium
        }
        return .low
    }
    
    private func calculateProjectImpact(_ project: Project, basedOn item: Any) -> ImpactLevel {
        // Simplified impact calculation
        if project.status == .completed {
            return .high
        } else if project.status == .inProgress {
            return .medium
        }
        return .low
    }
    
    private func calculateSkillImpact(_ skill: Skill, basedOn item: Any) -> ImpactLevel {
        // Simplified impact calculation
        switch skill.proficiency {
        case .expert: return .high
        case .advanced: return .medium
        case .intermediate: return .low
        case .beginner: return .minimal
        }
    }
    
    private func generateRecommendations(for item: Any) -> [String] {
        var recommendations: [String] = []
        
        if let goal = item as? ProfessionalGoal {
            if goal.status == .notStarted {
                recommendations.append("Start working on this goal to unlock progress in related projects and skills")
            } else if goal.status == .inProgress {
                recommendations.append("Focus on completing key milestones to accelerate progress in related areas")
            }
        } else if let project = item as? Project {
            if project.status == .notStarted {
                recommendations.append("Begin this project to make progress toward related goals")
            } else if project.status == .inProgress {
                recommendations.append("Complete critical tasks to maintain momentum in related goals")
            }
        } else if let skill = item as? Skill {
            if skill.proficiency == .beginner {
                recommendations.append("Develop this skill to enable progress in related goals and projects")
            } else if skill.proficiency == .intermediate {
                recommendations.append("Advance this skill to unlock new opportunities in related areas")
            }
        }
        
        return recommendations
    }
}

struct ImpactAnalysis {
    var directImpact: [ImpactItem] = []
    var indirectImpact: [ImpactItem] = []
    var recommendations: [String] = []
}

struct ImpactItem: Identifiable {
    let id = UUID()
    let title: String
    let type: ItemType
    let impact: ImpactLevel
}

enum ImpactLevel: String {
    case minimal = "Minimal"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct ImpactSummaryView: View {
    let analysis: ImpactAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Impact Summary")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Direct Impact",
                    value: "\(analysis.directImpact.count)",
                    color: .blue
                )
                
                StatCard(
                    title: "Indirect Impact",
                    value: "\(analysis.indirectImpact.count)",
                    color: .orange
                )
            }
            
            if !analysis.recommendations.isEmpty {
                Text("Key Recommendations")
                    .font(.subheadline)
                    .padding(.top)
                
                ForEach(analysis.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(recommendation)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct ImpactSectionView: View {
    let title: String
    let items: [ImpactItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            ForEach(items) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.title)
                            .font(.subheadline)
                        Text(item.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    ImpactLevelView(level: item.impact)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
    }
}

struct ImpactLevelView: View {
    let level: ImpactLevel
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index < impactLevelValue ? Color.accentColor : Color.gray.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var impactLevelValue: Int {
        switch level {
        case .minimal: return 1
        case .low: return 2
        case .medium: return 3
        case .high: return 4
        }
    }
}

struct RecommendationsView: View {
    let recommendations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Recommendations")
                .font(.headline)
            
            ForEach(recommendations, id: \.self) { recommendation in
                HStack(alignment: .top) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text(recommendation)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationView {
        ProgressImpactView()
            .modelContainer(for: [
                ProfessionalGoal.self,
                Project.self,
                Skill.self
            ], inMemory: true)
    }
} 