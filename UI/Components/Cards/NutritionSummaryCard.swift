import SwiftUI

struct NutritionSummaryCard: View {
    @ObservedObject var nutritionStore: NutritionStore
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("Daily Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Nutrition circles
            HStack(spacing: 20) {
                NutritionCircle(
                    title: "Calories",
                    current: nutritionStore.getTodaysTotalCalories(),
                    goal: 2000,
                    color: .blue
                )
                
                NutritionCircle(
                    title: "Protein",
                    current: nutritionStore.getTodaysTotalProtein(),
                    goal: 150,
                    color: .green,
                    unit: "g"
                )
                
                NutritionCircle(
                    title: "Carbs",
                    current: nutritionStore.getTodaysTotalCarbs(),
                    goal: 250,
                    color: .orange,
                    unit: "g"
                )
                
                NutritionCircle(
                    title: "Fat",
                    current: nutritionStore.getTodaysTotalFat(),
                    goal: 65,
                    color: .red,
                    unit: "g"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct NutritionCircle: View {
    let title: String
    let current: Int
    let goal: Int
    let color: Color
    var unit: String = ""
    
    private var percentage: Double {
        min(Double(current) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(current)")
                        .font(.system(.title3, design: .rounded))
                        .bold()
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(width: 60, height: 60)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
} 