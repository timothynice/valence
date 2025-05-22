import SwiftUI
import SwiftData

struct MenuBarWidgetView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState // For opening the app

    @Query(sort: [SortDescriptor(\Pillar.type, order: .forward)]) private var allPillars: [Pillar]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) { // Increased spacing a bit
            Text("Everyline Quick View")
                .font(.headline)
                .padding(.bottom, 5)

            // Daily Focus - Placeholder for now
            HStack {
                Image(systemName: "pin.fill")
                    .foregroundColor(.gray)
                Text("Set your daily focus in the app.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Divider()
                .padding(.vertical, 2)

            Text("Pillar Streaks:")
                .font(.caption.bold())
                .padding(.bottom, 2)

            if allPillars.isEmpty {
                Text("No pillars set up yet. Open the app to add them.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical)
            } else {
                ForEach(allPillars) { pillar in
                    HStack(spacing: 8) { // Added spacing
                        Image(systemName: pillar.type.iconName)
                            .foregroundColor(pillarColor(for: pillar.type)) // Use helper for color consistency
                        Text(pillar.type.rawValue)
                            .font(.caption)
                        Spacer()
                        Text("\(pillar.currentStreak)🔥")
                            .font(.caption)
                            .foregroundColor(.orange) // Explicit color for streak
                        
                        Button {
                            checkIn(pillar: pillar)
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.secondary) // Subtle color for checkmark
                        }
                        .buttonStyle(.plain) 
                    }
                    .padding(.vertical, 2) // Reduced vertical padding for rows
                }
            }

            Divider()
                .padding(.vertical, 2)

            Button {
                appState.openMainWindow()
            } label: {
                HStack { // Ensure label is full width for clickability
                    Spacer()
                    Label("Open App", systemImage: "arrow.up.forward.app")
                    Spacer()
                }
            }
            .buttonStyle(.bordered) // Make button more prominent
            .padding(.top, 5)
        }
        .padding()
        .frame(width: 280) // Set a fixed width
    }

    private func checkIn(pillar: Pillar) {
        // Create a new ScoreEntry for today with score 1
        // Assumes ScoreEntry is defined in Pillar.swift (as per last successful read of Pillar.swift)
        let newEntry = ScoreEntry(score: 1, date: Date(), pillar: pillar)
        modelContext.insert(newEntry)
        
        // Also update the pillar's main score and add to its history
        // The Pillar's addScoreEntry method already handles this
        pillar.addScoreEntry(score: 1, date: Date()) 

        do {
            try modelContext.save()
            print("Checked in for \(pillar.type.rawValue)")
        } catch {
            // This is a menu bar widget, so extensive error handling might be overkill.
            // Logging to console is fine.
            print("Error saving check-in for \(pillar.type.rawValue): \(error)")
        }
    }
    
    // Helper function for pillar colors (consistent with TodayView)
    private func pillarColor(for pillarType: PillarType) -> Color {
        switch pillarType {
        case .faith: return .purple
        case .family: return .orange
        case .fitness: return .green
        case .finances: return .blue
        case .freedom: return .yellow
        case .fun: return .pink
        }
    }
}

#Preview {
    // Define the schema including Pillar and ScoreEntry
    // ScoreEntry is assumed to be defined within Pillar.swift for this preview.
    // If it were a separate @Model, it would be listed directly here.
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: [Pillar.self, ScoreEntry.self], configurations: config)
    
    // Create sample pillars for the preview
    PillarType.allCases.forEach { pType in
        let pillar = Pillar(type: pType, score: Int.random(in: 0...2), weeklyTarget: 5)
        container.mainContext.insert(pillar)
        
        // Optionally, add some score entries to test streaks
        if pType == .fitness { // Example: Add some history to fitness
            let today = Date()
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            // Create ScoreEntry instances and associate them if your Pillar.addScoreEntry doesn't do it
             let entry1 = ScoreEntry(score: 1, date: yesterday, pillar: pillar)
             container.mainContext.insert(entry1)
             pillar.scoreHistory?.append(entry1) // Manually append if addScoreEntry doesn't
        }
    }

    return MenuBarWidgetView()
        .modelContainer(container)
        .environmentObject(AppState())
} 