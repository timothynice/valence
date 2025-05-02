import SwiftUI
import SwiftData

struct SkillsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var skills: [Skill]
    @State private var searchText = ""
    @State private var selectedCategory: SkillCategory?
    @State private var selectedProficiency: SkillProficiency?
    @State private var showingNewSkill = false
    
    private var filteredSkills: [Skill] {
        skills.filter { skill in
            let matchesSearch = searchText.isEmpty || 
                skill.name.localizedCaseInsensitiveContains(searchText) ||
                skill.description.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || skill.category == selectedCategory
            let matchesProficiency = selectedProficiency == nil || skill.proficiency == selectedProficiency
            
            return matchesSearch && matchesCategory && matchesProficiency
        }
        .sorted { $0.name < $1.name }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search and Filters
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Picker("Category", selection: $selectedCategory) {
                                Text("All Categories").tag(Optional<SkillCategory>.none)
                                ForEach(SkillCategory.allCases, id: \.self) { category in
                                    Text(category.rawValue).tag(Optional(category))
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Picker("Proficiency", selection: $selectedProficiency) {
                                Text("All Levels").tag(Optional<SkillProficiency>.none)
                                ForEach(SkillProficiency.allCases, id: \.self) { level in
                                    Text(level.rawValue).tag(Optional(level))
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Skills List
                LazyVStack(spacing: 16) {
                    ForEach(filteredSkills) { skill in
                        NavigationLink(destination: SkillDetailView(skill: skill)) {
                            SkillCard(skill: skill)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Skills")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewSkill = true
                } label: {
                    Label("New Skill", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewSkill) {
            SkillDetailView()
        }
    }
}

struct SkillCard: View {
    let skill: Skill
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(skill.name)
                    .font(.headline)
                
                Spacer()
                
                Text(skill.proficiency.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(proficiencyColor(for: skill.proficiency))
                    .cornerRadius(8)
            }
            
            if !skill.description.isEmpty {
                Text(skill.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text(skill.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                
                Spacer()
                
                if let nextLevel = skill.nextProficiencyLevel {
                    Text("Next: \(nextLevel.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !skill.goals.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Related Goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(skill.goals.prefix(3)) { goal in
                        HStack {
                            Image(systemName: goal.status == .completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(goal.isOverdue ? .red : .secondary)
                            Text(goal.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    if skill.goals.count > 3 {
                        Text("+\(skill.goals.count - 3) more goals")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !skill.resources.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resources")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(skill.resources.prefix(3)) { resource in
                        HStack {
                            Image(systemName: resource.status == .completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(.secondary)
                            Text(resource.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    if skill.resources.count > 3 {
                        Text("+\(skill.resources.count - 3) more resources")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !skill.developmentPlan.isEmpty {
                Text("Development Plan")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(skill.developmentPlan)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
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

#Preview {
    NavigationView {
        SkillsListView()
            .modelContainer(for: [Skill.self], inMemory: true)
    }
} 