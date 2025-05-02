import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
    @State private var status: ProjectStatus = .notStarted
    @State private var priority: ProjectPriority = .medium
    @State private var notes = ""
    @State private var showingNewTask = false
    @State private var showingDeleteConfirmation = false
    
    let project: Project?
    
    init(project: Project? = nil) {
        self.project = project
        if let project = project {
            _title = State(initialValue: project.title)
            _description = State(initialValue: project.description)
            _startDate = State(initialValue: project.startDate)
            _endDate = State(initialValue: project.endDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60))
            _status = State(initialValue: project.status)
            _priority = State(initialValue: project.priority)
            _notes = State(initialValue: project.notes)
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
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(ProjectPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                }
                
                Section("Tasks") {
                    if let project = project {
                        ForEach(project.tasks) { task in
                            NavigationLink(destination: TaskDetailView(task: task)) {
                                TaskRow(task: task)
                            }
                        }
                        
                        Button {
                            showingNewTask = true
                        } label: {
                            Label("Add Task", systemImage: "plus")
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                if project != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Project", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(project == nil ? "New Project" : "Edit Project")
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
            .sheet(isPresented: $showingNewTask) {
                TaskDetailView(project: project)
            }
            .confirmationDialog("Delete Project", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let project = project {
                        modelContext.delete(project)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this project? This action cannot be undone.")
            }
        }
    }
    
    private func save() {
        if let project = project {
            project.title = title
            project.description = description
            project.startDate = startDate
            project.endDate = endDate
            project.status = status
            project.priority = priority
            project.notes = notes
            project.updatedAt = Date()
        } else {
            let newProject = Project(
                title: title,
                description: description,
                startDate: startDate,
                endDate: endDate,
                status: status,
                priority: priority,
                notes: notes
            )
            modelContext.insert(newProject)
        }
    }
}

struct TaskRow: View {
    let task: ProjectTask
    
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isOverdue ? .red : .secondary)
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                
                if let dueDate = task.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if task.isCompleted {
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
}

#Preview {
    ProjectDetailView()
        .modelContainer(for: [Project.self], inMemory: true)
} 