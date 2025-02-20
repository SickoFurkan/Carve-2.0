import SwiftUI

struct SuggestionsView: View {
    @StateObject private var viewModel = SuggestionsViewModel()
    @State private var showingNewSuggestion = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var suggestions: [FoodSuggestion] = []
    @State private var selectedSuggestion: FoodSuggestion?
    @ObservedObject var nutritionStore: NutritionStore
    @Environment(\.dismiss) var dismiss
    
    init(nutritionStore: NutritionStore) {
        self.nutritionStore = nutritionStore
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(suggestions) { suggestion in
                    SuggestionRow(suggestion: suggestion, viewModel: viewModel)
                        .onTapGesture {
                            Task {
                                await handleSelection(suggestion)
                            }
                        }
                }
            }
            .navigationTitle("Suggesties")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewSuggestion = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Gereed") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNewSuggestion) {
                NewSuggestionView(viewModel: viewModel)
            }
            .task {
                await loadSuggestions()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    @MainActor
    private func loadSuggestions() async {
        do {
            suggestions = try await viewModel.getSuggestions()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    @MainActor
    private func handleSelection(_ suggestion: FoodSuggestion) async {
        do {
            let analysis = try await viewModel.analyzeSuggestion(suggestion)
            if let analysis = analysis {
                nutritionStore.addMeal(Meal(
                    id: UUID(),
                    name: suggestion.name,
                    calories: analysis.calories,
                    protein: analysis.protein,
                    carbs: analysis.carbs,
                    fat: analysis.fat,
                    time: DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
                ), for: Date())
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct SuggestionRow: View {
    let suggestion: FoodSuggestion
    @ObservedObject var viewModel: SuggestionsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.name)
                    .font(.headline)
                Spacer()
                Text("@\(suggestion.username)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(suggestion.description)
                .font(.body)
                .lineLimit(3)
            
            HStack {
                Button(action: {
                    Task {
                        await viewModel.toggleUpvote(for: suggestion)
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.hasUpvoted(suggestion) ? "hand.thumbsup.fill" : "hand.thumbsup")
                        Text("\(suggestion.upvotes)")
                    }
                    .foregroundColor(viewModel.hasUpvoted(suggestion) ? .blue : .gray)
                }
                
                Spacer()
                
                Text(formatDate(suggestion.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct NewSuggestionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SuggestionsViewModel
    @State private var title = ""
    @State private var description = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nieuwe Suggestie")) {
                    TextField("Titel", text: $title)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section {
                    Button("Plaatsen") {
                        submitSuggestion()
                    }
                    .disabled(title.isEmpty || description.isEmpty)
                }
            }
            .navigationTitle("Nieuwe Suggestie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func submitSuggestion() {
        Task {
            do {
                try await viewModel.addSuggestion(title: title, description: description)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct NewSuggestionView_Previews: PreviewProvider {
    static var previews: some View {
        NewSuggestionView(viewModel: SuggestionsViewModel())
    }
}

#Preview {
    SuggestionsView(nutritionStore: NutritionStore())
        .environmentObject(FirebaseService.shared)
} 