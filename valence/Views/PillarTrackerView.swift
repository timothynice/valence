import SwiftUI
import SwiftData
import Charts

struct PillarTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pillars: [Pillar]
    @State private var selectedPillar: Pillar?
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !pillars.isEmpty {
                    ScrollView {
                        VStack(spacing: 20) {
                            PillarChart(pillars: pillars)
                                .frame(height: 300)
                                .padding()
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(pillars) { pillar in
                                    PillarCard(pillar: pillar)
                                        .onTapGesture {
                                            selectedPillar = pillar
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Pillars", systemImage: "chart.bar")
                    } description: {
                        Text("Add your first pillar to start tracking")
                    } actions: {
                        Button("Add Pillar") {
                            showingAddSheet = true
                        }
                    }
                }
            }
            .navigationTitle("Life Pillars")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Pillar", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddPillarSheet()
            }
            .sheet(item: $selectedPillar) { pillar in
                PillarDetailSheet(pillar: pillar)
            }
        }
    }
}

struct PillarChart: View {
    let pillars: [Pillar]
    
    var body: some View {
        Chart(pillars) { pillar in
            BarMark(
                x: .value("Pillar", pillar.type.rawValue),
                y: .value("Score", pillar.score)
            )
            .foregroundStyle(by: .value("Pillar", pillar.type.rawValue))
        }
        .chartYScale(domain: 0...10)
    }
}

struct PillarCard: View {
    let pillar: Pillar
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pillar.type.rawValue)
                .font(.headline)
            
            HStack {
                Text("Score:")
                    .foregroundColor(.secondary)
                Text("\(pillar.score)")
                    .font(.title2)
                    .bold()
            }
            
            ProgressView(value: Double(pillar.score), total: 10)
                .tint(progressColor)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var progressColor: Color {
        switch pillar.score {
        case 0...3: return .red
        case 4...6: return .yellow
        case 7...8: return .blue
        default: return .green
        }
    }
}

struct AddPillarSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: PillarType = .fitness // Updated default
    @State private var score: Double = 5
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Type", selection: $selectedType) {
                    ForEach(PillarType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
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
            .navigationTitle("New Pillar")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") { addPillar() }
            )
        }
    }
    
    private func addPillar() {
        let pillar = Pillar(type: selectedType, score: Int(score))
        pillar.notes = notes
        modelContext.insert(pillar)
        dismiss()
    }
}

struct PillarDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var pillar: Pillar
    @State private var newScore: Double
    @State private var notes: String
    
    init(pillar: Pillar) {
        self.pillar = pillar
        _newScore = State(initialValue: Double(pillar.score))
        _notes = State(initialValue: pillar.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Score") {
                    Slider(value: $newScore, in: 0...10, step: 1) {
                        Text("Score")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("10")
                    }
                    Text("Current Score: \(Int(newScore))")
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle(pillar.type.rawValue)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { updatePillar() }
            )
        }
    }
    
    private func updatePillar() {
        pillar.score = Int(newScore)
        pillar.notes = notes
        pillar.updatedAt = Date()
        dismiss()
    }
}

// Removed incorrect extension PillarType: CaseIterable
// The enum itself in Pillar.swift is already CaseIterable and provides the correct cases.

#Preview {
    PillarTrackerView()
        .modelContainer(for: Pillar.self, inMemory: true)
} 