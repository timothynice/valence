import SwiftUI
import SwiftData

struct ResourceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var url = ""
    @State private var type: ResourceType = .course
    @State private var status: ResourceStatus = .notStarted
    @State private var notes = ""
    @State private var showingDeleteConfirmation = false
    
    let resource: SkillResource?
    let skill: Skill?
    
    init(resource: SkillResource? = nil, skill: Skill? = nil) {
        self.resource = resource
        self.skill = skill
        if let resource = resource {
            _title = State(initialValue: resource.title)
            _url = State(initialValue: resource.url)
            _type = State(initialValue: resource.type)
            _status = State(initialValue: resource.status)
            _notes = State(initialValue: resource.notes)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("URL", text: $url)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                }
                
                Section("Type & Status") {
                    Picker("Type", selection: $type) {
                        ForEach(ResourceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(ResourceStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                if resource != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Resource", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(resource == nil ? "New Resource" : "Edit Resource")
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
            .confirmationDialog("Delete Resource", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let resource = resource {
                        modelContext.delete(resource)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this resource? This action cannot be undone.")
            }
        }
    }
    
    private func save() {
        if let resource = resource {
            resource.title = title
            resource.url = url
            resource.type = type
            resource.status = status
            resource.notes = notes
            resource.updatedAt = Date()
        } else if let skill = skill {
            let newResource = SkillResource(
                title: title,
                url: url,
                type: type,
                status: status,
                notes: notes
            )
            skill.resources.append(newResource)
            modelContext.insert(newResource)
        }
    }
}

#Preview {
    ResourceDetailView()
        .modelContainer(for: [Skill.self], inMemory: true)
} 