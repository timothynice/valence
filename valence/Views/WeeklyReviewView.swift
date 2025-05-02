import SwiftUI
import SwiftData

struct WeeklyReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeeklyReview.startDate, order: .reverse) private var reviews: [WeeklyReview]
    @State private var showingAddSheet = false
    
    var currentWeekReview: WeeklyReview? {
        reviews.first { $0.isCurrentWeek }
    }
    
    var body: some View {
        NavigationView {
            List {
                if let currentReview = currentWeekReview {
                    Section("Current Week") {
                        NavigationLink(destination: WeeklyReviewDetailView(review: currentReview)) {
                            WeeklyReviewRow(review: currentReview)
                        }
                    }
                }
                
                Section("Previous Reviews") {
                    ForEach(reviews.filter { !$0.isCurrentWeek }) { review in
                        NavigationLink(destination: WeeklyReviewDetailView(review: review)) {
                            WeeklyReviewRow(review: review)
                        }
                    }
                }
            }
            .navigationTitle("Weekly Reviews")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if currentWeekReview == nil {
                            showingAddSheet = true
                        }
                    }) {
                        Label("New Review", systemImage: "plus")
                    }
                    .disabled(currentWeekReview != nil)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddWeeklyReviewSheet()
            }
        }
    }
}

struct WeeklyReviewRow: View {
    let review: WeeklyReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.startDate, style: .date)
                Text("-")
                Text(review.endDate, style: .date)
                
                Spacer()
                
                if review.isCurrentWeek {
                    Text("Current")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if !review.wins.isEmpty {
                Text("Wins: \(review.wins.count)")
                    .font(.caption)
            }
            
            if !review.insights.isEmpty {
                Text("Insights: \(review.insights.count)")
                    .font(.caption)
            }
            
            if !review.pillarReflections.isEmpty {
                Text("Reflections: \(review.pillarReflections.count)")
                    .font(.caption)
            }
        }
    }
}

struct WeeklyReviewDetailView: View {
    @Bindable var review: WeeklyReview
    @State private var isEditing = false
    
