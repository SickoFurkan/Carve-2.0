import SwiftUI

struct FoodEntriesList: View {
    @ObservedObject var viewModel: FoodEntryViewModel
    @ObservedObject var nutritionStore: NutritionStore
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Today's Meals")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(nutritionStore.getMealsForDate(selectedDate)) { meal in
                MealRow(meal: meal, style: .detailed)
            }
            
            if nutritionStore.getMealsForDate(selectedDate).isEmpty {
                Text("No meals added yet")
                    .foregroundColor(.gray)
                    .italic()
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}