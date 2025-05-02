import SwiftUI
import SwiftData

struct QuickActionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var action: QuickAction
    @State private var text: String = ""
    @State private var selectedPillar: PillarType?
    @State private var score: Int = 5
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                switch action.type {
                case .addFocus:
                    TextField("What's your focus for today?", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                case .addPillarScore:
                    Picker("Pillar", selection: $selectedPillar) {
                        ForEach(PillarType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type as PillarType?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    VStack(alignment: .leading) {
                        Text("Score: \(score)/10")
                        Slider(value: Binding(
                            get: { Double(score) },
                            set: { score = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    
                case .addWin, .addStruggle, .addInsight:
                    TextField("Enter \(action.type.rawValue.lowercased())", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(action.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAction()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        switch action.type {
        case .addFocus, .addWin, .addStruggle, .addInsight:
            return !text.isEmpty
        case .addPillarScore:
            return selectedPillar != nil
        }
    }
    
    private func saveAction() {
        switch action.type {
        case .addFocus:
            let newFocus = DailyFocus(focusText: text)
            modelContext.insert(newFocus)
            
        case .addPillarScore:
            if let pillarType = selectedPillar {
                if let existingPillar = try? modelContext.fetch(FetchDescriptor<Pillar>())
                    .first(where: { $0.type == pillarType }) {
                    existingPillar.addScoreEntry(score: score)
                } else {
                    let newPillar = Pillar(type: pillarType, score: score)
                    modelContext.insert(newPillar)
                }
            }
            
        case .addWin, .addStruggle, .addInsight:
            if let review = try? modelContext.fetch(FetchDescriptor<WeeklyReview>())
                .first(where: { $0.isCurrentWeek }) {
                switch action.type {
                case .addWin:
                    review.wins.append(text)
                case .addStruggle:
                    review.struggles.append(text)
                case .addInsight:
                    review.insights.append(text)
                default:
                    break
                }
            }
        }
    }
}

#Preview {
    QuickActionSheet(action: QuickAction(type: .addFocus, title: "Add Focus", order: 0))
        .modelContainer(for: [DailyFocus.self, Pillar.self, WeeklyReview.self], inMemory: true)
} 