import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
    @State private var isCompleted = false
    @State private var priority: TaskPriority = .medium
    @State private var notes = ""
    @State private var showingDeleteConfirmation = false
    
    let task: ProjectTask?
    let project: Project?
    
    init(task: ProjectTask? = nil, project: Project? = nil) {
        self.task = task
        self.project = project
        if let task = task {
            _title = State(initialValue: task.title)
            _description = State(initialValue: task.description)
            _dueDate = State(initialValue: task.dueDate ?? Date().addingTimeInterval(7 * 24 * 60 * 60))
            _isCompleted = State(initialValue: task.isCompleted)
            _priority = State(initialValue: task.priority)
            _notes = State(initialValue: task.notes)
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
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                if task != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Task", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
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
            .confirmationDialog("Delete Task", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let task = task {
                        modelContext.delete(task)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
            }
        }
    }
    
    private func save() {
        if let task = task {
            task.title = title
            task.description = description
            task.dueDate = dueDate
            task.isCompleted = isCompleted
            task.priority = priority
            task.notes = notes
            task.updatedAt = Date()
            
            if isCompleted && task.completedDate == nil {
                task.completedDate = Date()
            } else if !isCompleted {
                task.completedDate = nil
            }
        } else if let project = project {
            let newTask = ProjectTask(
                title: title,
                description: description,
                dueDate: dueDate,
                isCompleted: isCompleted,
                priority: priority,
                notes: notes
            )
            project.tasks.append(newTask)
            modelContext.insert(newTask)
        }
    }
}

#Preview {
    TaskDetailView()
        .modelContainer(for: [Project.self], inMemory: true)
} 