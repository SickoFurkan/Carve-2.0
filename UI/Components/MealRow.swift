import SwiftUI

public enum MealRowStyle {
    case compact
    case detailed
}

public struct MealRow: View {
    private let meal: Meal
    private let style: MealRowStyle
    
    public init(meal: Meal, style: MealRowStyle = .detailed) {
        self.meal = meal
        self.style = style
    }
    
    public var body: some View {
        switch style {
        case .compact:
            compactView
        case .detailed:
            detailedView
        }
    }
    
    private var compactView: some View {
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
    
    private var detailedView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.headline)
                Text(meal.timeString)
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

private struct NutrientLabel: View {
    let value: Int
    let unit: String
    
    var body: some View {
        Text("\(value)\(unit)")
            .font(.caption)
            .foregroundColor(.gray)
    }
} 