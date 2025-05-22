import SwiftUI
import SwiftData // Keep for later integration

struct TodayView: View {
    @State private var dailyFocusText: String = ""
    @Environment(\.modelContext) private var modelContext // Uncommented for QuickJournalView
    // @EnvironmentObject var appState: AppState // Will add if TodayView needs it directly
    @State private var showingQuickJournalSheet = false // Added for sheet presentation

    // @Query private var dailyFocusItems: [DailyFocus] // For later SwiftData integration
    // @State private var currentDailyFocus: DailyFocus? // For later
    @State private var dailyQuote: String = ""
    @Query private var allPillars: [Pillar] // Fetch all pillars

    private static let inspirationalQuotes: [String] = [
        "The journey of a thousand miles begins with a single step. - Lao Tzu",
        "Your work is going to fill a large part of your life, and the only way to be truly satisfied is to do what you believe is great work. - Steve Jobs",
        "The best way to predict the future is to create it. - Peter Drucker",
        "Do not go where the path may lead, go instead where there is no path and leave a trail. - Ralph Waldo Emerson",
        "The only limit to our realization of tomorrow will be our doubts of today. - Franklin D. Roosevelt",
        "For I know the plans I have for you, declares the LORD, plans for welfare and not for evil, to give you a future and a hope. - Jeremiah 29:11",
        "I can do all things through him who strengthens me. - Philippians 4:13",
        "Trust in the LORD with all your heart, and do not lean on your own understanding. - Proverbs 3:5"
        // Add more quotes/verses as desired
    ]

    // Example of how you might load/save focus text later
    // func loadOrInitializeFocus() {
    //     let today = Calendar.current.startOfDay(for: Date())
    //     currentDailyFocus = dailyFocusItems.first { focus in
    //         Calendar.current.isDate(focus.date, inSameDayAs: today)
    //     }
    //     if let focus = currentDailyFocus {
    //         dailyFocusText = focus.focusText
    //     } else {
    //         // Optionally create a new one or just leave text blank
    //         // let newFocus = DailyFocus(date: today, focusText: "")
    //         // modelContext.insert(newFocus)
    //         // currentDailyFocus = newFocus
    //         dailyFocusText = ""
    //     }
    // }

    // func saveFocus() {
    //     if let focus = currentDailyFocus {
    //         focus.focusText = dailyFocusText
    //         focus.updatedAt = Date()
    //     } else {
    //         // Handle case where currentDailyFocus might be nil if not created on load
    //         let today = Calendar.current.startOfDay(for: Date())
    //         let newFocus = DailyFocus(date: today, focusText: dailyFocusText)
    //         // modelContext.insert(newFocus) // Requires modelContext
    //         // currentDailyFocus = newFocus
    //         print("New focus object would be created and saved here.")
    //     }
    //     print("Focus saved: \(dailyFocusText)")
    // }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - Reflection for Today
                    VStack(alignment: .leading) {
                        Text("Reflection for Today")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(dailyQuote)
                            .font(.system(.body, design: .serif).italic())
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(8)
                            .lineLimit(nil) 
                            .minimumScaleFactor(0.5)
                    }
                    .padding(.horizontal)

