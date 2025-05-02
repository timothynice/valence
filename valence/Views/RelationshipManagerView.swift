import SwiftUI
import SwiftData
import Charts

struct RelationshipManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [ProfessionalGoal]
    @Query private var projects: [Project]
    @Query private var skills: [Skill]
    
    @State private var selectedItem: AnyHashable?
    @State private var selectedItemType: ItemType = .goal
    @State private var showingLinkSheet = false
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
    
    private var selectedItemRelationships: [AnyHashable] {
        guard let selected = selectedItem else { return [] }
        
        if let goal = selected as? ProfessionalGoal {
            return goal.projects + goal.skills
        } else if let project = selected as? Project {
            return project.goals + project.skills
        } else if let skill = selected as? Skill {
            return skill.goals + skill.projects
        }
        return []
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
            if let selected = selectedItem {
                VStack(spacing: 16) {
                    // Selected Item Details
                    if let goal = selected as? ProfessionalGoal {
                        GoalDetailCard(goal: goal)
                    } else if let project = selected as? Project {
                        ProjectDetailCard(project: project)
                    } else if let skill = selected as? Skill {
                        SkillDetailCard(skill: skill)
                    }
                    
                    // Relationships Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Linked Items")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if selectedItemRelationships.isEmpty {
                            Text("No linked items")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            List(selectedItemRelationships, id: \.self) { item in
                                if let goal = item as? ProfessionalGoal {
                                    GoalRow(goal: goal)
                                } else if let project = item as? Project {
                                    ProjectRow(project: project)
                                } else if let skill = item as? Skill {
                                    SkillRow(skill: skill)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Link Button
                    Button {
                        showingLinkSheet = true
                    } label: {
                        Label("Link Item", systemImage: "link")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            } else {
                Text("Select an item to view relationships")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingLinkSheet) {
            LinkItemView(selectedItem: selectedItem)
        }
    }
}

struct GoalRow: View {
    let goal: ProfessionalGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(goal.title)
                .font(.headline)
            Text(goal.status.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.title)
                .font(.headline)
            Text(project.status.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SkillRow: View {
    let skill: Skill
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(skill.name)
                .font(.headline)
            Text(skill.proficiency.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct GoalDetailCard: View {
    let goal: ProfessionalGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(goal.title)
                .font(.title2)
                .bold()
            
            if !goal.description.isEmpty {
                Text(goal.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(goal.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: goal.status))
                    .cornerRadius(8)
                
                Text(goal.priority.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor(for: goal.priority))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    private func statusColor(for status: GoalStatus) -> Color {
        switch status {
        case .notStarted: return .gray.opacity(0.2)
        case .inProgress: return .blue.opacity(0.2)
        case .completed: return .green.opacity(0.2)
        case .onHold: return .orange.opacity(0.2)
        case .cancelled: return .red.opacity(0.2)
        }
    }
    
    private func priorityColor(for priority: GoalPriority) -> Color {
        switch priority {
        case .low: return .gray.opacity(0.2)
        case .medium: return .blue.opacity(0.2)
        case .high: return .orange.opacity(0.2)
        case .critical: return .red.opacity(0.2)
        }
    }
}

struct ProjectDetailCard: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.title)
                .font(.title2)
                .bold()
            
            if !project.description.isEmpty {
                Text(project.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(project.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: project.status))
                    .cornerRadius(8)
                
                Text(project.priority.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor(for: project.priority))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    private func statusColor(for status: ProjectStatus) -> Color {
        switch status {
        case .notStarted: return .gray.opacity(0.2)
        case .inProgress: return .blue.opacity(0.2)
        case .completed: return .green.opacity(0.2)
        case .onHold: return .orange.opacity(0.2)
        case .cancelled: return .red.opacity(0.2)
        }
    }
    
    private func priorityColor(for priority: ProjectPriority) -> Color {
        switch priority {
        case .low: return .gray.opacity(0.2)
        case .medium: return .blue.opacity(0.2)
        case .high: return .orange.opacity(0.2)
        case .critical: return .red.opacity(0.2)
        }
    }
}

struct SkillDetailCard: View {
    let skill: Skill
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(skill.name)
                .font(.title2)
                .bold()
            
            if !skill.description.isEmpty {
                Text(skill.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(skill.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                
                Text(skill.proficiency.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(proficiencyColor(for: skill.proficiency))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    private func proficiencyColor(for proficiency: SkillProficiency) -> Color {
        switch proficiency {
        case .beginner: return .blue.opacity(0.2)
        case .intermediate: return .green.opacity(0.2)
        case .advanced: return .orange.opacity(0.2)
        case .expert: return .red.opacity(0.2)
        }
    }
}

struct LinkItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedItem: AnyHashable?
    @State private var selectedLinkType: ItemType = .goal
    @State private var searchText = ""
    
    private var itemsToLink: [AnyHashable] {
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
        
        switch selectedLinkType {
        case .goal:
            return goals.filter(searchPredicate)
        case .project:
            return projects.filter(searchPredicate)
        case .skill:
            return skills.filter(searchPredicate)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Link Type Picker
                Picker("Link Type", selection: $selectedLinkType) {
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
                List(itemsToLink, id: \.self) { item in
                    Button {
                        linkItem(item)
                        dismiss()
                    } label: {
                        if let goal = item as? ProfessionalGoal {
                            GoalRow(goal: goal)
                        } else if let project = item as? Project {
                            ProjectRow(project: project)
                        } else if let skill = item as? Skill {
                            SkillRow(skill: skill)
                        }
                    }
                }
            }
            .navigationTitle("Link Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func linkItem(_ item: AnyHashable) {
        guard let selected = selectedItem else { return }
        
        if let goal = selected as? ProfessionalGoal {
            if let project = item as? Project {
                goal.projects.append(project)
            } else if let skill = item as? Skill {
                goal.skills.append(skill)
            }
        } else if let project = selected as? Project {
            if let goal = item as? ProfessionalGoal {
                project.goals.append(goal)
            } else if let skill = item as? Skill {
                project.skills.append(skill)
            }
        } else if let skill = selected as? Skill {
            if let goal = item as? ProfessionalGoal {
                skill.goals.append(goal)
            } else if let project = item as? Project {
                skill.projects.append(project)
            }
        }
    }
}

#Preview {
    NavigationView {
        RelationshipManagerView()
            .modelContainer(for: [
                ProfessionalGoal.self,
                Project.self,
                Skill.self
            ], inMemory: true)
    }
} 