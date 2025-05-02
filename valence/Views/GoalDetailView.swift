import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var targetDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
    @State private var status: GoalStatus = .notStarted
    @State private var priority: GoalPriority = .medium
    @State private var selectedPillars: Set<PillarType> = []
    @State private var notes = ""
    @State private var showingNewMilestone = false
    @State private var showingDeleteConfirmation = false
    
    let goal: ProfessionalGoal?
    
    init(goal: ProfessionalGoal? = nil) {
        self.goal = goal
        if let goal = goal {
            _title = State(initialValue: goal.title)
            _description = State(initialValue: goal.description)
            _startDate = State(initialValue: goal.startDate)
            _targetDate = State(initialValue: goal.targetDate)
            _status = State(initialValue: goal.status)
            _priority = State(initialValue: goal.priority)
            _selectedPillars = State(initialValue: Set(goal.pillarTypes))
            _notes = State(initialValue: goal.notes)
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
                
                Section("Timeline") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                }
                
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(GoalStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(GoalPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                }
                
                Section("Pillars") {
                    ForEach(PillarType.allCases, id: \.self) { pillar in
                        Toggle(pillar.rawValue, isOn: Binding(
                            get: { selectedPillars.contains(pillar) },
                            set: { isSelected in
                                if isSelected {
                                    selectedPillars.insert(pillar)
                                } else {
                                    selectedPillars.remove(pillar)
                                }
                            }
                        ))
                    }
                }
                
                Section("Milestones") {
                    if let goal = goal {
                        ForEach(goal.milestones) { milestone in
                            NavigationLink(destination: MilestoneDetailView(milestone: milestone)) {
                                MilestoneRow(milestone: milestone)
                            }
                        }
                        
                        Button {
                            showingNewMilestone = true
                        } label: {
                            Label("Add Milestone", systemImage: "plus")
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                if goal != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Goal", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
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
            .sheet(isPresented: $showingNewMilestone) {
                MilestoneDetailView(goal: goal)
            }
            .confirmationDialog("Delete Goal", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let goal = goal {
                        modelContext.delete(goal)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this goal? This action cannot be undone.")
            }
        }
    }
    
    private func save() {
        if let goal = goal {
            goal.title = title
            goal.description = description
            goal.startDate = startDate
            goal.targetDate = targetDate
            goal.status = status
            goal.priority = priority
            goal.pillarTypes = Array(selectedPillars)
            goal.notes = notes
            goal.updatedAt = Date()
        } else {
            let newGoal = ProfessionalGoal(
                title: title,
                description: description,
                startDate: startDate,
                targetDate: targetDate,
                status: status,
                priority: priority,
                pillarTypes: Array(selectedPillars),
                notes: notes
            )
            modelContext.insert(newGoal)
        }
    }
}

struct MilestoneRow: View {
    let milestone: GoalMilestone
    
    var body: some View {
        HStack {
            Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(milestone.isOverdue ? .red : .secondary)
            
            VStack(alignment: .leading) {
                Text(milestone.title)
                    .font(.headline)
                
                if let dueDate = milestone.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if milestone.isCompleted {
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
}

#Preview {
    GoalDetailView()
        .modelContainer(for: [ProfessionalGoal.self], inMemory: true)
} 