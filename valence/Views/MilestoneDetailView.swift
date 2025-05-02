import SwiftUI
import SwiftData

struct MilestoneDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
    @State private var isCompleted = false
    @State private var notes = ""
    @State private var showingDeleteConfirmation = false
    
    let milestone: GoalMilestone?
    let goal: ProfessionalGoal?
    
    init(milestone: GoalMilestone? = nil, goal: ProfessionalGoal? = nil) {
        self.milestone = milestone
        self.goal = goal
        if let milestone = milestone {
            _title = State(initialValue: milestone.title)
            _description = State(initialValue: milestone.description)
            _dueDate = State(initialValue: milestone.dueDate ?? Date().addingTimeInterval(7 * 24 * 60 * 60))
            _isCompleted = State(initialValue: milestone.isCompleted)
            _notes = State(initialValue: milestone.notes)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section("Due Date") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
                
                Section("Status") {
                    Toggle("Completed", isOn: $isCompleted)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                if milestone != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Milestone", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(milestone == nil ? "New Milestone" : "Edit Milestone")
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
                    .disabled(title.isEmpty)
                }
            }
            .confirmationDialog("Delete Milestone", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let milestone = milestone {
                        modelContext.delete(milestone)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this milestone? This action cannot be undone.")
            }
        }
    }
    
    private func save() {
        if let milestone = milestone {
            milestone.title = title
            milestone.description = description
            milestone.dueDate = dueDate
            milestone.isCompleted = isCompleted
            milestone.notes = notes
            milestone.updatedAt = Date()
            
            if isCompleted && milestone.completedDate == nil {
                milestone.completedDate = Date()
            } else if !isCompleted {
                milestone.completedDate = nil
            }
        } else if let goal = goal {
            let newMilestone = GoalMilestone(
                title: title,
                description: description,
                dueDate: dueDate,
                isCompleted: isCompleted,
                notes: notes
            )
            goal.milestones.append(newMilestone)
            modelContext.insert(newMilestone)
        }
    }
}

#Preview {
    MilestoneDetailView()
        .modelContainer(for: [ProfessionalGoal.self], inMemory: true)
} 