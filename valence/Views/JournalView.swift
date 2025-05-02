import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
    var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return entries
        }
        return entries.filter { entry in
            entry.content.localizedCaseInsensitiveContains(searchText) ||
            entry.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredEntries) { entry in
                    NavigationLink(destination: JournalEntryDetailView(entry: entry)) {
                        JournalEntryRow(entry: entry)
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Entry", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search entries")
            .sheet(isPresented: $showingAddSheet) {
                AddJournalEntrySheet()
            }
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredEntries[index])
            }
        }
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                MoodIndicator(mood: entry.mood)
            }
            
            Text(entry.content)
                .lineLimit(2)
                .font(.body)
            
            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(entry.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct JournalEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: JournalEntry
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(entry.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    MoodIndicator(mood: entry.mood)
                }
                
                Text(entry.content)
                    .font(.body)
                
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                if !entry.pillarTypes.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Related Areas:")
                            .font(.headline)
                        ForEach(entry.pillarTypes, id: \.self) { pillar in
                            Text("• \(pillar.rawValue)")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditJournalEntrySheet(entry: entry)
        }
    }
}

struct AddJournalEntrySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var mood: Mood = .neutral
    @State private var selectedPillars: Set<PillarType> = []
    @State private var tagInput = ""
    @State private var tags: Set<String> = []
    
    var body: some View {
        NavigationView {
            Form {
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(height: 150)
                }
                
                Section("Mood") {
                    Picker("Mood", selection: $mood) {
                        ForEach([Mood.veryNegative, .negative, .neutral, .positive, .veryPositive], id: \.self) { mood in
                            Text(mood.rawValue).tag(mood)
                        }
                    }
                }
                
                Section("Related Areas") {
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
                
                Section("Tags") {
                    HStack {
                        TextField("Add tag", text: $tagInput)
                        Button("Add") {
                            if !tagInput.isEmpty {
                                tags.insert(tagInput)
                                tagInput = ""
                            }
                        }
                    }
                    
                    ForEach(Array(tags), id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button(action: { tags.remove(tag) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    addEntry()
                }
                .disabled(content.isEmpty)
            )
        }
    }
    
    private func addEntry() {
        let entry = JournalEntry(content: content, mood: mood)
        entry.tags = Array(tags)
        entry.pillarTypes = Array(selectedPillars)
        modelContext.insert(entry)
        dismiss()
    }
}

struct EditJournalEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: JournalEntry
    @State private var content: String
    @State private var mood: Mood
    @State private var selectedPillars: Set<PillarType>
    @State private var tagInput = ""
    @State private var tags: Set<String>
    
    init(entry: JournalEntry) {
        self.entry = entry
        _content = State(initialValue: entry.content)
        _mood = State(initialValue: entry.mood)
        _selectedPillars = State(initialValue: Set(entry.pillarTypes))
        _tags = State(initialValue: Set(entry.tags))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(height: 150)
                }
                
                Section("Mood") {
                    Picker("Mood", selection: $mood) {
                        ForEach([Mood.veryNegative, .negative, .neutral, .positive, .veryPositive], id: \.self) { mood in
                            Text(mood.rawValue).tag(mood)
                        }
                    }
                }
                
                Section("Related Areas") {
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
                
                Section("Tags") {
                    HStack {
                        TextField("Add tag", text: $tagInput)
                        Button("Add") {
                            if !tagInput.isEmpty {
                                tags.insert(tagInput)
                                tagInput = ""
                            }
                        }
                    }
                    
                    ForEach(Array(tags), id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button(action: { tags.remove(tag) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    updateEntry()
                }
                .disabled(content.isEmpty)
            )
        }
    }
    
    private func updateEntry() {
        entry.content = content
        entry.mood = mood
        entry.tags = Array(tags)
        entry.pillarTypes = Array(selectedPillars)
        entry.updatedAt = Date()
        dismiss()
    }
}

struct MoodIndicator: View {
    let mood: Mood
    
    var body: some View {
        HStack {
            Image(systemName: moodIcon)
                .foregroundColor(moodColor)
            Text(mood.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var moodIcon: String {
        switch mood {
        case .veryNegative: return "face.smiling.inverse"
        case .negative: return "face.frown"
        case .neutral: return "face.neutral"
        case .positive: return "face.smiling"
        case .veryPositive: return "face.smiling.inverse"
        }
    }
    
    private var moodColor: Color {
        switch mood {
        case .veryNegative: return .red
        case .negative: return .orange
        case .neutral: return .yellow
        case .positive: return .green
        case .veryPositive: return .blue
        }
    }
}

#Preview {
    NavigationView {
        JournalView()
            .modelContainer(for: [JournalEntry.self], inMemory: true)
    }
} 