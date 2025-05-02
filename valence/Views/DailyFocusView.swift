import SwiftUI
import SwiftData

struct DailyFocusView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dailyFocusItems: [DailyFocus]
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
    var filteredItems: [DailyFocus] {
        if searchText.isEmpty {
            return dailyFocusItems
        }
        return dailyFocusItems.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredItems) { item in
                    DailyFocusItemRow(item: item)
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Daily Focus")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Daily Focus", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search daily focus items")
            .sheet(isPresented: $showingAddSheet) {
                AddDailyFocusSheet()
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredItems[index])
            }
        }
    }
}

struct DailyFocusItemRow: View {
    @Bindable var item: DailyFocus
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.headline)
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $item.isCompleted)
                .labelsHidden()
        }
    }
}

struct AddDailyFocusSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $description)
            }
            .navigationTitle("New Daily Focus")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") {
                    addItem()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = DailyFocus(title: title, description: description)
            modelContext.insert(newItem)
        }
        dismiss()
    }
}

#Preview {
    DailyFocusView()
        .modelContainer(for: DailyFocus.self, inMemory: true)
} 