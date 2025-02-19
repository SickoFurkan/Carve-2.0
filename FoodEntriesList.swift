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
                MealRow(meal: meal)
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

struct MealRow: View {
    let meal: Meal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.headline)
                Text(meal.time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(meal.calories) kcal")
                    .font(.subheadline)
                    .bold()
                
                HStack(spacing: 8) {
                    NutrientLabel(value: meal.protein, unit: "P")
                    NutrientLabel(value: meal.carbs, unit: "C")
                    NutrientLabel(value: meal.fat, unit: "F")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct NutrientLabel: View {
    let value: Int
    let unit: String
    
    var body: some View {
        Text("\(value)\(unit)")
            .font(.caption)
            .foregroundColor(.gray)
    }
} 