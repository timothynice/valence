import SwiftUI
import SwiftData

struct GoalsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [ProfessionalGoal]
    @State private var searchText = ""
    @State private var selectedStatus: GoalStatus?
    @State private var selectedPriority: GoalPriority?
    @State private var selectedPillar: PillarType?
    @State private var showingNewGoal = false
    
    private var filteredGoals: [ProfessionalGoal] {
        goals.filter { goal in
            let matchesSearch = searchText.isEmpty || 
                goal.title.localizedCaseInsensitiveContains(searchText) ||
                goal.description.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = selectedStatus == nil || goal.status == selectedStatus
            let matchesPriority = selectedPriority == nil || goal.priority == selectedPriority
            let matchesPillar = selectedPillar == nil || goal.pillarTypes.contains(selectedPillar!)
            
            return matchesSearch && matchesStatus && matchesPriority && matchesPillar
        }
        .sorted { $0.targetDate < $1.targetDate }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search and Filters
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Picker("Status", selection: $selectedStatus) {
                                Text("All Statuses").tag(Optional<GoalStatus>.none)
                                ForEach(GoalStatus.allCases, id: \.self) { status in
                                    Text(status.rawValue).tag(Optional(status))
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Picker("Priority", selection: $selectedPriority) {
                                Text("All Priorities").tag(Optional<GoalPriority>.none)
                                ForEach(GoalPriority.allCases, id: \.self) { priority in
                                    Text(priority.rawValue).tag(Optional(priority))
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Picker("Pillar", selection: $selectedPillar) {
                                Text("All Pillars").tag(Optional<PillarType>.none)
                                ForEach(PillarType.allCases, id: \.self) { pillar in
                                    Text(pillar.rawValue).tag(Optional(pillar))
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Goals List
                LazyVStack(spacing: 16) {
                    ForEach(filteredGoals) { goal in
                        NavigationLink(destination: GoalDetailView(goal: goal)) {
                            GoalCard(goal: goal)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewGoal = true
                } label: {
                    Label("New Goal", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewGoal) {
            GoalDetailView()
        }
    }
}

struct GoalCard: View {
    let goal: ProfessionalGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                
                Spacer()
                
                Text(goal.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: goal.status))
                    .cornerRadius(8)
            }
            
            if !goal.description.isEmpty {
                Text(goal.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Label("\(goal.progressPercentage)%", systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !goal.pillarTypes.isEmpty {
                    ForEach(goal.pillarTypes, id: \.self) { pillar in
                        Text(pillar.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                    }
                }
            }
            
            HStack {
                Text("Due: \(goal.targetDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(goal.isOverdue ? .red : .secondary)
                
                Spacer()
                
                Text(goal.priority.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor(for: goal.priority))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    private func statusColor(for status: GoalStatus) -> Color {
        switch status {
        case .notStarted: return .gray.opacity(0.2)
        case .inProgress: return .blue.opacity(0.2)
        case .completed: return .green.opacity(0.2)
        case .onHold: return .orange.opacity(0.2)
        case .cancelled: return .red.opacity(0.2)
        }
    }
    
    private func priorityColor(for priority: GoalPriority) -> Color {
        switch priority {
        case .low: return .gray.opacity(0.2)
        case .medium: return .blue.opacity(0.2)
        case .high: return .orange.opacity(0.2)
        case .critical: return .red.opacity(0.2)
        }
    }
}

#Preview {
    NavigationView {
        GoalsListView()
            .modelContainer(for: [ProfessionalGoal.self], inMemory: true)
    }
} 