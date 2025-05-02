import SwiftUI
import SwiftData
import Charts

struct DependencyGraphView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [ProfessionalGoal]
    @Query private var projects: [Project]
    @Query private var skills: [Skill]
    
    @State private var selectedItem: AnyHashable?
    @State private var searchText = ""
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    private var nodes: [Node] {
        var nodes: [Node] = []
        
        // Add goals as nodes
        for goal in goals {
            nodes.append(Node(
                id: goal.id,
                title: goal.title,
                type: .goal,
                status: goal.status,
                priority: goal.priority
            ))
        }
        
        // Add projects as nodes
        for project in projects {
            nodes.append(Node(
                id: project.id,
                title: project.title,
                type: .project,
                status: project.status,
                priority: project.priority
            ))
        }
        
        // Add skills as nodes
        for skill in skills {
            nodes.append(Node(
                id: skill.id,
                title: skill.name,
                type: .skill,
                proficiency: skill.proficiency
            ))
        }
        
        return nodes
    }
    
    private var edges: [Edge] {
        var edges: [Edge] = []
        
        // Add goal-project relationships
        for goal in goals {
            for project in goal.projects {
                edges.append(Edge(
                    source: goal.id,
                    target: project.id,
                    type: .goalProject
                ))
            }
        }
        
        // Add goal-skill relationships
        for goal in goals {
            for skill in goal.skills {
                edges.append(Edge(
                    source: goal.id,
                    target: skill.id,
                    type: .goalSkill
                ))
            }
        }
        
        // Add project-skill relationships
        for project in projects {
            for skill in project.skills {
                edges.append(Edge(
                    source: project.id,
                    target: skill.id,
                    type: .projectSkill
                ))
            }
        }
        
        return edges
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                GridView()
                    .opacity(0.1)
                
                // Graph
                GraphView(
                    nodes: nodes,
                    edges: edges,
                    selectedItem: $selectedItem,
                    scale: scale,
                    offset: offset
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastOffset.width + value
                        }
                        .onEnded { _ in
                            lastOffset.width = scale
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                
                // Search and filter controls
                VStack {
                    SearchBar(text: $searchText)
                        .padding()
                    
                    Spacer()
                    
                    // Legend
                    LegendView()
                        .padding()
                }
            }
        }
        .navigationTitle("Dependency Graph")
    }
}

struct Node: Identifiable, Hashable {
    let id: UUID
    let title: String
    let type: NodeType
    var status: GoalStatus?
    var priority: GoalPriority?
    var proficiency: SkillProficiency?
    
    enum NodeType {
        case goal
        case project
        case skill
    }
}

struct Edge: Identifiable {
    let id = UUID()
    let source: UUID
    let target: UUID
    let type: EdgeType
    
    enum EdgeType {
        case goalProject
        case goalSkill
        case projectSkill
    }
}

struct GraphView: View {
    let nodes: [Node]
    let edges: [Edge]
    @Binding var selectedItem: AnyHashable?
    let scale: CGFloat
    let offset: CGSize
    
    var body: some View {
        ZStack {
            // Draw edges
            ForEach(edges) { edge in
                EdgeView(edge: edge, nodes: nodes)
                    .stroke(edgeColor(for: edge.type), lineWidth: 1)
            }
            
            // Draw nodes
            ForEach(nodes) { node in
                NodeView(node: node, isSelected: selectedItem?.id == node.id)
                    .onTapGesture {
                        selectedItem = node
                    }
                    .position(nodePosition(for: node))
            }
        }
        .scaleEffect(scale)
        .offset(offset)
    }
    
    private func nodePosition(for node: Node) -> CGPoint {
        // Simple grid layout for now
        let index = nodes.firstIndex(of: node) ?? 0
        let row = index / 3
        let col = index % 3
        return CGPoint(
            x: CGFloat(col) * 200 + 100,
            y: CGFloat(row) * 200 + 100
        )
    }
    
    private func edgeColor(for type: Edge.EdgeType) -> Color {
        switch type {
        case .goalProject: return .blue
        case .goalSkill: return .green
        case .projectSkill: return .orange
        }
    }
}

struct NodeView: View {
    let node: Node
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(node.title)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            if let status = node.status {
                Text(status.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .frame(width: 100)
        .background(nodeColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
    
    private var nodeColor: Color {
        switch node.type {
        case .goal: return .blue.opacity(0.2)
        case .project: return .orange.opacity(0.2)
        case .skill: return .green.opacity(0.2)
        }
    }
}

struct EdgeView: Shape {
    let edge: Edge
    let nodes: [Node]
    
    func path(in rect: CGRect) -> Path {
        guard let sourceNode = nodes.first(where: { $0.id == edge.source }),
              let targetNode = nodes.first(where: { $0.id == edge.target }) else {
            return Path()
        }
        
        let sourcePos = CGPoint(x: 0, y: 0) // Simplified for now
        let targetPos = CGPoint(x: 100, y: 100) // Simplified for now
        
        var path = Path()
        path.move(to: sourcePos)
        path.addLine(to: targetPos)
        return path
    }
}

struct GridView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let spacing: CGFloat = 50
                
                // Vertical lines
                for x in stride(from: 0, through: width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                
                // Horizontal lines
                for y in stride(from: 0, through: height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        }
    }
}

struct LegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.headline)
            
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 12, height: 12)
                Text("Goals")
                    .font(.caption)
            }
            
            HStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 12, height: 12)
                Text("Projects")
                    .font(.caption)
            }
            
            HStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 12, height: 12)
                Text("Skills")
                    .font(.caption)
            }
            
            Divider()
            
            HStack {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 2)
                Text("Goal-Project")
                    .font(.caption)
            }
            
            HStack {
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 20, height: 2)
                Text("Goal-Skill")
                    .font(.caption)
            }
            
            HStack {
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 20, height: 2)
                Text("Project-Skill")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationView {
        DependencyGraphView()
            .modelContainer(for: [
                ProfessionalGoal.self,
                Project.self,
                Skill.self
            ], inMemory: true)
    }
} 