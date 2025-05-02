import SwiftUI
import SwiftData

struct QuickJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var content: String = ""
    @State private var selectedMood: JournalEntryMood = .neutral
    @State private var selectedTags: Set<String> = []
    @State private var selectedPillars: Set<PillarType> = []
    @State private var showFollowUpPicker = false
    @State private var followUpDate: Date?
    @State private var newTag: String = ""
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                        .focused($isContentFocused)
                }
                
                Section("Mood") {
                    Picker("How are you feeling?", selection: $selectedMood) {
                        ForEach(JournalEntryMood.allCases, id: \.self) { mood in
                            Text(mood.rawValue).tag(mood)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Tags") {
                    ForEach(Array(selectedTags), id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button(action: { selectedTags.remove(tag) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Add tag", text: $newTag)
                        Button("Add") {
                            if !newTag.isEmpty {
                                selectedTags.insert(newTag)
                                newTag = ""
                            }
                        }
                        .disabled(newTag.isEmpty)
                    }
                }
                
                Section("Related Pillars") {
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
                
                Section {
                    Toggle("Set Follow-up", isOn: $showFollowUpPicker)
                    
                    if showFollowUpPicker {
                        DatePicker("Follow-up Date", selection: Binding(
                            get: { followUpDate ?? Date() },
                            set: { followUpDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("Quick Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                        dismiss()
                    }
                    .disabled(content.isEmpty)
                }
            }
            .onAppear {
                isContentFocused = true
            }
        }
    }
    
    private func saveEntry() {
        let entry = JournalEntry(
            content: content,
            mood: selectedMood,
            tags: Array(selectedTags),
            pillarTypes: Array(selectedPillars),
            isQuickEntry: true,
            followUpDate: showFollowUpPicker ? followUpDate : nil
        )
        modelContext.insert(entry)
        
        if let followUpDate = followUpDate {
            scheduleFollowUpNotification(for: entry, date: followUpDate)
        }
    }
    
    private func scheduleFollowUpNotification(for entry: JournalEntry, date: Date) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Journal Entry Follow-up"
        content.body = "Time to follow up on your journal entry: \(entry.content.prefix(50))..."
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: entry.id.uuidString, content: content, trigger: trigger)
        
        center.add(request)
    }
}

#Preview {
    QuickJournalView()
        .modelContainer(for: [JournalEntry.self], inMemory: true)
} 