    var body: some View {
        List {
            Section("Date Range") {
                HStack {
                    Text(review.startDate, style: .date)
                    Text("-")
                    Text(review.endDate, style: .date)
                }
            }
            
            Section("Wins") {
                if review.wins.isEmpty {
                    Text("No wins recorded")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(review.wins, id: \.self) { win in
                        Text("• \(win)")
                    }
                }
            }
            
            Section("Struggles") {
                if review.struggles.isEmpty {
                    Text("No struggles recorded")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(review.struggles, id: \.self) { struggle in
                        Text("• \(struggle)")
                    }
                }
            }
            
            Section("Insights") {
                if review.insights.isEmpty {
                    Text("No insights recorded")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(review.insights, id: \.self) { insight in
                        Text("• \(insight)")
                    }
                }
            }
            
            Section("Next Week Focus") {
                if review.nextWeekFocus.isEmpty {
                    Text("No focus set for next week")
                        .foregroundColor(.secondary)
                } else {
                    Text(review.nextWeekFocus)
                }
            }
            
            Section("Pillar Reflections") {
                if review.pillarReflections.isEmpty {
                    Text("No pillar reflections recorded")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(review.pillarReflections) { reflection in
                        VStack(alignment: .leading) {
                            Text(reflection.pillarType.rawValue)
                                .font(.headline)
                            HStack {
                                Text("Score: \(reflection.score)")
                                    .foregroundColor(.secondary)
                            }
                            if !reflection.notes.isEmpty {
                                Text(reflection.notes)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Weekly Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditWeeklyReviewSheet(review: review)
        }
    }
}

struct AddWeeklyReviewSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var wins: [String] = []
    @State private var struggles: [String] = []
    @State private var insights: [String] = []
    @State private var nextWeekFocus = ""
    @State private var reflections: [PillarReflection] = []
    @State private var newItemText = ""
    @State private var selectedSection: ReviewSection = .wins
    
    enum ReviewSection: String, CaseIterable {
        case wins = "Wins"
        case struggles = "Struggles"
        case insights = "Insights"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Add Items") {
                    Picker("Section", selection: $selectedSection) {
                        ForEach(ReviewSection.allCases, id: \.self) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        TextField("New item", text: $newItemText)
                        Button("Add") {
                            addItem()
                        }
                        .disabled(newItemText.isEmpty)
                    }
                }
                
                Section("Wins") {
                    ForEach(wins, id: \.self) { win in
                        HStack {
                            Text(win)
                            Spacer()
                            Button(action: { wins.removeAll { $0 == win } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section("Struggles") {
                    ForEach(struggles, id: \.self) { struggle in
                        HStack {
                            Text(struggle)
                            Spacer()
                            Button(action: { struggles.removeAll { $0 == struggle } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section("Insights") {
                    ForEach(insights, id: \.self) { insight in
                        HStack {
                            Text(insight)
                            Spacer()
                            Button(action: { insights.removeAll { $0 == insight } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section("Next Week Focus") {
                    TextEditor(text: $nextWeekFocus)
                        .frame(height: 100)
                }
                
                Section("Pillar Reflections") {
                    ForEach(PillarType.allCases, id: \.self) { pillarType in
                        NavigationLink(destination: AddPillarReflectionView(
                            pillarType: pillarType,
                            reflections: $reflections
                        )) {
                            if let reflection = reflections.first(where: { $0.pillarType == pillarType }) {
                                HStack {
                                    Text(pillarType.rawValue)
                                    Spacer()
                                    Text("Score: \(reflection.score)")
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text(pillarType.rawValue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Weekly Review")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { saveReview() }
            )
        }
    }
    
    private func addItem() {
        guard !newItemText.isEmpty else { return }
        switch selectedSection {
        case .wins:
            wins.append(newItemText)
        case .struggles:
            struggles.append(newItemText)
        case .insights:
            insights.append(newItemText)
        }
        newItemText = ""
    }
    
    private func saveReview() {
        let review = WeeklyReview()
        review.wins = wins
        review.struggles = struggles
        review.insights = insights
        review.nextWeekFocus = nextWeekFocus
        review.pillarReflections = reflections
        modelContext.insert(review)
        dismiss()
    }
}

struct EditWeeklyReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var review: WeeklyReview
    @State private var wins: [String]
    @State private var struggles: [String]
    @State private var insights: [String]
    @State private var nextWeekFocus: String
    @State private var reflections: [PillarReflection]
    @State private var newItemText = ""
    @State private var selectedSection: AddWeeklyReviewSheet.ReviewSection = .wins
    
    init(review: WeeklyReview) {
        self.review = review
        _wins = State(initialValue: review.wins)
        _struggles = State(initialValue: review.struggles)
        _insights = State(initialValue: review.insights)
        _nextWeekFocus = State(initialValue: review.nextWeekFocus)
        _reflections = State(initialValue: review.pillarReflections)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Add Items") {
                    Picker("Section", selection: $selectedSection) {
                        ForEach(AddWeeklyReviewSheet.ReviewSection.allCases, id: \.self) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        TextField("New item", text: $newItemText)
                        Button("Add") {
                            addItem()
                        }
                        .disabled(newItemText.isEmpty)
                    }
                }
                
                Section("Wins") {
                    ForEach(wins, id: \.self) { win in
                        HStack {
                            Text(win)
                            Spacer()
                            Button(action: { wins.removeAll { $0 == win } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section("Struggles") {
                    ForEach(struggles, id: \.self) { struggle in
                        HStack {
                            Text(struggle)
                            Spacer()
                            Button(action: { struggles.removeAll { $0 == struggle } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section("Insights") {
                    ForEach(insights, id: \.self) { insight in
                        HStack {
                            Text(insight)
                            Spacer()
                            Button(action: { insights.removeAll { $0 == insight } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section("Next Week Focus") {
                    TextEditor(text: $nextWeekFocus)
                        .frame(height: 100)
                }
                
                Section("Pillar Reflections") {
                    ForEach(PillarType.allCases, id: \.self) { pillarType in
                        NavigationLink(destination: AddPillarReflectionView(
                            pillarType: pillarType,
                            reflections: $reflections
                        )) {
                            if let reflection = reflections.first(where: { $0.pillarType == pillarType }) {
                                HStack {
                                    Text(pillarType.rawValue)
                                    Spacer()
                                    Text("Score: \(reflection.score)")
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text(pillarType.rawValue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Weekly Review")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { updateReview() }
            )
        }
    }
    
    private func addItem() {
        guard !newItemText.isEmpty else { return }
        switch selectedSection {
        case .wins:
            wins.append(newItemText)
        case .struggles:
            struggles.append(newItemText)
        case .insights:
            insights.append(newItemText)
        }
        newItemText = ""
    }
    
    private func updateReview() {
        review.wins = wins
        review.struggles = struggles
        review.insights = insights
        review.nextWeekFocus = nextWeekFocus
        review.pillarReflections = reflections
        review.updatedAt = Date()
        dismiss()
    }
}

struct AddPillarReflectionView: View {
    let pillarType: PillarType
    @Binding var reflections: [PillarReflection]
    @Environment(\.dismiss) private var dismiss
    @State private var score: Double
    @State private var notes: String
    
    init(pillarType: PillarType, reflections: Binding<[PillarReflection]>) {
        self.pillarType = pillarType
        self._reflections = reflections
        
        let existingReflection = reflections.wrappedValue.first { $0.pillarType == pillarType }
        _score = State(initialValue: Double(existingReflection?.score ?? 5))
        _notes = State(initialValue: existingReflection?.notes ?? "")
    }
    
    var body: some View {
        Form {
            Section("Score") {
                Slider(value: $score, in: 0...10, step: 1) {
                    Text("Score")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("10")
                }
                Text("Current Score: \(Int(score))")
            }
            
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(height: 100)
            }
        }
        .navigationTitle(pillarType.rawValue)
        .navigationBarItems(
            trailing: Button("Save") {
                saveReflection()
                dismiss()
            }
        )
    }
    
    private func saveReflection() {
        if let index = reflections.firstIndex(where: { $0.pillarType == pillarType }) {
            reflections[index].score = Int(score)
            reflections[index].notes = notes
        } else {
            let reflection = PillarReflection(pillarType: pillarType, score: Int(score))
            reflection.notes = notes
            reflections.append(reflection)
        }
    }
}

#Preview {
    WeeklyReviewView()
        .modelContainer(for: WeeklyReview.self, inMemory: true)
} 