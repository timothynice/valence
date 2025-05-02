import SwiftUI
import SwiftData

struct SkillDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var category: SkillCategory = .technical
    @State private var proficiency: SkillProficiency = .beginner
    @State private var developmentPlan = ""
    @State private var notes = ""
    @State private var showingNewResource = false
    @State private var showingDeleteConfirmation = false
    
    let skill: Skill?
    
    init(skill: Skill? = nil) {
        self.skill = skill
        if let skill = skill {
            _name = State(initialValue: skill.name)
            _description = State(initialValue: skill.description)
            _category = State(initialValue: skill.category)
            _proficiency = State(initialValue: skill.proficiency)
            _developmentPlan = State(initialValue: skill.developmentPlan)
            _notes = State(initialValue: skill.notes)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section("Category & Level") {
                    Picker("Category", selection: $category) {
                        ForEach(SkillCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    Picker("Proficiency", selection: $proficiency) {
                        ForEach(SkillProficiency.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }
                
                Section("Development Plan") {
                    TextEditor(text: $developmentPlan)
                        .frame(height: 100)
                }
                
                Section("Resources") {
                    if let skill = skill {
                        ForEach(skill.resources) { resource in
                            NavigationLink(destination: ResourceDetailView(resource: resource)) {
                                ResourceRow(resource: resource)
                            }
                        }
                        
                        Button {
                            showingNewResource = true
                        } label: {
                            Label("Add Resource", systemImage: "plus")
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                if skill != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Skill", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(skill == nil ? "New Skill" : "Edit Skill")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingNewResource) {
                ResourceDetailView(skill: skill)
            }
            .confirmationDialog("Delete Skill", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let skill = skill {
                        modelContext.delete(skill)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this skill? This action cannot be undone.")
            }
        }
    }
    
    private func save() {
        if let skill = skill {
            skill.name = name
            skill.description = description
            skill.category = category
            skill.proficiency = proficiency
            skill.developmentPlan = developmentPlan
            skill.notes = notes
            skill.updatedAt = Date()
        } else {
            let newSkill = Skill(
                name: name,
                description: description,
                category: category,
                proficiency: proficiency,
                developmentPlan: developmentPlan,
                notes: notes
            )
            modelContext.insert(newSkill)
        }
    }
}

struct ResourceRow: View {
    let resource: SkillResource
    
    var body: some View {
        HStack {
            Image(systemName: resource.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading) {
                Text(resource.title)
                    .font(.headline)
                
                Text(resource.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if resource.status == .completed {
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
}

#Preview {
    SkillDetailView()
        .modelContainer(for: [Skill.self], inMemory: true)
} 