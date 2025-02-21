import SwiftUI

struct ForkDownsView: View {
    @Binding var selectedDate: Date
    @ObservedObject var nutritionStore: NutritionStore
    @State private var showingAddFood = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Nutrition Summary Card
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Nutrition")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        NutritionStatView(
                            value: "\(nutritionStore.getTotalCaloriesForDate(selectedDate))",
                            label: "Calories",
                            icon: "flame.fill",
                            unit: "kcal"
                        )
                        
                        NutritionStatView(
                            value: "\(nutritionStore.getTotalProteinForDate(selectedDate))",
                            label: "Protein",
                            icon: "chart.bar.fill",
                            unit: "g"
                        )
                        
                        NutritionStatView(
                            value: "\(nutritionStore.getTotalCarbsForDate(selectedDate))",
                            label: "Carbs",
                            icon: "chart.pie.fill",
                            unit: "g"
                        )
                    }
                }
                .padding()
            }
            .cardStyle()
            
            // Recent Meals Card
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Meals")
                        .font(.headline)
                    
                    ForEach(nutritionStore.getMealsForDate(selectedDate)) { meal in
                        MealRow(meal: meal)
                    }
                    
                    Button(action: {
                        showingAddFood = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Meal")
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
            .cardStyle()
        }
        .standardPageLayout()
        .sheet(isPresented: $showingAddFood) {
            AddWorkoutFoodSheet(isPresented: $showingAddFood, nutritionStore: nutritionStore)
        }
    }
}

struct NutritionStatView: View {
    let value: String
    let label: String
    let icon: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.orange)
            Text(value + unit)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MealRow: View {
    let meal: Meal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.subheadline)
                Text("\(meal.calories) kcal")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(meal.timeString)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
} 