import SwiftUI

struct NutritionalGoalsSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Voedingsdoelen")
                .font(.headline)
                .padding(.bottom, 8)
            
            Group {
                NutritionalGoalRow(label: "Dagelijkse calorieën", value: $viewModel.tempDailyCalorieGoal, unit: "kcal")
                NutritionalGoalRow(label: "Eiwitten", value: $viewModel.tempDailyProteinGoal, unit: "g")
                NutritionalGoalRow(label: "Koolhydraten", value: $viewModel.tempDailyCarbsGoal, unit: "g")
                NutritionalGoalRow(label: "Vetten", value: $viewModel.tempDailyFatGoal, unit: "g")
            }
            
            Button("Bereken aanbevolen doelen") {
                viewModel.calculateRecommendedGoals()
            }
            .padding(.top)
        }
    }
} 