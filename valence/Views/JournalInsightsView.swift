import SwiftUI
import SwiftData
import Charts

struct JournalInsightsView: View {
    @Query private var entries: [JournalEntry]
    @State private var timeRange: TimeRange = .month
    @State private var selectedPillar: PillarType?
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    private var filteredEntries: [JournalEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        return entries.filter { entry in
            let matchesPillar = selectedPillar == nil || entry.pillarTypes.contains(selectedPillar!)
            
            let isInRange: Bool
            switch timeRange {
            case .week:
                isInRange = calendar.isDate(entry.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                isInRange = calendar.isDate(entry.date, equalTo: now, toGranularity: .month)
            case .year:
                isInRange = calendar.isDate(entry.date, equalTo: now, toGranularity: .year)
            }
            
            return matchesPillar && isInRange
        }
    }
    
    private var moodDistribution: [(mood: JournalEntryMood, count: Int)] {
        let counts = Dictionary(grouping: filteredEntries, by: \.mood)
            .mapValues(\.count)
        return JournalEntryMood.allCases.map { mood in
            (mood: mood, count: counts[mood] ?? 0)
        }
    }
    
    private var pillarDistribution: [(pillar: PillarType, count: Int)] {
        let counts = Dictionary(grouping: filteredEntries.flatMap(\.pillarTypes), by: { $0 })
            .mapValues(\.count)
        return PillarType.allCases.map { pillar in
            (pillar: pillar, count: counts[pillar] ?? 0)
        }
    }
    
    private var entryFrequency: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return grouped.map { (date: $0.key, count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }
    
    private var mostCommonTags: [(tag: String, count: Int)] {
        let counts = Dictionary(grouping: filteredEntries.flatMap(\.tags), by: { $0 })
            .mapValues(\.count)
        return counts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { (tag: $0.key, count: $0.value) }
    }
    
    private var followUpStats: (total: Int, completed: Int, overdue: Int) {
        let followUps = filteredEntries.filter { $0.requiresFollowUp }
        return (
            total: followUps.count,
            completed: followUps.filter { $0.isFollowedUp }.count,
            overdue: followUps.filter { $0.isOverdue }.count
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range Picker
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Pillar Filter
                Picker("Pillar", selection: $selectedPillar) {
                    Text("All Pillars").tag(Optional<PillarType>.none)
                    ForEach(PillarType.allCases, id: \.self) { pillar in
                        Text(pillar.rawValue).tag(Optional(pillar))
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                
                // Summary Cards
                HStack {
                    SummaryCard(title: "Total Entries", value: "\(filteredEntries.count)")
                    SummaryCard(title: "Follow-ups", value: "\(followUpStats.completed)/\(followUpStats.total)")
                    SummaryCard(title: "Overdue", value: "\(followUpStats.overdue)")
                }
                .padding(.horizontal)
                
                // Mood Distribution
                VStack(alignment: .leading) {
                    Text("Mood Distribution")
                        .font(.headline)
                    Chart(moodDistribution) { item in
                        BarMark(
                            x: .value("Mood", item.mood.rawValue),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(by: .value("Mood", item.mood.rawValue))
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Entry Frequency
                VStack(alignment: .leading) {
                    Text("Entry Frequency")
                        .font(.headline)
                    Chart(entryFrequency) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(.blue)
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Pillar Distribution
                VStack(alignment: .leading) {
                    Text("Pillar Distribution")
                        .font(.headline)
                    Chart(pillarDistribution) { item in
                        BarMark(
                            x: .value("Pillar", item.pillar.rawValue),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(by: .value("Pillar", item.pillar.rawValue))
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Most Common Tags
                VStack(alignment: .leading) {
                    Text("Most Common Tags")
                        .font(.headline)
                    ForEach(mostCommonTags, id: \.tag) { item in
                        HStack {
                            Text("#\(item.tag)")
                            Spacer()
                            Text("\(item.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    JournalInsightsView()
        .modelContainer(for: [JournalEntry.self], inMemory: true)
} 