                    // MARK: - Daily Focus
                    VStack(alignment: .leading) {
                        Text("Daily Focus")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Using TextEditor for potential multi-line input
                        TextEditor(text: $dailyFocusText)
                            .frame(height: 75)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            // .onChange(of: dailyFocusText) { _, _ in saveFocus() } // Save on change
                        
                        Text("What's your one-line focus for today?")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // MARK: - Pillar Check-ins
                    VStack(alignment: .leading) {
                        Text("Pillar Check-ins")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(PillarType.allCases, id: \.self) { pillarType in
                                let pillar = allPillars.first { $0.type == pillarType }

                                HStack {
                                    Circle()
                                        .fill(healthIndicatorColor(for: pillar))
                                        .frame(width: 10, height: 10)
                                    
                                    Image(systemName: pillarType.iconName)
                                        .foregroundColor(pillarColor(for: pillarType))
                                        .frame(width: 24, height: 24)
                                    
                                    VStack(alignment: .leading) {
                                        Text(pillarType.rawValue)
                                            .font(.headline)
                                        if let p = pillar {
                                            Text("Target: \(p.weeklyTarget)/wk")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()

                                    if let p = pillar {
                                        Text("\(p.currentStreak)🔥")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .padding(.trailing, 5)
                                    } else {
                                        Text("0🔥") // Default if pillar not found
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 5)
                                    }

                                    Button {
                                        // Placeholder for check-in action
                                        // This will need to find or create the Pillar object
                                        // and then call addScoreEntry on it.
                                        if let p = pillar {
                                            // Example: Add a positive score entry
                                            // p.addScoreEntry(score: 1)
                                            print("\(p.type.rawValue) check-in tapped (existing pillar).")
                                        } else {
                                            // Handle case where pillar might not exist yet
                                            // Potentially create it:
                                            // let newPillar = Pillar(type: pillarType)
                                            // modelContext.insert(newPillar)
                                            // newPillar.addScoreEntry(score: 1)
                                            print("\(pillarType.rawValue) check-in tapped (new pillar would be created).")
                                        }
                                    } label: {
                                        Image(systemName: "checkmark.circle")
                                            .font(.title2)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Quick Journal Button
                    Button {
                        showingQuickJournalSheet = true
                    } label: {
                        Label("Quick Journal Entry", systemImage: "square.and.pencil")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Spacer() // Pushes content to the top if ScrollView is not filled
                }
                .padding(.vertical)
            }
            .navigationTitle("Everyline Today")
            .onAppear {
                selectDailyQuote()
                // loadOrInitializeFocus() // If you still need this
            }
            .sheet(isPresented: $showingQuickJournalSheet) {
                QuickJournalView()
                    // QuickJournalView already uses @Environment for modelContext,
                    // so it will inherit from TodayView's environment.
                    // No need to explicitly pass appState as QuickJournalView doesn't use it.
            }
        }
    }

    // Helper function for pillar colors
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

    private func healthIndicatorColor(for pillar: Pillar?) -> Color {
        guard let p = pillar, let history = p.scoreHistory,
              let lastEntry = history.filter({ $0.score > 0 }).sorted(by: { $0.date > $1.date }).first else {
            return .gray // No entries or no positive scores
        }
        if Calendar.current.isDateInToday(lastEntry.date) {
            return .green
        } else if Calendar.current.isDateInYesterday(lastEntry.date) {
            return .yellow
        }
        return .gray // Older than yesterday or no positive score entries
    }

    private func selectDailyQuote() {
        let currentDateString = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
        let lastQuoteDate = UserDefaults.standard.string(forKey: "lastQuoteDate")

        if lastQuoteDate != currentDateString || UserDefaults.standard.string(forKey: "currentDailyQuote") == nil {
            let selected = TodayView.inspirationalQuotes.randomElement() ?? "No quote available."
            UserDefaults.standard.set(selected, forKey: "currentDailyQuote")
            UserDefaults.standard.set(currentDateString, forKey: "lastQuoteDate")
            self.dailyQuote = selected
        } else {
            self.dailyQuote = UserDefaults.standard.string(forKey: "currentDailyQuote") ?? "Loading quote..."
        }
    }
}

#Preview {
    // Updated Preview to provide modelContext and sample Pillar data
    let container = try! ModelContainer(for: JournalEntry.self, DailyFocus.self, Pillar.self, ScoreEntry.self, inMemory: true)
    
    // Create sample pillars for the preview
    PillarType.allCases.forEach { pillarType in
        let pillar = Pillar(type: pillarType, score: Int.random(in: 0...10), weeklyTarget: Int.random(in: 3...7))
        // Optionally add some sample score history to test streak/health indicator
        if pillarType == .fitness { // Example: Add some history to fitness
            let today = Date()
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
            pillar.addScoreEntry(score: 1, date: twoDaysAgo) // Streak day 1
            pillar.addScoreEntry(score: 1, date: yesterday) // Streak day 2
//            pillar.addScoreEntry(score: 1, date: today)     // Streak day 3 (if uncommented)
        }
        if pillarType == .faith {
             pillar.addScoreEntry(score: 1, date: Date()) // Checked in today
        }
        container.mainContext.insert(pillar)
    }
    
    return TodayView()
        .modelContainer(container)
        // .environmentObject(AppState()) // Add if AppState is used by TodayView
}
